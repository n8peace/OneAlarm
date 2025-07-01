-- Remove source_ip field from logs table
-- This field is unused and serves no current purpose

-- Drop the column
ALTER TABLE logs DROP COLUMN IF EXISTS source_ip;

-- Log the removal
INSERT INTO logs (event_type, meta)
VALUES (
  'schema_change',
  jsonb_build_object(
    'action', 'remove_source_ip',
    'table', 'logs',
    'column', 'source_ip',
    'reason', 'Field was unused and served no current purpose',
    'removal_timestamp', NOW()
  )
); 