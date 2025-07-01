# Generate Audio Function

A Supabase Edge Function that creates a set of general wake-up audio clips for a gentle wake-up experience using OpenAI's TTS technology.

## 🎯 Overview

This function generates 5 general morning audio messages using OpenAI's TTS-1 model, delivering calming wake-up content tailored to each user's preferred name. The system creates a peaceful morning routine with gentle, non-personalized encouragement.

## ✨ Features

- **Calming Wake-up Experience**: Slow, gentle TTS voices with mindful language
- **General Content**: 5 general wake-up messages per user (no longer 29 personalized clips)
- **Efficient Storage**: Caches generated audio in Supabase Storage to avoid re-generation
- **OpenAI TTS**: Uses OpenAI's TTS-1 for high-quality speech synthesis
- **Batch Processing**: Processes all 5 clips efficiently with retry logic

## 🎵 Voice Configuration

### Supported Voices

- `alloy`: Neutral voice
- `ash`: Male voice  
- `echo`: Male voice
- `fable`: Female voice
- `onyx`: Male voice
- `nova`: Female voice (default)
- `shimmer`: Female voice
- `verse`: Neutral voice

### Voice Selection Logic

Voice selection is based on user preference (`tts_voice` field in `user_preferences` table).
- **Default**: `alloy` if no voice is specified
- **Speed**: 1.0 (normal pace for clear wake-up experience)
- **Instructions**: All voices use calming, gentle instructions for peaceful wake-up experience

### Voice Instructions

The TTS system includes specific instructions to ensure all audio clips are generated with a calm, gentle tone:

- **Tone**: Calm, gentle, and soothing
- **Voice Quality**: Soft, peaceful voice that gently wakes someone up
- **Pace**: Slow, mindful pace with warm, encouraging energy
- **Purpose**: Peaceful morning wake-up experience

## 📁 File Structure

```
generate-audio/
├── index.ts           # Main function entry point
├── services.ts        # Core business logic
├── config.ts          # Configuration and templates
├── types.ts           # TypeScript type definitions
└── README.md          # This file
```

## 🔧 Configuration

### Environment Variables

- `OPENAI_API_KEY`: OpenAI API key for TTS generation
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for database access
- `SUPABASE_STORAGE_BUCKET`: Storage bucket for audio files

### Audio Settings

- **Model**: `gpt-4o-mini-tts`
- **Speed**: 1.0 (normal pace)
- **Format**: AAC
- **Instructions**: Calm, gentle wake-up tone with soothing voice
- **Retry Logic**: Up to 3 attempts with exponential backoff
- **Concurrent Processing**: All 5 clips processed in a single batch

## 🗄️ Database Integration

This function integrates with the following tables:

- `users`: To get the user's ID
- `user_preferences`: To retrieve user's preferences like voice and name
- `audio`: Stores metadata about generated audio files
- `logs`: Logs generation events and errors

## 🎭 General Wake-up Messages

The following 5 audio clips are generated for each user:

1. **wake_up_message_1**: General wake-up message 1
2. **wake_up_message_2**: General wake-up message 2
3. **wake_up_message_3**: General wake-up message 3
4. **wake_up_message_4**: General wake-up message 4
5. **wake_up_message_5**: General wake-up message 5

Each message is gentle, calming, and uses the user's preferred name.

## 🔄 API Usage

### Request Format

```json
{
  "userId": "user-uuid",
  "forceRegenerate": false
}
```

### Response Format

```json
{
  "success": true,
  "message": "Generated 5 audio clips successfully",
  "generatedClips": [
    {
      "clipId": "wake_up_message_1",
      "fileName": "wake_up_message_1.aac",
      "audioUrl": "https://...",
      "fileSize": 121440
    }
  ],
  "failedClips": [],
  "storageBaseUrl": "audio-files"
}
```

## 🛠️ Key Services

- **`DatabaseService`**: Manages all database interactions
  - `getUser()`: Fetches user details
  - `getUserPreferences()`: Retrieves user personalization settings
  - `saveAudioFile()`: Saves audio file metadata to the database
- **`OpenAITTSService`**: Handles TTS generation with retry logic
  - `generateSpeech()`: Creates audio from text
  - `generateSpeechWithRetry()`: Retries failed generations
- **`StorageService`**: Handles file operations with Supabase Storage
  - `uploadAudioFile()`: Uploads the generated audio file
  - `getExistingFiles()`: Lists existing files to prevent duplicates

## ⚠️ Error Handling

- **Missing User**: Returns a `404 Not Found` if the user doesn't exist
- **Missing Preferences**: Returns error if user preferences not found
- **Audio Generation Failure**: Catches and logs errors from the TTS service
- **Upload Failure**: Logs errors if the audio file fails to upload to storage
- **TTS Failures**: Retries failed TTS generations up to 3 times
- **Partial Success**: Returns 207 status code if some clips fail but others succeed

## 🧪 Testing

### Manual Testing

```bash
# Test with a specific user
bash scripts/test-system.sh audio YOUR_SERVICE_ROLE_KEY
```

### Database Verification

```sql
-- Check recent audio records
SELECT * FROM audio ORDER BY generated_at DESC LIMIT 5;

-- Check audio records by user
SELECT * FROM audio WHERE user_id = 'YOUR_USER_ID' ORDER BY generated_at DESC;
```

### Expected Behavior

1. **Success**: Returns 200 with generated clip information
2. **Partial Success**: Returns 207 if some clips fail
3. **User Not Found**: Returns 404
4. **Missing Preferences**: Returns 400 with error message
5. **Database Records**: Creates entries in `audio` table for each successful generation

## 📊 Performance

- **Batch Processing**: Processes all 5 clips in a single batch
- **Database Records**: Creates records in `audio` table for each generated clip
- **Storage**: Uploads AAC files to Supabase Storage
- **Error Handling**: Logs failures and retries failed generations

## 🔄 Cron Job

The function can be called by cron jobs to generate audio for users:

```bash
# Example cron job call
curl -X POST https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-audio \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"userId": "user-uuid"}'
```

## 📈 Monitoring

- **Function Logs**: Check Supabase Dashboard → Functions → generate-audio
- **Database**: Monitor audio file generation in `audio` table
- **Storage**: Check Supabase Storage bucket for uploaded files
- **Performance**: Monitor execution times and success rates

## 📝 Logging

All operations are logged to the `logs` table with:
- Function start/end events
- Error details with stack traces
- Performance metrics
- User activity tracking

## 🚀 Deployment

```bash
# Deploy the function
supabase functions deploy generate-audio

# Test the deployment
bash scripts/test-system.sh audio YOUR_SERVICE_ROLE_KEY
```

## 🔍 Monitoring

- Check function logs in Supabase dashboard
- Monitor audio file generation in `audio` table
- Track user preferences in `user_preferences` table
- Review error logs for troubleshooting 