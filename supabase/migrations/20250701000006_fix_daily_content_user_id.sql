-- Fix daily_content table user_id constraint issue
-- The function is trying to insert without user_id but the column is NOT NULL

-- Option 1: Add user_id column if it doesn't exist (for user-specific content)
ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Option 2: Make user_id nullable if it exists and is NOT NULL (for global content)
-- This allows the daily-content function to insert global content without a specific user
ALTER TABLE daily_content ALTER COLUMN user_id DROP NOT NULL;

-- Add index for performance if user_id column exists
CREATE INDEX IF NOT EXISTS idx_daily_content_user_id ON daily_content(user_id);

-- Update RLS policy to allow global content access
DROP POLICY IF EXISTS "Users can view daily content" ON daily_content;
CREATE POLICY "Users can view daily content" ON daily_content FOR SELECT USING (
    user_id IS NULL OR auth.uid() = user_id
);

-- Add comment for documentation
COMMENT ON COLUMN daily_content.user_id IS 'User ID for user-specific content, NULL for global content'; 