-- Add direct generate-audio call to user_preferences trigger for DEVELOP
-- This migration adds the direct HTTP call to generate-audio when user preferences change
-- This matches main's behavior and ensures immediate audio generation

-- Create or replace the trigger function to include direct HTTP call
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

    -- Direct HTTP call to generate-audio function (matches main's behavior)
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

    -- Queue audio generation for all active alarms for this user (existing logic)
    -- This avoids hardcoded URLs and allows the queue system to handle it
    INSERT INTO audio_generation_queue (
        alarm_id,
        user_id,
        scheduled_for,
        status,
        priority
    )
    SELECT 
        a.id,
        a.user_id,
        a.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        1  -- Higher priority for preference changes
    FROM alarms a
    WHERE a.user_id = NEW.user_id AND a.active = true
    ON CONFLICT (alarm_id) DO UPDATE SET
        status = 'pending',
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-create triggers
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
CREATE TRIGGER on_preferences_updated
  AFTER UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;
CREATE TRIGGER on_preferences_inserted
  AFTER INSERT ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_update',
  jsonb_build_object(
    'action', 'add_direct_generate_audio_call',
    'trigger_name', 'on_preferences_updated',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Add direct HTTP call to generate-audio while keeping queue logic',
    'environment', 'develop',
    'approach', 'direct_http_plus_queue',
    'url', 'https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-audio',
    'timestamp', NOW()
  )
); 