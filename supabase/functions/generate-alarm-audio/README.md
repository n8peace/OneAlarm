# Generate Alarm Audio Function

## Overview

The `generate-alarm-audio` function creates personalized combined audio files for specific alarms. It processes items from the `audio_generation_queue` table and generates comprehensive audio content that includes weather updates, news, sports, and market information in a single file.

## Function Purpose

- **Processes audio generation queue** every 1 minute via cron job
- **Generates one combined audio file** per alarm (3-5 minutes duration)
- **Batch processing**: Handles 25 alarms per function invocation
- **Concurrent processing**: Up to 50 alarms per batch
- **Integrates multiple content types**: Weather, news, sports, stocks, and holidays
- **Uses OpenAI GPT and TTS** for natural, personalized content
- **Stores audio in Supabase Storage** with 48-hour expiration
- **Updates database metadata** with file information and status

## Audio Content Structure

Each combined audio file includes:

1. **Weather Updates** (if available)
   - Natural, conversational weather with helpful recommendations
   - Location-specific conditions and forecasts
   - Gracefully skips if weather data unavailable

2. **News Overview**
   - Professional news summaries based on user interests
   - Structured, informative content

3. **Sports Updates**
   - Team-specific sports coverage
   - Recent games and upcoming events

4. **Market Updates**
   - Stock and financial information
   - News impact analysis on markets

5. **Holiday Recognition**
   - Appropriate time allocation based on holiday importance
   - Cultural and seasonal awareness

6. **Gentle Transitions**
   - Smooth flow between content segments with pauses
   - Natural conversation flow

## Configuration

### Environment Variables

```bash
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key

# Supabase Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Audio Configuration
AUDIO_BUCKET_NAME=audio-files
AUDIO_EXPIRATION_HOURS=48
AUDIO_FORMAT=aac
TTS_SPEED=0.95
DEFAULT_TTS_VOICE=alloy

# Content Configuration
MAX_CONTENT_LENGTH=3000
WEATHER_WEIGHT=0.2
NEWS_WEIGHT=0.3
SPORTS_WEIGHT=0.2
MARKET_WEIGHT=0.2
HOLIDAY_WEIGHT=0.1
```

### Audio Settings

- **Format**: AAC (Advanced Audio Codec) for optimal quality and compression
- **Speed**: 0.95 (slightly slower for calming effect)
- **Duration**: 3-5 minutes target
- **File Size**: ~1-2MB per combined file
- **Expiration**: 48 hours
- **Audio Type**: `'combined'` in database

## Database Integration

### Input: Audio Generation Queue

The function processes items from `audio_generation_queue`:

```sql
SELECT * FROM audio_generation_queue 
WHERE status = 'pending' 
AND scheduled_for <= NOW()
ORDER BY scheduled_for ASC
LIMIT 10
```

### Output: Audio Table

Generated audio metadata is stored in the `audio` table:

```sql
INSERT INTO audio (
    user_id, alarm_id, audio_type, audio_url, 
    status, file_size, generated_at, expires_at
) VALUES (
    userId, alarmId, 'combined', audioUrl,
    'ready', fileSize, NOW(), NOW() + INTERVAL '48 hours'
)
```

### Queue Status Updates

Queue items are updated with processing status:

```sql
UPDATE audio_generation_queue 
SET status = 'processing' 
WHERE id = queueItemId

-- On completion:
UPDATE audio_generation_queue 
SET status = 'completed' 
WHERE id = queueItemId

-- On failure:
UPDATE audio_generation_queue 
SET status = 'failed' 
WHERE id = queueItemId
```

## Content Generation Process

### 1. User Data Retrieval

```typescript
// Fetch user preferences and content
const userPrefs = await getUserPreferences(userId)
const dailyContent = await getDailyContent(userId, today)
const weatherData = await getWeatherData(userId)
```

### 2. Combined Script Generation

```typescript
// Generate comprehensive script with all content types
const combinedScript = await generateCombinedScript({
    userPrefs,
    dailyContent,
    weatherData,
    contentWeights: {
        weather: 0.2,
        news: 0.3,
        sports: 0.2,
        market: 0.2,
        holiday: 0.1
    }
})
```

### 3. Audio Generation

```typescript
// Generate single combined audio file
const audioBuffer = await generateAudio({
    script: combinedScript,
    voice: userPrefs.tts_voice || 'alloy',
    speed: 0.95,
    format: 'aac'
})
```

### 4. Storage and Database Update

```typescript
// Upload to Supabase Storage
const audioUrl = await uploadAudio(audioBuffer, fileName)

// Update database
await insertAudioMetadata({
    userId,
    alarmId,
    audioUrl,
    fileSize: audioBuffer.length,
    audioType: 'combined'
})
```

## Error Handling

### Graceful Degradation

- **Missing Weather Data**: Continues with content generation, skips weather section
- **Content Failures**: Falls back to basic content if specific sections fail
- **TTS Errors**: Retries with different voice or falls back to default
- **Storage Errors**: Logs errors and marks queue item as failed

### Retry Logic

- **Queue Processing**: Failed items remain in queue for retry
- **TTS Generation**: Automatic retry with exponential backoff
- **Storage Upload**: Multiple retry attempts with error logging

## Performance Considerations

- **Batch Processing**: Handles 25 alarms per function invocation
- **Concurrent Processing**: Up to 50 alarms per batch
- **Memory Usage**: Optimized for single combined audio generation
- **Storage Costs**: ~1-2MB per alarm, 48-hour expiration
- **API Costs**: One GPT call + one TTS call per alarm
- **System Capacity**: Supports ~7,500-15,000 users