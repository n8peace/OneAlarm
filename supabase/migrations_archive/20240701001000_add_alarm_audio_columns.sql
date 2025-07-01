-- Add missing columns to alarms table for migration compatibility
ALTER TABLE alarms ADD COLUMN IF NOT EXISTS alarm_timezone TEXT DEFAULT 'UTC' NOT NULL;
ALTER TABLE alarms ADD COLUMN IF NOT EXISTS alarm_date DATE;
ALTER TABLE alarms ADD COLUMN IF NOT EXISTS alarm_time_local TIME;
ALTER TABLE alarms ADD COLUMN IF NOT EXISTS next_trigger_at TIMESTAMP WITH TIME ZONE;

-- Create audio table if it does not exist
CREATE TABLE IF NOT EXISTS audio (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    audio_type TEXT NOT NULL,
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
); 