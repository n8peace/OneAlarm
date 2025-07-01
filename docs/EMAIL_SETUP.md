# Email Notification Setup Guide

## 📧 Email Service Options

### **Option 1: SendGrid (Recommended - Easy Setup)**

#### **Step 1: Create SendGrid Account**
1. Go to [SendGrid.com](https://sendgrid.com)
2. Sign up for a free account (100 emails/day free)
3. Verify your email address

#### **Step 2: Get API Key**
1. Go to **Settings → API Keys**
2. Click **Create API Key**
3. Choose **Restricted Access** → **Mail Send**
4. Copy the API key

#### **Step 3: Configure Supabase**
```bash
# Set your email address
supabase secrets set ALERT_EMAIL="your-email@example.com"

# Set SendGrid API key
supabase secrets set SENDGRID_API_KEY="SG.your-sendgrid-api-key-here"
```

#### **Step 4: Deploy Updated Function**
```bash
supabase functions deploy daily-content
```

### **Option 2: AWS SES (Advanced - More Control)**

#### **Step 1: AWS SES Setup**
1. Go to AWS Console → SES
2. Verify your email address
3. Create SMTP credentials
4. Get your SMTP settings

#### **Step 2: Configure Supabase**
```bash
supabase secrets set ALERT_EMAIL="your-email@example.com"
supabase secrets set AWS_SES_ACCESS_KEY="your-access-key"
supabase secrets set AWS_SES_SECRET_KEY="your-secret-key"
supabase secrets set AWS_SES_REGION="us-east-1"
```

### **Option 3: Resend (Modern Alternative)**

#### **Step 1: Create Resend Account**
1. Go to [Resend.com](https://resend.com)
2. Sign up for free account (3,000 emails/month free)
3. Verify your domain or email

#### **Step 2: Get API Key**
1. Go to **API Keys** section
2. Create new API key
3. Copy the key

#### **Step 3: Configure Supabase**
```bash
supabase secrets set ALERT_EMAIL="your-email@example.com"
supabase secrets set RESEND_API_KEY="re_your-resend-api-key"
```

## 🔧 Alternative: Simple Webhook to Email Service

If you prefer not to set up a full email service, you can use a webhook-to-email service:

### **Option A: IFTTT (If This Then That)**
1. Create IFTTT account
2. Create applet: **Webhook → Email**
3. Get your webhook URL
4. Set it as notification webhook:
   ```bash
   supabase secrets set NOTIFICATION_WEBHOOK_URL="https://maker.ifttt.com/trigger/your-event/with/key/your-key"
   ```

### **Option B: Zapier**
1. Create Zapier account
2. Create zap: **Webhook → Email**
3. Get your webhook URL
4. Set it as notification webhook

### **Option C: Make.com (Integromat)**
1. Create Make.com account
2. Create scenario: **Webhook → Email**
3. Get your webhook URL
4. Set it as notification webhook

## 📋 Quick Setup Commands

### **For SendGrid (Recommended):**
```bash
# 1. Set your email
supabase secrets set ALERT_EMAIL="your-email@example.com"

# 2. Set SendGrid API key
supabase secrets set SENDGRID_API_KEY="SG.your-key-here"

# 3. Deploy the function
supabase functions deploy daily-content

# 4. Test it
curl -X POST https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/daily-content \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

### **For Webhook-to-Email:**
```bash
# 1. Set webhook URL (IFTTT, Zapier, etc.)
supabase secrets set NOTIFICATION_WEBHOOK_URL="https://your-webhook-url.com"

# 2. Deploy the function
supabase functions deploy daily-content
```

## 🧪 Testing Email Notifications

### **Test Function Failure:**
1. Temporarily break your function (e.g., wrong API key)
2. Run the function manually
3. Check your email for failure alert

### **Test Timeout Alert:**
1. The function will automatically alert if it takes >30 seconds
2. You can test this by adding a delay in your function

### **Test Success Notification:**
1. Run the function successfully
2. Check your email for success notification

## 📧 Email Alert Examples

### **Function Failure Alert:**
```
Subject: 🚨 OneAlarm Alert: ❌ Daily content collection failed after 15000ms

Body:
🚨 OneAlarm Alert

Function: daily-content
Message: ❌ Daily content collection failed after 15000ms
Time: 2024-01-01T12:00:00Z
Environment: production

Details:
{
  "executionTime": 15000,
  "error": "API timeout",
  "stack": "Error: Request timeout..."
}
```

### **Timeout Alert:**
```
Subject: 🚨 OneAlarm Alert: ⏰ Daily content collection took too long: 45000ms

Body:
🚨 OneAlarm Alert

Function: daily-content
Message: ⏰ Daily content collection took too long: 45000ms
Time: 2024-01-01T12:00:00Z
Environment: production

Details:
{
  "executionTime": 45000
}
```

### **Success Notification:**
```
Subject: 🚨 OneAlarm Alert: ✅ Daily content collection completed successfully in 8500ms

Body:
🚨 OneAlarm Alert

Function: daily-content
Message: ✅ Daily content collection completed successfully in 8500ms
Time: 2024-01-01T12:00:00Z
Environment: production

Details:
{
  "executionTime": 8500
}
```

## 🔍 Troubleshooting

### **Email Not Sending:**
1. Check API keys are set correctly
2. Verify email address is valid
3. Check function logs for email errors
4. Ensure email service account is active

### **Spam/Junk Folder:**
1. Add alerts@onealarm.com to your contacts
2. Check spam/junk folder
3. Verify your email service settings

### **Too Many Emails:**
1. Adjust notification settings in config
2. Disable success notifications if desired
3. Increase timeout threshold

## ✅ Verification Checklist

- [ ] Email service account created
- [ ] API keys configured in Supabase
- [ ] Function deployed with email support
- [ ] Test email received
- [ ] Alert emails are formatted correctly
- [ ] No email errors in function logs

## 💰 Cost Comparison

| Service | Free Tier | Paid Plans |
|---------|-----------|------------|
| SendGrid | 100 emails/day | $14.95/month for 50k emails |
| Resend | 3,000 emails/month | $20/month for 50k emails |
| AWS SES | 62,000 emails/month | $0.10 per 1,000 emails |
| IFTTT | 5 applets free | $5/month for unlimited |

**Recommendation:** Start with SendGrid (100 free emails/day is plenty for alerts) or IFTTT (simple webhook setup). 