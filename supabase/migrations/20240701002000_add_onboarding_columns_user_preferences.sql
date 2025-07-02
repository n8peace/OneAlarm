-- Add onboarding_completed and onboarding_step columns to user_preferences for migration compatibility
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0; 