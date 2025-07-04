-- Compare RLS policies between dev and prod
-- This script shows all RLS policies and their configurations

-- 1. Show all RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 2. Show RLS enabled tables
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
    AND rowsecurity = true
ORDER BY tablename;

-- 3. Show specific policies for user_preferences table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
    AND tablename = 'user_preferences'
ORDER BY policyname;

-- 4. Show function permissions for net schema
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    p.proacl as permissions
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'net'
ORDER BY p.proname;

-- 5. Show role permissions
SELECT 
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles
WHERE rolname IN ('authenticated', 'anon', 'service_role', 'postgres')
ORDER BY rolname; 