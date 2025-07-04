-- Fix the handle_new_user trigger function to prevent circular reference
-- The function was trying to insert into users table when a user is already being created

-- Drop the problematic trigger function
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Create a corrected version that only handles user_preferences
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create user_preferences record, don't try to insert into users table
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user(); 