-- Fix user_preferences schema to exactly match main
-- This migration removes extra columns and matches main's schema exactly

-- ============================================================================
-- STEP 1: REMOVE EXTRA COLUMNS THAT MAIN DOESN'T HAVE
-- ============================================================================

-- Remove preferred_voice (main uses tts_voice) - already removed in previous migration
-- ALTER TABLE user_preferences DROP COLUMN IF EXISTS preferred_voice;

-- Remove preferred_speed (not in main schema)
ALTER TABLE user_preferences DROP COLUMN IF EXISTS preferred_speed;

-- Remove created_at (not in main schema)
ALTER TABLE user_preferences DROP COLUMN IF EXISTS created_at;

-- ============================================================================
-- STEP 2: UPDATE DEFAULTS TO MATCH MAIN
-- ============================================================================

-- Update tts_voice default to match main (no default in main)
ALTER TABLE user_preferences ALTER COLUMN tts_voice DROP DEFAULT;

-- Update timezone default to match main (no default in main)
ALTER TABLE user_preferences ALTER COLUMN timezone DROP DEFAULT;

-- ============================================================================
-- STEP 3: VERIFY STRUCTURE MATCHES MAIN
-- ============================================================================

-- Add comments for documentation
COMMENT ON COLUMN user_preferences.user_id IS 'Reference to users table (NOT NULL)';
COMMENT ON COLUMN user_preferences.sports_team IS 'User favorite sports team';
COMMENT ON COLUMN user_preferences.stocks IS 'Array of stock symbols user follows';
COMMENT ON COLUMN user_preferences.include_weather IS 'Whether to include weather in audio';
COMMENT ON COLUMN user_preferences.timezone IS 'User timezone for scheduling';
COMMENT ON COLUMN user_preferences.updated_at IS 'Last update timestamp';
COMMENT ON COLUMN user_preferences.preferred_name IS 'User preferred name for personalization';
COMMENT ON COLUMN user_preferences.tts_voice IS 'Text-to-speech voice preference';
COMMENT ON COLUMN user_preferences.news_categories IS 'Array of preferred news categories';
COMMENT ON COLUMN user_preferences.onboarding_completed IS 'Whether user completed onboarding';
COMMENT ON COLUMN user_preferences.onboarding_step IS 'Current onboarding step number';

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'schema_update',
  jsonb_build_object(
    'action', 'fix_user_preferences_schema_exact',
    'table', 'user_preferences',
    'changes', jsonb_build_object(
      'removed_columns', ARRAY['preferred_speed', 'created_at'],
      'updated_defaults', ARRAY['tts_voice', 'timezone']
    ),
    'purpose', 'Exact match to main branch schema',
    'environment', 'develop',
    'main_schema', 'user_id, sports_team, stocks, include_weather, timezone, updated_at, preferred_name, tts_voice, news_categories, onboarding_completed, onboarding_step',
    'timestamp', NOW()
  )
); 