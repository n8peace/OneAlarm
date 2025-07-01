# Database Schema Documentation

## Overview

The OneAlarm database is built on PostgreSQL with Supabase and includes comprehensive user management, alarm scheduling, audio generation, and real-time features. The schema supports personalized AI-powered alarm audio with combined content generation and simplified timezone handling.

## Authentication & User Management

### Supabase Auth Integration
The system uses Supabase's built-in authentication system with a custom `public.users` table for application-specific data:

- **`auth.users`**: Managed by Supabase Auth (authentication, sessions, JWT tokens)
- **`public.users`**: Custom table for application-specific user data

### One-Way Auth Sync
A database trigger automatically syncs user data from `auth.users` to `public.users`:

```sql
-- Trigger function: sync_auth_to_public_user()
-- Fires on INSERT to auth.users
-- Creates corresponding public.users record automatically
```

**Sync Behavior:**
- **One-way**: `auth.users` → `public.users` only
- **Automatic**: Triggered when user first authenticates
- **Non-blocking**: Doesn't prevent direct `public.users` creation for testing
- **Conflict handling**: Updates existing records if user ID already exists

**Benefits:**
- Ensures all authenticated users have corresponding application data
- Maintains testing flexibility (direct `public.users` creation still works)
- Provides production consistency without complexity

## Core Tables

### `users` Table
Core user data and authentication information.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    onboarding_done BOOLEAN DEFAULT FALSE,
    subscription_status TEXT DEFAULT 'trialing',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_admin BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE
);
```

**Creation Methods:**
1. **Automatic (Production)**: Created via database trigger when user authenticates with Supabase Auth
2. **Manual (Testing)**: Direct insertion using service role key for testing purposes

**Auth Sync Behavior:**
- **One-way sync**: `auth.users` → `public.users` via `sync_auth_to_public_user()` trigger
- **Automatic creation**: Triggered on `auth.users` INSERT operations
- **Conflict handling**: Updates existing records if user ID already exists
- **Testing compatibility**: Direct `public.users` creation still works for testing

**Key Fields:**
- `id`: UUID that matches `auth.users.id` for authenticated users
- `email`: User's email address (synced from `auth.users.email`)
- `phone`: User's phone number (optional)
- `onboarding_done`: Whether user has completed onboarding
- `subscription_status`: User's subscription status (trialing, active, cancelled, etc.)
- `is_admin`: Whether user has admin privileges
- `last_login`: Timestamp of last login

### `user_preferences` Table
User personalization settings for audio generation and content preferences.

```sql
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
```

**Key Fields:**
- `tts_voice`: OpenAI TTS voice preference (alloy, ash, echo, fable, onyx, nova, shimmer, verse)
- `preferred_name`: User's preferred name for personalization
- `timezone`: User's timezone for accurate alarm scheduling (master timezone)
- `news_categories`: Array of preferred news categories (general, business, technology, sports)
- `sports_team`: User's favorite sports team
- `stocks`: Array of stock symbols to track
- `include_weather`: Whether to include weather in audio

**Audio Content:**
- **Fixed Tone**: All audio content uses a standardized "calm and encouraging" tone
- **Voice Selection**: Uses only `tts_voice` field for TTS voice selection
- **Simplified Experience**: Consistent audio experience across all users

**Audio Duration:**
- **Fixed Duration**: All alarm audio uses a standardized 300-second (5-minute) duration
- **No User Configuration**: Duration is not configurable per user to ensure consistency
- **Optimized Content**: GPT-4o generates content optimized for the 300-second timeframe

**Multi-Category News System:**
- Users can select their preferred news categories from: **general, business, technology, sports**
- The `news_categories` array stores the user's category preferences
- The system uses `news_categories[0]` as the primary category for content selection
- A database trigger ensures 'general' is always included as a fallback
- The `daily-content` function generates content for all four categories daily
- Audio generation uses the user's selected category to fetch relevant news content

### `alarms` Table
Timezone-aware alarm schedules with simplified timezone handling and explicit date support.

```sql
CREATE TABLE alarms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    alarm_date DATE,
    alarm_time_local TIME NOT NULL,
    alarm_timezone TEXT NOT NULL DEFAULT 'UTC',
    next_trigger_at TIMESTAMP WITH TIME ZONE,
    active BOOLEAN DEFAULT TRUE,
    is_overridden BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Key Features:**
