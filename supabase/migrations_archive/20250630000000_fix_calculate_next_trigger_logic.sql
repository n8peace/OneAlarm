-- Fix calculate_next_trigger function to use provided alarm_date
-- The trigger should not calculate alarm_date - it should come from row creation
-- The trigger should only calculate next_trigger_at based on provided values

CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
DECLARE
  local_dt TIMESTAMP;
BEGIN
  -- Validate that required fields are provided
  IF NEW.alarm_date IS NULL THEN
    RAISE EXCEPTION 'alarm_date must be provided when creating/updating alarms';
  END IF;
  
  IF NEW.alarm_time_local IS NULL THEN
    RAISE EXCEPTION 'alarm_time_local must be provided when creating/updating alarms';
  END IF;
  
  IF NEW.alarm_timezone IS NULL THEN
    RAISE EXCEPTION 'alarm_timezone must be provided when creating/updating alarms';
  END IF;
  
  -- Create the local datetime using provided alarm_date and alarm_time_local
  local_dt := (NEW.alarm_date::timestamp + NEW.alarm_time_local::interval);

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

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'calculate_next_trigger_fix',
  jsonb_build_object(
    'action', 'fix_calculate_next_trigger_logic',
    'function', 'calculate_next_trigger',
    'change', 'Trigger now uses provided alarm_date instead of calculating it internally',
    'benefits', 'Cleaner separation of concerns, more predictable behavior, explicit date control',
    'validation', 'Added validation for required fields (alarm_date, alarm_time_local, alarm_timezone)',
    'fix_timestamp', NOW()
  )
); 