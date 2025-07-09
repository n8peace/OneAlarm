-- Fix audio_generation_queue table by adding missing updated_at column
ALTER TABLE audio_generation_queue 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Add trigger to update updated_at column
CREATE OR REPLACE FUNCTION update_audio_generation_queue_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS update_audio_generation_queue_updated_at ON audio_generation_queue;
CREATE TRIGGER update_audio_generation_queue_updated_at
    BEFORE UPDATE ON audio_generation_queue
    FOR EACH ROW EXECUTE FUNCTION update_audio_generation_queue_updated_at(); 