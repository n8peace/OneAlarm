-- Check trigger_audio_generation function
-- This will show us if the function uses net extension

-- Get the function definition
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'trigger_audio_generation';

-- Check if the function contains net extension calls
SELECT 
    'trigger_audio_generation' as function_name,
    CASE 
        WHEN pg_get_functiondef(p.oid) LIKE '%net.%' THEN 'USES NET EXTENSION'
        ELSE 'NO NET EXTENSION'
    END as net_usage
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'trigger_audio_generation';

-- Also check update_updated_at_column function
SELECT 
    'update_updated_at_column' as function_name,
    CASE 
        WHEN pg_get_functiondef(p.oid) LIKE '%net.%' THEN 'USES NET EXTENSION'
        ELSE 'NO NET EXTENSION'
    END as net_usage
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'update_updated_at_column'; 