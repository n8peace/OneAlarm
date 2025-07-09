# Triggers Documentation

## Overview

This document describes all database triggers in the OneAlarm system, their functions, and how they work together to provide automated audio generation and queue management.

## Environment Differences

### Main vs Develop Environments

| Environment | Net Extension | Approach | Status |
|-------------|---------------|----------|---------|
| **Main** | ❌ Not Available | Queue-based | ✅ Working |
| **Develop** | ❌ Not Available | Queue-based | ✅ Working |

**Note:** Both environments use the same queue-based approach since the `net` extension is not available in Supabase.

## Core Triggers

### 1. User Preferences Triggers

**Purpose:** Trigger audio generation when user preferences change.

#### Triggers
- `on_preferences_updated` - Fires on UPDATE to user_preferences
- `on_preferences_inserted` - Fires on INSERT to user_preferences

#### Function: `trigger_audio_generation()`

**Behavior:**
- Triggers on INSERT operations (always)
- Triggers on UPDATE operations only when:
  - `tts_voice` changes
  - `preferred_name` changes

**Actions:**
1. Logs the preference change to `logs` table
2. Queues audio generation for all active alarms for the user
3. Uses `audio_generation_queue` table for scheduling

**Queue Logic:**
```sql
INSERT INTO audio_generation_queue (
    alarm_id,
    user_id,
    scheduled_for,
    status,
    priority
)
SELECT 
    a.id,
    a.user_id,
    a.next_trigger_at - INTERVAL '58 minutes',
    'pending',
    1  -- Higher priority for preference changes
FROM alarms a
WHERE a.user_id = NEW.user_id AND a.active = true
```

### 2. Alarm Triggers

**Purpose:** Queue audio generation when alarms are created or updated.

#### Trigger
- `alarm_audio_queue_trigger` - Fires on INSERT or UPDATE to alarms

#### Function: `manage_alarm_audio_queue()`

**Behavior:**
- Only triggers when alarm is active AND has a next_trigger_at time
- Logs alarm creation/update to `logs` table
- Queues audio generation for the specific alarm

**Queue Logic:**
```sql
INSERT INTO audio_generation_queue (
    alarm_id,
    user_id,
    scheduled_for,
    status,
    priority
)
VALUES (
    NEW.id,
    NEW.user_id,
    NEW.next_trigger_at - INTERVAL '58 minutes',
    'pending',
    2  -- Normal priority for alarm creation
)
```

### 3. System Triggers

#### Timestamp Update Triggers
- `update_users_updated_at` - Updates `updated_at` on users table
- `update_user_preferences_updated_at` - Updates `updated_at` on user_preferences table
- `update_alarms_updated_at` - Updates `updated_at` on alarms table
- `update_daily_content_updated_at` - Updates `updated_at` on daily_content table
- `update_audio_updated_at` - Updates `updated_at` on audio table

#### Auth Sync Triggers
- `on_auth_user_created` - Creates user and preferences when auth user is created
- `trigger_sync_auth_to_public_user` - Syncs auth users to public users table

#### Alarm Calculation Triggers
- `calculate_next_trigger_trigger` - Calculates next trigger time for alarms

## Queue System

### Audio Generation Queue

**Table:** `audio_generation_queue`

**Purpose:** Centralized queue for all audio generation requests.

**Columns:**
- `id` - Primary key
- `alarm_id` - Reference to alarm (unique constraint)
- `user_id` - Reference to user
- `scheduled_for` - When to generate audio (58 minutes before alarm)
- `status` - pending, processing, completed, failed
- `priority` - 1 (high) for preferences, 2 (normal) for alarms, 3 (default)
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp

**Priority Levels:**
- `1` - High priority (preference changes)
- `2` - Normal priority (alarm creation)
- `3` - Default priority

### Queue Processing

**Note:** Queue processing is handled by external systems:
- Supabase Edge Functions
- Scheduled cron jobs
- Backend services

The triggers only populate the queue - they don't process it directly.

## Logging System

### Logs Table

**Purpose:** Track all trigger activities and system events.

