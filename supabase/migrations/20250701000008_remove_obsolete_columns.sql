-- Remove obsolete columns from production schema to match dev

-- Drop obsolete column from alarms
ALTER TABLE alarms DROP COLUMN IF EXISTS timezone_at_creation;

-- Drop obsolete columns from user_preferences
ALTER TABLE user_preferences DROP COLUMN IF EXISTS onboarding_completed;
ALTER TABLE user_preferences DROP COLUMN IF EXISTS onboarding_step; 