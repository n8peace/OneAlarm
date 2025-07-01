// Main service for generating alarm audio

import { getSupabaseClient } from '../_shared/utils/database.ts';
import { logEvent } from '../_shared/utils/database.ts';
import { CONFIG, validateVoice } from './config.ts';
import { GPTService } from './utils/gpt-service.ts';
import { TTSService } from './utils/tts-service.ts';
import { StorageService } from './utils/storage-service.ts';
import type { 
  GenerateAlarmAudioResponse, 
  GeneratedClip, 
  FailedClip,
  Alarm,
  UserPreferences,
  WeatherData,
  DailyContent,
  DailyContentResult
} from './types.ts';

export class GenerateAlarmAudioService {
  private gptService: GPTService;
  private ttsService: TTSService;
  private storageService: StorageService;
  private supabase = getSupabaseClient();

  constructor() {
    this.gptService = new GPTService();
    this.ttsService = new TTSService();
    this.storageService = new StorageService();
  }

  async generateAlarmAudio(alarmId: string, forceRegenerate: boolean = false): Promise<GenerateAlarmAudioResponse> {
    const generatedClips: GeneratedClip[] = [];
    const failedClips: FailedClip[] = [];

    console.log(`🔍 [DEBUG] generateAlarmAudio started for alarmId: ${alarmId}, forceRegenerate: ${forceRegenerate}`);

    try {
      // 1. Fetch alarm and validate
      console.log(`🔍 [DEBUG] Step 1: Fetching alarm ${alarmId}`);
      const alarm = await this.getAlarm(alarmId);
      if (!alarm) {
        console.error(`❌ [DEBUG] Alarm not found: ${alarmId}`);
        throw new Error('Alarm not found');
      }
      console.log(`✅ [DEBUG] Alarm found:`, {
        id: alarm.id,
        user_id: alarm.user_id,
        alarm_date: alarm.alarm_date,
        alarm_time_local: alarm.alarm_time_local,
        alarm_timezone: alarm.alarm_timezone,
        next_trigger_at: alarm.next_trigger_at,
        active: alarm.active
      });

      // 2. Fetch user data
      console.log(`🔍 [DEBUG] Step 2: Fetching user data for user: ${alarm.user_id}`);
      const [userPreferences, weatherData] = await Promise.all([
        this.getUserPreferences(alarm.user_id),
        this.getWeatherData(alarm.user_id)
      ]);
      
      console.log(`✅ [DEBUG] User preferences:`, userPreferences ? {
        user_id: userPreferences.user_id,
        tts_voice: userPreferences.tts_voice,
        news_categories: userPreferences.news_categories,
        preferred_name: userPreferences.preferred_name,
        timezone: userPreferences.timezone
      } : 'null');
      
      console.log(`✅ [DEBUG] Weather data:`, weatherData ? {
        user_id: weatherData.user_id,
        current_temp: weatherData.current_temp,
        condition: weatherData.condition
      } : 'null');

      // 3. Fetch daily content based on user's news category preference
      console.log(`🔍 [DEBUG] Step 3: Fetching daily content`);
      const userNewsCategories = userPreferences?.news_categories || ['general'];
      console.log(`🔍 [DEBUG] User news categories: ${userNewsCategories.join(', ')}`);
      
      // Ensure 'general' is always first if it exists in the array
      const orderedCategories = userNewsCategories.includes('general') 
        ? ['general', ...userNewsCategories.filter(cat => cat !== 'general')]
        : userNewsCategories;
      
      console.log(`🔍 [DEBUG] Ordered categories: ${orderedCategories.join(', ')}`);
      
      // Fetch daily content for all categories, with graceful fallback
      const dailyContentPromises = orderedCategories.map(async (category) => {
        try {
          console.log(`🔍 [DEBUG] Fetching content for category: ${category}`);
          const content = await this.getDailyContent(category);
          console.log(`✅ [DEBUG] Content for ${category}:`, content ? {
            id: content.id,
            news_category: content.news_category,
            headline: content.headline ? content.headline.substring(0, 50) + '...' : 'null'
          } : 'null');
          return { news_category: category, content, success: true };
        } catch (error) {
          console.warn(`⚠️ [DEBUG] Failed to fetch daily content for category ${category}:`, error);
          return { news_category: category, content: null, success: false };
        }
      });
      
      const dailyContentResults = await Promise.all(dailyContentPromises);
      const availableContent = dailyContentResults.filter(result => result.success && result.content);
      console.log(`✅ [DEBUG] Available content categories: ${availableContent.map(r => r.news_category).join(', ')}`);

      // 4. Check if audio already exists (unless forceRegenerate)
      console.log(`🔍 [DEBUG] Step 4: Checking existing audio`);
      if (!forceRegenerate) {
        const existingAudio = await this.getExistingAudio(alarmId);
        console.log(`🔍 [DEBUG] Existing audio count: ${existingAudio.length}`);
        if (existingAudio.length > 0) {
          console.log(`✅ [DEBUG] Audio already exists, returning existing clips`);
          return {
            success: true,
            message: 'Audio already exists for this alarm',
            generatedClips: existingAudio.map(audio => ({
              clipId: audio.id,
              fileName: audio.audio_url?.split('/').pop() || '',
              audioUrl: audio.audio_url || '',
              fileSize: 0,
              audioType: 'combined' as const
            })),
            failedClips: [],
            alarmId,
            userId: alarm.user_id
          };
        }
      }

      // 5. Generate combined audio (weather + content)
      console.log(`🔍 [DEBUG] Step 5: Generating combined audio`);
      try {
        console.log(`🔍 [DEBUG] Calling generateCombinedAudio`);
        const combinedClip = await this.generateCombinedAudio(alarm, userPreferences, weatherData, dailyContentResults);
        console.log(`✅ [DEBUG] Combined audio generated successfully:`, {
          clipId: combinedClip.clipId,
          fileName: combinedClip.fileName,
          fileSize: combinedClip.fileSize,
          audioType: combinedClip.audioType
        });
        generatedClips.push(combinedClip);
        await logEvent('combined_audio_generated', alarm.user_id, { alarm_id: alarmId });
      } catch (error) {
        console.error(`❌ [DEBUG] Combined audio generation failed:`, error);
        failedClips.push({
          clipId: `combined_${alarmId}`,
          error: error instanceof Error ? error.message : 'Unknown error',
          audioType: 'combined'
        });
      }

      // 6. Update queue status
      console.log(`🔍 [DEBUG] Step 6: Updating queue status`);
      const success = generatedClips.length > 0;
      console.log(`🔍 [DEBUG] Success: ${success}, Generated clips: ${generatedClips.length}, Failed clips: ${failedClips.length}`);
      await this.updateQueueStatus(alarmId, success);

      const message = success 
        ? `Generated ${generatedClips.length} audio clips successfully`
        : 'Failed to generate any audio clips';

      console.log(`✅ [DEBUG] generateAlarmAudio completed: ${message}`);

      return {
        success,
        message,
        generatedClips,
        failedClips,
        alarmId,
        userId: alarm.user_id
      };

    } catch (error) {
      console.error(`❌ [DEBUG] generateAlarmAudio failed with error:`, error);
      console.error(`❌ [DEBUG] Error stack:`, error instanceof Error ? error.stack : 'No stack trace');
      await this.updateQueueStatus(alarmId, false, error instanceof Error ? error.message : 'Unknown error');
      throw error;
    }
  }

