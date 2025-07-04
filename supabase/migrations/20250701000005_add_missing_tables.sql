-- Add missing tables that are referenced by edge functions
-- This migration adds tables that are defined in the database types but missing from production

-- Create weather_data table
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

-- Create user_events table
CREATE TABLE IF NOT EXISTS user_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio_generation_queue table
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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_weather_data_user_id ON weather_data(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_user_id ON audio_generation_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_alarm_id ON audio_generation_queue(alarm_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_scheduled_for ON audio_generation_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_status ON audio_generation_queue(status);

-- Enable Row Level Security
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_generation_queue ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can insert own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can update own weather data" ON weather_data;
CREATE POLICY "Users can view own weather data" ON weather_data FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own weather data" ON weather_data FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own weather data" ON weather_data FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own events" ON user_events;
DROP POLICY IF EXISTS "Users can insert own events" ON user_events;
CREATE POLICY "Users can view own events" ON user_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own events" ON user_events FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own audio generation queue" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can insert own audio generation queue" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can update own audio generation queue" ON audio_generation_queue;
CREATE POLICY "Users can view own audio generation queue" ON audio_generation_queue FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own audio generation queue" ON audio_generation_queue FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own audio generation queue" ON audio_generation_queue FOR UPDATE USING (auth.uid() = user_id);

-- Add comments for documentation
COMMENT ON TABLE weather_data IS 'Weather data for user locations';
COMMENT ON TABLE user_events IS 'User activity events for analytics';
COMMENT ON TABLE audio_generation_queue IS 'Queue for scheduled audio generation tasks'; 