- `alarm_date`: Specific date for the alarm (optional, defaults to current date) - **Used in GPT prompt generation**
- `alarm_time_local`: Local time for the alarm (e.g., "07:00:00")
- `alarm_timezone`: Timezone for this alarm (always matches user_preferences.timezone)
- `next_trigger_at`: Calculated UTC timestamp for next alarm trigger
- `active`: Whether the alarm is currently enabled
- `is_overridden`: Whether the alarm has been manually overridden

**Alarm Date Integration:**
- The `alarm_date` field is used by the GPT-4o service to include the local date in generated audio scripts
- `alarm_date` **must be provided** when creating or updating an alarm. The database trigger no longer calculates this value.
- The trigger function `calculate_next_trigger` now only calculates `next_trigger_at` using the provided `alarm_date`, `alarm_time_local`, and `alarm_timezone` fields.
- Date is formatted as "Today is [Weekday], [Month] [Day], [Year]" in the user's timezone
- Provides context to GPT-4o about the specific date the alarm is for
- Gracefully handles missing date information with fallback message
- Example: "Today is Tuesday, June 24, 2025"

**Timezone Handling:**
- `alarm_timezone` always matches `user_preferences.timezone`
- When user changes timezone, all their alarms are automatically updated
- Travel-friendly: alarms adjust to user's current location seamlessly
- No confusion between creation timezone and current timezone

### `audio` Table
Generated audio file metadata and storage information.

```sql
CREATE TABLE audio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    script_text TEXT,
    audio_url TEXT,
    generated_at TIMESTAMP DEFAULT NOW(),
    error TEXT,
    audio_type TEXT CHECK (audio_type IN ('weather', 'content', 'general', 'combined', 'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3', 'test_clip')),
    duration_seconds INTEGER,
    file_size INTEGER,
    expires_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'ready',
    cached_at TIMESTAMP WITH TIME ZONE,
    cache_status TEXT DEFAULT 'pending'
);
```

**Key Features:**
- `audio_type`: Type of audio content (weather, content, general, combined, wake_up_message_1, wake_up_message_2, wake_up_message_3, test_clip)
  - **Allowed values:** 'weather', 'content', 'general', 'combined', 'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3', **'test_clip'** (for testing only)
  - **Note:** 'test_clip' is used for automated test insertions and is not part of production audio flows.
- `status`: Generation status tracking (ready, generating, failed, expired)
- `cache_status`: Local caching status for iOS app (pending, downloading, cached, failed)
- `file_size`: File size in bytes for monitoring
- `expires_at`: Expiration timestamp for automatic cleanup (48 hours for combined audio)
- `duration_seconds`: Audio duration in seconds
- `error`: Error message if generation failed

**Audio Content Types:**
- **Individual clips** (`generate-audio`): greeting_personal, encouragement_personal, etc.
- **Combined audio** (`generate-alarm-audio`): weather + news + sports + markets + holidays

**Recent Fixes:**
- Removed ON CONFLICT clause that was causing constraint errors
- Fixed success determination logic for existing audio files
- Improved error handling and logging

## Generic Audio Files

### Overview
Pre-generated audio files available immediately for all voice types, stored in Supabase Storage.

### Storage Location
- **Path**: `audio-files/generic_audio/`
- **Access**: Public URLs (no authentication required)
- **Format**: AAC files
- **Total Files**: 48 (6 messages × 8 voices)

### File Naming Convention
```
{voice}_{message_id}.aac
```

**Examples:**
- `alloy_generic_wake_up_message_1.aac`
- `nova_generic_voice_preview.aac`
- `echo_generic_wake_up_message_3.aac`

### Available Voice Types
1. `alloy` - Neutral, balanced voice
2. `ash` - Deep, authoritative voice
3. `echo` - Warm, friendly voice
4. `fable` - Storytelling voice
5. `onyx` - Strong, confident voice
6. `nova` - Bright, energetic voice
7. `shimmer` - Soft, gentle voice
8. `verse` - Poetic, melodic voice

