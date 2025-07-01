-- Migration: Restructure daily_content table from 4 rows per day to 1 row per day
-- This changes the schema from news_category + headline to 4 separate headline columns

-- Step 1: Add new category-specific headline columns
ALTER TABLE daily_content 
ADD COLUMN general_headlines TEXT,
ADD COLUMN business_headlines TEXT,
ADD COLUMN technology_headlines TEXT,
ADD COLUMN sports_headlines TEXT;

-- Step 2: Migrate existing data from 4-row format to 1-row format
-- First, create a temporary table to hold the consolidated data
CREATE TEMP TABLE temp_daily_content AS
SELECT 
    date,
    MAX(CASE WHEN news_category = 'general' THEN headline END) as general_headlines,
    MAX(CASE WHEN news_category = 'business' THEN headline END) as business_headlines,
    MAX(CASE WHEN news_category = 'technology' THEN headline END) as technology_headlines,
    MAX(CASE WHEN news_category = 'sports' THEN headline END) as sports_headlines,
    MAX(sports_summary) as sports_summary,
    MAX(stocks_summary) as stocks_summary,
    MAX(holidays) as holidays,
    MAX(created_at) as created_at
FROM daily_content
GROUP BY date;

-- Step 3: Clear existing data and insert consolidated data
DELETE FROM daily_content;

INSERT INTO daily_content (
    date,
    general_headlines,
    business_headlines,
    technology_headlines,
    sports_headlines,
    sports_summary,
    stocks_summary,
    holidays,
    created_at
)
SELECT 
    date,
    general_headlines,
    business_headlines,
    technology_headlines,
    sports_headlines,
    sports_summary,
    stocks_summary,
    holidays,
    created_at
FROM temp_daily_content;

-- Step 4: Drop old columns
ALTER TABLE daily_content 
DROP COLUMN news_category,
DROP COLUMN headline;

-- Step 5: Update indexes
-- Drop old index
DROP INDEX IF EXISTS idx_daily_content_user_date;

-- Create new index for date-based queries (only if it doesn't exist)
CREATE INDEX IF NOT EXISTS idx_daily_content_date ON daily_content(date);

-- Step 7: Add comments for documentation
COMMENT ON COLUMN daily_content.general_headlines IS 'News headlines for general category';
COMMENT ON COLUMN daily_content.business_headlines IS 'News headlines for business category';
COMMENT ON COLUMN daily_content.technology_headlines IS 'News headlines for technology category';
COMMENT ON COLUMN daily_content.sports_headlines IS 'News headlines for sports category';
COMMENT ON COLUMN daily_content.sports_summary IS 'Shared sports data across all categories';
COMMENT ON COLUMN daily_content.stocks_summary IS 'Shared stock market data across all categories';
COMMENT ON COLUMN daily_content.holidays IS 'Shared holiday information across all categories';

-- Step 8: Clean up temporary table
DROP TABLE temp_daily_content; 