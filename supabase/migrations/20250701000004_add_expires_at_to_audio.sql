-- Add expires_at column to audio table for cleanup functionality
-- This column is required by the cleanup-audio-files function

-- Add expires_at column if it doesn't exist
ALTER TABLE audio ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;

-- Add index for efficient cleanup queries
CREATE INDEX IF NOT EXISTS idx_audio_expires_at ON audio(expires_at);

-- Add comment for documentation
COMMENT ON COLUMN audio.expires_at IS 'Expiration timestamp for automatic cleanup (48 hours for combined audio)'; 