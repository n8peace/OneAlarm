-- Fix audio type constraint to allow generate-audio function types
-- The generate-audio function creates clips with types like wake_up_message_1, wake_up_message_2, etc.

-- Drop the existing constraint
ALTER TABLE audio DROP CONSTRAINT IF EXISTS check_audio_type;

-- Re-add the constraint with wake_up_message types included
ALTER TABLE audio ADD CONSTRAINT check_audio_type 
  CHECK (audio_type IN (
    'weather', 
    'content', 
    'general', 
    'combined',
    'wake_up_message_1',
    'wake_up_message_2', 
    'wake_up_message_3'
  ));

-- Add comment for documentation
COMMENT ON COLUMN audio.audio_type IS 'Type of audio: weather, content, general, combined, or wake_up_message_X'; 