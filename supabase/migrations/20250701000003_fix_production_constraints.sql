-- Fix production constraints safely
-- This migration handles constraint conflicts in production

-- Step 1: Add user_id to logs table if it doesn't exist
ALTER TABLE logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Step 2: Fix user_preferences table - ensure proper primary key
-- Check if user_preferences has the correct structure
DO $$ 
BEGIN
    -- If user_preferences doesn't have user_id as primary key, fix it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_preferences' 
        AND constraint_name = 'user_preferences_pkey'
    ) THEN
        -- Drop any existing primary key
        ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS preferences_pkey;
        ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;
        
        -- Remove id column if it exists
        ALTER TABLE user_preferences DROP COLUMN IF EXISTS id;
        
        -- Add primary key constraint on user_id
        ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id);
    END IF;
END $$;

-- Step 3: Add any missing indexes for performance
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at);

-- Step 4: Add RLS policies for logs table
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own logs" ON logs;
DROP POLICY IF EXISTS "Users can insert own logs" ON logs;

-- Create new policies
CREATE POLICY "Users can view own logs" ON logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own logs" ON logs FOR INSERT WITH CHECK (auth.uid() = user_id); 