-- Initial schema for OneAlarm production database
-- This migration creates the complete base schema

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE audio_type AS ENUM ('alarm', 'test_clip');
CREATE TYPE alarm_status AS ENUM ('active', 'inactive', 'snoozed');

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    timezone TEXT DEFAULT 'America/New_York',
    preferred_voice TEXT DEFAULT 'alloy',
    preferred_speed REAL DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create alarms table
CREATE TABLE IF NOT EXISTS alarms (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    time TIME NOT NULL,
    days_of_week INTEGER[] NOT NULL DEFAULT '{1,2,3,4,5,6,7}',
    status alarm_status DEFAULT 'active',
    next_trigger TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Timezone and scheduling fields
    alarm_timezone TEXT DEFAULT 'UTC' NOT NULL,
    alarm_date DATE,
    alarm_time_local TIME,
    next_trigger_at TIMESTAMP WITH TIME ZONE
);

-- Create daily_content table
CREATE TABLE IF NOT EXISTS daily_content (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    general_headlines TEXT,
    business_headlines TEXT,
    technology_headlines TEXT,
    sports_headlines TEXT,
    sports_summary TEXT,
    stocks_summary TEXT,
    holidays TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Create audio_files table
CREATE TABLE IF NOT EXISTS audio_files (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    audio_type audio_type NOT NULL,
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio table (for migration compatibility)
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

-- Create logs table (minimal for migration compatibility)
CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    event_type TEXT,
    meta JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_alarms_user_id ON alarms(user_id);
CREATE INDEX IF NOT EXISTS idx_alarms_next_trigger ON alarms(next_trigger);
CREATE INDEX IF NOT EXISTS idx_daily_content_user_date ON daily_content(user_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_content_date ON daily_content(date);
CREATE INDEX IF NOT EXISTS idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_alarm_id ON audio_files(alarm_id);

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alarms_updated_at BEFORE UPDATE ON alarms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_content_updated_at BEFORE UPDATE ON daily_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_audio_files_updated_at BEFORE UPDATE ON audio_files FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_audio_updated_at BEFORE UPDATE ON audio FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO users (id, email) VALUES (NEW.id, NEW.email);
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function to calculate next trigger time
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

-- Create trigger for calculating next trigger
CREATE TRIGGER calculate_next_trigger_trigger
    BEFORE INSERT OR UPDATE ON alarms
    FOR EACH ROW EXECUTE FUNCTION calculate_next_trigger();

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE alarms ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own preferences" ON user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON user_preferences FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own alarms" ON alarms FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own alarms" ON alarms FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own alarms" ON alarms FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own alarms" ON alarms FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own daily content" ON daily_content FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own daily content" ON daily_content FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own daily content" ON daily_content FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own audio files" ON audio_files FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own audio files" ON audio_files FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own audio files" ON audio_files FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own audio files" ON audio_files FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own audio" ON audio FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own audio" ON audio FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own audio" ON audio FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own audio" ON audio FOR DELETE USING (auth.uid() = user_id); 