-- Migration to sync DEVELOP schema to match MAIN
-- This migration modifies DEVELOP to match MAIN's schema exactly

-- ========================================
-- ALARMS TABLE CHANGES
-- ========================================

-- Add missing created_at column
ALTER TABLE alarms ADD COLUMN IF NOT EXISTS created_at timestamp without time zone DEFAULT now();

-- Change user_id to nullable (YES)
ALTER TABLE alarms ALTER COLUMN user_id DROP NOT NULL;

-- Change updated_at to timestamp without time zone
ALTER TABLE alarms ALTER COLUMN updated_at TYPE timestamp without time zone;

-- Change next_trigger_at to timestamp without time zone
ALTER TABLE alarms ALTER COLUMN next_trigger_at TYPE timestamp without time zone;

-- Change timezone_at_creation to NOT NULL
ALTER TABLE alarms ALTER COLUMN timezone_at_creation SET NOT NULL;

-- ========================================
-- AUDIO TABLE CHANGES
-- ========================================

-- Change user_id to nullable (YES)
ALTER TABLE audio ALTER COLUMN user_id DROP NOT NULL;

-- Rename file_url to audio_url
ALTER TABLE audio RENAME COLUMN file_url TO audio_url;

-- Rename duration to duration_seconds
ALTER TABLE audio RENAME COLUMN duration TO duration_seconds;

-- Add missing alarm_id column
ALTER TABLE audio ADD COLUMN IF NOT EXISTS alarm_id uuid REFERENCES alarms(id);

-- Change audio_type to character varying(50)
ALTER TABLE audio ALTER COLUMN audio_type TYPE character varying(50);

-- Change status to character varying(50)
ALTER TABLE audio ALTER COLUMN status TYPE character varying(50);

-- Change cache_status to character varying(50)
ALTER TABLE audio ALTER COLUMN cache_status TYPE character varying(50);

-- Drop created_at and updated_at columns (not in main)
ALTER TABLE audio DROP COLUMN IF EXISTS created_at;
ALTER TABLE audio DROP COLUMN IF EXISTS updated_at;

-- ========================================
-- AUDIO_FILES TABLE - DROP ENTIRELY
-- ========================================

-- Drop the audio_files table (doesn't exist in main)
DROP TABLE IF EXISTS audio_files CASCADE;

-- ========================================
-- AUDIO_GENERATION_QUEUE TABLE CHANGES
-- ========================================

-- Change status to NOT NULL
ALTER TABLE audio_generation_queue ALTER COLUMN status SET NOT NULL;

-- Add missing columns from main
ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS retry_count integer DEFAULT 0;
ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS max_retries integer DEFAULT 3;
ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS error_message text;
ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS processed_at timestamp with time zone;

-- Drop updated_at column (not in main)
ALTER TABLE audio_generation_queue DROP COLUMN IF EXISTS updated_at;

-- ========================================
-- DAILY_CONTENT TABLE CHANGES
-- ========================================

-- Change date to nullable (YES)
ALTER TABLE daily_content ALTER COLUMN date DROP NOT NULL;

-- Drop columns that don't exist in main
ALTER TABLE daily_content DROP COLUMN IF EXISTS news_summary;
ALTER TABLE daily_content DROP COLUMN IF EXISTS weather_summary;
ALTER TABLE daily_content DROP COLUMN IF EXISTS stock_summary;
ALTER TABLE daily_content DROP COLUMN IF EXISTS holiday_info;
ALTER TABLE daily_content DROP COLUMN IF EXISTS updated_at;

-- Add missing columns from main
ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS holidays text;
ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS general_headlines text;
ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS business_headlines text;
ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS technology_headlines text;
ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS sports_headlines text;

-- Change created_at to timestamp without time zone
ALTER TABLE daily_content ALTER COLUMN created_at TYPE timestamp without time zone;

-- ========================================
-- LOGS TABLE CHANGES
-- ========================================

-- Change event_type to nullable (YES)
ALTER TABLE logs ALTER COLUMN event_type DROP NOT NULL;

-- Change created_at to timestamp without time zone
ALTER TABLE logs ALTER COLUMN created_at TYPE timestamp without time zone;

-- ========================================
-- USER_EVENTS TABLE CHANGES
-- ========================================

-- Change user_id to nullable (YES)
ALTER TABLE user_events ALTER COLUMN user_id DROP NOT NULL;

-- Change event_type to nullable (YES)
ALTER TABLE user_events ALTER COLUMN event_type DROP NOT NULL;

-- Drop event_data column (not in main)
ALTER TABLE user_events DROP COLUMN IF EXISTS event_data;

-- Change created_at to timestamp without time zone
ALTER TABLE user_events ALTER COLUMN created_at TYPE timestamp without time zone;

-- ========================================
-- USER_PREFERENCES TABLE CHANGES
-- ========================================

-- Drop id column (not in main)
ALTER TABLE user_preferences DROP COLUMN IF EXISTS id;

-- Change user_id to NOT NULL and make it the primary key
ALTER TABLE user_preferences ALTER COLUMN user_id SET NOT NULL;

-- Drop existing primary key if it exists
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;

-- Add primary key constraint on user_id
ALTER TABLE user_preferences ADD PRIMARY KEY (user_id);

-- Change include_weather default to true
ALTER TABLE user_preferences ALTER COLUMN include_weather SET DEFAULT true;

-- Change tts_voice default to null
ALTER TABLE user_preferences ALTER COLUMN tts_voice DROP DEFAULT;

-- Drop created_at column (not in main)
ALTER TABLE user_preferences DROP COLUMN IF EXISTS created_at;

-- Add missing columns from main
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS onboarding_step integer DEFAULT 0;

-- Change updated_at to timestamp without time zone
ALTER TABLE user_preferences ALTER COLUMN updated_at TYPE timestamp without time zone;

-- ========================================
-- USERS TABLE CHANGES
-- ========================================

-- Change email to nullable (YES)
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- Change created_at to timestamp without time zone
ALTER TABLE users ALTER COLUMN created_at TYPE timestamp without time zone;

-- Change last_login to timestamp without time zone
ALTER TABLE users ALTER COLUMN last_login TYPE timestamp without time zone;

-- Drop updated_at column (not in main)
ALTER TABLE users DROP COLUMN IF EXISTS updated_at;

-- ========================================
-- WEATHER_DATA TABLE CHANGES
-- ========================================

-- Change location to character varying(255)
ALTER TABLE weather_data ALTER COLUMN location TYPE character varying(255);

-- Change current_temp to integer
ALTER TABLE weather_data ALTER COLUMN current_temp TYPE integer;

-- Change high_temp to integer
ALTER TABLE weather_data ALTER COLUMN high_temp TYPE integer;

-- Change low_temp to integer
ALTER TABLE weather_data ALTER COLUMN low_temp TYPE integer;

-- Change condition to character varying(100)
ALTER TABLE weather_data ALTER COLUMN condition TYPE character varying(100);

-- Drop columns that don't exist in main
ALTER TABLE weather_data DROP COLUMN IF EXISTS temperature;
ALTER TABLE weather_data DROP COLUMN IF EXISTS humidity;
ALTER TABLE weather_data DROP COLUMN IF EXISTS wind_speed;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Log the migration completion
INSERT INTO logs (event_type, meta) VALUES (
    'schema_migration_completed',
    '{"migration": "20250707000011_sync_develop_to_main_schema", "description": "Synced develop schema to match main"}'
); 