-- Fix UUID generation for users table
-- This ensures that the users table can generate UUIDs automatically

-- First, let's check if the uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Add default UUID generation to the users table id column
ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Also ensure the handle_new_user function works correctly
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO users (id, email, onboarding_done, subscription_status, is_admin) 
    VALUES (NEW.id, NEW.email, false, 'trialing', false);
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'uuid_generation_fix',
  jsonb_build_object(
    'action', 'fix_uuid_generation',
    'table', 'users',
    'changes', jsonb_build_object(
      'added_uuid_extension', true,
      'set_default_uuid', true,
      'updated_handle_new_user', true
    ),
    'timestamp', NOW()
  )
); 