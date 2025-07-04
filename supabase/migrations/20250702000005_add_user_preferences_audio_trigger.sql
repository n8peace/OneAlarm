-- Add trigger function to call generate-audio when user preferences change
-- This ensures general audio clips are generated when key preferences are updated

-- Create the trigger function
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
    PERFORM net.http_post(
      url := 'https://bfrvahxmokeyrfnlaiwd.supabase.co/functions/v1/generate-audio',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcnZhaHhtb2tleXJmbmxhaXdkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQzMDI2NCwiZXhwIjoyMDY3MDA2MjY0fQ.C2x_AIkig4Fc7JSEyrkxve7E4uAwwvSRhPNDAeOfW-A'
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

-- Create trigger for user preferences updates
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
CREATE TRIGGER on_preferences_updated
  AFTER UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

-- Create trigger for user preferences inserts (for new users)
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;
CREATE TRIGGER on_preferences_inserted
  AFTER INSERT ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

-- Log the creation
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_creation',
  jsonb_build_object(
    'action', 'add_user_preferences_audio_trigger',
    'trigger_name', 'on_preferences_updated',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Automatically generate general audio clips when user preferences change',
    'creation_timestamp', NOW()
  )
); 