  async processQueueItems(batchSize: number = 50): Promise<{ processedCount: number; successCount: number; failedCount: number }> {
    try {
      // Get multiple pending queue items
      const { data: queueItems, error } = await this.supabase
        .from('audio_generation_queue')
        .select('alarm_id, user_id')
        .eq('status', 'pending')
        .lte('scheduled_for', new Date().toISOString())
        .order('scheduled_for', { ascending: true })
        .limit(batchSize);

      if (error || !queueItems || queueItems.length === 0) {
        console.log('No pending queue items found');
        return { processedCount: 0, successCount: 0, failedCount: 0 };
      }

      console.log(`Processing ${queueItems.length} queue items`);

      let successCount = 0;
      let failedCount = 0;

      // Process each queue item
      for (const queueItem of queueItems) {
        try {
          console.log(`Processing queue item for alarm: ${queueItem.alarm_id}`);

          // Update status to processing
          await this.supabase
            .from('audio_generation_queue')
            .update({ 
              status: 'processing'
            })
            .eq('alarm_id', queueItem.alarm_id);

          // Generate audio for this alarm
          const result = await this.generateAlarmAudio(queueItem.alarm_id, false);

          if (result.success) {
            successCount++;
          } else {
            failedCount++;
          }

        } catch (error) {
          console.error(`Failed to process alarm ${queueItem.alarm_id}:`, error);
          failedCount++;
          
          // Update queue status to failed
          await this.supabase
            .from('audio_generation_queue')
            .update({ 
              status: 'failed'
            })
            .eq('alarm_id', queueItem.alarm_id);
        }
      }

      return {
        processedCount: queueItems.length,
        successCount,
        failedCount
      };

    } catch (error) {
      console.error('Batch queue processing failed:', error);
      return { processedCount: 0, successCount: 0, failedCount: 0 };
    }
  }

