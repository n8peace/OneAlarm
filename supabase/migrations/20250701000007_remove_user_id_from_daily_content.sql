-- Remove user_id column from daily_content table
-- This table is designed for global daily content, not user-specific content

-- Drop all RLS policies that depend on user_id first
DROP POLICY IF EXISTS "Users can view own daily content" ON daily_content;
DROP POLICY IF EXISTS "Users can insert own daily content" ON daily_content;
DROP POLICY IF EXISTS "Users can update own daily content" ON daily_content;
DROP POLICY IF EXISTS "Users can delete own daily content" ON daily_content;
DROP POLICY IF EXISTS "Users can view daily content" ON daily_content;

-- Drop the index first
DROP INDEX IF EXISTS idx_daily_content_user_id;

-- Remove the user_id column
ALTER TABLE daily_content DROP COLUMN IF EXISTS user_id;

-- Create new RLS policy for global access
CREATE POLICY "Users can view daily content" ON daily_content FOR SELECT USING (true);

-- Add comment for documentation
COMMENT ON TABLE daily_content IS 'Global daily content for all users (news, sports, stocks, holidays)'; 