-- Add audio_url column to audio table for cleanup functionality
ALTER TABLE audio ADD COLUMN IF NOT EXISTS audio_url TEXT;
COMMENT ON COLUMN audio.audio_url IS 'URL to the audio file in storage, used for cleanup and playback'; 