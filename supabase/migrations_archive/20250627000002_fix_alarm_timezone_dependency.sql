-- Fix alarm timezone dependency issue
-- Make alarm scheduling work without requiring user_preferences to exist

-- Update the calculate_next_trigger function to use alarm_timezone directly
-- instead of depending on user_preferences.timezone
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
DECLARE
  local_dt TIMESTAMP;
BEGIN
  -- Use alarm_date if provided, otherwise fall back to current date
  IF NEW.alarm_date IS NOT NULL THEN
    local_dt := (NEW.alarm_date::timestamp + NEW.alarm_time_local::interval);
  ELSE
    local_dt := (CURRENT_DATE::timestamp + NEW.alarm_time_local::interval);
  END IF;

  -- Use alarm's own timezone directly, with fallback to UTC
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
      'local_dt', local_dt,
      'next_trigger_at', NEW.next_trigger_at,
      'calculation_method', 'alarm_timezone_direct'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update the manage_alarm_audio_queue function to be more robust
CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audio_generation_queue (alarm_id, user_id, scheduled_for)
    VALUES (NEW.id, NEW.user_id, NEW.next_trigger_at - INTERVAL '58 minutes')
    ON CONFLICT (alarm_id) DO NOTHING;
    
  -- Handle UPDATE
  ELSIF TG_OP = 'UPDATE' THEN
    -- Update queue if next_trigger_at changed
    IF OLD.next_trigger_at != NEW.next_trigger_at THEN
      UPDATE audio_generation_queue 
      SET scheduled_for = NEW.next_trigger_at - INTERVAL '58 minutes',
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

-- Add constraint to ensure alarm_timezone is not null
ALTER TABLE alarms ALTER COLUMN alarm_timezone SET NOT NULL;

-- Add default value for alarm_timezone if not provided
ALTER TABLE alarms ALTER COLUMN alarm_timezone SET DEFAULT 'UTC';

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'timezone_dependency_fix',
  jsonb_build_object(
    'action', 'fix_alarm_timezone_dependency',
    'change', 'calculate_next_trigger now uses alarm_timezone directly',
    'reason', 'Remove dependency on user_preferences for alarm scheduling',
    'benefit', 'Alarms can be scheduled correctly without user_preferences existing',
    'fix_timestamp', NOW()
  )
); 