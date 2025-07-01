# Verification Guide - How to Check if Your Cron Job is Working

## 🔍 Step-by-Step Verification

### **Step 1: Check Cron Jobs are Set Up**

1. **Go to Supabase Dashboard:**
   ```
   https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs
   ```

2. **Open SQL Editor** and run the contents of `check-cron-status.sql`

3. **Expected Results:**
   - You should see 2 cron jobs: `daily-content-hourly` and `daily-content-health-check`
   - Both should show `active = true`
   - `next_run` should show the next scheduled time

### **Step 2: Check Function Execution Logs**

1. **In SQL Editor**, run the contents of `check-function-logs.sql`

2. **Expected Results:**
   - Recent entries with `event_type = 'daily_content_function_started'`
   - Status should be `success` for completed runs
   - Execution times should be reasonable (under 30 seconds)

### **Step 3: Check Supabase Dashboard Logs**

1. **Go to Logs tab** in your Supabase dashboard
2. **Look for:**
   - Function invocations
   - Any error messages
   - Execution times

### **Step 4: Check Daily Content Data**

1. **In SQL Editor**, run:
   ```sql
   SELECT * FROM daily_content 
   ORDER BY date DESC 
   LIMIT 5;
   ```

2. **Expected Results:**
   - Recent entries with today's date
   - News, sports, and stocks summaries populated

### **Step 5: Manual Function Test**

1. **Get your API key:**
   - Go to Settings → API in Supabase dashboard
   - Copy the `anon` public key

2. **Test the function:**
   ```bash
   curl -X POST https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/daily-content \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -d '{}'
   ```

3. **Expected Response:**
   ```
   ✅ Daily content collected successfully!
   ```

## 📊 What to Look For

### **✅ Success Indicators:**

1. **Cron Jobs Active:**
   - `daily-content-hourly` shows `active = true`
   - `next_run` shows future time
   - No error messages in cron.job table

2. **Function Executing:**
   - Log entries with `daily_content_function_started`
   - Status `success` in recent runs
   - Reasonable execution times (< 30 seconds)

3. **Data Being Collected:**
   - New entries in `daily_content` table
   - News, sports, and stocks summaries populated
   - Recent dates in the data

4. **Health Monitoring:**
   - `daily-content-health-check` cron job active
   - No health alert entries (unless there's an actual problem)

### **❌ Problem Indicators:**

1. **Cron Jobs Not Running:**
   - No entries in `cron.job` table
   - `active = false` for your jobs
   - Error messages in cron setup

2. **Function Failing:**
   - Status `error` in logs
   - Error messages in function logs
   - No recent successful executions

3. **No Data:**
   - Empty `daily_content` table
   - Old dates in data
   - Missing summaries

## 🕐 Timing Expectations

### **When to Expect Runs:**
- **Every hour at 3 minutes past the hour**
- **Examples:** 1:03, 2:03, 3:03, 4:03, etc.
- **Health check every 30 minutes**

### **How Long to Wait:**
- **First run:** Should happen at the next hour mark
- **If you just set it up:** Wait until the next :03 minute
- **Verification:** Check logs 5-10 minutes after expected run time

## 🚨 Troubleshooting

### **If Cron Jobs Don't Show Up:**
1. Re-run the `setup-cron-manually.sql` script
2. Check if `pg_cron` extension is enabled
3. Verify you have proper database permissions

### **If Function Isn't Running:**
1. Check function deployment status
2. Verify the function URL in cron job
3. Check function logs for errors

### **If No Data is Collected:**
1. Check API keys in environment variables
2. Verify external APIs are accessible
3. Check function logs for API errors

## 📈 Monitoring Dashboard

Once everything is working, you can monitor:

- **Supabase Dashboard → Functions → daily-content**
- **Supabase Dashboard → Logs**
- **Database → Tables → logs** (for detailed execution history)
- **Database → Extensions → pg_cron** (for cron job status)

## ✅ Success Checklist

- [ ] Cron jobs appear in `cron.job` table
- [ ] Function executes successfully (check logs)
- [ ] Data is collected and stored
- [ ] Health monitoring is active
- [ ] No error messages in logs
- [ ] Execution times are reasonable

Your cron job is working when you see regular, successful function executions in your logs at the expected times! 