-- Fix user_preferences audio trigger for DEVELOP
-- Copy and paste this entire SQL into your Supabase Dashboard SQL Editor
-- This migration ensures the trigger uses the queue-based approach (not HTTP calls)
-- This matches the development schema pattern and doesn't require the net extension

-- Create or replace the trigger function to use queue-based approach
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

    -- Queue audio generation for all active alarms for this user
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
    'action', 'fix_develop_user_preferences_trigger',
    'trigger_name', 'on_preferences_updated',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Use queue-based approach instead of HTTP calls',
    'environment', 'develop',
    'approach', 'queue_based',
    'timestamp', NOW()
  )
); 