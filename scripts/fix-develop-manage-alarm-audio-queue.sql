-- Fix manage_alarm_audio_queue function in develop environment
-- Remove reference to non-existent updated_at column in audio_generation_queue table

-- Drop and recreate the function without the updated_at field reference
DROP FUNCTION IF EXISTS manage_alarm_audio_queue() CASCADE;

CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    -- Only queue if alarm is active and has a next trigger time
    IF NEW.active = true AND NEW.next_trigger_at IS NOT NULL THEN
      
      -- Log the alarm creation
      INSERT INTO logs (event_type, user_id, meta)
      VALUES (
        'alarm_audio_queue_trigger',
        NEW.user_id,
        jsonb_build_object(
          'alarm_id', NEW.id,
          'next_trigger_at', NEW.next_trigger_at,
          'triggered_at', NOW(),
          'action', 'queue_audio_generation',
          'operation', 'INSERT',
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
          status = 'pending';
          -- Removed: updated_at = NOW();
    END IF;
    
  -- Handle UPDATE
  ELSIF TG_OP = 'UPDATE' THEN
    -- Only queue if alarm is active and has a next trigger time
    IF NEW.active = true AND NEW.next_trigger_at IS NOT NULL THEN
      
      -- Log the alarm update
      INSERT INTO logs (event_type, user_id, meta)
      VALUES (
        'alarm_audio_queue_trigger',
        NEW.user_id,
        jsonb_build_object(
          'alarm_id', NEW.id,
          'next_trigger_at', NEW.next_trigger_at,
          'triggered_at', NOW(),
          'action', 'queue_audio_generation',
          'operation', 'UPDATE',
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
          status = 'pending';
          -- Removed: updated_at = NOW();
    END IF;
    
  -- Handle DELETE
  ELSIF TG_OP = 'DELETE' THEN
    -- Log the alarm deletion
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'alarm_audio_queue_trigger',
      OLD.user_id,
      jsonb_build_object(
        'alarm_id', OLD.id,
        'triggered_at', NOW(),
        'action', 'cleanup_audio_generation_queue',
        'operation', 'DELETE',
        'environment', 'develop',
        'approach', 'queue_based_no_net_extension'
      )
    );

    -- Remove any pending audio generation for this alarm
    DELETE FROM audio_generation_queue WHERE alarm_id = OLD.id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Re-create the trigger to include DELETE event
DROP TRIGGER IF EXISTS alarm_audio_queue_trigger ON alarms;
CREATE TRIGGER alarm_audio_queue_trigger
  AFTER INSERT OR UPDATE OR DELETE ON alarms
  FOR EACH ROW
  EXECUTE FUNCTION manage_alarm_audio_queue();

-- Log the fix
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_fix',
  jsonb_build_object(
    'action', 'fix_manage_alarm_audio_queue_function',
    'function_name', 'manage_alarm_audio_queue',
    'fix', 'removed_reference_to_non_existent_updated_at_column',
    'environment', 'develop',
    'timestamp', NOW()
  )
); 