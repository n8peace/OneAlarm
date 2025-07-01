import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';
import { CONFIG } from './config.ts';
import { getAllClipIds, getClipTemplate } from './config.ts';
import { validateVoice } from '../_shared/constants/config.ts';
import type { UserPreferences, AudioClip, GeneratedClip, FailedClip, S3UploadResult, OpenAITTSRequest } from './types.ts';

// Initialize Supabase client
const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Database service for user preferences and audio records
export class DatabaseService {
  private supabase: any;

  constructor() {
    this.supabase = supabase;
  }

  public getClient() {
    return this.supabase;
  }

  async getUserPreferences(userId: string): Promise<UserPreferences | null> {
    try {
      const { data, error } = await this.supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      if (error) {
        console.error('Error fetching user preferences:', error);
        return null;
      }

      return data;
    } catch (error) {
      console.error('Exception fetching user preferences:', error);
      return null;
    }
  }

  async createAudioFileRecord(record: {
    user_id: string;
    script_text: string;
    audio_url: string;
    audio_type: string;
    duration_seconds?: number;
    error?: string;
    file_size?: number;
    alarm_id?: string;
    expires_at?: string;
  }): Promise<string | null> {
    try {
      const insertData = {
        user_id: record.user_id,
        script_text: record.script_text,
        audio_url: record.audio_url,
        audio_type: record.audio_type,
        duration_seconds: record.duration_seconds || null,
        error: record.error || null,
        file_size: record.file_size || null,
        alarm_id: record.alarm_id || null,
        expires_at: record.expires_at || null,
        generated_at: new Date().toISOString(),
        status: 'ready',
        cache_status: 'pending'
      };
      
      const { data, error } = await this.supabase
        .from('audio')
        .insert(insertData)
        .select('id')
        .single();

      if (error) {
        console.error(`❌ Database insertion error:`, error);
        return null;
      }

      return data.id;
    } catch (error) {
      console.error(`❌ Exception creating audio record:`, error);
      return null;
    }
  }

  async updateAudioStatus(audioId: string, status: 'ready' | 'failed', audioUrl?: string, fileSize?: number): Promise<void> {
    try {
      const updateData: any = {
        status
      };

      if (status === 'ready' && audioUrl) {
        updateData.audio_url = audioUrl;
        updateData.file_size = fileSize;
      }

      const { error } = await this.supabase
        .from('audio')
        .update(updateData)
        .eq('id', audioId);

      if (error) {
        console.error('Failed to update audio status:', error);
        throw new Error(`Failed to update audio status: ${error.message}`);
      }
    } catch (error) {
      console.error('Exception updating audio status:', error);
      throw error;
    }
  }

  async logEvent(eventType: string, userId: string, meta?: Record<string, any>): Promise<void> {
    try {
      await this.supabase
        .from('logs')
        .insert({
          event_type: eventType,
          user_id: userId,
          meta: meta || {},
          created_at: new Date().toISOString()
        });
    } catch (error) {
      console.error('Error logging event:', error);
    }
  }

  async checkExistingAudioFiles(userId: string): Promise<Record<string, string>> {
    try {
      const { data, error } = await this.supabase
        .from('audio')
        .select('audio_type, audio_url')
        .eq('user_id', userId)
        .is('error', null);

      if (error) {
        console.error('Error checking existing audio files:', error);
        return {};
      }

      const existingFiles: Record<string, string> = {};
      data?.forEach((record: any) => {
        existingFiles[record.audio_type] = record.audio_url;
      });

      return existingFiles;
    } catch (error) {
      console.error('Exception checking existing audio files:', error);
      return {};
    }
  }
}

// OpenAI TTS service
export class OpenAITTSService {
  private apiKey: string;
  private config = CONFIG.openai;

  constructor() {
    this.apiKey = Deno.env.get('OPENAI_API_KEY')!;
    if (!this.apiKey) {
      throw new Error('OPENAI_API_KEY environment variable is required');
    }
  }

  async generateSpeech(text: string, voice: string): Promise<{ audioBuffer: ArrayBuffer; durationSeconds: number } | null> {
    const requestBody: OpenAITTSRequest = {
      model: this.config.model,
      input: text,
      voice: voice,
      response_format: 'aac',
      speed: this.config.speed,
      instructions: this.config.instructions
    };

    try {
      const response = await fetch(this.config.apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(requestBody)
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`OpenAI TTS failed: ${response.status} - ${errorText}`);
      }

      const audioBuffer = await response.arrayBuffer();
      
      // Calculate approximate duration based on script length and voice speed
      // Average speaking rate is ~150 words per minute, adjusted for voice speed
      const wordCount = text.split(' ').length;
      const baseDurationSeconds = (wordCount / 150) * 60; // Base duration at normal speed
      const adjustedDurationSeconds = baseDurationSeconds / this.config.speed;

      return {
        audioBuffer,
        durationSeconds: Math.round(adjustedDurationSeconds)
      };
    } catch (error) {
      console.error('OpenAI TTS generation failed:', error);
      return null;
    }
  }

  async generateSpeechWithRetry(text: string, voice: string, maxRetries: number = 3): Promise<{ audioBuffer: ArrayBuffer; durationSeconds: number } | null> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      const result = await this.generateSpeech(text, voice);
      if (result) return result;
      
      if (attempt < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, this.config.retryDelay * attempt));
      }
    }
    return null;
  }
}

