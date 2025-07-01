-- Remove unused fields from alarms table
-- These fields are not used in any business logic and can be safely removed

-- Remove the unused columns
ALTER TABLE alarms DROP COLUMN IF EXISTS is_scheduled;
ALTER TABLE alarms DROP COLUMN IF EXISTS days_active;
ALTER TABLE alarms DROP COLUMN IF EXISTS snooze_option;

-- Add comment to document the change
COMMENT ON TABLE alarms IS 'Alarms table - removed unused fields: is_scheduled, days_active, snooze_option'; 