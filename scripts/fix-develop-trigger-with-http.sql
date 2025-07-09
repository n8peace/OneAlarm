-- Fix trigger_audio_generation function for develop environment
-- Now using http_post to call generate-audio for general audio (like main does)

-- Drop and recreate the trigger function to call generate-audio directly
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;

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
        'note', 'calling_generate_audio_with_http_post'
      )
    );

    -- Call generate-audio function for general audio (like main does)
    -- Now using http_post instead of net.http_post
    PERFORM http_post(
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

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_fix',
  jsonb_build_object(
    'action', 'fix_develop_trigger_with_http',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Call generate-audio for general audio when preferences change',
    'environment', 'develop',
    'approach', 'http_post_to_generate_audio',
    'note', 'Now matches main environment behavior exactly',
    'timestamp', NOW()
  )
); 