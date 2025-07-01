# SwiftUI Integration - Phase 1: Backend Enhancements

## Overview

Phase 1 focuses on updating the existing Supabase backend to better support SwiftUI integration. This includes database schema enhancements, real-time subscriptions, status tracking, and comprehensive testing.

## Audio File Integration (June 2025)

- Each alarm now generates only **one combined audio file** (AAC format, 3-5 minutes) that includes weather (if available), news, sports, and market information.
- The audio file will have `audio_type: 'combined'` in the database.
- The app should expect only one audio file per alarm and display/play it accordingly.
- Audio files are stored in Supabase Storage with RLS (Row Level Security).
- Only the authenticated user can access their audio files.
- Audio files expire after 48 hours.

## 🗄️ Database Schema Enhancements

### New Columns Added

#### Audio Table
- **`status`** (VARCHAR(50)): Tracks audio generation status
  - Values: `'generating'`, `'ready'`, `'failed'`, `'expired'`
  - Default: `'generating'`
- **`cached_at`** (TIMESTAMP WITH TIME ZONE): When audio was cached on client
- **`cache_status`** (VARCHAR(50)): Client-side caching status
  - Values: `'pending'`, `'downloading'`, `'cached'`, `'failed'`
  - Default: `'pending'`

#### User Preferences Table
- **`onboarding_completed`** (BOOLEAN): Whether user completed onboarding
  - Default: `FALSE`
- **`onboarding_step`** (VARCHAR(50)): Current step in onboarding process
  - Default: `'welcome'`

#### Audio Generation Queue Table
- **`priority`** (INTEGER): Queue processing priority (1-10)
  - Default: `5`
  - Higher numbers = lower priority

### Indexes for Performance
```sql
CREATE INDEX idx_audio_user_id_status ON audio(user_id, status);
CREATE INDEX idx_audio_cache_status ON audio(cache_status);
CREATE INDEX idx_audio_generation_queue_status_scheduled ON audio_generation_queue(status, scheduled_for);
CREATE INDEX idx_user_preferences_onboarding ON user_preferences(onboarding_completed, onboarding_step);
```

## 🔄 Real-time Subscriptions

### Enabled Tables
- **`audio`**: Real-time updates for audio generation status
- **`user_preferences`**: Real-time updates for preference changes
- **`alarms`**: Real-time updates for alarm modifications

### Subscription Channels
```typescript
// SwiftUI will subscribe to these channels:
supabase.channel("audio_updates")
  .on(.postgresChanges(event: .insert, table: "audio"))
  .on(.postgresChanges(event: .update, table: "audio"))

supabase.channel("preferences_updates")
  .on(.postgresChanges(event: .update, table: "user_preferences"))

supabase.channel("alarm_updates")
  .on(.postgresChanges(event: .insert, table: "alarms"))
  .on(.postgresChanges(event: .update, table: "alarms"))
```

## 🤖 Database Triggers

### 1. User Creation Trigger
**Function**: `handle_new_user()`
**Trigger**: `on_user_created`
**Purpose**: Auto-creates user preferences when a new user is created

```sql
-- Automatically creates user preferences with defaults
INSERT INTO user_preferences (
  user_id, tts_voice, tone, timezone, 
  onboarding_completed, onboarding_step
) VALUES (
  NEW.id, 'alloy', 'calm and gentle', 'America/New_York',
  FALSE, 'welcome'
);
```

### 2. Preferences Update Trigger
**Function**: `trigger_audio_generation()`
**Trigger**: `on_preferences_updated`
**Purpose**: Triggers audio regeneration when key preferences change

```sql
-- Triggers when tts_voice, tone, or preferred_name changes
IF OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
   OLD.tone IS DISTINCT FROM NEW.tone OR
   OLD.preferred_name IS DISTINCT FROM NEW.preferred_name THEN
  -- Call generate-audio function
END IF;
```

### 3. Alarm Changes Trigger
**Function**: `handle_alarm_changes()`
**Trigger**: `on_alarm_changes`
**Purpose**: Auto-populates audio generation queue

```sql
-- For new alarms: adds to queue
INSERT INTO audio_generation_queue (alarm_id, user_id, scheduled_for, priority)
VALUES (NEW.id, NEW.user_id, scheduled_time, 5);

-- For updated alarms: updates queue
UPDATE audio_generation_queue
SET scheduled_for = new_time, status = 'pending'
WHERE alarm_id = NEW.id;
```

### 4. Offline Issue Logging
**Function**: `log_offline_issue()`
**Trigger**: `on_audio_status_change`
**Purpose**: Logs when audio isn't cached in time

```sql
-- Logs when audio expires without being cached
IF NEW.status = 'expired' AND NEW.cache_status = 'pending' THEN
  INSERT INTO logs (event_type, user_id, meta)
  VALUES ('audio_expired_uncached', NEW.user_id, metadata);
END IF;
```

## 📁 Storage Access Policies

### User Access Policy
```sql
-- Users can access their own audio files
CREATE POLICY "Users can access their own audio files" ON storage.objects
  FOR SELECT USING (
    auth.uid()::text = (
      SELECT user_id 
      FROM audio 
      WHERE audio_url LIKE '%' || storage.foldername(name)[3] || '%'
      LIMIT 1
    )
  );
```

### Service Role Policies
- **Upload**: Service role can upload audio files
- **Update**: Service role can update audio files
- **Delete**: Service role can delete audio files

