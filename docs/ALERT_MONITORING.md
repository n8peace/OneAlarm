# Alert Monitoring Guide

## 🔍 Where to See Your Alerts

### **1. Database Logs (Primary Method)**

**Go to Supabase Dashboard → SQL Editor** and run the queries from `check-alerts.sql`:

#### **All Alerts:**
```sql
SELECT 
  id,
  event_type,
  meta->>'message' as alert_message,
  meta->>'error' as error_details,
  created_at
FROM logs 
WHERE event_type IN ('daily_content_health_alert', 'daily_content_function_started')
  AND (meta->>'status' = 'error' OR event_type = 'daily_content_health_alert')
ORDER BY created_at DESC
LIMIT 20;
```

#### **Timeout Alerts:**
```sql
SELECT 
  id,
  meta->>'message' as alert_message,
  meta->>'execution_time_ms' as execution_time_ms,
  created_at
FROM logs 
WHERE event_type = 'daily_content_function_started'
  AND (meta->>'execution_time_ms')::int > 30000
ORDER BY created_at DESC;
```

### **2. Supabase Dashboard Logs**

1. **Go to:** https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs/logs
2. **Look for:**
   - Function invocations with error status
   - Health alert entries
   - Timeout warnings

### **3. External Notification Channels**

#### **Slack (if configured):**
- Check your configured Slack channel
- Look for messages with 🚨, ❌, or ⏰ emojis
- Messages include function details and error information

#### **Webhook (if configured):**
- Check your webhook endpoint logs
- Look for POST requests with alert JSON data
- Monitor your webhook service dashboard

#### **Email (if configured):**
- Check your email inbox
- Look for alert emails from your notification service

## 🚨 Types of Alerts You'll See

### **1. Function Failure Alerts**
- **Trigger:** Function crashes or throws an error
- **Message:** "❌ Daily content collection failed after Xms"
- **Details:** Error message, stack trace, execution time

### **2. Timeout Alerts**
- **Trigger:** Function takes longer than 30 seconds
- **Message:** "⏰ Daily content collection took too long: Xms"
- **Details:** Execution time, function performance

### **3. Health Check Alerts**
- **Trigger:** Function hasn't run in 2 hours
- **Message:** "Daily content function has not executed in the last 2 hours"
- **Details:** Last execution time, current time

### **4. Success Notifications**
- **Trigger:** Function completes successfully
- **Message:** "✅ Daily content collection completed successfully in Xms"
- **Details:** Execution time, API results

## 📊 Alert Data Structure

Each alert contains:

```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "function": "daily-content",
  "message": "Alert message here",
  "details": {
    "executionTime": 45000,
    "error": "API timeout",
    "stack": "Error stack trace",
    "api_results": {
      "news": {"success": false, "error": "API error"},
      "sports": {"success": true, "error": null},
      "stocks": {"success": false, "error": "Rate limit"}
    }
  },
  "environment": "production"
}
```

## 🔧 Setting Up External Notifications

### **Slack Setup:**
```bash
supabase secrets set SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

### **Webhook Setup:**
```bash
supabase secrets set NOTIFICATION_WEBHOOK_URL="https://your-webhook-url.com/notify"
```

### **Email Setup:**
```bash
supabase secrets set ALERT_EMAIL="your-email@example.com"
```

## 📈 Monitoring Dashboard

### **Real-time Monitoring:**
1. **Supabase Dashboard → Logs** (real-time function logs)
2. **Database → Tables → logs** (detailed execution history)
3. **External channels** (Slack, webhook, email)

### **Alert Frequency:**
- **Function failures:** Immediate
- **Timeouts:** When execution > 30 seconds
- **Health checks:** Every 30 minutes (if function hasn't run in 2 hours)
- **Success notifications:** After each successful run

## 🎯 Quick Alert Check

**To quickly see if you have any alerts:**

1. **Go to Supabase Dashboard**
2. **Open SQL Editor**
3. **Run this query:**
   ```sql
   SELECT COUNT(*) as alert_count 
   FROM logs 
   WHERE event_type = 'daily_content_health_alert' 
      OR (event_type = 'daily_content_function_started' AND meta->>'status' = 'error');
   ```

**If `alert_count > 0`, you have alerts to review!**

## 🚨 Troubleshooting Alerts

### **If you're not seeing alerts:**
1. Check if notifications are enabled in config
2. Verify webhook URLs are correct
3. Check function logs for notification errors
4. Ensure environment variables are set

### **If you're getting too many alerts:**
1. Adjust the timeout threshold (currently 30 seconds)
2. Modify the health check interval (currently 2 hours)
3. Disable specific notification channels

## ✅ Alert Verification Checklist

- [ ] Database logs show alert entries
- [ ] External notifications are working (if configured)
- [ ] Alert messages are informative
- [ ] Error details are captured
- [ ] Timestamps are accurate
- [ ] No duplicate alerts

Your alerts will help you monitor the health and performance of your daily content function! 