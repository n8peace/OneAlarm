-- Fix develop trigger to properly handle INSERT and UPDATE operations
-- This migration fixes the trigger function to work correctly for both operations

-- Create or replace the trigger function to handle both INSERT and UPDATE
CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS $$
BEGIN
  -- For INSERT operations, always trigger since we're creating new preferences
  -- For UPDATE operations, only trigger if key audio-related preferences changed
  IF TG_OP = 'INSERT' OR 
     (TG_OP = 'UPDATE' AND (
       OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
       OLD.preferred_name IS DISTINCT FROM NEW.preferred_name
     )) THEN

    -- Log the change for debugging
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'preferences_updated_audio_trigger',
      NEW.user_id,
      jsonb_build_object(
        'operation', TG_OP,
        'old_tts_voice', CASE WHEN TG_OP = 'UPDATE' THEN OLD.tts_voice ELSE NULL END,
        'new_tts_voice', NEW.tts_voice,
        'old_preferred_name', CASE WHEN TG_OP = 'UPDATE' THEN OLD.preferred_name ELSE NULL END,
        'new_preferred_name', NEW.preferred_name,
        'triggered_at', NOW(),
        'action', 'audio_generation_triggered',
        'environment', 'develop',
        'note', 'queue_only_no_direct_http'
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
    'action', 'fix_develop_trigger_insert_update',
    'trigger_name', 'on_preferences_updated_and_inserted',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Fix trigger to handle both INSERT and UPDATE operations correctly',
    'environment', 'develop',
    'approach', 'queue_only_no_direct_http',
    'note', 'Fixed OLD value references on INSERT operations',
    'timestamp', NOW()
  )
); 