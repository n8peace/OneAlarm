-- Remove user_preferences_audio_trigger that causes net schema errors
-- This trigger tries to call net.http_post which doesn't exist in production

-- Drop the triggers that use the problematic function
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;

-- Drop the function that references net.http_post
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;

-- Log the removal
INSERT INTO logs (event_type, meta)
VALUES (
    'trigger_removal',
    jsonb_build_object(
        'action', 'remove_user_preferences_audio_trigger',
        'trigger_names', ARRAY['on_preferences_updated', 'on_preferences_inserted'],
        'function_name', 'trigger_audio_generation',
        'reason', 'net schema does not exist in production, causing user preferences operations to fail',
        'removal_timestamp', NOW()
    )
); 