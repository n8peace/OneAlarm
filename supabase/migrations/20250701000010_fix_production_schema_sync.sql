-- Fix production schema to match development
-- This migration addresses all schema differences between prod and dev

-- Step 1: Remove obsolete columns from alarms table
ALTER TABLE alarms DROP COLUMN IF EXISTS name;
ALTER TABLE alarms DROP COLUMN IF EXISTS time;
ALTER TABLE alarms DROP COLUMN IF EXISTS days_of_week;
ALTER TABLE alarms DROP COLUMN IF EXISTS status;
ALTER TABLE alarms DROP COLUMN IF EXISTS next_trigger;
ALTER TABLE alarms DROP COLUMN IF EXISTS timezone_at_creation;

-- Step 2: Remove obsolete columns from user_preferences table
ALTER TABLE user_preferences DROP COLUMN IF EXISTS onboarding_completed;
ALTER TABLE user_preferences DROP COLUMN IF EXISTS onboarding_step;

-- Step 3: Remove user_id from daily_content table
-- Drop RLS policies first
DROP POLICY IF EXISTS "Users can view own daily content" ON daily_content;
DROP POLICY IF EXISTS "Users can insert own daily content" ON daily_content;
DROP POLICY IF EXISTS "Users can update own daily content" ON daily_content;
DROP POLICY IF EXISTS "Users can delete own daily content" ON daily_content;

-- Drop index
DROP INDEX IF EXISTS idx_daily_content_user_id;

-- Remove column
ALTER TABLE daily_content DROP COLUMN IF EXISTS user_id;

-- Create new RLS policy for global access
DROP POLICY IF EXISTS "Users can view daily content" ON daily_content;
CREATE POLICY "Users can view daily content" ON daily_content FOR SELECT USING (true);

-- Step 4: Add missing columns to audio table
ALTER TABLE audio ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE audio ADD COLUMN IF NOT EXISTS audio_url TEXT;

-- Step 5: Create missing tables
CREATE TABLE IF NOT EXISTS weather_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    location TEXT NOT NULL,
    current_temp INTEGER,
    high_temp INTEGER,
    low_temp INTEGER,
    condition TEXT,
    sunrise_time TIME,
    sunset_time TIME,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audio_generation_queue (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    priority INTEGER DEFAULT 0
);

-- Step 6: Create missing indexes
CREATE INDEX IF NOT EXISTS idx_weather_data_user_id ON weather_data(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_user_id ON audio_generation_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_alarm_id ON audio_generation_queue(alarm_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_scheduled_for ON audio_generation_queue(scheduled_for);

-- Step 7: Enable RLS on new tables
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_generation_queue ENABLE ROW LEVEL SECURITY;

-- Step 8: Create RLS policies for new tables
DROP POLICY IF EXISTS "Users can view own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can insert own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can update own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can delete own weather data" ON weather_data;
CREATE POLICY "Users can view own weather data" ON weather_data FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own weather data" ON weather_data FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own weather data" ON weather_data FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own weather data" ON weather_data FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own events" ON user_events;
DROP POLICY IF EXISTS "Users can insert own events" ON user_events;
CREATE POLICY "Users can view own events" ON user_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own events" ON user_events FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own queue items" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can insert own queue items" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can update own queue items" ON audio_generation_queue;
CREATE POLICY "Users can view own queue items" ON audio_generation_queue FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own queue items" ON audio_generation_queue FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own queue items" ON audio_generation_queue FOR UPDATE USING (auth.uid() = user_id);

-- Step 9: Add comments for documentation
COMMENT ON COLUMN audio.expires_at IS 'Timestamp when audio file expires and should be cleaned up';
COMMENT ON COLUMN audio.audio_url IS 'URL to the audio file in storage, used for cleanup and playback';
COMMENT ON TABLE daily_content IS 'Global daily content for all users (news, sports, stocks, holidays)';
COMMENT ON TABLE weather_data IS 'User-specific weather data for alarm content';
COMMENT ON TABLE user_events IS 'User interaction events for analytics';
COMMENT ON TABLE audio_generation_queue IS 'Queue for processing audio generation requests'; 