**Key Event Types:**
- `preferences_updated_audio_trigger` - User preferences changed
- `alarm_audio_queue_trigger` - Alarm created/updated
- `complete_sync_main_to_develop` - Environment synchronization

**Metadata Structure:**
```json
{
  "operation": "INSERT|UPDATE",
  "old_tts_voice": "previous_value",
  "new_tts_voice": "new_value",
  "triggered_at": "timestamp",
  "action": "audio_generation_triggered",
  "environment": "main|develop",
  "approach": "queue_based_no_net_extension"
}
```

## Migration History

### Recent Changes

**2025-07-07: Complete Sync**
- Removed all `net.http_post` calls
- Implemented queue-based approach
- Synchronized main and develop environments
- Added comprehensive logging

**Key Migration Files:**
- `scripts/sync-main-to-develop-complete.sql` - Complete trigger sync
- `supabase/migrations/20250707000010_fix_develop_net_extension_final.sql` - Final net extension fix

## Testing

### Test Scripts

1. **`scripts/test-system-main.sh`** - Test main environment
2. **`scripts/test-system.sh`** - Test develop environment
3. **`scripts/test-user-preferences-update.sh`** - Test preference triggers
4. **`scripts/test-user-preferences-trigger.sh`** - Test trigger functionality

### Manual Testing

**Test User Preferences Trigger:**
```sql
-- Update user preferences to trigger audio generation
UPDATE user_preferences 
SET tts_voice = 'nova' 
WHERE user_id = 'your-test-user-id';

-- Check if queue entry was created
SELECT * FROM audio_generation_queue 
WHERE user_id = 'your-test-user-id' 
ORDER BY created_at DESC;
```

**Test Alarm Trigger:**
```sql
-- Create a test alarm
INSERT INTO alarms (user_id, alarm_time_local, alarm_timezone, active)
VALUES ('your-test-user-id', '08:00:00', 'America/New_York', true);

-- Check if queue entry was created
SELECT * FROM audio_generation_queue 
WHERE user_id = 'your-test-user-id' 
ORDER BY created_at DESC;
```

## Troubleshooting

### Common Issues

1. **"schema 'net' does not exist"**
   - **Cause:** Function trying to use `net.http_post`
   - **Solution:** Use queue-based approach instead

2. **Triggers not firing**
   - **Check:** Verify trigger exists and is enabled
   - **Check:** Ensure function exists and is valid
   - **Check:** Review logs for errors

3. **Queue not being processed**
   - **Check:** External queue processor is running
   - **Check:** Queue entries have correct status
   - **Check:** Scheduled_for times are in the future

### Debug Queries

**Check all triggers:**
```sql
SELECT 
    tgrelid::regclass as table_name,
    tgname as trigger_name,
    tgfoid::regproc as function_name
FROM pg_trigger 
WHERE tgrelid::regclass::text LIKE 'public.%'
ORDER BY tgrelid::regclass, tgname;
```

**Check function definitions:**
```sql
SELECT 
    proname,
    CASE 
        WHEN prosrc LIKE '%net.http_post%' THEN 'CONTAINS_NET_HTTP_POST'
        ELSE 'QUEUE_BASED_ONLY'
    END as status
FROM pg_proc 
WHERE proname IN ('trigger_audio_generation', 'manage_alarm_audio_queue');
```

**Check recent logs:**
```sql
SELECT event_type, user_id, meta, created_at
FROM logs 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

## Best Practices

1. **Always use queue-based approach** - Avoid direct HTTP calls in triggers
2. **Log all trigger activities** - Use the logs table for debugging
3. **Test triggers thoroughly** - Use provided test scripts
4. **Monitor queue processing** - Ensure external systems are working
5. **Keep environments in sync** - Use migration scripts to maintain consistency

## Future Enhancements

1. **Real-time queue processing** - WebSocket-based processing
2. **Priority-based scheduling** - More sophisticated priority system
3. **Retry mechanisms** - Automatic retry for failed queue items
4. **Performance monitoring** - Track trigger performance and queue processing times 