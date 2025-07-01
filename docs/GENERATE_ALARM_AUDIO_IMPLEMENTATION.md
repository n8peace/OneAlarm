# Generate Alarm Audio Implementation

## Overview

The `generate-alarm-audio` function creates personalized audio content for alarm wake-up experiences. It combines weather data, daily content (multi-category news: general, business, technology, sports), and user preferences to generate a cohesive morning message.

## Architecture

### Core Components

1. **GenerateAlarmAudioService** - Main orchestrator
2. **GPTService** - Content generation using OpenAI GPT
3. **TTSService** - Text-to-speech conversion
4. **StorageService** - File upload and management
5. **DatabaseService** - Data persistence and retrieval

### Data Flow

```
Alarm Trigger → Queue Item → Content Generation → TTS → Storage → Database
```

## Configuration

### Shared Configuration
The function uses shared configuration from `_shared/constants/config.ts`:

- **TTS Settings**: Model, API URL, voices, retry logic
- **Storage Settings**: Bucket, folders, file extensions
- **Audio Settings**: Duration limits, file size limits
- **Error Messages**: Standardized error handling

### Function-Specific Configuration
Located in `config.ts`:

- **GPT Settings**: Model, temperature, token limits
- **Audio Settings**: Combined duration, expiration
- **System Settings**: Timeouts, execution limits
- **Prompts**: Content generation templates

## API Endpoints

### POST /generate-alarm-audio
Generate audio for a specific alarm.

**Request Body:**
```json
{
  "alarmId": "uuid",
  "forceRegenerate": false
}
```

**Response:**
```json
{
  "success": true,
  "message": "Generated 1 audio clips successfully",
  "generatedClips": [
    {
      "clipId": "combined_alarm_123",
      "fileName": "combined_audio.aac",
      "audioUrl": "https://...",
      "fileSize": 123456,
      "audioType": "combined"
    }
  ],
  "failedClips": [],
  "alarmId": "uuid",
  "userId": "uuid"
}
```

### GET /generate-alarm-audio
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "function": "generate-alarm-audio",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Queue Processing

### Atomic Queue Claiming (June 2025 Update)
The function now atomically marks queue items as "processing" before any background work begins. This prevents double-processing even if the function is triggered multiple times (e.g., by cron or manual calls).

**How it works:**
- The function fetches all `pending` queue items that are due for processing.
- It immediately marks these items as `processing` in a single atomic update.
- Only after this update does it start background processing.
- Any concurrent invocation will not pick up the same items, as they are no longer `pending`.
- This guarantees that each queue item is only processed by one invocation at a time.

**Previous Issue:**
- Before this fix, multiple invocations could fetch the same `pending` items before any were marked as `processing`, causing duplicate audio generation.
- This race condition is now fully resolved.

### Batch Processing
The function supports processing multiple queue items:

```typescript
await service.processQueueItems(batchSize: number = 50)
```

### Parallel Processing
For high-volume scenarios:

```typescript
await service.processQueueItemsParallel(batchSize: number = 10, maxConcurrent: number = 50)
```

### Async Processing
For non-blocking operations:

```typescript
await service.processQueueItemsAsync(batchSize: number = 10, maxConcurrent: number = 50)
```

## Content Generation

### Alarm Date Integration
- **Date Context**: The system now includes the alarm's specific date in the GPT prompt
- **Time Context**: The system now includes the alarm's specific time in the GPT prompt
- **Local Formatting**: Date is formatted as "Today is [Weekday], [Month] [Day], [Year]" and time as "Alarm Time: [HH:MM AM/PM]" in the user's timezone
- **Timezone Awareness**: Uses `alarm_timezone` to ensure correct local date and time display
- **Fallback Handling**: Gracefully handles missing date/time information with appropriate fallback message
- **Example Output**: "Today is Tuesday, June 24, 2025. Alarm Time: 07:30 AM"

### Weather Integration
- Fetches current weather data for user's location
- Integrates weather information into morning message
- Provides relevant recommendations (layers, sunscreen, etc.)

### Daily Content Integration (Multi-Category News)
- News articles are now fetched and stored for four categories: **general, business, technology, sports**
- Each user can select their preferred news category in their preferences (`news_categories` array)
- The function fetches daily content for the user's selected category and includes it in the generated audio
- **Enhanced Sports Updates**: Two-day coverage with timezone-aware processing, finished games with scores, and upcoming games with local times
- Stock market data for user's portfolio
- Holiday information

### User Personalization
- Uses preferred name in greetings
- Adapts content based on user preferences, including their selected news category from `news_categories[0]`
- Maintains consistent tone and style

## Audio Generation

### TTS Configuration
- **Model**: `gpt-4o-mini-tts`
- **Format**: AAC
- **Speed**: 0.95 (slightly slower for clarity)
- **Voices**: alloy, ash, echo, fable, onyx, nova, shimmer, verse
- **Retries**: 3 attempts with exponential backoff

### File Management
- **Storage**: Supabase Storage bucket
- **Organization**: `/alarm-audio/{user_id}/{alarm_id}/`
- **Expiration**: 48 hours
- **Max Size**: 10MB per file

## Database Schema

### Audio Table
```sql
CREATE TABLE audio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  alarm_id UUID REFERENCES alarms(id),
  audio_type TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  script_text TEXT,
  duration_seconds INTEGER,
  file_size INTEGER,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Queue Table
```sql
CREATE TABLE audio_generation_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  alarm_id UUID REFERENCES alarms(id),
  scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Error Handling

