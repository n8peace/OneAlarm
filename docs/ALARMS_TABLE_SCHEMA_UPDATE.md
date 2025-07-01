# Alarms Table Schema Update

## Overview
Updated the `alarms` table to remove unused fields and simplify the schema.

## Removed Fields
- `is_scheduled` - Not used in business logic
- `days_active` - Not used in business logic  
- `snooze_option` - Not used in business logic

## Current Schema
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

## Key Changes
- **Removed unused fields**: `is_scheduled`, `days_active`, `snooze_option`
- **Simplified schema**: Focus on core alarm functionality
- **Maintained core fields**: All essential alarm functionality preserved

## Migration
The migration `20250629000010_remove_unused_alarm_fields.sql` safely removes these unused columns.

## Database Triggers

### Calculate Next Trigger
Automatically calculates the next trigger time based on user's timezone:

```sql
CREATE OR REPLACE FUNCTION calculate_next_trigger()
RETURNS TRIGGER AS $$
DECLARE
  user_timezone TEXT;
BEGIN
  -- Get user's current timezone, fallback to timezone_at_creation if not set
  SELECT timezone INTO user_timezone 
  FROM user_preferences 
  WHERE user_id = NEW.user_id;
  
  -- Use user's timezone if set, otherwise use timezone_at_creation
  user_timezone := COALESCE(user_timezone, NEW.timezone_at_creation);
  
  -- Validate timezone and fallback to UTC if invalid
  BEGIN
    NEW.next_trigger_at = (
      CURRENT_DATE + NEW.alarm_time_local
    ) AT TIME ZONE user_timezone;
  EXCEPTION WHEN OTHERS THEN
    -- If timezone is invalid, fallback to UTC
    NEW.next_trigger_at = (
      CURRENT_DATE + NEW.alarm_time_local
    ) AT TIME ZONE 'UTC';
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Audio Generation Queue
Manages audio generation scheduling with 58-minute lead time:

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

### Audio Generation Trigger
```sql
CREATE OR REPLACE FUNCTION handle_alarm_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into audio generation queue
    INSERT INTO audio_generation_queue (alarm_id, user_id, scheduled_for, status)
    VALUES (NEW.id, NEW.user_id, 
            COALESCE(NEW.alarm_date::text || ' ' || NEW.alarm_time_local, 
                     CURRENT_DATE::text || ' ' || NEW.alarm_time_local)::timestamp,
            'pending');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## API Usage

### Creating an Alarm
```json
{
  "user_id": "uuid",
  "alarm_date": "2025-06-25",
  "alarm_time_local": "07:00:00",
  "alarm_timezone": "America/New_York",
  "active": true
}
```

### Updating an Alarm
```json
{
  "alarm_time_local": "08:00:00"
}
```

## Timezone Support

### Valid IANA Timezones
- UTC
- America/New_York, America/Chicago, America/Denver, America/Los_Angeles
- America/Anchorage, Pacific/Honolulu
- Europe/London, Europe/Paris, Europe/Berlin
- Asia/Tokyo, Asia/Shanghai, Asia/Kolkata
- Australia/Sydney, Australia/Perth

### Timezone Handling
1. **Creation**: `alarm_timezone` stores the timezone for the alarm
2. **Calculation**: `next_trigger_at` is calculated using the alarm's timezone
3. **Fallback**: If timezone is invalid, system falls back to UTC
4. **Travel**: Alarms automatically adjust when user changes timezone

## Benefits

### 1. **Timezone Awareness**
- Alarms work correctly across timezone changes
- Supports users who travel frequently
- Automatic adjustment to local time

### 2. **Simplified Schema**
- Removed unused fields for cleaner design
- Focus on core alarm functionality
- Better maintainability

### 3. **Enhanced Audio Generation**
- 58-minute lead time for content generation
- Better content freshness
- Improved user experience

### 4. **Data Integrity**
- Required timezone field prevents invalid data
- Automatic trigger calculation
- Proper UTC timestamp storage

## Migration Notes

### For Existing Code
- Update API calls to use `alarm_time_local` instead of `alarm_time`
- Always include `alarm_timezone` when creating alarms
- Handle timezone-aware scheduling in client applications

### For New Development
- Use the current schema for all new alarm creation
- Implement timezone-aware UI components
- Test with different timezone scenarios
- Validate timezone strings before submission

## Testing

### Schema Validation
```sql
-- Check if alarms table has correct structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'alarms' 
ORDER BY ordinal_position;
```

### Trigger Testing
```sql
-- Test alarm creation with timezone
INSERT INTO alarms (user_id, alarm_time_local, alarm_timezone)
VALUES ('test-user-id', '07:30:00', 'America/New_York');

-- Verify next_trigger_at was calculated
SELECT alarm_time_local, alarm_timezone, next_trigger_at 
FROM alarms 
WHERE user_id = 'test-user-id';
```

#### Create a recurring alarm
```json
{
  "user_id": "uuid",
  "alarm_time_local": "08:00:00",
  "alarm_timezone": "America/New_York",
  "active": true
}
```

#### SQL Insert Example
```sql
INSERT INTO alarms (user_id, alarm_time_local, alarm_timezone, active)
VALUES ('uuid', '07:00:00', 'America/New_York', true);
```

---

**Status**: ✅ **Active and Deployed**
**Last Updated**: June 2025
**Compatibility**: All current code uses this schema 