### Available Message Types
1. `generic_wake_up_message_1` - "Good morning. It's time to start the day — no rush..."
2. `generic_wake_up_message_2` - "Good morning. Take a moment to just be here..."
3. `generic_wake_up_message_3` - "Hello. Welcome to this new day..."
4. `generic_wake_up_message_4` - "Good morning. The day is waiting..."
5. `generic_wake_up_message_5` - "Rise and shine. A new day is here..."
6. `generic_voice_preview` - "Good morning. I'm here to help you ease into each day..."

### Usage in App
- **Instant Playback**: Available immediately without generation delay
- **Fallback Option**: Use when personalized audio is not available
- **Voice Selection**: Match user's preferred TTS voice
- **Caching**: Download and cache all 6 messages for user's voice on first launch

### URL Construction
```javascript
const baseUrl = "https://joyavvleaxqzksopnmjs.supabase.co/storage/v1/object/public/audio-files/generic_audio/";
const fileName = `${ttsVoice}_${messageId}.aac`;
const fullUrl = baseUrl + fileName;
```

### Database Integration
- **No database records**: Generic files are not tracked in the `audio` table
- **Storage only**: Files exist only in Supabase Storage
- **Public access**: No RLS policies apply to generic audio files
- **App responsibility**: iOS app manages caching and playback of generic files

### `weather_data` Table
Current weather information from the native app.

```sql
CREATE TABLE weather_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    location TEXT NOT NULL,
    current_temp INTEGER,
    high_temp INTEGER,
    low_temp INTEGER,
    condition TEXT,
    sunrise_time TEXT,
    sunset_time TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Key Features:**
- `user_id`: References the user who owns this weather data
- `location`: User's location (city, state, country)
- `current_temp`: Current temperature in Fahrenheit
- `high_temp`: High temperature for the day
- `low_temp`: Low temperature for the day
- `condition`: Weather condition description (e.g., "Partly Cloudy")
- `sunrise_time`: Sunrise time in local timezone
- `sunset_time`: Sunset time in local timezone
- `updated_at`: When the weather data was last updated
- `created_at`: When the weather record was created

**Usage:**
- Weather data is fetched by the iOS app and stored in this table
- The `generate-alarm-audio` function uses this data to include weather information in audio scripts
- Weather data is optional - audio generation continues even if weather data is unavailable

### `daily_content` Table
**Purpose**: Stores daily news, sports, stocks, and holidays in a single row per day with separate columns for each news category. This structure provides efficient storage and retrieval of content for all four categories (general, business, technology, sports) in one row per day.

```sql
CREATE TABLE daily_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date TEXT,
    general_headlines TEXT,
    business_headlines TEXT,
    technology_headlines TEXT,
    sports_headlines TEXT,
    sports_summary TEXT,
    stocks_summary TEXT,
    holidays TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Key Features:**
- **One Row Per Day**: Each day has a single row containing all content for that date
- **Four Headline Columns**: Separate columns for each news category (general, business, technology, sports)
- **Comprehensive Content**: Each headline column contains 10+ news items with titles, descriptions, and content
- **User Personalization**: Users select their preferred category in `user_preferences.news_categories`
- **Comprehensive Stock Coverage**: `stocks_summary` includes data for all 25 symbols across 6 market sectors
- **Efficient Retrieval**: Single query retrieves all content for a specific date

**Content Structure:**
Each headline column (general_headlines, business_headlines, technology_headlines, sports_headlines) contains:
- 10+ news items per category
- Each item includes: title, description, and content
- Formatted as numbered list with consistent structure
- Content truncated to reasonable length for audio generation

**Stock Symbols Coverage (25 total):**
- **Technology (10)**: AAPL, GOOGL, TSLA, MSFT, NVDA, META, AMZN, NFLX, ADBE, CRM
- **Finance (4)**: JPM, BAC, WFC, GS
- **Healthcare (4)**: JNJ, PFE, UNH, ABBV
- **Consumer (4)**: KO, PG, WMT, DIS
- **Market Index (1)**: ^GSPC
- **Crypto (2)**: BTC-USD, ETH-USD

**Content Selection Logic:**
- Each user receives news content matching their selected category in preferences
- The system uses `user_preferences.news_categories[0]` as the primary category
- Audio generation extracts the appropriate headline column based on user preference
- Fallback to 'general' category if user's preference is unavailable

**Database Indexes:**
```sql
CREATE INDEX idx_daily_content_date ON daily_content(date);
CREATE INDEX idx_daily_content_created_at ON daily_content(created_at DESC);
```

