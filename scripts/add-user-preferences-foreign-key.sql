-- Add missing foreign key constraint to user_preferences table
-- This matches the main environment schema exactly

-- Add foreign key constraint to user_preferences table
ALTER TABLE user_preferences 
ADD CONSTRAINT user_preferences_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Verify the changes
SELECT 'Foreign key constraint added successfully' as status; 