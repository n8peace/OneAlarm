-- Remove unique constraint on daily_content.date to match main environment
-- This migration removes the daily_content_date_key constraint that exists in develop but not in main

-- Drop the unique constraint on the date column
ALTER TABLE daily_content DROP CONSTRAINT IF EXISTS daily_content_date_key;

-- Also drop any unique index that might exist
DROP INDEX IF EXISTS daily_content_date_key;

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'constraint_removal',
  jsonb_build_object(
    'action', 'remove_daily_content_date_unique_constraint',
    'table', 'daily_content',
    'column', 'date',
    'constraint_name', 'daily_content_date_key',
    'reason', 'Match main environment schema',
    'environment', 'develop',
    'timestamp', NOW()
  )
); 