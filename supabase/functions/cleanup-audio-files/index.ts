import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { getSupabaseClient } from '../_shared/utils/database.ts';
import { logFunctionStart, logFunctionEnd, logFunctionError, createHealthCheckResponse, createCorsResponse } from '../_shared/utils/logging.ts';

const FUNCTION_NAME = 'cleanup-audio-files';

interface CleanupResult {
  databaseRecordsDeleted: number;
  storageFilesDeleted: number;
  errors: string[];
  success: boolean;
}

class AudioCleanupService {
  private supabase = getSupabaseClient();

  async cleanupExpiredAudio(): Promise<CleanupResult> {
    const result: CleanupResult = {
      databaseRecordsDeleted: 0,
      storageFilesDeleted: 0,
      errors: [],
      success: true
    };

    try {
      console.log('Starting audio cleanup process...');

      // Step 1: Get expired audio records from database
      const { data: expiredAudio, error: fetchError } = await this.supabase
        .from('audio')
        .select('id, audio_url, audio_type, alarm_id')
        .lt('expires_at', new Date().toISOString())
        .not('audio_url', 'is', null);

      if (fetchError) {
        throw new Error(`Failed to fetch expired audio records: ${fetchError.message}`);
      }

      if (!expiredAudio || expiredAudio.length === 0) {
        console.log('No expired audio files found');
        return result;
      }

      console.log(`Found ${expiredAudio.length} expired audio files to clean up`);

      // Step 2: Delete storage files
      const storageErrors = await this.deleteStorageFiles(expiredAudio);
      result.errors.push(...storageErrors);
      result.storageFilesDeleted = expiredAudio.length - storageErrors.length;

      // Step 3: Delete database records
      const { error: deleteError } = await this.supabase
        .from('audio')
        .delete()
        .lt('expires_at', new Date().toISOString());

      if (deleteError) {
        throw new Error(`Failed to delete expired audio records: ${deleteError.message}`);
      }

      result.databaseRecordsDeleted = expiredAudio.length;

      console.log(`Cleanup completed: ${result.databaseRecordsDeleted} database records deleted, ${result.storageFilesDeleted} storage files deleted`);

      return result;

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Audio cleanup failed:', errorMessage);
      result.errors.push(errorMessage);
      result.success = false;
      return result;
    }
  }

  private async deleteStorageFiles(audioRecords: any[]): Promise<string[]> {
    const errors: string[] = [];
    const bucketName = 'audio-files';

    for (const record of audioRecords) {
      try {
        // Extract file path from audio_url
        const filePath = this.extractFilePathFromUrl(record.audio_url);
        
        if (!filePath) {
          errors.push(`Could not extract file path from URL: ${record.audio_url}`);
          continue;
        }

        // Delete from storage
        const { error } = await this.supabase.storage
          .from(bucketName)
          .remove([filePath]);

        if (error) {
          errors.push(`Failed to delete storage file ${filePath}: ${error.message}`);
        } else {
          console.log(`Deleted storage file: ${filePath}`);
        }

      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        errors.push(`Error deleting storage file for record ${record.id}: ${errorMessage}`);
      }
    }

    return errors;
  }

  private extractFilePathFromUrl(audioUrl: string): string | null {
    try {
      // Extract path from URL like: https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/alarm-audio/weather/uuid_weather_2024-01-01T12-00-00-000Z.aac
      const url = new URL(audioUrl);
      const pathParts = url.pathname.split('/');
      
      // Find the bucket name and extract everything after it
      const bucketIndex = pathParts.findIndex(part => part === 'audio-files');
      if (bucketIndex === -1 || bucketIndex >= pathParts.length - 1) {
        return null;
      }

      // Return the path after the bucket name
      return pathParts.slice(bucketIndex + 1).join('/');
    } catch (error) {
      console.error('Error extracting file path from URL:', error);
      return null;
    }
  }
}

// Initialize the cleanup service
const cleanupService = new AudioCleanupService();

serve(async (req) => {
  const requestId = crypto.randomUUID();
  
  try {
    logFunctionStart(FUNCTION_NAME, { requestId });

    // Handle CORS
    if (req.method === 'OPTIONS') {
      return createCorsResponse();
    }

    // Handle health check
    if (req.method === 'GET') {
      return createHealthCheckResponse(FUNCTION_NAME);
    }

    // Handle cleanup request
    if (req.method === 'POST') {
      const result = await cleanupService.cleanupExpiredAudio();

      logFunctionEnd(FUNCTION_NAME, { 
        requestId,
        databaseRecordsDeleted: result.databaseRecordsDeleted,
        storageFilesDeleted: result.storageFilesDeleted,
        errorCount: result.errors.length
      });

      return new Response(
        JSON.stringify({
          success: result.success,
          message: `Cleanup completed: ${result.databaseRecordsDeleted} database records deleted, ${result.storageFilesDeleted} storage files deleted`,
          result,
          timestamp: new Date().toISOString()
        }),
        {
          status: result.success ? 200 : 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          }
        }
      );
    }

    // Method not allowed
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      }
    );

  } catch (error) {
    logFunctionError(FUNCTION_NAME, error as Error, { requestId });
    
    return new Response(
      JSON.stringify({
        success: false,
        error: `Internal server error: ${(error as Error).message}`,
        result: {
          databaseRecordsDeleted: 0,
          storageFilesDeleted: 0,
          errors: [(error as Error).message],
          success: false
        },
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      }
    );
  }
}); 