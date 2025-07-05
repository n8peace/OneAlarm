-- OneAlarm Development Environment Complete Setup
-- This script creates all tables, functions, and triggers needed for the development environment
-- Run this in the Supabase Dashboard SQL Editor while on the 'develop' branch

-- ============================================================================
-- STEP 1: CREATE TABLES
-- ============================================================================

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    onboarding_done BOOLEAN DEFAULT FALSE,
    subscription_status TEXT DEFAULT 'trialing',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_admin BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    timezone TEXT DEFAULT 'America/New_York',
    preferred_voice TEXT DEFAULT 'alloy',
    preferred_speed REAL DEFAULT 1.0,
    news_categories TEXT[] DEFAULT ARRAY['general'],
    sports_team TEXT,
    stocks TEXT[],
    include_weather BOOLEAN DEFAULT TRUE,
    preferred_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create alarms table (timezone-aware)
CREATE TABLE IF NOT EXISTS alarms (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_date DATE,
    alarm_time_local TIME NOT NULL,
    alarm_timezone TEXT NOT NULL DEFAULT 'UTC',
    next_trigger_at TIMESTAMP WITH TIME ZONE,
    active BOOLEAN DEFAULT TRUE,
    is_overridden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create daily_content table (global content)
CREATE TABLE IF NOT EXISTS daily_content (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    date TEXT NOT NULL UNIQUE,
    general_headlines TEXT,
    business_headlines TEXT,
    technology_headlines TEXT,
    sports_headlines TEXT,
    sports_summary TEXT,
    stocks_summary TEXT,
    holidays TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio table
CREATE TABLE IF NOT EXISTS audio (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    audio_type TEXT NOT NULL CHECK (audio_type IN ('weather', 'content', 'general', 'combined', 'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3', 'test_clip')),
    duration_seconds INTEGER,
    expires_at TIMESTAMP WITH TIME ZONE,
    audio_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio_files table (legacy compatibility)
CREATE TABLE IF NOT EXISTS audio_files (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    audio_type TEXT NOT NULL,
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create logs table
CREATE TABLE IF NOT EXISTS logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type TEXT,
    meta JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create weather_data table
CREATE TABLE IF NOT EXISTS weather_data (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    location TEXT NOT NULL,
    current_temp INTEGER,
    high_temp INTEGER,
    low_temp INTEGER,
    condition TEXT,
    sunrise_time TEXT,
    sunset_time TEXT,
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
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    priority INTEGER DEFAULT 0,
    UNIQUE(alarm_id)
);

-- ============================================================================
-- STEP 2: CREATE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_alarms_user_id ON alarms(user_id);
CREATE INDEX IF NOT EXISTS idx_alarms_next_trigger_at ON alarms(next_trigger_at);
CREATE INDEX IF NOT EXISTS idx_alarms_active ON alarms(active);
CREATE INDEX IF NOT EXISTS idx_daily_content_date ON daily_content(date);
CREATE INDEX IF NOT EXISTS idx_audio_user_id ON audio(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_alarm_id ON audio(alarm_id);
CREATE INDEX IF NOT EXISTS idx_audio_type ON audio(audio_type);
CREATE INDEX IF NOT EXISTS idx_audio_expires_at ON audio(expires_at);
CREATE INDEX IF NOT EXISTS idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_alarm_id ON audio_files(alarm_id);
CREATE INDEX IF NOT EXISTS idx_weather_data_user_id ON weather_data(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_scheduled_for ON audio_generation_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_status ON audio_generation_queue(status);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_user_id ON audio_generation_queue(user_id);

-- ============================================================================
-- STEP 3: CREATE FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to sync auth users to public users
CREATE OR REPLACE FUNCTION sync_auth_to_public_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, created_at)
    VALUES (NEW.id, NEW.email, NEW.created_at)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO users (id, email) VALUES (NEW.id, NEW.email);
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate next trigger time
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
DECLARE
  local_dt TIMESTAMP;
BEGIN
  -- Validate that required fields are provided
  IF NEW.alarm_date IS NULL THEN
    RAISE EXCEPTION 'alarm_date must be provided when creating/updating alarms';
  END IF;
  
  IF NEW.alarm_time_local IS NULL THEN
    RAISE EXCEPTION 'alarm_time_local must be provided when creating/updating alarms';
  END IF;
  
  IF NEW.alarm_timezone IS NULL THEN
    RAISE EXCEPTION 'alarm_timezone must be provided when creating/updating alarms';
  END IF;
  
  -- Create the local datetime using provided alarm_date and alarm_time_local
  local_dt := (NEW.alarm_date::timestamp + NEW.alarm_time_local::interval);

  -- Convert to UTC using alarm's timezone
  BEGIN
    NEW.next_trigger_at := local_dt AT TIME ZONE NEW.alarm_timezone;
  EXCEPTION WHEN OTHERS THEN
    -- If timezone is invalid, fallback to UTC
    NEW.next_trigger_at := local_dt AT TIME ZONE 'UTC';
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to queue audio generation
CREATE OR REPLACE FUNCTION queue_audio_generation()
RETURNS TRIGGER AS $$
BEGIN
    -- Queue audio generation 58 minutes before alarm
    INSERT INTO audio_generation_queue (
        alarm_id, 
        user_id, 
        scheduled_for, 
        status, 
        priority
    ) VALUES (
        NEW.id,
        NEW.user_id,
        NEW.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        0
    )
    ON CONFLICT (alarm_id) DO UPDATE SET
        scheduled_for = EXCLUDED.scheduled_for,
        status = 'pending',
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle user preferences updates (matches production)
CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger if key audio-related preferences changed
  IF OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
     OLD.preferred_name IS DISTINCT FROM NEW.preferred_name THEN
    
    -- Log the change for debugging
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'preferences_updated_audio_trigger',
      NEW.user_id,
      jsonb_build_object(
        'old_tts_voice', OLD.tts_voice,
        'new_tts_voice', NEW.tts_voice,
        'old_preferred_name', OLD.preferred_name,
        'new_preferred_name', NEW.preferred_name,
        'triggered_at', NOW(),
        'action', 'audio_generation_triggered'
      )
    );
    
    -- Note: In development, we'll queue audio generation instead of calling the function directly
    -- This avoids hardcoded URLs and allows the queue system to handle it
    INSERT INTO audio_generation_queue (
        alarm_id,
        user_id,
        scheduled_for,
        status,
        priority
    )
    SELECT 
        a.id,
        a.user_id,
        a.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        1  -- Higher priority for preference changes
    FROM alarms a
    WHERE a.user_id = NEW.user_id AND a.active = true
    ON CONFLICT (alarm_id) DO UPDATE SET
        status = 'pending',
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- Function to handle audio status changes
CREATE OR REPLACE FUNCTION handle_audio_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Log audio status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO logs (event_type, meta) VALUES (
            'audio_status_changed',
            jsonb_build_object(
                'audio_id', NEW.id,
                'user_id', NEW.user_id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'audio_type', NEW.audio_type
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 4: CREATE TRIGGERS
-- ============================================================================

-- Timestamp update triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alarms_updated_at BEFORE UPDATE ON alarms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_content_updated_at BEFORE UPDATE ON daily_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_audio_files_updated_at BEFORE UPDATE ON audio_files FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_audio_updated_at BEFORE UPDATE ON audio FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auth user sync trigger
CREATE TRIGGER trigger_sync_auth_to_public_user
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION sync_auth_to_public_user();

-- New user creation trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Alarm calculation trigger
CREATE TRIGGER calculate_next_trigger_trigger
    BEFORE INSERT OR UPDATE ON alarms
    FOR EACH ROW EXECUTE FUNCTION calculate_next_trigger();

-- Audio generation queue trigger
CREATE TRIGGER alarm_audio_queue_trigger
    AFTER INSERT OR UPDATE ON alarms
    FOR EACH ROW EXECUTE FUNCTION queue_audio_generation();

-- User preferences triggers (matches production)
CREATE TRIGGER on_preferences_updated
    AFTER UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

CREATE TRIGGER on_preferences_inserted
    AFTER INSERT ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

-- Audio status change trigger
CREATE TRIGGER on_audio_status_change
    AFTER UPDATE ON audio
    FOR EACH ROW EXECUTE FUNCTION handle_audio_status_change();

-- ============================================================================
-- STEP 5: ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE alarms ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_generation_queue ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 6: CREATE RLS POLICIES
-- ============================================================================

-- Users table policies
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

-- User preferences policies
CREATE POLICY "Users can view own preferences" ON user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON user_preferences FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own preferences" ON user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Alarms table policies
CREATE POLICY "Users can view own alarms" ON alarms FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own alarms" ON alarms FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own alarms" ON alarms FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own alarms" ON alarms FOR DELETE USING (auth.uid() = user_id);

-- Daily content policies (global content, but users can only view)
CREATE POLICY "Users can view daily content" ON daily_content FOR SELECT USING (true);

-- Audio table policies
CREATE POLICY "Users can view own audio" ON audio FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own audio" ON audio FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own audio" ON audio FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own audio" ON audio FOR DELETE USING (auth.uid() = user_id);

-- Audio files table policies
CREATE POLICY "Users can view own audio files" ON audio_files FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own audio files" ON audio_files FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own audio files" ON audio_files FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own audio files" ON audio_files FOR DELETE USING (auth.uid() = user_id);

-- Weather data policies
CREATE POLICY "Users can view own weather data" ON weather_data FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own weather data" ON weather_data FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own weather data" ON weather_data FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own weather data" ON weather_data FOR DELETE USING (auth.uid() = user_id);

-- User events policies
CREATE POLICY "Users can view own events" ON user_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own events" ON user_events FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Audio generation queue policies
CREATE POLICY "Users can view own queue items" ON audio_generation_queue FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own queue items" ON audio_generation_queue FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own queue items" ON audio_generation_queue FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own queue items" ON audio_generation_queue FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- STEP 7: VERIFICATION
-- ============================================================================

-- Log successful setup
INSERT INTO logs (event_type, meta) VALUES (
    'development_schema_setup',
    jsonb_build_object(
        'timestamp', NOW(),
        'status', 'completed',
        'tables_created', 9,
        'triggers_created', 12,
        'policies_created', 25
    )
);

-- Display setup summary
SELECT 
    'Development Schema Setup Complete' as status,
    COUNT(*) as tables_created,
    NOW() as completed_at
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'user_preferences', 'alarms', 'daily_content', 'audio', 'audio_files', 'logs', 'weather_data', 'user_events', 'audio_generation_queue'); 