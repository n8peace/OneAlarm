-- Fix user_preferences schema to match main
-- This migration updates the develop user_preferences table to match main's schema exactly

-- ============================================================================
-- STEP 1: ADD MISSING COLUMNS
-- ============================================================================

-- Add the id column as the primary key
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();

-- Add tts_voice column (main uses this instead of preferred_voice)
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS tts_voice TEXT DEFAULT 'alloy';

-- ============================================================================
-- STEP 2: UPDATE PRIMARY KEY
-- ============================================================================

-- Drop the existing primary key constraint
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;

-- Add the new primary key constraint on id
ALTER TABLE user_preferences ADD PRIMARY KEY (id);

-- ============================================================================
-- STEP 3: MIGRATE DATA
-- ============================================================================

-- Copy preferred_voice data to tts_voice if tts_voice is null
UPDATE user_preferences 
SET tts_voice = preferred_voice 
WHERE tts_voice IS NULL AND preferred_voice IS NOT NULL;

-- ============================================================================
-- STEP 4: REMOVE OBSOLETE COLUMNS
-- ============================================================================

-- Remove preferred_voice (replaced by tts_voice)
ALTER TABLE user_preferences DROP COLUMN IF EXISTS preferred_voice;

-- Remove preferred_speed (not in main schema)
ALTER TABLE user_preferences DROP COLUMN IF EXISTS preferred_speed;

-- ============================================================================
-- STEP 5: ADD UNIQUE CONSTRAINT
-- ============================================================================

-- Add unique constraint on user_id to ensure one preference per user
ALTER TABLE user_preferences 
ADD CONSTRAINT user_preferences_user_id_unique UNIQUE (user_id);

-- ============================================================================
-- STEP 6: UPDATE DEFAULTS TO MATCH MAIN
-- ============================================================================

-- Update timezone default to match main
ALTER TABLE user_preferences ALTER COLUMN timezone SET DEFAULT 'America/New_York';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Add comments for documentation
COMMENT ON COLUMN user_preferences.id IS 'Primary key for user preferences';
COMMENT ON COLUMN user_preferences.user_id IS 'Reference to users table';
COMMENT ON COLUMN user_preferences.tts_voice IS 'Text-to-speech voice preference (alloy, ash, echo, fable, onyx, nova, shimmer, verse)';
COMMENT ON COLUMN user_preferences.preferred_name IS 'User preferred name for personalization';

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'schema_update',
  jsonb_build_object(
    'action', 'fix_user_preferences_schema',
    'table', 'user_preferences',
    'changes', jsonb_build_object(
      'added_columns', ARRAY['id', 'tts_voice'],
      'removed_columns', ARRAY['preferred_voice', 'preferred_speed'],
      'primary_key_change', 'user_id -> id',
      'unique_constraint', 'user_id'
    ),
    'purpose', 'Match main branch schema exactly',
    'environment', 'develop',
    'timestamp', NOW()
  )
); 