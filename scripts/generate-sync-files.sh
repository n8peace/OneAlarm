#!/bin/bash

# Generate Complete Main to Develop Synchronization Files
# Covers: Tables, RLS Policies, Triggers, Functions, and Storage
# This script generates all necessary files for complete synchronization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📁 Generating Complete Main → Develop Synchronization Files${NC}"
echo "================================================================"
echo

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Step 1: Create comprehensive synchronization SQL
print_status "info" "Step 1: Creating comprehensive synchronization SQL..."

SYNC_SQL="
-- ============================================================================
-- COMPLETE MAIN TO DEVELOP SYNCHRONIZATION
-- Covers: Tables, RLS Policies, Triggers, Functions, and Storage
-- Generated on $(date)
-- ============================================================================

-- ============================================================================
-- STEP 1: CLEAN DEVELOP ENVIRONMENT
-- ============================================================================

-- Drop all triggers first
DO \$\$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table 
        FROM information_schema.triggers 
        WHERE trigger_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I CASCADE', 
                      trigger_record.trigger_name, 
                      trigger_record.event_object_table);
    END LOOP;
END \$\$;

-- Drop all functions
DO \$\$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT proname 
        FROM pg_proc 
        WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        AND proname NOT LIKE 'pg_%'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I CASCADE', func_record.proname);
    END LOOP;
END \$\$;

-- Drop all tables (in correct order to handle foreign keys)
DROP TABLE IF EXISTS audio_generation_queue CASCADE;
DROP TABLE IF EXISTS audio_files CASCADE;
DROP TABLE IF EXISTS audio CASCADE;
DROP TABLE IF EXISTS daily_content CASCADE;
DROP TABLE IF EXISTS weather_data CASCADE;
DROP TABLE IF EXISTS user_events CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS alarms CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS logs CASCADE;

-- ============================================================================
-- STEP 2: CREATE TABLES (EXACT COPY FROM MAIN)
-- ============================================================================

-- Create logs table
CREATE TABLE logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type TEXT NOT NULL,
    user_id UUID,
    meta JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create users table
CREATE TABLE users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    onboarding_done BOOLEAN DEFAULT FALSE,
    subscription_status TEXT DEFAULT 'trialing',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_admin BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_preferences table
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    news_categories TEXT[] DEFAULT ARRAY['general'],
    sports_team TEXT,
    stocks TEXT[],
    include_weather BOOLEAN DEFAULT TRUE,
    timezone TEXT DEFAULT 'America/New_York',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    preferred_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    tts_voice TEXT DEFAULT 'alloy'
);

-- Create alarms table
CREATE TABLE alarms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_date DATE,
    alarm_time_local TIME NOT NULL,
    alarm_timezone TEXT NOT NULL DEFAULT 'UTC',
    next_trigger_at TIMESTAMP WITH TIME ZONE,
    active BOOLEAN DEFAULT TRUE,
    is_overridden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create daily_content table
