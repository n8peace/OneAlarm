-- Remove onboarding_completed and onboarding_step from user_preferences

-- 1. Drop dependent indexes (if exist)
DROP INDEX IF EXISTS idx_user_preferences_onboarding;

-- 2. Remove comments (if exist)
COMMENT ON COLUMN user_preferences.onboarding_completed IS NULL;
COMMENT ON COLUMN user_preferences.onboarding_step IS NULL;

-- 3. Remove columns
ALTER TABLE user_preferences
  DROP COLUMN IF EXISTS onboarding_completed,
  DROP COLUMN IF EXISTS onboarding_step;

-- 4. Update handle_new_user trigger to remove onboarding fields
DROP TRIGGER IF EXISTS on_user_created ON users;
DROP FUNCTION IF EXISTS handle_new_user();

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_preferences (
    user_id, 
    tts_voice, 
    timezone
  )
  VALUES (
    NEW.id, 
    'alloy', 
    'America/New_York'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_created
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 5. Log the change
INSERT INTO logs (event_type, meta)
VALUES (
  'remove_onboarding_from_user_preferences',
  jsonb_build_object(
    'action', 'remove_onboarding_fields',
    'table', 'user_preferences',
    'removed_columns', ARRAY['onboarding_completed', 'onboarding_step'],
    'updated_at', NOW()
  )
); 