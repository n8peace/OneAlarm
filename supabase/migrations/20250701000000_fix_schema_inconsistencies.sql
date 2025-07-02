-- Fix schema inconsistencies found during verification
-- This migration addresses issues with logs, user_preferences, and users tables

-- Step 1: Add user_id to logs table if it doesn't exist
ALTER TABLE logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Step 2: Fix user_preferences table - remove separate id column and use user_id as primary key
-- First, drop the existing primary key constraint
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS preferences_pkey;

-- Remove the id column if it exists
ALTER TABLE user_preferences DROP COLUMN IF EXISTS id;

-- Add primary key constraint on user_id
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id);

-- Step 3: Fix duplicate primary key in users table
-- This will be handled by the existing constraint, but let's ensure it's clean
-- The users table should only have one primary key on id

-- Step 4: Add any missing indexes for performance
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at);

-- Step 5: Add RLS policies for logs table
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own logs" ON logs;
DROP POLICY IF EXISTS "Users can insert own logs" ON logs;

-- Create new policies
CREATE POLICY "Users can view own logs" ON logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own logs" ON logs FOR INSERT WITH CHECK (auth.uid() = user_id); 