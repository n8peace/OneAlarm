-- Remove content_duration column from user_preferences table
-- This field is being replaced with a fixed 300-second duration in the generate-alarm-audio function

-- Drop the constraint first
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS check_content_duration;

-- Drop the column
ALTER TABLE user_preferences DROP COLUMN IF EXISTS content_duration;

-- Log the removal
INSERT INTO logs (event_type, meta)
VALUES (
  'schema_change',
  jsonb_build_object(
    'action', 'remove_content_duration',
    'table', 'user_preferences',
    'column', 'content_duration',
    'reason', 'Replaced with fixed 300-second duration in generate-alarm-audio function',
    'removal_timestamp', NOW()
  )
); 