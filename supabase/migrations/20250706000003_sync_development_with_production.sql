-- Sync Development Schema with Production
-- This migration brings development in sync with production schema

-- ============================================================================
-- 1. FIX user_preferences TABLE
-- ============================================================================

-- Add missing columns to user_preferences
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS tts_voice TEXT,
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;

-- ============================================================================
-- 2. FIX audio TABLE
-- ============================================================================

-- Add missing columns to audio table
ALTER TABLE audio 
ADD COLUMN IF NOT EXISTS script_text TEXT,
ADD COLUMN IF NOT EXISTS generated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS error TEXT,
ADD COLUMN IF NOT EXISTS status CHARACTER VARYING DEFAULT 'generating',
ADD COLUMN IF NOT EXISTS cached_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS cache_status CHARACTER VARYING DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS file_size INTEGER;

-- Remove file_path column if it exists (production doesn't have it)
ALTER TABLE audio DROP COLUMN IF EXISTS file_path;

-- Update audio_type default to match production
ALTER TABLE audio ALTER COLUMN audio_type SET DEFAULT 'general';

-- ============================================================================
-- 3. FIX alarms TABLE
-- ============================================================================

-- Add missing timezone_at_creation column
ALTER TABLE alarms 
ADD COLUMN IF NOT EXISTS timezone_at_creation TEXT NOT NULL DEFAULT 'UTC';

-- Update existing rows to have timezone_at_creation
UPDATE alarms 
SET timezone_at_creation = alarm_timezone 
WHERE timezone_at_creation IS NULL;

-- ============================================================================
-- 4. FIX daily_content TABLE
-- ============================================================================

-- Change date column type from text to date
ALTER TABLE daily_content ALTER COLUMN date TYPE DATE USING date::DATE;

-- ============================================================================
-- 5. FIX weather_data TABLE
-- ============================================================================

-- Update location column type to match production
ALTER TABLE weather_data ALTER COLUMN location TYPE CHARACTER VARYING;

-- Update sunrise_time and sunset_time to time type
ALTER TABLE weather_data 
ALTER COLUMN sunrise_time TYPE TIME WITHOUT TIME ZONE USING sunrise_time::TIME,
ALTER COLUMN sunset_time TYPE TIME WITHOUT TIME ZONE USING sunset_time::TIME;

-- ============================================================================
-- 6. FIX audio_generation_queue TABLE
-- ============================================================================

-- Update status column type and default
ALTER TABLE audio_generation_queue 
ALTER COLUMN status TYPE CHARACTER VARYING,
ALTER COLUMN status SET DEFAULT 'pending';

-- Update priority default to match production
ALTER TABLE audio_generation_queue ALTER COLUMN priority SET DEFAULT 5;

-- ============================================================================
-- 7. FIX audio_files TABLE
-- ============================================================================

-- Update audio_type to use enum type like production
-- Note: This assumes the enum type exists in production
-- If not, we'll keep it as text for now

-- ============================================================================
-- 8. UPDATE UUID GENERATION TO MATCH PRODUCTION
-- ============================================================================

-- Update all tables to use gen_random_uuid() instead of uuid_generate_v4()
ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE alarms ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE audio ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE audio_files ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE audio_generation_queue ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE daily_content ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE logs ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE user_events ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE weather_data ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- ============================================================================
-- 9. UPDATE TIMESTAMP TYPES TO MATCH PRODUCTION
-- ============================================================================

-- Update timestamp columns to use 'timestamp without time zone' where production does
ALTER TABLE users ALTER COLUMN created_at TYPE TIMESTAMP WITHOUT TIME ZONE;
ALTER TABLE users ALTER COLUMN last_login TYPE TIMESTAMP WITHOUT TIME ZONE;
ALTER TABLE users ALTER COLUMN updated_at TYPE TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE alarms ALTER COLUMN created_at TYPE TIMESTAMP WITHOUT TIME ZONE;
ALTER TABLE alarms ALTER COLUMN updated_at TYPE TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE daily_content ALTER COLUMN created_at TYPE TIMESTAMP WITHOUT TIME ZONE;
ALTER TABLE daily_content ALTER COLUMN updated_at TYPE TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE logs ALTER COLUMN created_at TYPE TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE user_events ALTER COLUMN created_at TYPE TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE user_preferences ALTER COLUMN updated_at TYPE TIMESTAMP WITHOUT TIME ZONE;

-- ============================================================================
-- 10. UPDATE NULLABLE CONSTRAINTS TO MATCH PRODUCTION
-- ============================================================================

-- Update user_id columns to be nullable where production allows it
ALTER TABLE alarms ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE audio ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE user_events ALTER COLUMN user_id DROP NOT NULL;

-- Update email to be nullable in users table
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- ============================================================================
-- 11. UPDATE DEFAULTS TO MATCH PRODUCTION
-- ============================================================================

-- Update timezone default in user_preferences
ALTER TABLE user_preferences ALTER COLUMN timezone DROP DEFAULT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Add comments for documentation
COMMENT ON COLUMN user_preferences.tts_voice IS 'Text-to-speech voice preference';
COMMENT ON COLUMN user_preferences.onboarding_completed IS 'Whether user has completed onboarding';
COMMENT ON COLUMN user_preferences.onboarding_step IS 'Current onboarding step number';
COMMENT ON COLUMN alarms.timezone_at_creation IS 'Timezone when alarm was created';
COMMENT ON COLUMN audio.script_text IS 'The text script used to generate audio';
COMMENT ON COLUMN audio.generated_at IS 'When the audio was generated';
COMMENT ON COLUMN audio.status IS 'Current status of audio generation';
COMMENT ON COLUMN audio.cache_status IS 'Status of audio caching'; 