  // Keep the old method for backward compatibility
  async processQueueItem(): Promise<{ alarmId: string; success: boolean } | null> {
    const result = await this.processQueueItems(1);
    if (result.processedCount === 0) {
      return null;
    }
    // For single item processing, we can't easily return the specific alarm ID
    // This method is kept for compatibility but should be deprecated
    return { alarmId: 'batch_processed', success: result.successCount > 0 };
  }

  // Process alarms asynchronously - returns immediately, continues processing in background
  async processQueueItemsAsync(batchSize: number = 10, maxConcurrent: number = 50): Promise<{ queuedCount: number; estimatedTime: number }> {
    try {
      // Fetch pending queue items
      const currentTime = new Date().toISOString();
      const { data: queueItems, error } = await this.supabase
        .from('audio_generation_queue')
        .select('alarm_id, user_id')
        .eq('status', 'pending')
        .lte('scheduled_for', currentTime)
        .order('scheduled_for', { ascending: true })
        .limit(batchSize);

      if (error || !queueItems || queueItems.length === 0) {
        return { queuedCount: 0, estimatedTime: 0 };
      }

      // Atomically mark these items as processing
      const alarmIds = queueItems.map(q => q.alarm_id);
      const { error: updateError } = await this.supabase
        .from('audio_generation_queue')
        .update({ 
          status: 'processing'
        })
        .in('alarm_id', alarmIds);

      if (updateError) {
        return { queuedCount: 0, estimatedTime: 0 };
      }

      // Start processing in background (don't await) - pass the specific items we claimed
      this.processQueueItemsParallel(queueItems, maxConcurrent).then((result) => {
        // background processing complete
      }).catch((error) => {
        // background processing failed
      });

      // Return immediately with queue info
      const estimatedTime = Math.ceil(queueItems.length / maxConcurrent) * 4; // ~4 minutes per batch
      
      return {
        queuedCount: queueItems.length,
        estimatedTime
      };

    } catch (error) {
      return { queuedCount: 0, estimatedTime: 0 };
    }
  }

  // Process alarms in parallel batches to avoid timeouts
  async processQueueItemsParallel(queueItems: Array<{alarm_id: string, user_id: string}>, maxConcurrent: number = 50): Promise<{ processedCount: number; successCount: number; failedCount: number }> {
    try {
      if (!queueItems || queueItems.length === 0) {
        return { processedCount: 0, successCount: 0, failedCount: 0 };
      }

      let successCount = 0;
      let failedCount = 0;

      // Process items in parallel batches
      for (let i = 0; i < queueItems.length; i += maxConcurrent) {
        const batch = queueItems.slice(i, i + maxConcurrent);
        const batchPromises = batch.map(async (queueItem) => {
          try {
            // Generate audio for this alarm
            const result = await this.generateAlarmAudio(queueItem.alarm_id, false);
            // Update queue status to completed for successful generation
            if (result.success) {
              await this.supabase
                .from('audio_generation_queue')
                .update({ 
                  status: 'completed',
                  processed_at: new Date().toISOString()
                })
                .eq('alarm_id', queueItem.alarm_id);
            }
            return {
              alarmId: queueItem.alarm_id,
              success: result.success
            };
          } catch (error) {
            // Update queue status to failed
            await this.supabase
              .from('audio_generation_queue')
              .update({ 
                status: 'failed',
                error_message: error instanceof Error ? error.message : 'Unknown error'
              })
              .eq('alarm_id', queueItem.alarm_id);
            return {
              alarmId: queueItem.alarm_id,
              success: false
            };
          }
        });
        const batchResults = await Promise.all(batchPromises);
        for (const result of batchResults) {
          if (result.success) {
            successCount++;
          } else {
            failedCount++;
          }
        }
      }
      return {
        processedCount: queueItems.length,
        successCount,
        failedCount
      };
    } catch (error) {
      return { processedCount: 0, successCount: 0, failedCount: 0 };
    }
  }

