# Production Schema Fix Summary

## Overview

This document summarizes the fixes applied to bring the production database schema in sync with the development environment.

## Issues Identified

### 1. **Alarms Table - Obsolete Columns**
**Production had these obsolete columns that were removed:**
- `name` - Not used in current alarm system
- `time` - Replaced by `alarm_time_local`
- `days_of_week` - Not used in current alarm system
- `status` - Replaced by `active` boolean
- `next_trigger` - Replaced by `next_trigger_at`
- `timezone_at_creation` - Replaced by `alarm_timezone`

**Current alarms table structure:**
```sql
CREATE TABLE alarms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
```

### 2. **User Preferences Table - Obsolete Columns**
**Production had these obsolete columns that were removed:**
- `onboarding_completed` - Not used in current system
- `onboarding_step` - Not used in current system

**Current user_preferences table structure:**
```sql
CREATE TABLE user_preferences (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    timezone TEXT DEFAULT 'America/New_York',
    preferred_voice TEXT DEFAULT 'alloy',
    preferred_speed REAL DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. **Daily Content Table - User ID Column**
**Production had `user_id` column that was removed:**
- Daily content is now global (not user-specific)
- All users share the same daily content
- Simplified data management and reduced storage

**Current daily_content table structure:**
```sql
CREATE TABLE daily_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL UNIQUE,
    general_headlines TEXT,
    business_headlines TEXT,
    technology_headlines TEXT,
    sports_headlines TEXT,
    sports_summary TEXT,
    stocks_summary TEXT,
    holidays TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4. **Audio Table - Missing Columns**
**Production was missing these columns that were added:**
- `expires_at` - Timestamp when audio file expires for cleanup
- `audio_url` - URL to the audio file in storage

**Current audio table structure:**
```sql
CREATE TABLE audio (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    audio_type TEXT NOT NULL,
    duration_seconds INTEGER,
    expires_at TIMESTAMP WITH TIME ZONE,
    audio_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 5. **Missing Tables**
**Production was missing these tables that were created:**

#### Weather Data Table
```sql
CREATE TABLE weather_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    location TEXT NOT NULL,
    current_temp INTEGER,
    high_temp INTEGER,
    low_temp INTEGER,
    condition TEXT,
    sunrise_time TIME,
    sunset_time TIME,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### User Events Table
```sql
CREATE TABLE user_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Audio Generation Queue Table
```sql
CREATE TABLE audio_generation_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    priority INTEGER DEFAULT 0
);
```

## Migration Applied

**Migration File:** `20250701000010_fix_production_schema_sync.sql`

**Applied via:** `scripts/fix-production-schema.sh`

## Key Benefits

### 1. **Simplified Alarm System**
- Removed unused fields that were causing confusion
- Streamlined alarm creation and management
- Better timezone handling with single source of truth

### 2. **Global Daily Content**
- Reduced storage requirements
- Simplified content management
- All users get same high-quality content

### 3. **Enhanced Audio Management**
- Added expiration tracking for cleanup
- Added URL tracking for playback
- Better file lifecycle management

### 4. **Complete Feature Set**
- Weather data for personalized content
- User events for analytics
- Audio generation queue for reliability

### 5. **Proper Security**
- All new tables have RLS policies
- User data isolation maintained
- Proper access controls in place

## Verification

After applying the migration, verify the schema is correct:

```bash
# Run the validation script
./scripts/validate-schema.sh

# Check migration status
supabase migration list

# Verify tables exist
curl -s "https://your-project.supabase.co/rest/v1/" \
  -H "apikey: $SUPABASE_ANON_KEY" | jq '.paths | keys'
```

## Rollback Plan

If issues occur, the migration can be rolled back by:

1. **Restoring from backup** (recommended)
2. **Manual schema restoration** (if backup unavailable)

**Note:** This migration removes data, so a backup is essential before applying.

## Next Steps

1. **Test the application** with the new schema
2. **Monitor for any issues** in production
3. **Update any client code** that might reference removed columns
4. **Verify all functions work** with the new schema

## Files Modified

- `supabase/migrations/20250701000010_fix_production_schema_sync.sql` - Migration file
- `scripts/fix-production-schema.sh` - Application script
- `docs/PRODUCTION_SCHEMA_FIX_SUMMARY.md` - This summary document 