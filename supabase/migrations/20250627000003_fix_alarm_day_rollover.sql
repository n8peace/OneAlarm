-- Fix alarm day rollover logic
-- Ensure alarms are scheduled for the correct day when time has already passed today

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

  -- Debug log
  INSERT INTO logs (event_type, user_id, meta)
  VALUES (
    'alarm_trigger_debug',
    NEW.user_id,
    jsonb_build_object(
      'alarm_id', NEW.id,
      'alarm_date', NEW.alarm_date,
      'alarm_time_local', NEW.alarm_time_local,
      'alarm_timezone', NEW.alarm_timezone,
      'current_time_local', current_time_local,
      'alarm_time_local_parsed', alarm_time_local,
      'target_date', target_date,
      'local_dt', local_dt,
      'next_trigger_at', NEW.next_trigger_at,
      'calculation_method', 'day_rollover_fixed'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'alarm_day_rollover_fix',
  jsonb_build_object(
    'action', 'fix_alarm_day_rollover',
    'change', 'calculate_next_trigger now properly handles day rollover and sets alarm_date',
    'logic', 'If alarm time has passed today, schedule for tomorrow and set alarm_date accordingly',
    'benefit', 'Alarms are scheduled for the correct day near midnight and alarm_date field is correct',
    'fix_timestamp', NOW()
  )
); 