-- Add missing on_preferences_inserted trigger to develop environment
-- This makes develop match main environment exactly

-- Step 1: Check current state
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'on_preferences_inserted' 
            AND event_object_table = 'user_preferences'
        ) THEN 'EXISTS'
        ELSE 'DOES NOT EXIST'
    END as on_preferences_inserted_status,
    
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'on_preferences_updated' 
            AND event_object_table = 'user_preferences'
        ) THEN 'EXISTS'
        ELSE 'DOES NOT EXIST'
    END as on_preferences_updated_status;

-- Step 2: Add the missing INSERT trigger
CREATE TRIGGER on_preferences_inserted
    AFTER INSERT ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

-- Step 3: Verify the trigger was created
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    'TRIGGER CREATED' as status
FROM information_schema.triggers 
WHERE trigger_name = 'on_preferences_inserted'
AND event_object_table = 'user_preferences';

-- Step 4: Log the addition
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_sync',
  jsonb_build_object(
    'action', 'add_missing_insert_trigger',
    'trigger_name', 'on_preferences_inserted',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Make develop match main environment exactly',
    'environment', 'develop',
    'approach', 'direct_http_match_main',
    'note', 'Added INSERT trigger to match main environment',
    'timestamp', NOW()
  )
);

-- Step 5: Final verification - show all triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'user_preferences'
ORDER BY trigger_name; 