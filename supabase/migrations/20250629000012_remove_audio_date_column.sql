-- Remove the date column from the audio table
-- This column is not used in any business logic and can be safely removed

-- Drop the index first
DROP INDEX IF EXISTS idx_audio_date;

-- Remove the date column
ALTER TABLE audio DROP COLUMN IF EXISTS date; 