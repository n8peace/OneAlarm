-- Fix missing auth triggers in development environment
-- Run this in the Supabase Dashboard SQL Editor on the develop branch

-- Add missing auth user sync trigger
DROP TRIGGER IF EXISTS trigger_sync_auth_to_public_user ON auth.users;
CREATE TRIGGER trigger_sync_auth_to_public_user
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION sync_auth_to_public_user();

-- Add missing new user creation trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Verify the triggers were created
SELECT 
    trigger_name,
    event_object_table as table_name,
    event_manipulation as event_type
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND trigger_name IN ('trigger_sync_auth_to_public_user', 'on_auth_user_created')
ORDER BY trigger_name; 