## 🔧 Function Updates

### Generate Alarm Audio Function
- **Status Tracking**: Audio records now track generation status
- **Cache Status**: Tracks client-side caching status
- **Duration Calculation**: Calculates approximate audio duration
- **Enhanced Error Handling**: Better error reporting and logging

### Key Changes
```typescript
// New audio record creation with status
await this.saveAudioMetadata(
  alarmId, userId, audioType, fileName, audioUrl, 
  scriptText, expiresAt, fileSize, durationSeconds
);

// Status tracking throughout generation
await this.markAudioGenerating(alarmId, userId, audioType);
await this.updateAudioStatus(audioId, 'ready', audioUrl, fileSize, durationSeconds);
```

## 🧪 End-to-End Testing

### Test Script: `scripts/test-system.sh load`

#### Test Coverage
1. **Database Schema Validation**: Verifies new columns exist
2. **Real-time Subscriptions**: Checks real-time is enabled
3. **User Creation & Preferences**: Tests auto-generation with PATCH-then-POST upsert logic
4. **Preferences Update**: Tests audio generation triggers
5. **Alarm Creation**: Tests queue population
6. **Audio Generation**: Tests status tracking
7. **Storage Policies**: Verifies access policies
8. **Offline Logging**: Tests issue logging
9. **Database Triggers**: Tests trigger functionality
10. **Real-time Data Flow**: Verifies subscription setup
11. **Load Testing**: Creates 10 complete user setups for comprehensive validation
12. **Idempotent Operations**: Ensures scripts work for repeated runs

#### Running Tests
```bash
# Run comprehensive load test with 10 users
bash scripts/test-system.sh load YOUR_SERVICE_ROLE_KEY

# Run individual function tests
bash scripts/test-system.sh audio YOUR_SERVICE_ROLE_KEY

# Check recent audio generation
bash scripts/check-recent-audio.sh USER_ID
```

#### Test Features
- **PATCH-then-POST Upsert**: Handles both new and existing data gracefully
- **Idempotent Operation**: Safe for repeated runs without 409 errors
- **Comprehensive Validation**: Tests entire audio generation pipeline
- **Real-time Monitoring**: Validates subscription and status updates

## 📊 Monitoring & Logging

### New Event Types
- **`audio_not_cached_in_time`**: Audio ready but not cached
- **`audio_expired_uncached`**: Audio expired without caching
- **`queue_processing_started`**: Queue processing begins
- **`queue_processing_completed`**: Queue processing ends

### Enhanced Logging
```sql
-- Example log entry for offline issues
{
  "event_type": "audio_expired_uncached",
  "user_id": "user-uuid",
  "meta": {
    "audio_id": "audio-uuid",
    "alarm_id": "alarm-uuid",
    "audio_type": "weather",
    "generated_at": "2024-01-01T12:00:00Z",
    "expires_at": "2024-01-03T12:00:00Z"
  }
}
```

## 🔄 Automated Processes

### Audio Expiration
- **Function**: `update_expired_audio()`
- **Schedule**: Every hour via cron
- **Purpose**: Updates audio status to 'expired' when time passes

### Queue Processing
- **Function**: `generate-alarm-audio` (existing)
- **Schedule**: Every 15 minutes via cron-job.org
- **Enhancement**: Now processes by priority

## 🚀 Deployment

### 1. Apply Database Migrations
```bash
supabase db push
```

### 2. Deploy Updated Functions
```bash
supabase functions deploy generate-alarm-audio
```

### 3. Run Integration Tests
```bash
npm run test:swiftui
```

### 4. Verify Real-time Setup
```bash
# Check real-time subscriptions
curl -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  "$SUPABASE_URL/rest/v1/realtime/subscriptions"
```

## ✅ Success Criteria

Phase 1 is complete when:

1. ✅ All database migrations apply successfully
2. ✅ Real-time subscriptions are enabled on key tables
3. ✅ Database triggers function correctly
4. ✅ Audio generation includes status tracking
5. ✅ Storage access policies are in place
6. ✅ End-to-end tests pass (10/10)
7. ✅ No breaking changes to existing functionality

## 🔍 Verification Checklist

- [ ] Database schema updated with new columns
- [ ] Real-time subscriptions enabled
- [ ] Database triggers created and tested
- [ ] Storage policies configured
- [ ] Function updates deployed
- [ ] Integration tests passing
- [ ] Existing functionality unchanged
- [ ] Monitoring and logging enhanced

## 📈 Performance Impact

### Minimal Impact
- **Database**: New indexes improve query performance
- **Real-time**: Only active when clients are connected
- **Triggers**: Lightweight operations with minimal overhead
- **Storage**: Policies add minimal query overhead

### Monitoring
- Track trigger execution times
- Monitor real-time subscription usage
- Watch for any performance degradation

## 🎯 Next Steps

Phase 1 provides the foundation for SwiftUI integration. Phase 2 will focus on:

1. **SwiftUI App Development**: Complete iOS app implementation
2. **Real-time Client Integration**: WebSocket subscriptions
3. **Audio Caching**: Local file management
4. **Offline Support**: Queue management and sync
5. **User Experience**: Onboarding and preferences flow

The backend is now ready to support a fully-featured SwiftUI alarm application with real-time audio delivery, offline support, and comprehensive monitoring. 