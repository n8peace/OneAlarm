-- Update alarms table to be timezone-aware
-- This allows alarms to work correctly when users travel between timezones

-- Step 1: Add new columns for timezone-aware alarm times
ALTER TABLE alarms ADD COLUMN IF NOT EXISTS alarm_time_local TIME;
ALTER TABLE alarms ADD COLUMN IF NOT EXISTS timezone_at_creation TEXT;

-- Step 2: Migrate existing data
-- (Removed: UPDATE alarms SET alarm_time_local = alarm_time::time, timezone_at_creation = 'UTC' WHERE alarm_time IS NOT NULL;)

-- Step 3: Drop the old alarm_time column
ALTER TABLE alarms DROP COLUMN IF EXISTS alarm_time;

-- Step 4: Make new columns NOT NULL after data migration
DROP TRIGGER IF EXISTS calculate_next_trigger_trigger ON alarms;
UPDATE alarms SET timezone_at_creation = 'UTC' WHERE timezone_at_creation IS NULL;
ALTER TABLE alarms ALTER COLUMN alarm_time_local SET NOT NULL;
ALTER TABLE alarms ALTER COLUMN timezone_at_creation SET NOT NULL;

-- Step 5: Add constraint to ensure valid timezone (using common timezones)
ALTER TABLE alarms ADD CONSTRAINT check_valid_timezone 
  CHECK (timezone_at_creation IN (
    'UTC', 'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'America/Anchorage', 'Pacific/Honolulu', 'Europe/London', 'Europe/Paris', 'Europe/Berlin',
    'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Kolkata', 'Australia/Sydney', 'Australia/Perth'
  ));

-- Step 6: Create function to calculate next trigger based on user's current timezone
DROP TRIGGER IF EXISTS calculate_next_trigger_trigger ON alarms;
DROP FUNCTION IF EXISTS calculate_next_trigger();
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
DECLARE
  user_timezone TEXT;
  local_dt TIMESTAMP;
BEGIN
  -- Use alarm_date and alarm_time_local to construct the local datetime
  IF NEW.alarm_date IS NULL THEN
    RAISE EXCEPTION 'alarm_date must be provided when creating/updating alarms';
  END IF;
  IF NEW.alarm_time_local IS NULL THEN
    RAISE EXCEPTION 'alarm_time_local must be provided when creating/updating alarms';
  END IF;
  IF NEW.timezone_at_creation IS NULL THEN
    RAISE EXCEPTION 'timezone_at_creation must be provided when creating/updating alarms';
  END IF;

  local_dt := (NEW.alarm_date::timestamp + NEW.alarm_time_local::interval);

  -- Get user's current timezone, fallback to timezone_at_creation if not set
  SELECT timezone INTO user_timezone 
  FROM user_preferences 
  WHERE user_id = NEW.user_id;
  user_timezone := COALESCE(user_timezone, NEW.timezone_at_creation);

  -- Convert to UTC using alarm's timezone
  BEGIN
    NEW.next_trigger_at := local_dt AT TIME ZONE user_timezone;
  EXCEPTION WHEN OTHERS THEN
    -- If timezone is invalid, fallback to UTC
    NEW.next_trigger_at := local_dt AT TIME ZONE 'UTC';
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create trigger to automatically calculate next_trigger_at
CREATE TRIGGER calculate_next_trigger_trigger
  BEFORE INSERT OR UPDATE ON alarms
  FOR EACH ROW EXECUTE FUNCTION calculate_next_trigger();

-- Step 8: Update the audio generation queue trigger to use next_trigger_at
DROP TRIGGER IF EXISTS alarm_audio_queue_trigger ON alarms;
DROP FUNCTION IF EXISTS manage_alarm_audio_queue();

CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audio_generation_queue (alarm_id, user_id, scheduled_for)
    VALUES (NEW.id, NEW.user_id, NEW.next_trigger_at - INTERVAL '25 minutes')
    ON CONFLICT (alarm_id) DO NOTHING;
    
  -- Handle UPDATE
  ELSIF TG_OP = 'UPDATE' THEN
    -- Update queue if next_trigger_at changed
    IF OLD.next_trigger_at != NEW.next_trigger_at THEN
      UPDATE audio_generation_queue 
      SET scheduled_for = NEW.next_trigger_at - INTERVAL '25 minutes',
          status = 'pending',
          retry_count = 0,
          error_message = NULL
      WHERE alarm_id = NEW.id;
    END IF;
    
  -- Handle DELETE
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM audio_generation_queue WHERE alarm_id = OLD.id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER alarm_audio_queue_trigger
  AFTER INSERT OR UPDATE OR DELETE ON alarms
  FOR EACH ROW EXECUTE FUNCTION manage_alarm_audio_queue();

-- Step 9: Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_alarms_timezone ON alarms(timezone_at_creation);
CREATE INDEX IF NOT EXISTS idx_alarms_next_trigger ON alarms(next_trigger_at);

-- Step 10: Update existing alarms to have proper next_trigger_at (with error handling)
UPDATE alarms 
SET next_trigger_at = (
  CURRENT_DATE + alarm_time_local
) AT TIME ZONE CASE 
  WHEN timezone_at_creation IN (
    'UTC', 'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'America/Anchorage', 'Pacific/Honolulu', 'Europe/London', 'Europe/Paris', 'Europe/Berlin',
    'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Kolkata', 'Australia/Sydney', 'Australia/Perth'
  ) THEN timezone_at_creation
  ELSE 'UTC'
END
WHERE next_trigger_at IS NULL; 