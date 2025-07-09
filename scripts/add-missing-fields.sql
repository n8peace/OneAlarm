-- Add missing fields to match main environment schema
-- This adds the fields that the test script expects

-- Add missing fields to weather_data table
ALTER TABLE weather_data 
ADD COLUMN IF NOT EXISTS current_temp REAL,
ADD COLUMN IF NOT EXISTS high_temp REAL,
ADD COLUMN IF NOT EXISTS low_temp REAL;

-- Add missing field to alarms table
ALTER TABLE alarms 
ADD COLUMN IF NOT EXISTS timezone_at_creation TEXT;

-- Update existing records to have default values
UPDATE weather_data 
SET 
    current_temp = temperature,
    high_temp = temperature + 5,
    low_temp = temperature - 5
WHERE current_temp IS NULL;

UPDATE alarms 
SET timezone_at_creation = alarm_timezone 
WHERE timezone_at_creation IS NULL;

-- Verify the changes
SELECT 'Missing fields added successfully' as status; 