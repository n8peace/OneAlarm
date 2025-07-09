-- Force drop extra columns from user_preferences to match main
ALTER TABLE user_preferences DROP COLUMN IF EXISTS preferred_voice;
ALTER TABLE user_preferences DROP COLUMN IF EXISTS preferred_speed;
ALTER TABLE user_preferences DROP COLUMN IF EXISTS created_at;

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'schema_update',
  jsonb_build_object(
    'action', 'force_drop_extra_columns',
    'table', 'user_preferences',
    'dropped_columns', ARRAY['preferred_voice', 'preferred_speed', 'created_at'],
    'timestamp', NOW()
  )
); 