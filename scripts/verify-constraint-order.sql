-- Verify user_preferences constraint order matches development
-- This script checks that FOREIGN KEY comes before PRIMARY KEY

SELECT 
    'user_preferences constraint order check' as check_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc1
            JOIN information_schema.table_constraints tc2 ON tc1.table_name = tc2.table_name
            WHERE tc1.table_name = 'user_preferences'
            AND tc1.constraint_type = 'FOREIGN KEY'
            AND tc2.constraint_type = 'PRIMARY KEY'
            AND tc1.constraint_name < tc2.constraint_name
        ) THEN 'PASS - FOREIGN KEY before PRIMARY KEY'
        ELSE 'FAIL - PRIMARY KEY before FOREIGN KEY'
    END as status; 