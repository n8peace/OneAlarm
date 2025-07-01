-- Add 'test_clip' as an allowed audio type for testing purposes
-- This allows the test script to insert test records without constraint violations

-- Drop the existing constraint
ALTER TABLE audio DROP CONSTRAINT IF EXISTS audio_type_check;

-- Recreate the constraint with 'test_clip' added
ALTER TABLE audio ADD CONSTRAINT audio_type_check 
    CHECK (audio_type IN (
        'weather', 'content', 'general', 'combined', 
        'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3',
        'test_clip'
    ));

-- Log the change
INSERT INTO logs (event_type, meta)
VALUES (
    'audio_type_constraint_updated',
    jsonb_build_object(
        'action', 'add_test_clip_audio_type',
        'added_type', 'test_clip',
        'reason', 'Allow test script to insert test records without constraint violations',
        'allowed_types', ARRAY['weather', 'content', 'general', 'combined', 'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3', 'test_clip'],
        'updated_at', NOW()
    )
); 