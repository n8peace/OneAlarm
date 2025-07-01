# Alarm Audio Generation System - Design Document

## 🎯 Overview

The Alarm Audio Generation System creates personalized audio content for each upcoming alarm, generating a single AAC recording: a combined clip (3-5 minutes) that includes weather (if available), news (multi-category: general, business, technology, sports), sports, and market information. This system provides users with natural weather updates and professional daily briefings to enhance their wake-up experience.

## 🏗️ Architecture

### Core Components

1. **`generate-alarm-audio` Edge Function** - Main audio generation engine ✅ **Deployed**
2. **`generate-audio` Edge Function** - Individual user audio clips ✅ **Deployed**
3. **Audio Generation Queue** - Database-driven scheduling system ✅ **Implemented**
4. **Database Tables** - Storage for weather data, queue management, and audio metadata ✅ **Created**
5. **Database Triggers** - Automatic queue management for alarm changes ✅ **Active**
6. **Multi-Category Daily Content** - News is fetched and stored for all four categories (general, business, technology, sports) every day. Each user receives news content based on their selected category in preferences.

### System Flow

```
Alarm Created/Updated → Database Trigger → Queue Entry → Cron Job → Audio Generation → Storage
```

## 📊 Database Schema

### 1. Weather Data Table ✅ **Implemented**

```sql
CREATE TABLE weather_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  location TEXT NOT NULL,
  current_temperature DECIMAL(4,1),
  high_temperature DECIMAL(4,1),
  low_temperature DECIMAL(4,1),
  condition TEXT,
  sunrise TIME,
  sunset TIME,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

**Purpose**: Current weather information updated by the native app for generating weather content in the combined audio clip.

### 2. Daily Content Table (Multi-Category News) ✅ **Implemented**

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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

**Purpose**: Stores daily news, sports, stocks, and holidays in a single row per day with separate columns for each news category. This new structure provides efficient storage and retrieval of content for all four categories (general, business, technology, sports) in one row per day.

### 3. Audio Generation Queue Table ✅ **Implemented**

```sql
CREATE TABLE audio_generation_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  alarm_id UUID NOT NULL,
  scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### 4. Audio Table ✅ **Implemented**

```sql
CREATE TABLE audio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  alarm_id UUID NOT NULL,
  audio_type TEXT CHECK (audio_type IN ('weather', 'content', 'general', 'combined')),
  audio_url TEXT,
  script_text TEXT,
  status TEXT DEFAULT 'ready',
  cache_status TEXT DEFAULT 'pending',
  generated_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  file_size INTEGER,
  duration_seconds INTEGER,
  error TEXT
);
```

## 🧠 Content Personalization

- **News**: Each user can select their preferred news category (general, business, technology, sports) in their preferences. The system fetches and stores daily news for all four categories, and each user's alarm audio includes news from their selected category.
- **Sports**: Enhanced sports coverage with two-day events, timezone-aware processing, and smart formatting (finished games with scores, upcoming games with local times)
- **Stocks**: Market data and news impact analysis
- **Weather**: Real-time data from the native app
- **Holidays**: Seasonal and cultural awareness

## 🛠️ Content Generation Flow

