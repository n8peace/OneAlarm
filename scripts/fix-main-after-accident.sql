-- Fix Main Environment After Accidental Develop Sync
-- This restores main to its correct state with the proper URL

-- Drop existing triggers first
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;

-- Drop existing function
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;

-- Create the correct main environment function with MAIN URL
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
    -- CORRECT MAIN URL: joyavvleaxqzksopnmjs (not xqkmpkfqoisqzznnvlox)
    PERFORM net.http_post(
      url := 'https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-audio',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxOTA3NjUsImV4cCI6MjA2NTc2Njc2NX0.LgCoghiKkmVzXMxHyNy6Xzzevmhq5DDEmlFMJevm75M'
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

-- Recreate triggers with correct main definitions
CREATE TRIGGER on_preferences_updated
    AFTER UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

CREATE TRIGGER on_preferences_inserted
    AFTER INSERT ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_fix',
  jsonb_build_object(
    'action', 'fix_main_after_accidental_develop_sync',
    'source', 'main_environment',
    'target', 'main_environment',
    'key_change', 'restore_correct_main_url',
    'correct_url', 'https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-audio',
    'incorrect_url_removed', 'https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-audio',
    'timestamp', NOW(),
    'note', 'Restored main environment to correct state after accidental develop sync'
  )
); 