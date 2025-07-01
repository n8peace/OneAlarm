-- Fix handle_new_user trigger function to remove tone field
-- This function is triggered when a new user is created and tries to insert user_preferences

-- Drop and recreate the function without tone field
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

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'fix_handle_new_user_trigger',
  jsonb_build_object(
    'action', 'fix_handle_new_user_trigger',
    'function', 'handle_new_user',
    'removed_field', 'tone',
    'reason', 'Tone field was removed from user_preferences table',
    'fixed_at', NOW()
  )
); 