**Migration History:**
- **Previous Structure**: One row per category per day (4 rows per day)
- **New Structure**: One row per day with 4 headline columns
- **Benefits**: Reduced storage, faster queries, simplified data management

### `audio_generation_queue` Table
Queue for scheduling alarm audio generation.

```sql
CREATE TABLE audio_generation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    priority INTEGER DEFAULT 0
);
```

**Key Features:**
- `alarm_id`: References the alarm for which audio should be generated
- `user_id`: References the user who owns the alarm
- `scheduled_for`: When audio should be generated (58 minutes before alarm)
- `status`: Queue processing status (pending, processing, completed, failed)
- `retry_count`: Number of retry attempts made
- `max_retries`: Maximum number of retry attempts allowed
- `error_message`: Error message if processing failed
- `created_at`: When the queue item was created
- `processed_at`: When the queue item was processed
- `priority`: Processing priority (higher numbers = higher priority)

**Queue Processing:**
- Items are processed by the `generate-alarm-audio` function
- Processing occurs every minute via cron job
- Failed items can be retried up to `max_retries` times
- Automatic population via database triggers when alarms are created/updated

### `logs` Table
System and user event logs for monitoring and debugging.

```sql
CREATE TABLE logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type TEXT,
    meta JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Key Features:**
- `user_id`: Optional reference to the user associated with the event
- `event_type`: Type of event (e.g., 'alarm_created', 'audio_generated', 'error_occurred')
- `meta`: JSON object containing additional event data
- `created_at`: Timestamp when the log entry was created

**Usage:**
- Used by all functions to log important events and errors
- Provides audit trail for debugging and monitoring
- Supports structured logging with JSON metadata

### `user_events` Table
Tracks user actions with the alarm (e.g., snooze, awake, etc.).

```sql
CREATE TABLE user_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Key Features:**
- `user_id`: References the user who performed the action
- `event_type`: Type of user action (e.g., 'alarm_snoozed', 'alarm_dismissed', 'app_opened')
- `created_at`: Timestamp when the event occurred

**Usage:**
- Tracks user engagement and behavior patterns
- Used for analytics and user experience optimization
- Supports real-time updates for SwiftUI integration

## Row Level Security (RLS)

### Audio Table RLS Policies

```sql
-- Enable RLS
ALTER TABLE audio ENABLE ROW LEVEL SECURITY;

-- Users can only access their own audio records
CREATE POLICY "Users can view own audio" ON audio
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own audio records (for cache status)
CREATE POLICY "Users can update own audio" ON audio
    FOR UPDATE USING (auth.uid() = user_id);

-- Service role has full access for backend operations
CREATE POLICY "Service role full access" ON audio
    FOR ALL USING (auth.role() = 'service_role');
```

### User Preferences RLS Policies

```sql
-- Enable RLS
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only access their own preferences
CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Service role has full access for backend operations
CREATE POLICY "Service role full access" ON user_preferences
    FOR ALL USING (auth.role() = 'service_role');
```

## Database Triggers

### Calculate Next Trigger Function

