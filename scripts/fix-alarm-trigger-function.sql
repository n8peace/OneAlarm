-- Fix manage_alarm_audio_queue function
-- Remove reference to non-existent 'name' field in alarms table

-- Drop and recreate the function without the 'name' field reference
DROP FUNCTION IF EXISTS manage_alarm_audio_queue() CASCADE;

CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- Only queue if alarm is active and has a next trigger time
  IF NEW.active = true AND NEW.next_trigger_at IS NOT NULL THEN
    
    -- Log the alarm creation/update
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'alarm_audio_queue_trigger',
      NEW.user_id,
      jsonb_build_object(
        'alarm_id', NEW.id,
        'next_trigger_at', NEW.next_trigger_at,
        'triggered_at', NOW(),
        'action', 'queue_audio_generation',
        'environment', 'develop',
        'approach', 'queue_based_no_net_extension'
      )
    );

    -- Queue audio generation for this alarm
    INSERT INTO audio_generation_queue (
        alarm_id,
        user_id,
        scheduled_for,
        status,
        priority
    )
    VALUES (
        NEW.id,
        NEW.user_id,
        NEW.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        2  -- Normal priority for alarm creation
    )
    ON CONFLICT (alarm_id) DO UPDATE SET
        scheduled_for = EXCLUDED.scheduled_for,
        status = 'pending',
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-create the trigger
DROP TRIGGER IF EXISTS alarm_audio_queue_trigger ON alarms;
CREATE TRIGGER alarm_audio_queue_trigger
  AFTER INSERT OR UPDATE ON alarms
  FOR EACH ROW
  EXECUTE FUNCTION manage_alarm_audio_queue();

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_fix',
  jsonb_build_object(
    'action', 'fix_alarm_trigger_function',
    'function_name', 'manage_alarm_audio_queue',
    'fix', 'removed_reference_to_non_existent_name_field',
    'environment', 'develop',
    'timestamp', NOW()
  )
); 