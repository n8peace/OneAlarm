# Production to Development Schema Sync

## Overview
This document outlines the migration to sync the production schema (`fhjmqoshlryypcyvdifw`) with the development schema (`joyavvleaxqzksopnmjs`).

## Key Differences Addressed

### 1. Alarms Table
**Production Missing Columns:**
- `active` (boolean, default: true)
- `is_overridden` (boolean, default: false) 
- `timezone_at_creation` (text, NOT NULL, default: 'UTC')

**Production Changes:**
- `user_id` becomes nullable (was NOT NULL)
- `created_at`/`updated_at` change to `timestamp without time zone`
- `id` default changes from `uuid_generate_v4()` to `gen_random_uuid()`

### 2. Audio Table
**Production Missing Columns:**
- `script_text` (text)
- `generated_at` (timestamp without time zone, default: now())
- `error` (text)
- `status` (character varying, default: 'generating')
- `cached_at` (timestamp with time zone)
- `cache_status` (character varying, default: 'pending')
- `file_size` (integer)

**Production Changes:**
- `user_id` becomes nullable
- `audio_type` changes to `character varying` with default 'general'
- `id` default changes to `gen_random_uuid()`

### 3. Audio Generation Queue
**Production Changes:**
- `status` becomes NOT NULL and changes to `character varying`
- `priority` default changes from 0 to 5
- `id` default changes to `gen_random_uuid()`

### 4. Daily Content
**Production Changes:**
- `date` becomes nullable (was NOT NULL)
- `created_at`/`updated_at` change to `timestamp without time zone`
- `id` default changes to `gen_random_uuid()`

### 5. Logs Table
**Major Change:**
- `id` changes from integer (auto-increment) to UUID with `gen_random_uuid()`
- `created_at` changes to `timestamp without time zone`

### 6. User Events
**Production Changes:**
- `created_at` changes to `timestamp without time zone`
- `id` default changes to `gen_random_uuid()`

### 7. User Preferences
**Production Missing Columns:**
- `sports_team` (text)
- `stocks` (text[])
- `include_weather` (boolean, default: true)
- `preferred_name` (text)
- `tts_voice` (text)
- `news_categories` (text[], default: ['general'])
- `onboarding_completed` (boolean, default: false)
- `onboarding_step` (integer, default: 0)

**Production Changes:**
- `created_at`/`updated_at` change to `timestamp without time zone`
- Remove defaults from `timezone`, `preferred_voice`, `preferred_speed`

### 8. Users Table
**Production Missing Columns:**
- `phone` (text)
- `onboarding_done` (boolean, default: false)
- `subscription_status` (text, default: 'trialing')
- `is_admin` (boolean, default: false)
- `last_login` (timestamp without time zone)

**Production Changes:**
- `email` becomes nullable (was NOT NULL)
- `created_at`/`updated_at` change to `timestamp without time zone`
- `id` default changes to `gen_random_uuid()`

### 9. Weather Data
**Production Changes:**
- `location` changes to `character varying`
- `condition` changes to `character varying`
- `id` default changes to `gen_random_uuid()`

## Migration File
The migration is located at: `supabase/migrations/20250702000002_sync_prod_with_dev_schema.sql`

## Risk Assessment
**HIGH RISK OPERATIONS:**
1. **Logs table recreation** - This involves dropping and recreating the logs table with a new UUID primary key
2. **Column type changes** - Multiple timestamp columns are changing from `with time zone` to `without time zone`
3. **Nullable constraint changes** - Several columns are becoming nullable

**MEDIUM RISK:**
1. **Default value changes** - Multiple ID columns changing from `uuid_generate_v4()` to `gen_random_uuid()`
2. **New columns with defaults** - Adding many new columns with default values

## Pre-Migration Checklist
- [ ] Backup production database
- [ ] Verify no active audio generation processes
- [ ] Check for any dependent applications that might be affected
- [ ] Test migration on a staging environment if possible

## Post-Migration Verification
- [ ] Verify all tables have correct structure
- [ ] Check that existing data is preserved
- [ ] Test application functionality
- [ ] Monitor for any errors in logs

## Project References
- **Development**: `joyavvleaxqzksopnmjs`
- **Production**: `fhjmqoshlryypcyvdifw` 