-- Enable http extension in develop environment
-- This will allow us to use http_post function like main uses net.http_post

CREATE EXTENSION IF NOT EXISTS http;

-- Verify the extension is enabled
SELECT 
    'http' as extension_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'http') THEN 'ENABLED'
        ELSE 'NOT ENABLED'
    END as status;

-- Test if http_post function is available
SELECT 
    'http_post' as function_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'http_post') THEN 'AVAILABLE'
        ELSE 'NOT AVAILABLE'
    END as status; 