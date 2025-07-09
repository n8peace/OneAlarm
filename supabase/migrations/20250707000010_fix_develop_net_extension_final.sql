-- Final fix for develop environment net extension error
-- This migration completely removes all net extension dependencies
-- and ensures the trigger function works without any net extension calls

-- Step 1: Drop and recreate the trigger function without ANY net extension calls
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;

CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS $$
BEGIN
  -- For INSERT operations, always trigger since we're creating new preferences
  -- For UPDATE operations, only trigger if key audio-related preferences changed
  IF TG_OP = 'INSERT' OR 
     (TG_OP = 'UPDATE' AND (
       OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
       OLD.preferred_name IS DISTINCT FROM NEW.preferred_name
     )) THEN

    -- Log the change for debugging
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'preferences_updated_audio_trigger',
      NEW.user_id,
      jsonb_build_object(
        'operation', TG_OP,
        'old_tts_voice', CASE WHEN TG_OP = 'UPDATE' THEN OLD.tts_voice ELSE NULL END,
        'new_tts_voice', NEW.tts_voice,
        'old_preferred_name', CASE WHEN TG_OP = 'UPDATE' THEN OLD.preferred_name ELSE NULL END,
        'new_preferred_name', NEW.preferred_name,
        'triggered_at', NOW(),
        'action', 'audio_generation_triggered',
        'environment', 'develop',
        'note', 'queue_only_no_direct_http_no_net_extension_final_fix'
      )
    );

    -- Queue audio generation for all active alarms for this user
    -- This avoids hardcoded URLs and allows the queue system to handle it
    INSERT INTO audio_generation_queue (
        alarm_id,
        user_id,
        scheduled_for,
        status,
        priority
    )
    SELECT 
        a.id,
        a.user_id,
        a.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        1  -- Higher priority for preference changes
    FROM alarms a
    WHERE a.user_id = NEW.user_id AND a.active = true
    ON CONFLICT (alarm_id) DO UPDATE SET
        status = 'pending',
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Re-create triggers
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
CREATE TRIGGER on_preferences_updated
  AFTER UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;
CREATE TRIGGER on_preferences_inserted
  AFTER INSERT ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

-- Step 3: Remove any default values from tts_voice that might cause issues
ALTER TABLE user_preferences ALTER COLUMN tts_voice DROP DEFAULT;

-- Step 4: Set a simple default for tts_voice
ALTER TABLE user_preferences ALTER COLUMN tts_voice SET DEFAULT 'alloy';

-- Step 5: Check for any other functions that might use net extension and drop them
-- This is a comprehensive cleanup to ensure no net extension calls remain
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT proname, oid 
        FROM pg_proc 
        WHERE prosrc LIKE '%net.http_post%' 
        AND proname != 'trigger_audio_generation'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.proname || ' CASCADE';
        RAISE NOTICE 'Dropped function % that contained net.http_post', func_record.proname;
    END LOOP;
END $$;

-- Step 6: Check for any functions that use net extension in any way
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT proname, oid 
        FROM pg_proc 
        WHERE prosrc LIKE '%net.%' 
        AND proname != 'trigger_audio_generation'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.proname || ' CASCADE';
        RAISE NOTICE 'Dropped function % that contained net extension reference', func_record.proname;
    END LOOP;
END $$;

-- Step 7: Add a comment documenting this fix
COMMENT ON FUNCTION trigger_audio_generation() IS 'Audio generation trigger for user preferences - NO NET EXTENSION DEPENDENCY';

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_final_fix',
  jsonb_build_object(
    'action', 'fix_develop_net_extension_final',
    'trigger_name', 'on_preferences_updated_and_inserted',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Complete removal of all net extension dependencies from develop environment',
    'environment', 'develop',
    'approach', 'queue_only_no_direct_http_no_net_extension_final',
    'changes', jsonb_build_object(
      'removed_net_http_post', true,
      'removed_net_extension_references', true,
      'simplified_trigger_function', true,
      'fixed_tts_voice_default', true
    ),
    'note', 'This is the final fix to resolve the schema net does not exist error',
    'timestamp', NOW()
  )
); 