### Common Error Scenarios
1. **Alarm Not Found**: Invalid alarm ID
2. **User Preferences Missing**: No user preferences found
3. **TTS Generation Failed**: OpenAI API errors
4. **Storage Upload Failed**: File upload issues
5. **Database Errors**: Connection or constraint issues

### Retry Logic
- **TTS**: 3 attempts with exponential backoff
- **Storage**: Single attempt with detailed error logging
- **Database**: Single attempt with rollback on failure

## Monitoring and Logging

### Event Logging
All operations are logged to the `logs` table:
- Only essential logs are now written (e.g., function_completed, errors). All debug logs (including alarm_trigger_debug and similar events) have been removed for production cleanliness.

### Health Monitoring
- Function execution time tracking
- Success/failure rate monitoring
- Queue processing metrics
- Storage usage monitoring

## Performance Considerations

### Optimization Strategies
1. **Batch Processing**: Process multiple alarms together
2. **Parallel Processing**: Concurrent audio generation
3. **Caching**: Reuse existing audio when possible
4. **Async Operations**: Non-blocking queue processing

### Resource Limits
- **Execution Time**: 5 minutes maximum
- **Memory**: 512MB limit
- **File Size**: 10MB per audio file
- **Concurrent Requests**: 50 maximum

## Testing

### Manual Testing
```bash
# Test with specific alarm
curl -X POST "https://project.supabase.co/functions/v1/generate-alarm-audio" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"alarmId": "uuid", "forceRegenerate": true}'
```

### Automated Testing
Use the test script:
```bash
./scripts/test-system.sh audio
```

## Troubleshooting

### Common Issues

1. **TTS API Errors**
   - Check OpenAI API key configuration
   - Verify API rate limits
   - Review error logs for specific failure reasons

2. **Storage Upload Failures**
   - Verify bucket permissions
   - Check file size limits
   - Review storage policies

3. **Queue Processing Issues**
   - Check queue item status
   - Verify alarm and user data
   - Review database constraints

### Debug Mode
Enable detailed logging by setting environment variables:
```bash
SUPABASE_LOG_LEVEL=debug
```

## 🎯 Recent Fixes and Improvements

### News Category Selection ✅ **Fixed June 2025**

**Issue**: The system was using the legacy `news_category` field instead of the new `news_categories` array, causing inconsistent news content delivery.

**Root Cause**: The `generate-alarm-audio` function was reading `userPreferences?.news_category` instead of using the `news_categories` array.

**Fix**: 
- Updated function to use `userPreferences?.news_categories[0]` as primary category
- Added `news_categories` field to TypeScript UserPreferences interface
- Updated test scripts to properly set `news_categories` array based on `news_category`

**Result**: Users now receive news content matching their selected category (general, business, technology, sports).

### GPT-4o Integration ✅ **Updated June 2025**

**Model**: Updated from GPT-3.5-turbo to GPT-4o for improved content generation quality.

**Configuration**:
- **Model**: `gpt-4o`
- **Temperature**: 0.8 (balanced creativity and consistency)
- **Max Tokens**: 1,200 (optimized for combined script length)
- **Prompt**: Streamlined to single combined prompt for weather + news + sports + stocks + holidays

**Result**: Higher quality, more coherent audio scripts with better personalization.

### Weather Data Integration ✅ **Enhanced June 2025**

**Improvements**:
- Enhanced error handling for missing weather data
- Better validation of weather data availability
- Improved logging for weather-related issues
- Graceful fallback when weather data is unavailable

**Result**: More reliable weather integration with better error reporting.

### Generate-Alarm-Audio Function ✅ **Fixed**

**Issue**: Database insertion was failing with "there is no unique or exclusion constraint matching the ON CONFLICT specification"

**Root Cause**: The `saveAudioMetadata` method was using an `ON CONFLICT` clause with `alarm_id,audio_type`, but no unique constraint existed on those fields.

**Fix**: Removed the `ON CONFLICT` clause and changed to regular `INSERT` operation.

**Result**: Combined audio generation now works correctly without constraint errors.

### Cascade Trigger Fix (June 26, 2025)
**Issue**: The `generate-audio` function was being called twice for each user preferences creation, causing duplicate audio generation.

**Root Cause**: A cascade trigger effect where the `trigger_ensure_general_category` trigger was firing on both INSERT and UPDATE operations, causing the `generate-audio` function to be called twice.

**Solution**: Changed the trigger from `BEFORE INSERT OR UPDATE` to `BEFORE INSERT ONLY` to prevent the cascade effect.

**Impact**: 
- ✅ Single generate-audio function call per user preferences creation
- ✅ Eliminated duplicate audio generation
- ✅ Improved system performance and resource usage
- ✅ Cleaner logs without duplicate entries

## Future Enhancements

1. **Voice Customization**: Allow users to select preferred voices
2. **Content Variety**: Implement content rotation and variation
3. **Performance Optimization**: Implement audio caching and compression
4. **Analytics**: Add detailed usage and performance metrics
5. **A/B Testing**: Support for different content styles and formats

---

**Note:** The alarm audio generation system now fully supports multi-category news. User preferences determine which news category is included in their personalized audio each day. 