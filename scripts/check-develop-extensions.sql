-- Check what extensions are enabled in develop environment
SELECT 
    extname as extension_name,
    extversion as version
FROM pg_extension 
ORDER BY extname;

-- Check if net extension exists
SELECT 
    'net' as extension_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'net') THEN 'ENABLED'
        ELSE 'NOT ENABLED'
    END as status;

-- Check if http extension exists
SELECT 
    'http' as extension_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'http') THEN 'ENABLED'
        ELSE 'NOT ENABLED'
    END as status; 