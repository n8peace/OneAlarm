-- Fix user_preferences primary key constraint name to match main environment
-- This migration corrects the constraint name from user_preferences_pkey1 to user_preferences_pkey

-- Drop the existing primary key constraint with incorrect name
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey1;

-- Also drop any other potential primary key constraints
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;

-- Recreate the primary key constraint with the correct name
-- Based on the sync migration, user_id should be the primary key
ALTER TABLE user_preferences ADD PRIMARY KEY (user_id);

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'constraint_fix',
  jsonb_build_object(
    'action', 'fix_user_preferences_primary_key_name',
    'table', 'user_preferences',
    'old_constraint_name', 'user_preferences_pkey1',
    'new_constraint_name', 'user_preferences_pkey',
    'primary_key_column', 'user_id',
    'reason', 'Match main environment constraint naming',
    'environment', 'develop',
    'timestamp', NOW()
  )
); 