-- Sync RLS Policies from Main to Develop
-- This script drops all existing policies and recreates them to match main

-- Step 1: Drop all existing policies for affected tables
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename IN ('alarms', 'audio', 'audio_files', 'audio_generation_queue', 'daily_content', 'logs', 'user_preferences', 'users', 'weather_data')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s" ON public.%I;', r.policyname, r.tablename);
    END LOOP;
END $$;

-- Step 2: Create all policies from main

-- ALARMS TABLE POLICIES
CREATE POLICY "Insert own alarm" ON public.alarms
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Select own alarm" ON public.alarms
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Update own alarm" ON public.alarms
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own alarms" ON public.alarms
  FOR DELETE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own alarms" ON public.alarms
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own alarm" ON public.alarms
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own alarms" ON public.alarms
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own alarm" ON public.alarms
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own alarms" ON public.alarms
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own alarm" ON public.alarms
  FOR SELECT TO public
  USING (auth.uid() = user_id);

-- AUDIO TABLE POLICIES
CREATE POLICY "Insert own audio" ON public.audio
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Select own audio" ON public.audio
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage audio files" ON public.audio
  FOR ALL TO public
  USING (auth.role() = 'service_role'::text);

CREATE POLICY "Users can delete own audio files" ON public.audio
  FOR DELETE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own audio" ON public.audio
  FOR DELETE TO public
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own audio files" ON public.audio
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own audio" ON public.audio
  FOR INSERT TO public
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can select their own audio" ON public.audio
  FOR SELECT TO public
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own audio files" ON public.audio
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own audio" ON public.audio
  FOR UPDATE TO public
  USING (user_id = auth.uid());

CREATE POLICY "Users can view own audio files" ON public.audio
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own audio" ON public.audio
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "service_role_full_access" ON public.audio
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

-- AUDIO_FILES TABLE POLICIES
CREATE POLICY "Users can delete own audio files" ON public.audio_files
  FOR DELETE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own audio files" ON public.audio_files
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own audio files" ON public.audio_files
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own audio files" ON public.audio_files
  FOR SELECT TO public
  USING (auth.uid() = user_id);

-- AUDIO_GENERATION_QUEUE TABLE POLICIES
CREATE POLICY "Service role can access all queue entries" ON public.audio_generation_queue
  FOR ALL TO public
  USING (auth.role() = 'service_role'::text);

CREATE POLICY "Users can view own queue entries" ON public.audio_generation_queue
  FOR SELECT TO public
  USING (auth.uid() = user_id);

-- DAILY_CONTENT TABLE POLICIES
CREATE POLICY "Authenticated users can read daily content" ON public.daily_content
  FOR SELECT TO public
  USING (auth.role() = 'authenticated'::text);

CREATE POLICY "Read for all authenticated users" ON public.daily_content
  FOR SELECT TO public
  USING (auth.role() = 'authenticated'::text);

-- LOGS TABLE POLICIES
CREATE POLICY "Insert own logs" ON public.logs
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Select own logs" ON public.logs
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs" ON public.logs
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own logs" ON public.logs
  FOR SELECT TO public
  USING (auth.uid() = user_id);

-- USER_PREFERENCES TABLE POLICIES
CREATE POLICY "Admins can access all preferences" ON public.user_preferences
  FOR ALL TO public
  USING ((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.is_admin = true)))));

CREATE POLICY "Insert own preferences" ON public.user_preferences
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Select own preferences" ON public.user_preferences
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Update own preferences" ON public.user_preferences
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert preferences" ON public.user_preferences
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" ON public.user_preferences
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own preferences" ON public.user_preferences
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own preferences" ON public.user_preferences
  FOR SELECT TO public
  USING (auth.uid() = user_id);

CREATE POLICY "service_role_full_access" ON public.user_preferences
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "users_can_access_own_preferences" ON public.user_preferences
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- USERS TABLE POLICIES
CREATE POLICY "Users can select their own data" ON public.users
  FOR SELECT TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can select their own user row" ON public.users
  FOR SELECT TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON public.users
  FOR UPDATE TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON public.users
  FOR UPDATE TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own user row" ON public.users
  FOR UPDATE TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can view own data" ON public.users
  FOR SELECT TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can view their own user row" ON public.users
  FOR SELECT TO public
  USING (auth.uid() = id);

CREATE POLICY "service_role_full_access" ON public.users
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "users_can_access_own_data" ON public.users
  FOR ALL TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- WEATHER_DATA TABLE POLICIES
CREATE POLICY "Service role can access all weather data" ON public.weather_data
  FOR ALL TO public
  USING (auth.role() = 'service_role'::text);

CREATE POLICY "Users can insert own weather data" ON public.weather_data
  FOR INSERT TO public
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own weather data" ON public.weather_data
  FOR UPDATE TO public
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own weather data" ON public.weather_data
  FOR SELECT TO public
  USING (auth.uid() = user_id);

-- Verification query to check all policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname; 