1. **Queue Processing**
   - Process up to 10 queue items per invocation
   - **Atomic Claiming:** All `pending` items are immediately marked as `processing` before any background work begins. This prevents double-processing even if the function is triggered multiple times.
   - Update status: `pending` → `processing` → `completed`/`failed`
   - Fetch alarm, user preferences, weather data, and daily content (for the user's selected news category)

   > **Note (June 2025):**
   > The queue processing logic was updated to atomically mark items as `processing` before background work. This fully resolves a previous race condition where multiple invocations could process the same queue item, causing duplicate audio generation.

2. **Combined Audio Generation**
   - **Natural, conversational weather updates** (if available) with helpful recommendations
   - Create a single comprehensive script using GPT-4o
   - Include weather, news (from the user's selected category), sports, stocks, and holidays in one seamless clip
   - Generate a single AAC audio file using OpenAI TTS
   - **Gracefully skip** weather section if data unavailable

3. **Storage & Database**
   - Upload AAC file to Supabase Storage with organized structure
   - Save metadata to audio table with 48-hour expiration
   - Update queue status and log events

## 🤖 GPT Integration

- **Prompt**: Generates a single comprehensive script that includes weather (if available), news (from the user's selected category), sports, stocks, and holidays, with smooth transitions and a gentle wake-up tone.
- **Content Structure**:
  1. **Weather Updates** (20% weight): Natural, conversational weather with helpful recommendations
  2. **News Overview** (30% weight): Professional news summaries based on user interests and selected category
  3. **Sports Updates** (20% weight): Enhanced sports coverage with two-day events, timezone-aware processing, and smart formatting (finished games with scores, upcoming games with local times)
  4. **Market Updates** (20% weight): Stock and financial information with news impact analysis
  5. **Holiday Recognition** (10% weight): Appropriate time allocation based on holiday importance

## 🏷️ Supported News Categories
- **general** (default)
- **business**
- **technology**
- **sports**

## 🏁 Implementation Status

- [x] Multi-category news support in daily content function
- [x] User preferences for news category
- [x] Audio generation uses category-specific news
- [x] SwiftUI integration supports category selection

---

**The Alarm Audio Generation System now supports multi-category news, providing each user with a personalized, up-to-date news briefing in their alarm audio!**

## 🎵 Edge Functions

### `generate-alarm-audio` ✅ **Deployed**

#### Purpose
Generates a single combined audio file for a specific alarm using user preferences, weather data, and daily content.

#### API Endpoint
```
POST /functions/v1/generate-alarm-audio
```

#### Input
```typescript
interface GenerateAlarmAudioRequest {
  alarmId?: string; // Optional - function can process queue automatically
  forceRegenerate?: boolean;
}
```

#### Output
```typescript
interface GenerateAlarmAudioResponse {
  success: boolean;
  message: string;
  generatedClips: {
    clipId: string;
    fileName: string;
    audioUrl: string;
    fileSize: number;
    audioType: 'combined';
  }[];
  failedClips: {
    clipId: string;
    error: string;
  }[];
  alarmId: string;
  userId: string;
}
```

#### Function Flow ✅ **Implemented**

1. **Queue Processing**
   - Process up to 10 queue items per invocation
   - Update status: `pending` → `processing` → `completed`/`failed`
   - Fetch alarm, user preferences, weather data, and daily content

2. **Combined Audio Generation**
   - **Natural, conversational weather updates** (if available) with helpful recommendations
   - Create a single comprehensive script using GPT-4o
   - Include weather, news (from the user's selected category), sports, stocks, and holidays in one seamless clip
   - Generate a single AAC audio file using OpenAI TTS
   - **Gracefully skip** weather section if data unavailable

3. **Storage & Database**
   - Upload AAC file to Supabase Storage with organized structure
   - Save metadata to audio table with 48-hour expiration
   - Update queue status and log events

#### Recent Fixes ✅ **June 2025**
- **News Category Selection**: Now properly uses `news_categories[0]` as primary category instead of legacy `news_category` field
- **Weather Data Integration**: Improved error handling and validation for weather data availability
- **GPT-4o Integration**: Updated to use GPT-4o model with temperature 0.8 and 1200 max tokens
- **TypeScript Types**: Added `news_categories` field to UserPreferences interface
- **Error Handling**: Enhanced error messages and logging for debugging

### `generate-audio` ✅ **Deployed**

#### Purpose
Creates individual user audio clips for personalization (greeting, encouragement, etc.).

#### API Endpoint
```
POST /functions/v1/generate-audio
```

#### Input
```typescript
interface AudioGenerationRequest {
  userId: string;
  forceRegenerate?: boolean;
}
```

#### Output
```typescript
interface AudioGenerationResponse {
  success: boolean;
  message: string;
  generatedClips: GeneratedClip[];
  failedClips: FailedClip[];
  userId: string;
  storageBaseUrl: string;
}
```

#### Function Flow ✅ **Implemented**

1. **User Preferences**
   - Fetch user preferences and TTS voice settings
   - Check for existing audio clips (unless forceRegenerate=true)

2. **Individual Clip Generation**
   - Generate personalized clips: greeting_personal, encouragement_personal, etc.
   - Use OpenAI TTS with user's preferred voice
   - Add pauses for natural flow

3. **Storage & Database**
   - Upload individual clips to Supabase Storage
   - Save metadata to audio table
   - Update status and log events

## 🛠️ Recent Fixes and Improvements

### Generate-Alarm-Audio Function ✅ **Fixed**

**Issue**: Database insertion was failing with "there is no unique or exclusion constraint matching the ON CONFLICT specification"

**Root Cause**: The `saveAudioMetadata` method was using an `ON CONFLICT` clause with `alarm_id,audio_type`, but no unique constraint existed on those fields.

**Fix**: Removed the `ON CONFLICT` clause and changed to regular `INSERT` operation.

**Result**: Combined audio generation now works correctly without constraint errors.

### Generate-Audio Function ✅ **Fixed**

**Issue**: Function was incorrectly reporting failure when existing audio clips were available.

**Root Cause**: Success determination logic only considered `generatedClips.length > 0`, ignoring existing files.

**Fix**: Updated success logic to consider it successful if:
- New clips were generated successfully, OR
- Existing clips are available

**Result**: Correct logging and success reporting, no more misleading failure messages.

### Success Determination Logic

```typescript
// Consider success if we have any generated clips OR if we have existing files available
const hasGeneratedClips = generatedClips.length > 0;
const hasExistingFiles = Object.keys(existingFiles).length > 0;
const success = hasGeneratedClips || hasExistingFiles;

const message = success 
  ? hasGeneratedClips 
    ? `Generated ${generatedClips.length} audio clips successfully`
    : `Audio clips already exist and are available`
  : 'Failed to generate any audio clips';
```

## 🎵 TTS Configuration ✅ **Implemented**

### Audio Settings
- **Format**: AAC (Advanced Audio Codec) for optimal quality and compression
- **Combined Duration**: 3-5 minutes target
- **Voice Speed**: 0.95 (calming, slightly slower pace)
- **Expiration**: 48 hours
- **Supported Voices**: Alloy, Ash, Echo, Fable, Onyx, Nova, Shimmer, Verse
- **File Size**: ~1-2MB per combined file

### Content Integration

The system generates **one comprehensive audio file** per alarm that includes:

- **Weather Updates** (if available): Natural, conversational weather with helpful recommendations
- **News Overview**: Professional news summaries based on user interests
- **Sports Updates**: Enhanced sports coverage with two-day events, timezone-aware processing, and smart formatting (finished games with scores, upcoming games with local times)
- **Market Updates**: Stock and financial information with news impact analysis
- **Holiday Recognition**: Appropriate time allocation based on holiday importance
- **Gentle Transitions**: Smooth flow between content segments with pauses

## ⏰ Timing & Scheduling ✅ **Implemented**

### Audio Generation Timing
- **Generation Time**: 58 minutes before alarm time
- **Purpose**: Ensures freshest daily content (news, weather, sports, stocks)
- **Queue Processing**: Every 15 minutes via cron job
- **Processing Limit**: Up to 10 queue items per run

### Content Freshness
- **Weather**: Real-time data from native app
- **News**: Daily content generated by `daily-content` function
- **Sports**: Updated daily with latest games and events
- **Stocks**: Market data with news impact analysis
- **Holidays**: Seasonal and cultural awareness

## 🔒 Security & Privacy ✅ **Implemented**

### Row Level Security (RLS)
- **Audio Table**: Users can only access their own audio records
- **Service Role**: Backend functions have full access for automation
- **Storage Policies**: Audio files protected by RLS policies

### Data Protection
- **User Isolation**: All content is user-specific and isolated
- **Secure Storage**: Audio files stored with access policies
- **48-hour Expiration**: Automatic cleanup of audio files

## 📈 Performance & Scaling ✅ **Implemented**

### Current Performance
- **Audio Generation**: 1 combined file per alarm (~30-60 seconds)
- **File Sizes**: ~1-2MB per combined file (AAC format)
- **Storage**: Automatic 48-hour expiration
- **Concurrency**: Unlimited concurrent TTS generations (no artificial limits)

### Scaling Considerations
- **Queue Processing**: Batch processing of up to 10 items per run
- **Content Caching**: Daily content cached to reduce API calls
- **Error Handling**: Graceful degradation and retry logic
- **Monitoring**: Comprehensive logging and performance tracking

## 🧪 Testing & Validation ✅ **Implemented**

### Test Coverage
- **Unit Tests**: Audio generation, script creation, storage upload
- **Integration Tests**: End-to-end alarm creation and audio generation
- **Load Tests**: Multiple users and alarms processing
- **Error Tests**: Missing data, API failures, storage errors

### Validation Scripts
```bash
# Test audio generation function
bash scripts/test-system.sh load

# End-to-end test with multiple users
bash scripts/end-to-end-load-test.sh

# Check recent audio generation
bash scripts/check-recent-audio.sh
```

## 📊 Monitoring & Logging ✅ **Implemented**

### Event Logging
- **Audio Generation Started**: When processing begins
- **Audio Generation Completed**: When audio is ready
- **Audio Generation Failed**: Error details and retry attempts
- **Queue Processing**: Status updates and performance metrics

### Performance Metrics
- **Processing Time**: Track time from queue to completion
- **File Sizes**: Monitor audio file sizes for optimization
- **Success Rate**: Track successful vs failed generations
- **Content Distribution**: Monitor content type weights and lengths

## 🚀 Future Enhancements

### Content Personalization
- **Dynamic Content Weights**: Adjust weights based on user preferences
- **Content Relevance**: Prioritize content based on user interests
- **Seasonal Adjustments**: Modify content based on time of year

### Quality Improvements
- **Audio Enhancement**: Post-processing for better audio quality
- **Voice Selection**: AI-powered voice selection based on content
- **Pacing Optimization**: Dynamic speed adjustment based on content type

### Performance Scaling
- **Parallel Processing**: Process multiple alarms simultaneously
- **Content Caching**: Cache daily content across users
- **CDN Integration**: Use CDN for faster audio delivery

## 📋 Implementation Status

### ✅ Completed
- [x] Database schema and triggers
- [x] Edge function implementation
- [x] GPT integration for combined script generation
- [x] TTS integration with AAC format
- [x] Storage integration with RLS policies
- [x] Queue processing and status tracking
- [x] Error handling and graceful degradation
- [x] Comprehensive logging and monitoring
- [x] Testing scripts and validation
- [x] Security implementation with RLS

### 🔄 In Progress
- [ ] Performance optimization and caching
- [ ] Content personalization enhancements
- [ ] Audio quality improvements

### 📅 Planned
- [ ] CDN integration for faster delivery
- [ ] Advanced content personalization
- [ ] Multi-language support

---

**🎉 The Alarm Audio Generation System is fully implemented, deployed, and production-ready!**

### 3. **Enhanced Sports Data**
- **Source**: TheSportsDB API
- **Two-Day Coverage**: Fetches events for today and tomorrow to handle timezone edge cases
- **Timezone-Aware Processing**: Uses `dateEventLocal` to categorize games by when they actually happen locally
- **Smart Formatting**: 
  - **Finished Games**: "Team A 3 - Team B 1 (Final)"
  - **Upcoming Games**: "Team A vs Team B at 19:00:00"
- **Comprehensive Coverage**: Today's Games + Tomorrow's Games sections
- **Local Time Display**: Shows game times in local venue timezone 