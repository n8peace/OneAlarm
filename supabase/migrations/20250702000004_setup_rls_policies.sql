-- Enable Row Level Security (RLS) on all tables
-- This ensures users can only access their own data while allowing service role full access

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE alarms ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_generation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can view own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can update own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can view own alarms" ON alarms;
DROP POLICY IF EXISTS "Users can create own alarms" ON alarms;
DROP POLICY IF EXISTS "Users can update own alarms" ON alarms;
DROP POLICY IF EXISTS "Users can delete own alarms" ON alarms;
DROP POLICY IF EXISTS "Users can view own audio" ON audio;
DROP POLICY IF EXISTS "Users can create own audio" ON audio;
DROP POLICY IF EXISTS "Users can update own audio" ON audio;
DROP POLICY IF EXISTS "Users can delete own audio" ON audio;
DROP POLICY IF EXISTS "Users can view own audio files" ON audio_files;
DROP POLICY IF EXISTS "Users can create own audio files" ON audio_files;
DROP POLICY IF EXISTS "Users can update own audio files" ON audio_files;
DROP POLICY IF EXISTS "Users can delete own audio files" ON audio_files;
DROP POLICY IF EXISTS "Users can view own queue items" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can create own queue items" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can update own queue items" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can delete own queue items" ON audio_generation_queue;
DROP POLICY IF EXISTS "Users can view own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can create own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can update own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can delete own weather data" ON weather_data;
DROP POLICY IF EXISTS "Users can view own events" ON user_events;
DROP POLICY IF EXISTS "Users can create own events" ON user_events;
DROP POLICY IF EXISTS "Public can view daily content" ON daily_content;
DROP POLICY IF EXISTS "Service role can access all data" ON users;
DROP POLICY IF EXISTS "Service role can access all data" ON user_preferences;
DROP POLICY IF EXISTS "Service role can access all data" ON alarms;
DROP POLICY IF EXISTS "Service role can access all data" ON audio;
DROP POLICY IF EXISTS "Service role can access all data" ON audio_files;
DROP POLICY IF EXISTS "Service role can access all data" ON audio_generation_queue;
DROP POLICY IF EXISTS "Service role can access all data" ON daily_content;
DROP POLICY IF EXISTS "Service role can access all data" ON logs;
DROP POLICY IF EXISTS "Service role can access all data" ON user_events;
DROP POLICY IF EXISTS "Service role can access all data" ON weather_data;

-- Users table policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Service role can access all data" ON users
    FOR ALL USING (auth.role() = 'service_role');

-- User preferences policies
CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can access all data" ON user_preferences
    FOR ALL USING (auth.role() = 'service_role');

-- Alarms policies
CREATE POLICY "Users can view own alarms" ON alarms
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own alarms" ON alarms
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own alarms" ON alarms
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own alarms" ON alarms
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role can access all data" ON alarms
    FOR ALL USING (auth.role() = 'service_role');

-- Audio policies
CREATE POLICY "Users can view own audio" ON audio
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own audio" ON audio
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own audio" ON audio
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own audio" ON audio
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role can access all data" ON audio
    FOR ALL USING (auth.role() = 'service_role');

-- Audio files policies
CREATE POLICY "Users can view own audio files" ON audio_files
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own audio files" ON audio_files
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own audio files" ON audio_files
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own audio files" ON audio_files
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role can access all data" ON audio_files
    FOR ALL USING (auth.role() = 'service_role');

-- Audio generation queue policies
CREATE POLICY "Users can view own queue items" ON audio_generation_queue
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own queue items" ON audio_generation_queue
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own queue items" ON audio_generation_queue
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own queue items" ON audio_generation_queue
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role can access all data" ON audio_generation_queue
    FOR ALL USING (auth.role() = 'service_role');

-- Daily content policies (public read access, service role full access)
CREATE POLICY "Public can view daily content" ON daily_content
    FOR SELECT USING (true);

CREATE POLICY "Service role can access all data" ON daily_content
    FOR ALL USING (auth.role() = 'service_role');

-- Logs policies (service role only - users shouldn't access logs)
CREATE POLICY "Service role can access all data" ON logs
    FOR ALL USING (auth.role() = 'service_role');

-- User events policies
CREATE POLICY "Users can view own events" ON user_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own events" ON user_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can access all data" ON user_events
    FOR ALL USING (auth.role() = 'service_role');

-- Weather data policies
CREATE POLICY "Users can view own weather data" ON weather_data
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own weather data" ON weather_data
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own weather data" ON weather_data
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own weather data" ON weather_data
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role can access all data" ON weather_data
    FOR ALL USING (auth.role() = 'service_role');

-- Create a function to handle user creation with proper RLS
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into users table (this will be handled by the trigger on auth.users)
    -- Insert into user_preferences table
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger is properly set up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Add comments for documentation
COMMENT ON POLICY "Users can view own profile" ON users IS 'Users can only view their own profile data';
COMMENT ON POLICY "Service role can access all data" ON users IS 'Service role has full access to all user data';
COMMENT ON POLICY "Public can view daily content" ON daily_content IS 'Daily content is publicly readable'; 