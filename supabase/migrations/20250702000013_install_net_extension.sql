-- Install net extension for HTTP calls in production
-- This enables the user_preferences_audio_trigger to work properly

-- Create the net schema first
CREATE SCHEMA IF NOT EXISTS "net";

-- Enable the http extension in the net schema
CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "net";

-- Log the installation
INSERT INTO logs (event_type, meta)
VALUES (
    'extension_installation',
    jsonb_build_object(
        'action', 'install_net_extension',
        'extension_name', 'http',
        'schema_name', 'net',
        'purpose', 'Enable HTTP calls for user_preferences_audio_trigger',
        'installation_timestamp', NOW()
    )
); 