// Supabase Storage service
export class SupabaseStorageService {
  private supabase: any;
  private config = CONFIG.storage;

  constructor() {
    this.supabase = supabase;
  }

  async uploadAudioFile(
    audioData: ArrayBuffer, 
    userId: string, 
    clipId: string
  ): Promise<S3UploadResult> {
    // console.log(`🔍 DEBUG: Starting storage upload for clip: ${clipId}, user: ${userId}`);
    // console.log(`🔍 DEBUG: Audio data size: ${audioData.byteLength} bytes`);
    
    try {
      // Construct proper path: users/{userId}/audio/{clipId}.aac
      const fileName = `${this.config.pathPrefix}/${userId}/${this.config.audioFolder}/${clipId}.${this.config.fileExtension}`;
      const contentType = 'audio/aac';
      const maxSize = 10 * 1024 * 1024; // 10MB limit

      // console.log(`🔍 DEBUG: Storage config:`, {
      //   bucket: this.config.bucket,
      //   pathPrefix: this.config.pathPrefix,
      //   audioFolder: this.config.audioFolder,
      //   fileExtension: this.config.fileExtension
      // });
      // console.log(`🔍 DEBUG: File path: ${fileName}`);
      // console.log(`🔍 DEBUG: Content type: ${contentType}`);

      if (audioData.byteLength > maxSize) {
        // console.error(`❌ DEBUG: File too large: ${audioData.byteLength} bytes (max: ${maxSize})`);
        return {
          success: false,
          error: 'File too large',
          url: null,
          fileSize: 0
        };
      }

      // Convert ArrayBuffer to Uint8Array for Supabase Storage
      // console.log(`🔍 DEBUG: Converting ArrayBuffer to Uint8Array...`);
      const uint8Array = new Uint8Array(audioData);
      // console.log(`✅ DEBUG: Conversion complete, Uint8Array length: ${uint8Array.length}`);

      // console.log(`🔍 DEBUG: Calling Supabase storage upload...`);
      const { error } = await this.supabase.storage
        .from(this.config.bucket)
        .upload(fileName, uint8Array, {
          contentType,
          upsert: true
        });

      if (error) {
        // console.error(`❌ DEBUG: Supabase Storage upload failed:`, error);
        // console.error(`❌ DEBUG: Error details:`, {
        //   message: error.message,
        //   details: error.details,
        //   hint: error.hint,
        //   code: error.code
        // });
        return {
          success: false,
          error: error.message,
          url: null,
          fileSize: 0
        };
      }

      // Fetch the public URL after successful upload
      const { data: publicUrlData } = this.supabase.storage
        .from(this.config.bucket)
        .getPublicUrl(fileName);
      const publicUrl = publicUrlData?.publicUrl || null;

      if (!publicUrl) {
        // console.error(`❌ DEBUG: Could not get public URL for uploaded file: ${fileName}`);
        return {
          success: false,
          error: 'Could not get public URL after upload',
          url: null,
          fileSize: audioData.byteLength
        };
      }

      // console.log(`✅ DEBUG: Supabase Storage upload successful, public URL: ${publicUrl}`);

      return {
        success: true,
        error: null,
        url: publicUrl,
        fileSize: audioData.byteLength
      };

    } catch (error) {
      // console.error(`❌ DEBUG: Supabase Storage upload failed with exception:`, error);
      // console.error(`❌ DEBUG: Exception details:`, {
      //   name: error instanceof Error ? error.name : 'Unknown',
      //   message: error instanceof Error ? error.message : 'Unknown error',
      //   stack: error instanceof Error ? error.stack : undefined
      // });
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        url: null,
        fileSize: 0
      };
    }
  }
}

// Audio generation orchestrator
export class AudioGenerationService {
  public db: DatabaseService;
  private tts: OpenAITTSService;
  private storage: SupabaseStorageService;

  constructor() {
    this.db = new DatabaseService();
    this.tts = new OpenAITTSService();
    this.storage = new SupabaseStorageService();
  }

