-- Complete the daily content restructure migration
-- This migration handles the case where the previous migration was partially applied

-- Step 1: Add new category-specific headline columns (if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_content' AND column_name = 'general_headlines') THEN
        ALTER TABLE daily_content ADD COLUMN general_headlines TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_content' AND column_name = 'business_headlines') THEN
        ALTER TABLE daily_content ADD COLUMN business_headlines TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_content' AND column_name = 'technology_headlines') THEN
        ALTER TABLE daily_content ADD COLUMN technology_headlines TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_content' AND column_name = 'sports_headlines') THEN
        ALTER TABLE daily_content ADD COLUMN sports_headlines TEXT;
    END IF;
END $$;

-- Step 2: (Data migration skipped; columns already dropped)

-- Step 3: Update indexes
DROP INDEX IF EXISTS idx_daily_content_user_date;
CREATE INDEX IF NOT EXISTS idx_daily_content_date ON daily_content(date);

-- Step 4: Add comments for documentation
COMMENT ON COLUMN daily_content.general_headlines IS 'News headlines for general category';
COMMENT ON COLUMN daily_content.business_headlines IS 'News headlines for business category';
COMMENT ON COLUMN daily_content.technology_headlines IS 'News headlines for technology category';
COMMENT ON COLUMN daily_content.sports_headlines IS 'News headlines for sports category';
COMMENT ON COLUMN daily_content.sports_summary IS 'Shared sports data across all categories';
COMMENT ON COLUMN daily_content.stocks_summary IS 'Shared stock market data across all categories';
COMMENT ON COLUMN daily_content.holidays IS 'Shared holiday information across all categories'; 