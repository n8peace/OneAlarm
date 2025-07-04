-- Migration to sync production schema with development schema
-- This migration addresses all differences between prod and dev environments

-- 1. Update alarms table
ALTER TABLE alarms 
ADD COLUMN IF NOT EXISTS active boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS is_overridden boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS timezone_at_creation text NOT NULL DEFAULT 'UTC';

-- Update user_id to be nullable to match dev
ALTER TABLE alarms ALTER COLUMN user_id DROP NOT NULL;

-- Update created_at to use timestamp without time zone
ALTER TABLE alarms ALTER COLUMN created_at TYPE timestamp without time zone;
ALTER TABLE alarms ALTER COLUMN updated_at TYPE timestamp without time zone;

-- Update id default to use gen_random_uuid()
ALTER TABLE alarms ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 2. Update audio table
ALTER TABLE audio 
ADD COLUMN IF NOT EXISTS script_text text,
ADD COLUMN IF NOT EXISTS generated_at timestamp without time zone DEFAULT now(),
ADD COLUMN IF NOT EXISTS error text,
ADD COLUMN IF NOT EXISTS status character varying DEFAULT 'generating',
ADD COLUMN IF NOT EXISTS cached_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS cache_status character varying DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS file_size integer;

-- Update user_id to be nullable
ALTER TABLE audio ALTER COLUMN user_id DROP NOT NULL;

-- Update data types to match dev
ALTER TABLE audio ALTER COLUMN audio_type TYPE character varying;
ALTER TABLE audio ALTER COLUMN audio_type SET DEFAULT 'general';

-- Update id default
ALTER TABLE audio ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 3. Update audio_generation_queue table
ALTER TABLE audio_generation_queue 
ALTER COLUMN status SET NOT NULL,
ALTER COLUMN status TYPE character varying,
ALTER COLUMN priority SET DEFAULT 5;

-- Update id default
ALTER TABLE audio_generation_queue ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 4. Update daily_content table
ALTER TABLE daily_content ALTER COLUMN date DROP NOT NULL;
ALTER TABLE daily_content ALTER COLUMN created_at TYPE timestamp without time zone;
ALTER TABLE daily_content ALTER COLUMN updated_at TYPE timestamp without time zone;
ALTER TABLE daily_content ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 5. Update logs table
-- First, create a new logs table with UUID id
CREATE TABLE IF NOT EXISTS logs_new (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid,
    event_type text,
    meta jsonb,
    created_at timestamp without time zone DEFAULT now()
);

-- Copy data from old logs table to new one
INSERT INTO logs_new (user_id, event_type, meta, created_at)
SELECT user_id, event_type, meta, created_at FROM logs;

-- Drop old logs table and rename new one
DROP TABLE logs;
ALTER TABLE logs_new RENAME TO logs;

-- 6. Update user_events table
ALTER TABLE user_events 
ALTER COLUMN created_at TYPE timestamp without time zone;
ALTER TABLE user_events ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 7. Update user_preferences table
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS sports_team text,
ADD COLUMN IF NOT EXISTS stocks text[],
ADD COLUMN IF NOT EXISTS include_weather boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS preferred_name text,
ADD COLUMN IF NOT EXISTS tts_voice text,
ADD COLUMN IF NOT EXISTS news_categories text[] DEFAULT ARRAY['general'],
ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS onboarding_step integer DEFAULT 0;

-- Update timestamp types
ALTER TABLE user_preferences 
ALTER COLUMN created_at TYPE timestamp without time zone,
ALTER COLUMN updated_at TYPE timestamp without time zone;

-- Update defaults to match dev
ALTER TABLE user_preferences 
ALTER COLUMN timezone DROP DEFAULT,
ALTER COLUMN preferred_voice DROP DEFAULT,
ALTER COLUMN preferred_speed DROP DEFAULT;

-- 8. Update users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone text,
ADD COLUMN IF NOT EXISTS onboarding_done boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS subscription_status text DEFAULT 'trialing',
ADD COLUMN IF NOT EXISTS is_admin boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS last_login timestamp without time zone;

-- Update email to be nullable
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

-- Update timestamp types
ALTER TABLE users 
ALTER COLUMN created_at TYPE timestamp without time zone,
ALTER COLUMN updated_at TYPE timestamp without time zone;

-- Update id default
ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 9. Update weather_data table
ALTER TABLE weather_data 
ALTER COLUMN location TYPE character varying,
ALTER COLUMN condition TYPE character varying;

-- Update id default
ALTER TABLE weather_data ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 10. Add missing columns to user_preferences that exist in dev but not in prod
-- These columns might have been removed in previous migrations, so we add them back
DO $$
BEGIN
    -- Add preferred_voice if it doesn't exist (it was removed in a previous migration)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_preferences' AND column_name = 'preferred_voice') THEN
        ALTER TABLE user_preferences ADD COLUMN preferred_voice text DEFAULT 'alloy';
    END IF;
    
    -- Add preferred_speed if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_preferences' AND column_name = 'preferred_speed') THEN
        ALTER TABLE user_preferences ADD COLUMN preferred_speed real DEFAULT 1.0;
    END IF;
END $$;

-- 11. Add missing columns to audio that exist in dev but not in prod
DO $$
BEGIN
    -- Add file_path if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'audio' AND column_name = 'file_path') THEN
        ALTER TABLE audio ADD COLUMN file_path text NOT NULL;
    END IF;
END $$;

-- 12. Ensure all tables have proper primary keys and constraints
-- This is a safety check to ensure the schema is consistent
-- Note: Primary keys should already exist, so we'll skip adding them to avoid conflicts 