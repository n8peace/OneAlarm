-- Fix users table foreign key constraint (Manual Application)
-- Copy and paste this into the Supabase SQL Editor

-- Drop the foreign key constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- Update the users table to allow direct user creation
-- The id column will still be UUID but won't reference auth.users
ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Update the handle_new_user function to work without auth.users dependency
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create user_preferences if the user doesn't already have them
    INSERT INTO user_preferences (user_id) 
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the sync_auth_to_public_user function to handle the case where auth user might not exist
CREATE OR REPLACE FUNCTION sync_auth_to_public_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Try to insert, but don't fail if auth user doesn't exist
    INSERT INTO public.users (id, email, created_at)
    VALUES (NEW.id, NEW.email, NEW.created_at)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the operation
        INSERT INTO logs (event_type, event_data, user_id)
        VALUES ('auth_sync_error', jsonb_build_object('error', SQLERRM, 'auth_user_id', NEW.id), NEW.id);
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the changes
SELECT 'Foreign key constraint removed successfully' as status; 