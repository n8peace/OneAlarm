-- Remove the category column from the daily_content table
-- This column is redundant with news_category and can be safely removed

-- Drop the index first
DROP INDEX IF EXISTS idx_daily_content_category_date;

-- Remove the category column
ALTER TABLE daily_content DROP COLUMN IF EXISTS category; 