  async generateUserAudioClips(userId: string, forceRegenerate: boolean = false): Promise<{
    success: boolean;
    generatedClips: GeneratedClip[];
    failedClips: FailedClip[];
    message: string;
  }> {
    // console.log(`🔍 DEBUG: Starting generateUserAudioClips for user: ${userId}, forceRegenerate: ${forceRegenerate}`);
    
    // Log start to database
    // await this.db.logEvent('debug_audio_generation_start', userId, {
    //   forceRegenerate,
    //   timestamp: new Date().toISOString()
    // });
    
    try {
      // Test database connectivity first
      // console.log(`🔍 DEBUG: Testing database connectivity...`);
      const { count, error } = await this.db.getClient()
        .from('audio')
        .select('*', { count: 'exact', head: true });
      
      if (error) {
        console.error(`Database connectivity test failed:`, error);
        // await this.db.logEvent('debug_database_connectivity_failed', userId, { error: error.message });
        return {
          success: false,
          generatedClips: [],
          failedClips: [],
          message: `Database connectivity failed: ${error.message}`
        };
      }
      // console.log(`✅ DEBUG: Database connectivity test passed, count: ${count}`);
      // await this.db.logEvent('debug_database_connectivity_passed', userId, { count });
    } catch (error) {
      console.error(`Database connectivity test exception:`, error);
      // await this.db.logEvent('debug_database_connectivity_exception', userId, { error: (error as Error).message });
      return {
        success: false,
        generatedClips: [],
        failedClips: [],
        message: `Database connectivity exception: ${(error as Error).message}`
      };
    }
    
    // Get user preferences
    // console.log(`🔍 DEBUG: Fetching user preferences for user: ${userId}`);
    const preferences = await this.db.getUserPreferences(userId);
    if (!preferences) {
      console.error(`User preferences not found for user: ${userId}`);
      // await this.db.logEvent('debug_user_preferences_not_found', userId, {});
      return {
        success: false,
        generatedClips: [],
        failedClips: [],
        message: 'User preferences not found'
      };
    }
    // console.log(`✅ DEBUG: User preferences found:`, {
    //   user_id: preferences.user_id,
    //   tts_voice: preferences.tts_voice,
    //   preferred_name: preferences.preferred_name
    // });
    // await this.db.logEvent('debug_user_preferences_found', userId, {
    //   tts_voice: preferences.tts_voice,
    //   preferred_name: preferences.preferred_name
    // });

    // Check existing files if not forcing regeneration
    let existingFiles: Record<string, string> = {};
    if (!forceRegenerate) {
      // console.log(`🔍 DEBUG: Checking existing audio files for user: ${userId}`);
      existingFiles = await this.db.checkExistingAudioFiles(userId);
      // console.log(`✅ DEBUG: Found ${Object.keys(existingFiles).length} existing files:`, Object.keys(existingFiles));
      // await this.db.logEvent('debug_existing_files_check', userId, {
      //   existingFilesCount: Object.keys(existingFiles).length,
      //   existingFiles: Object.keys(existingFiles)
      // });
    } else {
      // console.log(`🔍 DEBUG: Force regenerate enabled, skipping existing file check`);
      // await this.db.logEvent('debug_force_regenerate_enabled', userId, {});
    }

    // Generate clips
    // console.log(`🔍 DEBUG: Creating audio clips...`);
    const clips = this.createAudioClips(preferences);
    // console.log(`✅ DEBUG: Created ${clips.length} clips:`, clips.map(c => c.id));
    // await this.db.logEvent('debug_clips_created', userId, {
    //   clipCount: clips.length,
    //   clipIds: clips.map(c => c.id)
    // });
    
    const generatedClips: GeneratedClip[] = [];
    const failedClips: FailedClip[] = [];

    // Process clips in batches
    const batchSize = CONFIG.generation.batchSize;
    // console.log(`🔍 DEBUG: Processing clips in batches of ${batchSize}`);
    
    for (let i = 0; i < clips.length; i += batchSize) {
      const batch = clips.slice(i, i + batchSize);
      // console.log(`🔍 DEBUG: Processing batch ${Math.floor(i/batchSize) + 1}:`, batch.map(c => c.id));
      // await this.db.logEvent('debug_batch_start', userId, {
      //   batchNumber: Math.floor(i/batchSize) + 1,
      //   clipIds: batch.map(c => c.id)
      // });
      
      const batchResults = await this.processClipBatch(batch, preferences, existingFiles);
      
      generatedClips.push(...batchResults.generatedClips);
      failedClips.push(...batchResults.failedClips);
      // console.log(`✅ DEBUG: Batch ${Math.floor(i/batchSize) + 1} completed - Generated: ${batchResults.generatedClips.length}, Failed: ${batchResults.failedClips.length}`);
      // await this.db.logEvent('debug_batch_complete', userId, {
      //   batchNumber: Math.floor(i/batchSize) + 1,
      //   generatedCount: batchResults.generatedClips.length,
      //   failedCount: batchResults.failedClips.length,
      //   failedClips: batchResults.failedClips.map(f => ({ clipId: f.clipId, error: f.error }))
      // });
    }

    // Consider success if we have any generated clips OR if we have existing files available
    const hasGeneratedClips = generatedClips.length > 0;
    const hasExistingFiles = Object.keys(existingFiles).length > 0;
    const success = hasGeneratedClips || hasExistingFiles;
    
    const message = success 
      ? hasGeneratedClips 
        ? `Generated ${generatedClips.length} audio clips successfully`
        : `Audio clips already exist and are available`
      : 'Failed to generate any audio clips';

    // console.log(`🔍 DEBUG: Final results - Success: ${success}, Generated: ${generatedClips.length}, Failed: ${failedClips.length}, Existing: ${Object.keys(existingFiles).length}`);

    // Log results with correct success determination
    // console.log(`🔍 DEBUG: Logging completion event...`);
    // await this.db.logEvent('audio_generation_completed', userId, {
    //   totalClips: clips.length,
    //   generatedCount: generatedClips.length,
    //   failedCount: failedClips.length,
    //   forceRegenerate,
    //   success,
    //   hasExistingFiles,
    //   existingFilesCount: Object.keys(existingFiles).length
    // });
    // console.log(`✅ DEBUG: Completion event logged`);

    return {
      success,
      generatedClips,
      failedClips,
      message
    };
  }

