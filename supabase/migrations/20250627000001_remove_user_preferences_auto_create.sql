-- Remove auto-create user_preferences trigger
-- This trigger was causing duplicate generate-audio calls and conflicts with test scripts

-- Drop the trigger that auto-creates user_preferences
DROP TRIGGER IF EXISTS on_user_created ON users;

-- Drop the function that handles new user creation
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Log the removal
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_removal',
  jsonb_build_object(
    'action', 'remove_user_preferences_auto_create',
    'trigger_name', 'on_user_created',
    'function_name', 'handle_new_user',
    'reason', 'Prevent duplicate generate-audio calls and allow clean test script execution',
    'removal_timestamp', NOW()
  )
); 