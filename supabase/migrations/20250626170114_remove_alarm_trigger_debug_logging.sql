-- Remove alarm trigger debug logging (no longer needed)
-- The timezone dependency fix and day rollover fix have been stable for several days
-- Debug logging is no longer necessary and adds performance overhead

-- Update the calculate_next_trigger function to remove debug logging
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
DECLARE
  local_dt TIMESTAMP;
  current_time_local TIME;
  alarm_time_local TIME;
  target_date DATE;
BEGIN
  -- Get current time in the alarm's timezone
  current_time_local := (NOW() AT TIME ZONE NEW.alarm_timezone)::time;
  alarm_time_local := NEW.alarm_time_local::time;
  
  -- Determine target date
  IF NEW.alarm_date IS NOT NULL THEN
    -- Use provided alarm_date
    target_date := NEW.alarm_date;
  ELSE
    -- Check if alarm time has already passed today
    IF current_time_local >= alarm_time_local THEN
      -- Alarm time has passed today, schedule for tomorrow
      target_date := (CURRENT_DATE + INTERVAL '1 day')::date;
    ELSE
      -- Alarm time hasn't passed yet, schedule for today
      target_date := CURRENT_DATE;
    END IF;
  END IF;
  
  -- Set the alarm_date field to match the target date
  NEW.alarm_date := target_date;
  
  -- Create the local datetime
  local_dt := (target_date::timestamp + alarm_time_local::interval);

  -- Convert to UTC using alarm's timezone
  BEGIN
    NEW.next_trigger_at := local_dt AT TIME ZONE NEW.alarm_timezone;
  EXCEPTION WHEN OTHERS THEN
    -- If timezone is invalid, fallback to UTC
    NEW.next_trigger_at := local_dt AT TIME ZONE 'UTC';
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Log the cleanup
INSERT INTO logs (event_type, meta)
VALUES (
  'alarm_trigger_debug_removed',
  jsonb_build_object(
    'action', 'remove_alarm_trigger_debug_logging',
    'reason', 'Recent fixes (timezone dependency, day rollover) are stable and no longer need debugging',
    'benefits', 'Reduced log table size, faster alarm operations, cleaner monitoring',
    'removed_at', NOW()
  )
);
