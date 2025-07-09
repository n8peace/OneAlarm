-- Sync Triggers from Main to Develop
-- This migration makes develop triggers match main exactly
-- Based on the main environment pattern that uses net.http_post

-- Drop existing triggers first
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;

-- Drop existing function
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;

-- Create the exact main environment function
-- This matches the pattern seen in main environment scripts
CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger if key audio-related preferences changed
  IF OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
     OLD.preferred_name IS DISTINCT FROM NEW.preferred_name THEN
    
    -- Log the change for debugging
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'preferences_updated_audio_trigger',
      NEW.user_id,
      jsonb_build_object(
        'old_tts_voice', OLD.tts_voice,
        'new_tts_voice', NEW.tts_voice,
        'old_preferred_name', OLD.preferred_name,
        'new_preferred_name', NEW.preferred_name,
        'triggered_at', NOW(),
        'action', 'audio_generation_triggered'
      )
    );
    
    -- Call generate-audio function for the user (general audio)
    -- This is the key difference: main uses net.http_post directly
    PERFORM net.http_post(
      url := 'https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-audio',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw'
      ),
      body := jsonb_build_object(
        'userId', NEW.user_id,
        'audio_type', 'general',
        'forceRegenerate', true
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers with exact main definitions
CREATE TRIGGER on_preferences_updated
    AFTER UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

CREATE TRIGGER on_preferences_inserted
    AFTER INSERT ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

-- Log the sync
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_sync',
  jsonb_build_object(
    'action', 'sync_triggers_main_to_develop',
    'source', 'main_environment',
    'target', 'develop_environment',
    'key_change', 'use_net_http_post_direct_call',
    'timestamp', NOW(),
    'note', 'Made develop triggers match main exactly - direct HTTP call to generate-audio'
  )
); 