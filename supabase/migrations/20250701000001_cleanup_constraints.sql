-- Clean up remaining constraint issues
-- This migration addresses redundant constraints and naming inconsistencies

-- Step 1: Remove redundant unique constraint on user_preferences.user_id
-- Since user_id is already the primary key, the unique constraint is redundant
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_user_id_unique;

-- Step 2: Clean up users table constraints
-- First drop all foreign key constraints that depend on users_pkey
ALTER TABLE alarms DROP CONSTRAINT IF EXISTS alarm_user_id_fkey;
ALTER TABLE audio_generation_queue DROP CONSTRAINT IF EXISTS audio_generation_queue_user_id_fkey;
ALTER TABLE audio DROP CONSTRAINT IF EXISTS daily_audio_user_id_fkey;
ALTER TABLE logs DROP CONSTRAINT IF EXISTS logs_user_id_fkey;
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS preferences_user_id_fkey;
ALTER TABLE user_events DROP CONSTRAINT IF EXISTS user_events_user_id_fkey;
ALTER TABLE weather_data DROP CONSTRAINT IF EXISTS weather_data_user_id_fkey;
ALTER TABLE audio_files DROP CONSTRAINT IF EXISTS audio_files_user_id_fkey;

-- Now drop and recreate the primary key
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE users ADD CONSTRAINT users_pkey PRIMARY KEY (id);

-- Recreate all foreign key constraints
ALTER TABLE alarms ADD CONSTRAINT alarm_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE audio_generation_queue ADD CONSTRAINT audio_generation_queue_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE audio ADD CONSTRAINT daily_audio_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE logs ADD CONSTRAINT logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_preferences ADD CONSTRAINT preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_events ADD CONSTRAINT user_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE weather_data ADD CONSTRAINT weather_data_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE audio_files ADD CONSTRAINT audio_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 3a: Drop all foreign keys referencing alarm_pkey
ALTER TABLE audio DROP CONSTRAINT IF EXISTS audio_alarm_id_fkey;
ALTER TABLE audio_generation_queue DROP CONSTRAINT IF EXISTS audio_generation_queue_alarm_id_fkey;
ALTER TABLE audio_files DROP CONSTRAINT IF EXISTS audio_files_alarm_id_fkey;

-- Step 3b: Drop and recreate the primary key on alarms
ALTER TABLE alarms DROP CONSTRAINT IF EXISTS alarm_pkey;
ALTER TABLE alarms ADD CONSTRAINT alarms_pkey PRIMARY KEY (id);

-- Step 3c: Recreate the foreign keys referencing alarms_pkey
ALTER TABLE audio ADD CONSTRAINT audio_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE CASCADE;
ALTER TABLE audio_generation_queue ADD CONSTRAINT audio_generation_queue_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE CASCADE;
ALTER TABLE audio_files ADD CONSTRAINT audio_files_alarm_id_fkey FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE CASCADE;

-- Step 4: Standardize constraint names for consistency
-- Rename daily_audio_pkey to audio_pkey for consistency
ALTER TABLE audio DROP CONSTRAINT IF EXISTS daily_audio_pkey;
ALTER TABLE audio ADD CONSTRAINT audio_pkey PRIMARY KEY (id);

-- Step 4: Verify and clean up any orphaned constraints
-- This will help identify any remaining issues 