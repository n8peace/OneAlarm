-- Dev Schema Dump - Converted from JSON to SQL
-- Generated for OneAlarm Production Reset

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables
CREATE TABLE alarms (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    active boolean DEFAULT true,
    updated_at timestamp without time zone DEFAULT now(),
    next_trigger_at timestamp without time zone,
    is_overridden boolean DEFAULT false,
    alarm_time_local time without time zone NOT NULL,
    alarm_date date,
    alarm_timezone text NOT NULL DEFAULT 'UTC'::text,
    timezone_at_creation text NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE audio (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    script_text text,
    audio_url text,
    generated_at timestamp without time zone DEFAULT now(),
    error text,
    duration_seconds integer,
    alarm_id uuid,
    audio_type character varying NOT NULL DEFAULT 'general'::character varying,
    expires_at timestamp with time zone,
    status character varying DEFAULT 'generating'::character varying,
    cached_at timestamp with time zone,
    cache_status character varying DEFAULT 'pending'::character varying,
    file_size integer,
    PRIMARY KEY (id)
);

-- Create audio_type enum first
CREATE TYPE audio_type_enum AS ENUM ('general', 'alarm', 'test_clip');

CREATE TABLE audio_files (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    alarm_id uuid,
    file_path text NOT NULL,
    audio_type audio_type_enum NOT NULL,
    duration_seconds integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE audio_generation_queue (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    alarm_id uuid NOT NULL,
    user_id uuid NOT NULL,
    scheduled_for timestamp with time zone NOT NULL,
    status character varying NOT NULL DEFAULT 'pending'::character varying,
    retry_count integer DEFAULT 0,
    max_retries integer DEFAULT 3,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    processed_at timestamp with time zone,
    priority integer DEFAULT 5,
    PRIMARY KEY (id)
);

CREATE TABLE daily_content (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    date date,
    sports_summary text,
    stocks_summary text,
    created_at timestamp without time zone DEFAULT now(),
    holidays text,
    general_headlines text,
    business_headlines text,
    technology_headlines text,
    sports_headlines text,
    PRIMARY KEY (id)
);

CREATE TABLE logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    event_type text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE user_events (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    event_type text,
    created_at timestamp without time zone DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE user_preferences (
    user_id uuid NOT NULL,
    sports_team text,
    stocks text[],
    include_weather boolean DEFAULT true,
    timezone text,
    updated_at timestamp without time zone DEFAULT now(),
    preferred_name text,
    tts_voice text,
    news_categories text[] DEFAULT ARRAY['general'::text],
    onboarding_completed boolean DEFAULT false,
    onboarding_step integer DEFAULT 0,
    PRIMARY KEY (user_id)
);

CREATE TABLE users (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    email text,
    phone text,
    onboarding_done boolean DEFAULT false,
    subscription_status text DEFAULT 'trialing'::text,
    created_at timestamp without time zone DEFAULT now(),
    is_admin boolean DEFAULT false,
    last_login timestamp without time zone,
    PRIMARY KEY (id)
);

CREATE TABLE weather_data (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    location character varying NOT NULL,
    current_temp integer,
    high_temp integer,
    low_temp integer,
    condition character varying,
    sunrise_time time without time zone,
    sunset_time time without time zone,
    updated_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

-- Add foreign key constraints
ALTER TABLE alarms ADD CONSTRAINT alarms_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE audio ADD CONSTRAINT audio_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE audio ADD CONSTRAINT audio_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE CASCADE;
ALTER TABLE audio_files ADD CONSTRAINT audio_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE audio_files ADD CONSTRAINT audio_files_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE CASCADE;
ALTER TABLE audio_generation_queue ADD CONSTRAINT audio_generation_queue_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE CASCADE;
ALTER TABLE audio_generation_queue ADD CONSTRAINT audio_generation_queue_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE logs ADD CONSTRAINT logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_events ADD CONSTRAINT user_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE weather_data ADD CONSTRAINT weather_data_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_alarms_user_id ON alarms(user_id);
CREATE INDEX IF NOT EXISTS idx_alarms_next_trigger_at ON alarms(next_trigger_at);
CREATE INDEX IF NOT EXISTS idx_audio_user_id ON audio(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_alarm_id ON audio(alarm_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_scheduled_for ON audio_generation_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_status ON audio_generation_queue(status);
CREATE INDEX IF NOT EXISTS idx_daily_content_date ON daily_content(date);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at);
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_weather_data_user_id ON weather_data(user_id);

-- Create trigger function for new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new auth users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Add comments for documentation
COMMENT ON TABLE alarms IS 'User alarm settings and schedules';
COMMENT ON TABLE audio IS 'Generated audio files and metadata';
COMMENT ON TABLE audio_files IS 'Audio file storage and metadata';
COMMENT ON TABLE audio_generation_queue IS 'Queue for audio generation tasks';
COMMENT ON TABLE daily_content IS 'Daily news and content summaries';
COMMENT ON TABLE logs IS 'System and user activity logs';
COMMENT ON TABLE user_events IS 'User interaction events';
COMMENT ON TABLE user_preferences IS 'User preferences and settings';
COMMENT ON TABLE users IS 'User accounts and profiles';
COMMENT ON TABLE weather_data IS 'Weather information for users';