-- Fix production users table to match development
-- Add missing columns that exist in dev but not in prod

-- Add missing columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_done BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'trialing';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT;

-- Add comments for documentation
COMMENT ON COLUMN users.onboarding_done IS 'Whether the user has completed onboarding';
COMMENT ON COLUMN users.subscription_status IS 'Current subscription status (trialing, active, cancelled, etc.)';
COMMENT ON COLUMN users.is_admin IS 'Whether the user has admin privileges';
COMMENT ON COLUMN users.last_login IS 'Timestamp of last login';
COMMENT ON COLUMN users.phone IS 'User phone number';

-- Update the handle_new_user function to include the new columns
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO users (id, email, onboarding_done, subscription_status, is_admin) 
    VALUES (NEW.id, NEW.email, false, 'trialing', false);
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 