```sql
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
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

  -- Debug log
  INSERT INTO logs (event_type, user_id, meta)
  VALUES (
    'alarm_trigger_debug',
    NEW.user_id,
    jsonb_build_object(
      'alarm_id', NEW.id,
      'alarm_date', NEW.alarm_date,
      'alarm_time_local', NEW.alarm_time_local,
      'alarm_timezone', NEW.alarm_timezone,
      'current_time_local', current_time_local,
      'alarm_time_local_parsed', alarm_time_local,
      'target_date', target_date,
      'local_dt', local_dt,
      'next_trigger_at', NEW.next_trigger_at,
      'calculation_method', 'day_rollover_fixed'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Alarm Audio Queue Trigger

```sql
CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audio_generation_queue (alarm_id, user_id, scheduled_for)
    VALUES (NEW.id, NEW.user_id, NEW.next_trigger_at - INTERVAL '58 minutes')
    ON CONFLICT (alarm_id) DO NOTHING;
    
  -- Handle UPDATE
  ELSIF TG_OP = 'UPDATE' THEN
    -- Update queue if next_trigger_at changed
    IF OLD.next_trigger_at != NEW.next_trigger_at THEN
      UPDATE audio_generation_queue 
      SET scheduled_for = NEW.next_trigger_at - INTERVAL '58 minutes',
          status = 'pending',
          retry_count = 0,
          error_message = NULL
      WHERE alarm_id = NEW.id;
    END IF;
    
  -- Handle DELETE
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM audio_generation_queue WHERE alarm_id = OLD.id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
```

## Recent Improvements

### Timezone Handling ✅ **Enhanced**
- **Simplified timezone management**: `alarm_timezone` always matches user preferences
- **Automatic synchronization**: When user changes timezone, all alarms update automatically
- **Travel-friendly**: Alarms adjust seamlessly to user's current location
- **Performance optimized**: No complex timezone calculations needed

### Audio Generation ✅ **Fixed**
- **Database insertion**: Removed problematic ON CONFLICT clauses
- **Success determination**: Fixed logic to correctly report success when existing files are available
- **Error handling**: Improved logging and error reporting
- **Constraint management**: Proper handling of database constraints

### Queue Management ✅ **Optimized**
- **Async processing**: Non-blocking queue processing for better performance
- **Status tracking**: Comprehensive status updates and error logging
- **Duplicate prevention**: UNIQUE constraint on alarm_id prevents duplicate queue items
- **Automatic cleanup**: Failed items are properly marked and logged

## Performance Considerations

### Indexes
- Primary keys on all tables for fast lookups
- Foreign key indexes for efficient joins
- Time-based indexes for queue processing
- User-specific indexes for RLS policies

### Constraints
- Foreign key constraints for data integrity
- Check constraints for valid audio types and status values
- Unique constraints to prevent duplicates
- NOT NULL constraints for required fields

### Monitoring
- Comprehensive logging for debugging
- Status tracking for all operations
- Error handling with detailed messages
- Performance metrics collection

## Row Level Security (RLS)

### Audio Table RLS Policies

```sql
-- Enable RLS
ALTER TABLE audio ENABLE ROW LEVEL SECURITY;

-- Users can only access their own audio records
CREATE POLICY "Users can view own audio" ON audio
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own audio records (for cache status)
CREATE POLICY "Users can update own audio" ON audio
    FOR UPDATE USING (auth.uid() = user_id);

-- Service role has full access for backend operations
CREATE POLICY "Service role full access" ON audio
    FOR ALL USING (auth.role() = 'service_role');
```

### User Preferences RLS Policies

```sql
-- Enable RLS
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only access their own preferences
CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Service role has full access for backend operations
CREATE POLICY "Service role full access" ON user_preferences
    FOR ALL USING (auth.role() = 'service_role');
