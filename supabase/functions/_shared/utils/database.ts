// Database utilities for common operations

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

// Centralized database client factory
let _supabaseClient: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (!_supabaseClient) {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing required environment variables: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    }
    
    _supabaseClient = createClient(supabaseUrl, supabaseServiceKey);
  }
  
  return _supabaseClient;
}

// Legacy export for backward compatibility
export const supabase = getSupabaseClient();

export async function logEvent(
  eventType: string,
  userId?: string,
  meta?: Record<string, any>
) {
  try {
    const { error } = await getSupabaseClient()
      .from('logs')
      .insert({
        event_type: eventType,
        user_id: userId,
        meta: meta || {}
      });

    if (error) {
      console.error('Error logging event:', error);
    }
  } catch (error) {
    console.error('Failed to log event:', error);
  }
}

export async function getUserById(userId: string) {
  const { data, error } = await getSupabaseClient()
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) {
    throw new Error(`Failed to get user: ${error.message}`);
  }

  return data;
}

export async function getDailyContentByUserId(userId: string) {
  const { data, error } = await getSupabaseClient()
    .from('daily_content')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (error) {
    throw new Error(`Failed to get daily content: ${error.message}`);
  }

  return data;
}

export async function getAudioFilesByUserId(userId: string) {
  const { data, error } = await getSupabaseClient()
    .from('audio')
    .select('*')
    .eq('user_id', userId)
    .order('generated_at', { ascending: false });

  if (error) {
    throw new Error(`Failed to get audio files: ${error.message}`);
  }

  return data;
}

export async function deleteExpiredAudioFiles() {
  const { data, error } = await getSupabaseClient()
    .from('audio')
    .delete()
    .lt('expires_at', new Date().toISOString()) // Delete files that have expired (older than 48 hours)
    .select();

  if (error) {
    throw new Error(`Failed to delete expired audio files: ${error.message}`);
  }

  return data;
} 