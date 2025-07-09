-- Fix user_preferences RLS policies to remove net extension dependency
-- This migration simplifies the RLS policies to avoid any complex subqueries
-- that might be causing the net extension error

-- Step 1: Drop all existing user_preferences policies
DROP POLICY IF EXISTS "Admins can access all preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Insert own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Select own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Update own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can insert preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can view own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can view their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "service_role_full_access" ON public.user_preferences;
DROP POLICY IF EXISTS "users_can_access_own_preferences" ON public.user_preferences;

-- Step 2: Create simplified RLS policies
-- Basic policies that don't use complex subqueries or functions

-- Service role has full access (for backend operations)
CREATE POLICY "service_role_full_access" ON public.user_preferences
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

-- Authenticated users can access their own preferences
CREATE POLICY "users_can_access_own_preferences" ON public.user_preferences
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Public users can view their own preferences (for basic access)
CREATE POLICY "public_view_own_preferences" ON public.user_preferences
  FOR SELECT TO public
  USING (auth.uid() = user_id);

-- Public users can update their own preferences
CREATE POLICY "public_update_own_preferences" ON public.user_preferences
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

-- Public users can insert their own preferences
CREATE POLICY "public_insert_own_preferences" ON public.user_preferences
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'rls_policy_fix',
  jsonb_build_object(
    'action', 'fix_user_preferences_rls_policies',
    'table', 'user_preferences',
    'purpose', 'Remove complex subqueries that may cause net extension errors',
    'changes', jsonb_build_object(
      'dropped_policies', ARRAY[
        'Admins can access all preferences',
        'Insert own preferences',
        'Select own preferences',
        'Update own preferences',
        'Users can insert preferences',
        'Users can update own preferences',
        'Users can update their own preferences',
        'Users can view own preferences',
        'Users can view their own preferences',
        'service_role_full_access',
        'users_can_access_own_preferences'
      ],
      'new_policies', ARRAY[
        'service_role_full_access',
        'users_can_access_own_preferences',
        'public_view_own_preferences',
        'public_update_own_preferences',
        'public_insert_own_preferences'
      ]
    ),
    'environment', 'develop',
    'note', 'Simplified policies to avoid net extension dependency',
    'timestamp', NOW()
  )
); 