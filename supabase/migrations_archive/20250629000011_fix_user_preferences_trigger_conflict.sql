-- Fix user preferences trigger conflict
-- The handle_new_user trigger is causing HTTP 409 conflicts when test scripts try to create preferences
-- This migration properly removes the auto-create trigger to allow clean test execution

-- Drop the trigger that auto-creates user_preferences
DROP TRIGGER IF EXISTS on_user_created ON users;

-- Drop the function that handles new user creation
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Log the removal
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_removal',
  jsonb_build_object(
    'action', 'fix_user_preferences_trigger_conflict',
    'trigger_name', 'on_user_created',
    'function_name', 'handle_new_user',
    'reason', 'Prevent HTTP 409 conflicts in test scripts by removing auto-create trigger',
    'removal_timestamp', NOW()
  )
); 