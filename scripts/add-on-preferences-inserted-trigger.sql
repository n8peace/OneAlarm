-- Add on_preferences_inserted trigger to match main environment
-- This adds the INSERT trigger that was removed during synchronization

-- First, check if the trigger already exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_preferences_inserted' 
        AND event_object_table = 'user_preferences'
    ) THEN
        RAISE NOTICE 'on_preferences_inserted trigger already exists';
    ELSE
        -- Create the INSERT trigger
        CREATE TRIGGER on_preferences_inserted
            AFTER INSERT ON user_preferences
            FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();
        
        RAISE NOTICE 'on_preferences_inserted trigger created successfully';
    END IF;
END $$;

-- Log the addition
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_addition',
  jsonb_build_object(
    'action', 'add_on_preferences_inserted_trigger',
    'trigger_name', 'on_preferences_inserted',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Trigger audio generation on user preferences INSERT',
    'environment', 'develop',
    'approach', 'direct_http_match_main',
    'note', 'Added INSERT trigger to match main environment behavior',
    'timestamp', NOW()
  )
);

-- Verify the trigger was created
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    'TRIGGER CREATED' as status
FROM information_schema.triggers 
WHERE trigger_name = 'on_preferences_inserted'
AND event_object_table = 'user_preferences'; 