  private createAudioClips(preferences: UserPreferences): AudioClip[] {
    const clips: AudioClip[] = [];
    const clipIds = getAllClipIds();

    for (const clipId of clipIds) {
      const template = getClipTemplate(clipId);
      if (!template) continue;

      const text = this.interpolateTemplate(template, preferences);
      const clip = CONFIG.clips[clipId as keyof typeof CONFIG.clips];
      
      clips.push({
        id: clipId,
        text,
        fileName: clip.fileName,
        description: clip.description
      });
    }

    return clips;
  }

  private interpolateTemplate(template: string, preferences: UserPreferences): string {
    return template
      .replace('{preferred_name}', preferences.preferred_name || 'there')
      .replace('{location}', preferences.timezone?.split('/').pop() || 'your area');
  }

  private async processClipBatch(
    clips: AudioClip[], 
    preferences: UserPreferences,
    existingFiles: Record<string, string>
  ): Promise<{ generatedClips: GeneratedClip[]; failedClips: FailedClip[] }> {
    const generatedClips: GeneratedClip[] = [];
    const failedClips: FailedClip[] = [];

    // Use shared voice validation instead of hardcoded array
    const voice = validateVoice(preferences.tts_voice);

    // Process clips sequentially to ensure database operations complete
    for (const clip of clips) {
      // Skip if already exists and not forcing regeneration
      if (existingFiles[clip.id]) {
        generatedClips.push({
          clipId: clip.id,
          fileName: clip.fileName,
          audioUrl: existingFiles[clip.id],
          fileSize: 0 // We don't have this info for existing files
        });
        continue;
      }

      try {
        // Generate speech
        const result = await this.tts.generateSpeechWithRetry(clip.text, voice);
        if (!result) {
          failedClips.push({
            clipId: clip.id,
            error: 'TTS generation failed'
          });
          continue;
        }

        // Upload to Supabase Storage
        const uploadResult = await this.storage.uploadAudioFile(result.audioBuffer, preferences.user_id!, clip.id);
        
        if (!uploadResult.success || !uploadResult.url) {
          failedClips.push({
            clipId: clip.id,
            error: uploadResult.error || 'Storage upload failed'
          });
          continue;
        }

        // Save to database
        const recordId = await this.db.createAudioFileRecord({
          user_id: preferences.user_id!,
          script_text: clip.text,
          audio_url: uploadResult.url,
          audio_type: clip.id,
          duration_seconds: result.durationSeconds,
          file_size: uploadResult.fileSize || 0
        });

        if (!recordId) {
          // Consider this a success since the audio file was created and stored
          // The database record can be recreated later if needed
          generatedClips.push({
            clipId: clip.id,
            fileName: clip.fileName,
            audioUrl: uploadResult.url,
            fileSize: uploadResult.fileSize || 0
          });
          continue;
        }

        generatedClips.push({
          clipId: clip.id,
          fileName: clip.fileName,
          audioUrl: uploadResult.url,
          fileSize: uploadResult.fileSize || 0
        });

        // Update audio status only if we have a record ID
        if (recordId) {
          await this.db.updateAudioStatus(recordId, 'ready', uploadResult.url, uploadResult.fileSize);
        }

      } catch (error) {
        console.error(`Error processing clip ${clip.id}:`, error);
        failedClips.push({
          clipId: clip.id,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
      }
    }

    return { generatedClips, failedClips };
  }
}