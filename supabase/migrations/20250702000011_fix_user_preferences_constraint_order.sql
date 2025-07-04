-- Fix user_preferences constraint order to match development schema
-- Production has: PRIMARY KEY first, then FOREIGN KEY
-- Development has: FOREIGN KEY first, then PRIMARY KEY
-- This migration reorders them to match development

-- Step 1: Drop existing constraints
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_user_id_fkey;

-- Step 2: Recreate constraints in the correct order (matching dev)
-- First: FOREIGN KEY
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Second: PRIMARY KEY
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_pkey 
    PRIMARY KEY (user_id);

-- Log the constraint reordering
INSERT INTO logs (event_type, meta)
VALUES (
    'schema_constraint_reorder',
    jsonb_build_object(
        'table', 'user_preferences',
        'action', 'reorder_constraints',
        'old_order', ARRAY['PRIMARY KEY', 'FOREIGN KEY'],
        'new_order', ARRAY['FOREIGN KEY', 'PRIMARY KEY'],
        'timestamp', NOW()
    )
); 