CREATE TABLE daily_content (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    news_summary TEXT,
    weather_summary TEXT,
    sports_summary TEXT,
    stock_summary TEXT,
    holiday_info TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio table
CREATE TABLE audio (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    audio_type TEXT NOT NULL DEFAULT 'general',
    file_url TEXT,
    duration INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    script_text TEXT,
    generated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    error TEXT,
    status CHARACTER VARYING DEFAULT 'generating',
    cached_at TIMESTAMP WITH TIME ZONE,
    cache_status CHARACTER VARYING DEFAULT 'pending',
    file_size INTEGER
);

-- Create audio_files table
CREATE TABLE audio_files (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    audio_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio_generation_queue table
CREATE TABLE audio_generation_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status CHARACTER VARYING DEFAULT 'pending',
    priority INTEGER DEFAULT 5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(alarm_id)
);

-- Create weather_data table
CREATE TABLE weather_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    location CHARACTER VARYING NOT NULL,
    temperature REAL,
    condition TEXT,
    humidity INTEGER,
    wind_speed REAL,
    sunrise_time TIME WITHOUT TIME ZONE,
    sunset_time TIME WITHOUT TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_events table
CREATE TABLE user_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    event_type TEXT NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- STEP 3: CREATE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_logs_event_type ON logs(event_type);
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_alarms_user_id ON alarms(user_id);
CREATE INDEX IF NOT EXISTS idx_alarms_next_trigger_at ON alarms(next_trigger_at);
CREATE INDEX IF NOT EXISTS idx_alarms_active ON alarms(active);
CREATE INDEX IF NOT EXISTS idx_daily_content_date ON daily_content(date);
CREATE INDEX IF NOT EXISTS idx_audio_user_id ON audio(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_type ON audio(audio_type);
CREATE INDEX IF NOT EXISTS idx_audio_expires_at ON audio(expires_at);
CREATE INDEX IF NOT EXISTS idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_alarm_id ON audio_files(alarm_id);
CREATE INDEX IF NOT EXISTS idx_weather_data_user_id ON weather_data(user_id);
CREATE INDEX IF NOT EXISTS idx_user_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_scheduled_for ON audio_generation_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_status ON audio_generation_queue(status);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_user_id ON audio_generation_queue(user_id);

-- ============================================================================
-- STEP 4: CREATE FUNCTIONS (EXACT COPY FROM MAIN)
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
\$\$ language 'plpgsql';

-- Function to sync auth users to public users
CREATE OR REPLACE FUNCTION sync_auth_to_public_user()
RETURNS TRIGGER AS \$\$
BEGIN
    INSERT INTO public.users (id, email, created_at)
    VALUES (NEW.id, NEW.email, NEW.created_at)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS \$\$
BEGIN
    INSERT INTO users (id, email) VALUES (NEW.id, NEW.email);
    INSERT INTO user_preferences (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate next trigger time
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS \$\$
DECLARE
  local_dt TIMESTAMP;
  current_time_local TIME;
  alarm_time_local TIME;
  target_date DATE;
BEGIN
  -- Get current time in the alarm's timezone
  current_time_local := (NOW() AT TIME ZONE NEW.alarm_timezone)::time;
  alarm_time_local := NEW.alarm_time_local::time;
  
  -- Determine target date
  IF NEW.alarm_date IS NOT NULL THEN
    -- Use provided alarm_date
    target_date := NEW.alarm_date;
  ELSE
    -- Check if alarm time has already passed today
    IF current_time_local >= alarm_time_local THEN
      -- Alarm time has passed today, schedule for tomorrow
      target_date := (CURRENT_DATE + INTERVAL '1 day')::date;
    ELSE
      -- Alarm time hasn't passed yet, schedule for today
      target_date := CURRENT_DATE;
    END IF;
  END IF;
  
  -- Set the alarm_date field to match the target date
  NEW.alarm_date := target_date;
  
  -- Create the local datetime
  local_dt := (target_date::timestamp + alarm_time_local::interval);

  -- Convert to UTC using alarm's timezone
  BEGIN
    NEW.next_trigger_at := local_dt AT TIME ZONE NEW.alarm_timezone;
  EXCEPTION WHEN OTHERS THEN
    -- If timezone is invalid, fallback to UTC
    NEW.next_trigger_at := local_dt AT TIME ZONE 'UTC';
  END;

  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

-- Function to queue audio generation
CREATE OR REPLACE FUNCTION queue_audio_generation()
RETURNS TRIGGER AS \$\$
BEGIN
    -- Queue audio generation 58 minutes before alarm
    INSERT INTO audio_generation_queue (
        alarm_id, 
        user_id, 
        scheduled_for, 
        status, 
        priority
    ) VALUES (
        NEW.id,
        NEW.user_id,
        NEW.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        0
    )
    ON CONFLICT (alarm_id) DO UPDATE SET
        scheduled_for = EXCLUDED.scheduled_for,
        status = 'pending',
        updated_at = NOW();
    
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

-- Function to trigger audio generation (MAIN VERSION WITH NET EXTENSION)
CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS \$\$
BEGIN
  -- Only trigger if key audio-related preferences changed
  IF OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
     OLD.preferred_name IS DISTINCT FROM NEW.preferred_name THEN
    
    -- Log the change for debugging
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'preferences_updated_audio_trigger',
      NEW.user_id,
      jsonb_build_object(
        'old_tts_voice', OLD.tts_voice,
        'new_tts_voice', NEW.tts_voice,
        'old_preferred_name', OLD.preferred_name,
        'new_preferred_name', NEW.preferred_name,
        'triggered_at', NOW(),
        'action', 'audio_generation_triggered'
      )
    );
    
    -- Call generate-audio function for the user (general audio)
    PERFORM net.http_post(
      url := 'https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-audio',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxOTA3NjUsImV4cCI6MjA2NTc2Njc2NX0.LgCoghiKkmVzXMxHyNy6Xzzevmhq5DDEmlFMJevm75M'
      ),
      body := jsonb_build_object(
        'userId', NEW.user_id,
        'audio_type', 'general',
        'forceRegenerate', true
      )
    );
  END IF;
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: CREATE TRIGGERS
-- ============================================================================

-- Timestamp update triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alarms_updated_at BEFORE UPDATE ON alarms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_content_updated_at BEFORE UPDATE ON daily_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_audio_files_updated_at BEFORE UPDATE ON audio_files FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_audio_updated_at BEFORE UPDATE ON audio FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auth user sync trigger
CREATE TRIGGER trigger_sync_auth_to_public_user
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION sync_auth_to_public_user();

-- New user creation trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Alarm calculation trigger
CREATE TRIGGER calculate_next_trigger_trigger
    BEFORE INSERT OR UPDATE ON alarms
    FOR EACH ROW EXECUTE FUNCTION calculate_next_trigger();

-- Audio generation queue trigger
CREATE TRIGGER alarm_audio_queue_trigger
    AFTER INSERT OR UPDATE ON alarms
    FOR EACH ROW EXECUTE FUNCTION queue_audio_generation();

-- User preferences triggers
CREATE TRIGGER on_preferences_updated
    AFTER UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

CREATE TRIGGER on_preferences_inserted
    AFTER INSERT ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

-- ============================================================================
-- STEP 6: CREATE RLS POLICIES (EXACT COPY FROM MAIN)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE alarms ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_generation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;

-- Service role has full access to all tables
CREATE POLICY \"service_role_full_access\" ON logs FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON users FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON user_preferences FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON alarms FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON daily_content FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON audio FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON audio_files FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON audio_generation_queue FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON weather_data FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY \"service_role_full_access\" ON user_events FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Users can access their own data
CREATE POLICY \"users_can_access_own_data\" ON users FOR ALL TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY \"users_can_access_own_preferences\" ON user_preferences FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY \"users_can_access_own_alarms\" ON alarms FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY \"users_can_access_own_audio\" ON audio FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY \"users_can_access_own_audio_files\" ON audio_files FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY \"users_can_access_own_weather_data\" ON weather_data FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY \"users_can_access_own_user_events\" ON user_events FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Public access policies for basic operations
CREATE POLICY \"public_view_own_data\" ON users FOR SELECT TO public USING (auth.uid() = id);
CREATE POLICY \"public_update_own_data\" ON users FOR UPDATE TO public USING (auth.uid() = id);
CREATE POLICY \"public_view_own_preferences\" ON user_preferences FOR SELECT TO public USING (auth.uid() = user_id);
CREATE POLICY \"public_update_own_preferences\" ON user_preferences FOR UPDATE TO public USING (auth.uid() = user_id);
CREATE POLICY \"public_insert_own_preferences\" ON user_preferences FOR INSERT TO public WITH CHECK (auth.uid() = user_id);
CREATE POLICY \"public_view_own_alarms\" ON alarms FOR SELECT TO public USING (auth.uid() = user_id);
CREATE POLICY \"public_update_own_alarms\" ON alarms FOR UPDATE TO public USING (auth.uid() = user_id);
CREATE POLICY \"public_insert_own_alarms\" ON alarms FOR INSERT TO public WITH CHECK (auth.uid() = user_id);
CREATE POLICY \"public_delete_own_alarms\" ON alarms FOR DELETE TO public USING (auth.uid() = user_id);

-- ============================================================================
-- STEP 7: LOG THE SYNCHRONIZATION
-- ============================================================================

INSERT INTO logs (event_type, meta)
VALUES (
  'environment_sync',
  jsonb_build_object(
    'action', 'sync_main_to_develop_complete',
    'source_environment', 'main',
    'target_environment', 'develop',
    'sync_type', 'complete_schema_copy',
    'includes', jsonb_build_object(
      'tables', true,
      'functions', true,
      'triggers', true,
      'indexes', true,
      'rls_policies', true
    ),
    'note', 'Complete synchronization from main to develop environment',
    'timestamp', NOW()
  )
);
"

# Step 2: Save the SQL to a file
SYNC_FILE="scripts/main-to-develop-complete-sync.sql"
echo "$SYNC_SQL" > "$SYNC_FILE"
print_status "success" "Complete synchronization SQL saved to: $SYNC_FILE"

# Step 3: Create storage synchronization instructions
print_status "info" "Step 2: Creating storage synchronization instructions..."

STORAGE_SYNC_FILE="scripts/storage-sync-instructions.md"
cat > "$STORAGE_SYNC_FILE" << 'EOF'
# Storage Synchronization Instructions

## Overview
Storage buckets and files need to be synchronized manually between environments.

## Steps to Sync Storage

### 1. Access Supabase Dashboard
- Go to [Supabase Dashboard](https://supabase.com/dashboard)
- Select your **main** project first
- Navigate to Storage

### 2. Export Storage from Main
- Go to Storage → Buckets
- Note down all bucket names and configurations
- For each bucket, download important files if needed

### 3. Configure Storage in Develop
- Switch to your **develop** project
- Go to Storage → Buckets
- Create the same buckets with identical configurations:
  - `audio-files` (public bucket)
  - `background-audio` (public bucket)
  - Any other buckets from main

### 4. Copy Files (if needed)
- Upload important files from main to develop
- This is optional for development environment

### 5. Verify Storage Configuration
- Test file uploads in develop
- Verify bucket policies match main

## Bucket Configurations

### audio-files bucket
- **Public bucket**: Yes
- **File size limit**: 50MB
- **Allowed MIME types**: audio/*

### background-audio bucket
- **Public bucket**: Yes
- **File size limit**: 50MB
- **Allowed MIME types**: audio/*

## Storage Policies
The RLS policies for storage will be created automatically when you create the buckets.
EOF

print_status "success" "Storage synchronization instructions saved to: $STORAGE_SYNC_FILE"

# Step 4: Create deployment instructions
print_status "info" "Step 3: Creating deployment instructions..."

DEPLOY_FILE="scripts/deploy-instructions.md"
cat > "$DEPLOY_FILE" << 'EOF'
# Complete Main to Develop Deployment Instructions

## Prerequisites
- Access to Supabase Dashboard for both main and develop projects
- Supabase CLI installed (optional, for edge functions)

## Step-by-Step Deployment

### 1. Apply Database Schema
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your **develop** project
3. Navigate to SQL Editor
4. Copy and paste the contents of `scripts/main-to-develop-complete-sync.sql`
5. Execute the migration
6. Verify all tables, functions, and triggers are created

### 2. Deploy Edge Functions
```bash
# Link to develop project
supabase link --project-ref xqkmpkfqoisqzznnvlox

# Deploy all functions
supabase functions deploy --project-ref xqkmpkfqoisqzznnvlox
```

### 3. Configure Storage
Follow the instructions in `scripts/storage-sync-instructions.md`

### 4. Set Environment Variables
In Supabase Dashboard → Settings → Edge Functions:
- `SUPABASE_URL`: https://xqkmpkfqoisqzznnvlox.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: [Your develop service role key]
- `OPENAI_API_KEY`: [Your OpenAI API key]
- `NEWSAPI_KEY`: [Your News API key]
- `SPORTSDB_API_KEY`: [Your Sports DB API key]
- `RAPIDAPI_KEY`: [Your RapidAPI key]
- `ABSTRACT_API_KEY`: [Your Abstract API key]

### 5. Test the Deployment
```bash
# Test user preferences
./scripts/test-user-preferences-update.sh

# Test system functionality
./scripts/test-system-develop.sh
```

## Verification Checklist

- [ ] All tables created successfully
- [ ] All functions deployed
- [ ] All triggers working
- [ ] RLS policies applied
- [ ] Storage buckets configured
- [ ] Environment variables set
- [ ] Edge functions deployed
- [ ] Basic functionality tested

## Troubleshooting

### Net Extension Error
If you get "schema 'net' does not exist" errors:
1. Apply the fix migration: `supabase/migrations/20250707000010_fix_develop_net_extension_final.sql`
2. This removes net extension dependencies for develop environment

### Function Deployment Issues
1. Check environment variables are set
2. Verify Supabase CLI is linked to correct project
3. Check function logs in Supabase Dashboard

### Storage Issues
1. Verify bucket names match exactly
2. Check bucket policies
3. Test file uploads manually
EOF

print_status "success" "Deployment instructions saved to: $DEPLOY_FILE"

# Step 5: Create a quick start guide
print_status "info" "Step 4: Creating quick start guide..."

QUICK_START_FILE="scripts/quick-start-sync.md"
cat > "$QUICK_START_FILE" << 'EOF'
# Quick Start: Main to Develop Synchronization

## 🚀 Fast Track (5 minutes)

### 1. Apply Database Schema
```bash
# Copy the SQL file content
cat scripts/main-to-develop-complete-sync.sql

# Paste into Supabase Dashboard SQL Editor and execute
```

### 2. Deploy Edge Functions
```bash
supabase link --project-ref xqkmpkfqoisqzznnvlox
supabase functions deploy --project-ref xqkmpkfqoisqzznnvlox
```

### 3. Set Environment Variables
In Supabase Dashboard → Settings → Edge Functions, add:
- `SUPABASE_URL`: https://xqkmpkfqoisqzznnvlox.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: [Your develop service role key]
- `OPENAI_API_KEY`: [Your OpenAI API key]
- `NEWSAPI_KEY`: [Your News API key]
- `SPORTSDB_API_KEY`: [Your Sports DB API key]
- `RAPIDAPI_KEY`: [Your RapidAPI key]
- `ABSTRACT_API_KEY`: [Your Abstract API key]

### 4. Test
```bash
./scripts/test-user-preferences-update.sh
```

## 📁 Files Generated
- `scripts/main-to-develop-complete-sync.sql` - Complete database sync
- `scripts/storage-sync-instructions.md` - Storage setup guide
- `scripts/deploy-instructions.md` - Detailed deployment guide
- `scripts/quick-start-sync.md` - This quick start guide

## ⚠️ Important Notes
- This will completely overwrite the develop environment
- The develop environment will have net extension dependency
- Apply the net extension fix if you want to avoid those issues
EOF

print_status "success" "Quick start guide saved to: $QUICK_START_FILE"

# Step 6: Summary
print_status "info" "Step 5: Synchronization Files Summary"
echo "============================================="
echo "• Complete schema SQL: ✅ $SYNC_FILE"
echo "• Storage instructions: ✅ $STORAGE_SYNC_FILE"
echo "• Deployment guide: ✅ $DEPLOY_FILE"
echo "• Quick start guide: ✅ $QUICK_START_FILE"
echo

print_status "success" "🎉 All synchronization files generated successfully!"
echo
print_status "info" "Next steps:"
echo "1. Apply the database schema: $SYNC_FILE"
echo "2. Follow storage instructions: $STORAGE_SYNC_FILE"
echo "3. Follow deployment guide: $DEPLOY_FILE"
echo "4. Use quick start guide: $QUICK_START_FILE"
echo

print_status "warning" "Important Notes:"
echo "• The develop environment will have net extension dependency"
echo "• If you want to avoid net extension issues, apply the fix migration after sync"
echo "• All data in develop will be replaced during this process"
echo

print_status "info" "Files created:"
echo "• $SYNC_FILE - Complete database synchronization SQL"
echo "• $STORAGE_SYNC_FILE - Storage synchronization instructions"
echo "• $DEPLOY_FILE - Complete deployment guide"
echo "• $QUICK_START_FILE - Quick start guide" 