-- Remove voice_gender and tone columns from user_preferences table
-- These fields are being replaced with fixed TTS voice selection and content tone

-- Drop the columns
ALTER TABLE user_preferences DROP COLUMN IF EXISTS voice_gender;
ALTER TABLE user_preferences DROP COLUMN IF EXISTS tone;

-- Update trigger functions to remove tone references
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

-- Log the removal
INSERT INTO logs (event_type, meta)
VALUES (
  'schema_change',
  jsonb_build_object(
    'action', 'remove_voice_gender_and_tone',
    'table', 'user_preferences',
    'columns', ARRAY['voice_gender', 'tone'],
    'reason', 'Simplified to use only tts_voice for voice selection and fixed content tone',
    'removal_timestamp', NOW()
  )
); 