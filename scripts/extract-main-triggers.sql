-- Extract Main Environment Triggers
-- Run this in the MAIN environment SQL editor to get exact trigger definitions

-- Extract trigger_audio_generation function
SELECT 
    '-- Main Environment: trigger_audio_generation function' as comment,
    pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'trigger_audio_generation';

-- Extract all triggers on user_preferences table
SELECT 
    '-- Main Environment: Triggers on user_preferences' as comment,
    tgname as trigger_name,
    tgtype,
    tgenabled,
    tgdeferrable,
    tginitdeferred,
    tgrelid::regclass as table_name,
    tgfoid::regproc as function_name,
    tgargs,
    tgqual,
    pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger 
WHERE tgrelid = 'user_preferences'::regclass;

-- Extract all functions that might be related to audio generation
SELECT 
    '-- Main Environment: Audio-related functions' as comment,
    proname as function_name,
    pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname IN (
    'trigger_audio_generation',
    'queue_audio_generation', 
    'handle_new_user',
    'sync_auth_to_public_user',
    'calculate_next_trigger'
);

-- Extract all triggers in the system
SELECT 
    '-- Main Environment: All triggers' as comment,
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    tgfoid::regproc as function_name,
    pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger 
WHERE tgname NOT LIKE 'pg_%'
ORDER BY tgrelid::regclass, tgname; 