```

## Database Triggers

### Calculate Next Trigger Function

```sql
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
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

  -- Debug log
  INSERT INTO logs (event_type, user_id, meta)
  VALUES (
    'alarm_trigger_debug',
    NEW.user_id,
    jsonb_build_object(
      'alarm_id', NEW.id,
      'alarm_date', NEW.alarm_date,
      'alarm_time_local', NEW.alarm_time_local,
      'alarm_timezone', NEW.alarm_timezone,
      'current_time_local', current_time_local,
      'alarm_time_local_parsed', alarm_time_local,
      'target_date', target_date,
      'local_dt', local_dt,
      'next_trigger_at', NEW.next_trigger_at,
      'calculation_method', 'day_rollover_fixed'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Timezone Synchronization Function

```sql
CREATE OR REPLACE FUNCTION sync_user_alarm_timezones()
RETURNS TRIGGER AS $$
BEGIN
  -- Update all user's alarms to match their new timezone
  UPDATE alarms 
  SET alarm_timezone = NEW.timezone
  WHERE user_id = NEW.user_id 
    AND alarm_timezone != NEW.timezone;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to sync timezones on user preference changes
CREATE TRIGGER sync_timezone_on_preferences_change
  AFTER UPDATE OF timezone ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_alarm_timezones();
```

### Audio Generation Queue Trigger

```sql
CREATE OR REPLACE FUNCTION schedule_alarm_audio_generation()
RETURNS TRIGGER AS $$
DECLARE
  user_timezone TEXT;
  scheduled_time TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get user's current timezone from preferences
  SELECT timezone INTO user_timezone
  FROM user_preferences
  WHERE user_id = NEW.user_id;
  
  -- Use alarm_timezone (which should match user preferences)
  user_timezone := COALESCE(user_timezone, NEW.alarm_timezone);
  
  -- Calculate when to generate audio (58 minutes before alarm)
  scheduled_time := NEW.next_trigger_at - interval '58 minutes';
  
  -- Insert into queue for audio generation
  INSERT INTO audio_generation_queue (user_id, alarm_id, scheduled_for, status)
  VALUES (NEW.user_id, NEW.id, scheduled_time, 'pending')
  ON CONFLICT (alarm_id) DO UPDATE SET
    scheduled_for = scheduled_time,
    status = 'pending',
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Real-Time Subscriptions & SwiftUI Integration

The following tables support real-time subscriptions for SwiftUI integration:

- `audio`: Real-time updates when audio status changes
- `user_preferences`: Real-time updates when preferences change (including `news_categories`)
- `alarms`: Real-time updates when alarms are created/updated
- `daily_content`: Real-time updates for new daily content in all four news categories

**Note:** The SwiftUI app should allow users to select one or more news categories (general, business, technology, sports) and will receive daily content for their selected category.

## Indexes

```sql
-- Performance indexes for common queries
CREATE INDEX idx_audio_user_id ON audio(user_id);
CREATE INDEX idx_audio_alarm_id ON audio(alarm_id);
CREATE INDEX idx_audio_status ON audio(status);
CREATE INDEX idx_audio_generation_queue_scheduled_for ON audio_generation_queue(scheduled_for);
CREATE INDEX idx_audio_generation_queue_status ON audio_generation_queue(status);
CREATE INDEX idx_daily_content_date ON daily_content(date);
CREATE INDEX idx_weather_data_user_id ON weather_data(user_id);
CREATE INDEX idx_logs_user_id ON logs(user_id);
CREATE INDEX idx_logs_event_type ON logs(event_type);
CREATE INDEX idx_alarms_timezone ON alarms(alarm_timezone);
CREATE INDEX idx_alarms_date_time ON alarms(alarm_date, alarm_time_local);
```

## Constraints

### Timezone Constraints
```sql
-- Valid timezone constraint for alarms
ALTER TABLE alarms ADD CONSTRAINT check_valid_alarm_timezone 
  CHECK (alarm_timezone IN (
    'UTC', 'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'America/Anchorage', 'Pacific/Honolulu', 'Europe/London', 'Europe/Paris', 'Europe/Berlin',
    'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Kolkata', 'Australia/Sydney', 'Australia/Perth'
  ));
```

### Audio Type Constraint
```sql
-- Audio type constraints
ALTER TABLE audio ADD CONSTRAINT audio_type_check 
    CHECK (audio_type IN ('weather', 'content', 'general', 'combined', 'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3', 'test_clip'));
```

### Status Constraints
```sql
-- Audio status constraints
ALTER TABLE audio ADD CONSTRAINT audio_status_check 
    CHECK (status IN ('generating', 'ready', 'failed', 'expired'));

-- Cache status constraints
ALTER TABLE audio ADD CONSTRAINT audio_cache_status_check 
    CHECK (cache_status IN ('pending', 'downloading', 'cached', 'failed'));

-- Queue status constraints
ALTER TABLE audio_generation_queue ADD CONSTRAINT queue_status_check 
    CHECK (status IN ('pending', 'processing', 'completed', 'failed'));
```

## Migration Notes
- The daily_content table now stores news for all four categories (general, business, technology, sports)
- User preferences select which category is used for each user
- All functions and UI should reference the user's selected news category for daily content

## Timezone Handling

### Key Principles
- **Single Source of Truth**: `user_preferences.timezone` is the master timezone
- **Automatic Synchronization**: `alarm_timezone` always matches user preferences
- **Travel-Friendly**: Alarms adjust to user's current location seamlessly
- **Consistent Behavior**: No confusion between creation timezone and current timezone

### Timezone Flow Example
1. **User creates alarm** at 7:00 AM in Los Angeles
   - `alarm_time_local`: "07:00:00"
   - `alarm_timezone`: "America/Los_Angeles"
   - `next_trigger_at`: 2025-06-25 14:00:00 UTC

2. **User moves to New York** and updates timezone
   - `alarm_timezone` automatically updates to "America/New_York"
   - `next_trigger_at` recalculates to 2025-06-25 11:00:00 UTC
   - Alarm still rings at 7:00 AM local time (New York)

## Monitoring

### Key Metrics
- Audio generation success rate
- Queue processing times
- File sizes and storage usage
- User engagement events
- Error rates and types
- Timezone synchronization success

### Useful Queries

```sql
-- Check recent audio generation
SELECT user_id, status, generated_at, file_size 
FROM audio 
WHERE generated_at > NOW() - INTERVAL '24 hours'
ORDER BY generated_at DESC;

-- Monitor queue status
SELECT status, COUNT(*) 
FROM audio_generation_queue 
GROUP BY status;

-- Check user engagement
SELECT event_type, COUNT(*) 
FROM user_events 
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY event_type;

-- Monitor timezone synchronization
SELECT user_id, alarm_timezone, COUNT(*) 
FROM alarms 
GROUP BY user_id, alarm_timezone;
```

## Migration History

### Type Consistency Fixes (June 30, 2025)
- **Updated**: All shared type definitions to match actual database schema
- **Fixed**: UserPreferences interface to include all database fields with correct types
- **Fixed**: DailyContent interface to match new 1-row-per-day schema
- **Fixed**: AudioType enum to include all database constraint values
- **Added**: Missing interfaces (WeatherData, Alarm, AudioMetadata) to shared types
- **Removed**: Duplicate type definitions from function-specific files
- **Added**: Backward compatibility fields to DailyContent interface
- **Result**: Complete type consistency across all functions and shared types

### Daily Content Restructure (June 30, 2025)
- **Previous Structure**: One row per category per day (4 rows per day)
- **New Structure**: One row per day with 4 headline columns
- **Added**: general_headlines, business_headlines, technology_headlines, sports_headlines columns
- **Removed**: news_category and headline columns
- **Benefits**: Reduced storage, faster queries, simplified data management
- **Migration**: Data migrated from 4-row format to 1-row format

### Logs Table Simplification (June 29, 2025)
- **Removed**: `source_ip` field from `logs` table
- **Reason**: Field was unused and served no current purpose
- **Impact**: Simplified logs table schema, no functional changes

### Voice and Tone Simplification (June 29, 2025)
- **Removed**: `voice_gender` and `tone` fields from `user_preferences` table
- **Added**: Fixed "calm and encouraging" tone for all audio content
- **Reason**: Simplified system by removing unnecessary voice gender and tone preferences
- **Impact**: All users now receive consistent audio tone, voice selection uses only `tts_voice`

### Content Duration Simplification (June 29, 2025)
- **Removed**: `content_duration` field from `user_preferences` table
- **Added**: Fixed 300-second (5-minute) duration for all alarm audio
- **Reason**: Simplified system by removing user-configurable duration that wasn't being used effectively
- **Impact**: All users now receive standardized 5-minute audio content optimized by GPT-4o

### Timezone Simplification (v2.0.0)
- **Removed**: `timezone_at_creation` field from alarms table
- **Added**: `alarm_timezone` field that always matches user preferences
- **Added**: Automatic timezone synchronization trigger
- **Updated**: All functions and triggers to use `alarm_timezone`
- **Improved**: Travel-friendly behavior with automatic timezone updates

### Previous Version (v1.0.0)
- Complex timezone handling with dual fields
- Manual timezone management required
- Potential confusion between creation and current timezone

## Recent Fixes

### Type Consistency ✅ **Fixed**
- **Shared Types**: All interfaces now match actual database schema exactly
- **Function Types**: Removed duplicate definitions, use shared types consistently
- **Database Types**: Complete and accurate representation of all tables
- **Backward Compatibility**: Existing code continues to work without changes
- **Type Safety**: Eliminated potential runtime errors from type mismatches

### Schema Documentation ✅ **Updated**
- **Table Definitions**: All table schemas now match actual database structure
- **Field Descriptions**: Accurate descriptions of all fields and their purposes
- **Migration History**: Complete record of recent changes and improvements
- **Usage Examples**: Clear examples of how each table is used in the system

### Function Integration ✅ **Verified**
- **generate-audio**: Already using shared types correctly
- **generate-alarm-audio**: Updated to use shared types, removed duplicates
- **daily-content**: Fixed type conflicts, uses shared types appropriately
- **All Functions**: Now use consistent type definitions across the codebase
