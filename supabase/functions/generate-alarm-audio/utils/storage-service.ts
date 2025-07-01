// Storage service for uploading audio files

import { getSupabaseClient } from '../../_shared/utils/database.ts';
import { CONFIG } from '../config.ts';

export class StorageService {
  private supabase = getSupabaseClient();

  async uploadAudioFile(
    audioBuffer: ArrayBuffer, 
    fileName: string, 
    audioType: 'combined'
  ): Promise<string> {
    try {
      // Convert ArrayBuffer to Uint8Array for upload
      const uint8Array = new Uint8Array(audioBuffer);
      
      // Create file path
      const filePath = `${CONFIG.storage.folder}/${audioType}/${fileName}`;
      
      // Upload to Supabase Storage
      const { data, error } = await this.supabase.storage
        .from(CONFIG.storage.bucket)
        .upload(filePath, uint8Array, {
          contentType: `audio/${CONFIG.tts.format}`,
          cacheControl: '3600', // 1 hour cache
          upsert: false // Don't overwrite existing files
        });

      if (error) {
        throw new Error(`Storage upload failed: ${error.message}`);
      }

      // Get public URL
      const { data: urlData } = this.supabase.storage
        .from(CONFIG.storage.bucket)
        .getPublicUrl(filePath);

      if (!urlData.publicUrl) {
        throw new Error('Failed to get public URL for uploaded file');
      }

      return urlData.publicUrl;

    } catch (error) {
      console.error('Storage upload error:', error);
      throw new Error(`Failed to upload audio file: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  async deleteAudioFile(fileName: string, audioType: 'weather' | 'content'): Promise<void> {
    try {
      const filePath = `${CONFIG.storage.folder}/${audioType}/${fileName}`;
      
      const { error } = await this.supabase.storage
        .from(CONFIG.storage.bucket)
        .remove([filePath]);

      if (error) {
        console.warn('Failed to delete audio file:', error.message);
      }
    } catch (error) {
      console.warn('Error deleting audio file:', error);
    }
  }
} 