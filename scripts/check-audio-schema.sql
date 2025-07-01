-- Check audio table schema and constraints
-- This script will help us understand the current state of the audio table

-- Check table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'audio' 
ORDER BY ordinal_position;

-- Check constraints
SELECT 
    constraint_name,
    constraint_type,
    check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'audio';

-- Check existing audio types
SELECT DISTINCT audio_type, COUNT(*) as count
FROM audio 
GROUP BY audio_type 
ORDER BY count DESC; 