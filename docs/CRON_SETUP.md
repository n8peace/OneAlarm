# Cron Job Setup - Cron-job.org

## **✅ Solution: Cron-job.org**

Your OneAlarm system is now running automatically using **cron-job.org**, a reliable external cron service for both daily content generation and alarm audio generation.

## **Current Setup**

### **Daily Content Generation**
- **Service**: Cron-job.org
- **Schedule**: Every hour at 3 minutes past the hour
- **Function**: `daily-content`
- **Status**: ✅ **Working**

### **Audio Generation Queue Processing**
- **Service**: Cron-job.org
- **Schedule**: Every 1 minute
- **Function**: `generate-alarm-audio`
- **Purpose**: Processes pending alarm audio generation (10 alarms, 5 concurrent, async)
- **Status**: ✅ **Working**

## **How It Works**

### **Daily Content Process**
1. **Cron-job.org** calls your Supabase function every hour
2. **Function** collects news, sports, and stock data
3. **Data** is stored in the `daily_content` table
4. **Logs** are created for monitoring

### **Audio Generation Process**
1. **Alarms** are automatically added to `audio_generation_queue` when created/updated
2. **Cron job** processes queue items every 1 minute (10 alarms, 5 concurrent, async)
3. **Function** returns immediately while continuing to process alarms in background
4. **Audio files** are stored with 48-hour expiration
5. **Queue status** is updated to track progress

## **Monitoring**

### **Cron-job.org Dashboard**
- **URL**: https://cron-job.org
- **Shows**: Execution history, success/failure status
- **Alerts**: Email notifications on failures

### **Supabase Dashboard**
- **Function Logs**: https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs/functions
- **Database**: Check `daily_content` and `audio_generation_queue` tables
- **Logs**: Monitor function execution logs

## **Configuration Details**

### **Daily Content Cron Job**
- **URL**: `https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/daily-content`
- **Method**: `POST`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og`
- **Body**: `{}`
- **Schedule**: `3 * * * *` (Every hour at minute 3)
- **Retries**: 3 attempts with 5-minute delays
- **Timeout**: 30 seconds

### **Audio Generation Cron Job**
- **URL**: `https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-alarm-audio`
- **Method**: `POST`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og`
- **Body**: `{}` (Function processes queue automatically)
- **Schedule**: `* * * * *` (Every 1 minute)
- **Retries**: 3 attempts with 5-minute delays
- **Timeout**: 30 seconds (cron job timeout)
- **Batch Size**: 10 alarms per execution
- **Concurrency**: 5 alarms processed simultaneously
- **Processing Mode**: Async (returns immediately, continues in background)

### **Function Features**

#### **Daily Content Function**
- **News API**: Collects top headlines
- **Sports API**: Gets today's sports events
- **Stocks API**: Fetches stock market data
- **Fallback Logic**: Uses previous data if APIs fail
- **Error Handling**: Comprehensive logging and notifications

#### **Audio Generation Function**
- **Dual Audio**: Weather (30s) and content (3-4min) clips per alarm
- **Personalization**: Uses user preferences and daily content
- **Weather Integration**: Natural, conversational weather updates
- **Content Types**: News, sports, and market information
- **Queue Processing**: 10 items per invocation with 5 concurrent executions
- **Async Processing**: Returns immediately, continues processing in background
- **Error Handling**: Graceful degradation and retry logic
- **Storage Management**: 48-hour expiration with cleanup

## **Queue Management**

### **Audio Generation Queue**
The `audio_generation_queue` table manages audio generation scheduling:

```sql
-- Check pending audio generation items
SELECT * FROM audio_generation_queue 
WHERE status = 'pending' 
AND scheduled_for <= NOW() 
ORDER BY scheduled_for ASC;

-- Monitor queue status
SELECT status, COUNT(*) 
FROM audio_generation_queue 
GROUP BY status;
```

### **Queue Processing Logic**
1. **Pending items** are processed in order of `scheduled_for`
2. **Atomic Claiming:** All `pending` items are immediately marked as `processing` before any background work begins. This prevents double-processing even if the function is triggered multiple times.
3. **Status updates**: `pending` → `processing` → `completed`/`failed`
4. **Error handling**: Failed items are logged with error messages
5. **Retry logic**: Function retries GPT and TTS generation up to 3 times

> **Note (June 2025):**
> The queue processing logic was updated to atomically mark items as `processing` before background work. This fully resolves a previous race condition where multiple invocations could process the same queue item, causing duplicate audio generation.

## **Troubleshooting**

### **If Cron Job Fails**
1. **Check cron-job.org dashboard** for error details
2. **Verify service role key** is correct
3. **Test function manually** using the test script
4. **Check Supabase logs** for function errors

### **Manual Testing**
```bash
# Test daily content function
./scripts/test-function.sh YOUR_SERVICE_ROLE_KEY

# Test audio generation function
./scripts/test-system.sh queue

# Comprehensive system check
./scripts/check-system-status.sh
```

### **Check Data Collection**
```sql
-- Check daily content
SELECT * FROM daily_content ORDER BY created_at DESC LIMIT 5;

-- Check audio generation queue
SELECT * FROM audio_generation_queue ORDER BY created_at DESC LIMIT 10;

-- Check generated audio files
SELECT * FROM audio ORDER BY generated_at DESC LIMIT 10;
```

### **Audio Generation Issues**
- **Weather data missing**: Function continues with content generation
- **GPT/TTS failures**: Automatic retry with exponential backoff
- **Storage issues**: Detailed error logging for debugging
- **Queue stuck**: Check for processing items and clear if needed

## **Benefits of This Setup**

- ✅ **Reliable**: 99.9% uptime guarantee
- ✅ **Simple**: No code maintenance required
- ✅ **Free**: 5 cron jobs, unlimited executions
- ✅ **Monitoring**: Built-in logs and notifications
- ✅ **Retries**: Automatic retry on failure
- ✅ **Secure**: Encrypted key storage
- ✅ **Scalable**: Queue-based processing for high volume
- ✅ **Resilient**: Graceful error handling and degradation

## **Why Not Database Cron?**

Supabase's managed PostgreSQL doesn't include the `net` extension needed for HTTP requests from database cron jobs. External cron services like cron-job.org are the standard solution for this type of automation.

## **Success Indicators**

### **Daily Content**
- ✅ Cron job shows "Success" status in dashboard
- ✅ Function logs show successful executions
- ✅ New data appears in `daily_content` table hourly
- ✅ No error notifications received
- ✅ Execution times are reasonable (< 30 seconds)

### **Audio Generation**
- ✅ Queue items are processed within 15 minutes
- ✅ Audio files are generated and stored successfully
- ✅ Weather and content clips are created for each alarm
- ✅ Queue status is updated correctly
- ✅ No failed items remain in queue

## **Next Steps**

Your cron jobs are working perfectly! You can now:

1. **Monitor** the automated data collection and audio generation
2. **Use the data** in your application
3. **Set up alerts** for any issues
4. **Scale** by adding more cron jobs if needed
5. **Optimize** queue processing frequency based on usage

## **Deployment Commands**

```bash
# Deploy the audio generation function
supabase functions deploy generate-alarm-audio

# Set up the audio generation cron job
# Add to cron-job.org with schedule: */15 * * * *
# URL: https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-alarm-audio
```

## **Service Role Key**

**Current Service Role Key** (for reference):
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og
```

**Important**: Keep this key secure and never expose it in client-side code.

---

**🎉 Your automated daily content collection and audio generation system is now live and working!** 