  private async getAlarm(alarmId: string): Promise<Alarm | null> {
    const { data, error } = await this.supabase
      .from('alarms')
      .select('*')
      .eq('id', alarmId)
      .single();

    if (error) {
      throw new Error(`Failed to get alarm: ${error.message}`);
    }

    return data;
  }

  private async getUserPreferences(userId: string): Promise<UserPreferences | null> {
    const { data, error } = await this.supabase
      .from('user_preferences')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) {
      console.warn('Failed to get user preferences:', error.message);
      return null;
    }

    return data;
  }

  private async getWeatherData(userId: string): Promise<WeatherData | null> {
    const { data, error } = await this.supabase
      .from('weather_data')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) {
      console.warn('Failed to get weather data:', error.message);
      return null;
    }

    return data;
  }

  private async getDailyContent(category?: string): Promise<DailyContent | null> {
    let query = this.supabase
      .from('daily_content')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(1);

    const { data, error } = await query.single();

    if (error) {
      console.warn('Failed to get daily content:', error.message);
      return null;
    }

    // If a specific category is requested, extract that category's headlines
    if (category && data) {
      const headlineColumn = `${category}_headlines` as keyof typeof data;
      const headline = data[headlineColumn] as string;
      
      return {
        ...data,
        // For backward compatibility, add the old fields
        news_category: category,
        headline: headline
      } as DailyContent;
    }

    return data;
  }

  private async getExistingAudio(alarmId: string): Promise<any[]> {
    const { data, error } = await this.supabase
      .from('audio')
      .select('*')
      .eq('alarm_id', alarmId)
      .in('audio_type', ['weather', 'content', 'combined']);

    if (error) {
      console.warn('Failed to get existing audio:', error.message);
      return [];
    }

    return data || [];
  }

  private async generateCombinedAudio(
    alarm: Alarm, 
    userPreferences: UserPreferences | null, 
    weatherData: WeatherData | null,
    dailyContentResults: DailyContentResult[]
  ): Promise<GeneratedClip> {
    console.log(`🔍 [DEBUG] generateCombinedAudio started for alarm: ${alarm.id}`);
    
    const voice = validateVoice(userPreferences?.tts_voice || null);
    console.log(`🔍 [DEBUG] Using TTS voice: ${voice}`);
    
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const fileName = `${alarm.id}_combined_${timestamp}.aac`;
    const clipId = `combined_${alarm.id}`;
    
    console.log(`🔍 [DEBUG] Generated filename: ${fileName}`);

    try {
      // Generate combined script with GPT
      console.log(`🔍 [DEBUG] Calling GPT service to generate combined script`);
      const combinedScript = await this.gptService.generateCombinedScript(alarm, weatherData, userPreferences, dailyContentResults);
      console.log(`✅ [DEBUG] GPT script generated successfully, length: ${combinedScript.length}`);

      // Generate audio with TTS
      console.log(`🔍 [DEBUG] Calling TTS service to generate speech`);
      const ttsResponse = await this.ttsService.generateSpeech(combinedScript, voice);
      console.log(`✅ [DEBUG] TTS audio generated successfully, fileSize: ${ttsResponse.fileSize}, duration: ${ttsResponse.durationSeconds}s`);

      // Upload to storage
      console.log(`🔍 [DEBUG] Uploading audio file to storage`);
      const audioUrl = await this.storageService.uploadAudioFile(
        ttsResponse.audioBuffer,
        fileName,
        'combined'
      );
      console.log(`✅ [DEBUG] Audio uploaded successfully, URL: ${audioUrl}`);

      // Save metadata to database
      console.log(`🔍 [DEBUG] Saving audio metadata to database`);
      const expiresAt = new Date(Date.now() + CONFIG.audio.expirationHours * 60 * 60 * 1000);
      await this.saveAudioMetadata(alarm.id, alarm.user_id, 'combined', fileName, audioUrl, combinedScript, expiresAt, ttsResponse.fileSize, ttsResponse.durationSeconds);
      console.log(`✅ [DEBUG] Audio metadata saved successfully`);

      const result = {
        clipId,
        fileName,
        audioUrl,
        fileSize: ttsResponse.fileSize,
        audioType: 'combined' as const
      };
      
      console.log(`✅ [DEBUG] generateCombinedAudio completed successfully:`, result);
      return result;
      
    } catch (error) {
      console.error(`❌ [DEBUG] generateCombinedAudio failed:`, error);
      console.error(`❌ [DEBUG] Error stack:`, error instanceof Error ? error.stack : 'No stack trace');
      throw error;
    }
  }

  private async saveAudioMetadata(
    alarmId: string,
    userId: string,
    audioType: 'weather' | 'content' | 'combined',
    fileName: string,
    audioUrl: string,
    scriptText: string,
    expiresAt: Date,
    fileSize: number,
    durationSeconds: number
  ): Promise<void> {
    const insertData = {
      user_id: userId,
      alarm_id: alarmId,
      audio_type: audioType,
      script_text: scriptText,
      audio_url: audioUrl,
      generated_at: new Date().toISOString(),
      expires_at: expiresAt.toISOString(),
      file_size: fileSize,
      duration_seconds: durationSeconds,
      status: 'ready', // Audio is ready for client consumption
      cache_status: 'pending' // Client needs to cache this
    };
    console.log('Attempting to insert audio metadata:', insertData);
    
    // Use regular insert instead of upsert since there's no unique constraint
    const { error } = await this.supabase
      .from('audio')
      .insert(insertData);
      
    if (error) {
      console.error('Failed to save audio metadata:', error);
      throw new Error(`Failed to save audio metadata: ${error.message}`);
    }
    console.log('Successfully inserted audio metadata for alarm:', alarmId, 'audioType:', audioType);
  }

  private async updateQueueStatus(
    alarmId: string, 
    success: boolean, 
    errorMessage?: string
  ): Promise<void> {
    const updateData: any = {
      status: success ? 'completed' : 'failed'
    };

    if (success) {
      updateData.processed_at = new Date().toISOString();
    } else if (errorMessage) {
      updateData.error_message = errorMessage;
    }

    const { error } = await this.supabase
      .from('audio_generation_queue')
      .update(updateData)
      .eq('alarm_id', alarmId);

    if (error) {
      console.error('Failed to update queue status:', error);
    }
  }

  private async markAudioGenerating(alarmId: string, userId: string, audioType: 'weather' | 'content'): Promise<string> {
    // Create initial audio record with 'generating' status
    const { data, error } = await this.supabase
      .from('audio')
      .insert({
        user_id: userId,
        alarm_id: alarmId,
        audio_type: audioType,
        status: 'generating',
        cache_status: 'pending',
        generated_at: new Date().toISOString()
      })
      .select('id')
      .single();

    if (error) {
      throw new Error(`Failed to create audio record: ${error.message}`);
    }

    return data.id;
  }

  private async updateAudioStatus(audioId: string, status: 'ready' | 'failed', audioUrl?: string, fileSize?: number, durationSeconds?: number): Promise<void> {
    const updateData: any = {
      status,
      updated_at: new Date().toISOString()
    };

    if (status === 'ready' && audioUrl) {
      updateData.audio_url = audioUrl;
      updateData.file_size = fileSize;
      updateData.duration_seconds = durationSeconds;
    }

    const { error } = await this.supabase
      .from('audio')
      .update(updateData)
      .eq('id', audioId);

    if (error) {
      throw new Error(`Failed to update audio status: ${error.message}`);
    }
  }
} 