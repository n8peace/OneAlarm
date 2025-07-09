-- Add missing on_audio_status_change trigger for develop environment
-- This migration adds the audio status change trigger that logs status changes

-- Create or replace the log_offline_issue function
CREATE OR REPLACE FUNCTION log_offline_issue()
RETURNS TRIGGER AS $$
BEGIN
    -- Log audio status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO logs (event_type, user_id, meta) VALUES (
            'audio_status_changed',
            NEW.user_id,
            jsonb_build_object(
                'audio_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'audio_type', NEW.audio_type,
                'action', 'status_change_logged',
                'environment', 'develop',
                'timestamp', NOW()
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the on_audio_status_change trigger
DROP TRIGGER IF EXISTS on_audio_status_change ON audio;
CREATE TRIGGER on_audio_status_change
    AFTER UPDATE ON audio
    FOR EACH ROW EXECUTE FUNCTION log_offline_issue();

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_update',
  jsonb_build_object(
    'action', 'add_on_audio_status_change_trigger',
    'trigger_name', 'on_audio_status_change',
    'function_name', 'log_offline_issue',
    'table', 'audio',
    'event', 'AFTER UPDATE',
    'purpose', 'Log audio status changes for monitoring',
    'environment', 'develop',
    'timestamp', NOW()
  )
); 