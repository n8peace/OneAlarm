-- Remove unused audio_files table
-- This table is no longer used and has been replaced by the audio table

-- Drop the audio_files table if it exists
DROP TABLE IF EXISTS audio_files CASCADE;

-- Remove any indexes associated with audio_files table
DROP INDEX IF EXISTS idx_audio_files_user_id;
DROP INDEX IF EXISTS idx_audio_files_alarm_id;

-- Log the removal
INSERT INTO logs (event_type, meta) 
VALUES ('table_removed', '{"table": "audio_files", "reason": "unused table replaced by audio table"}'); 