# Development Environment Setup Guide

## 🚨 Critical: Environment Variables Required

The development environment functions are returning 500 errors because **environment variables are not set** in Supabase. This guide will help you set them up.

## 📋 Required Environment Variables

Based on the function code analysis, you need to set these environment variables in your **Supabase Development Project**:

### **Core Supabase Variables**
- `SUPABASE_URL` - Your development project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Your development project service role key

### **External API Keys**
- `OPENAI_API_KEY` - OpenAI API key for content generation
- `NEWSAPI_KEY` - News API key for news content
- `SPORTSDB_API_KEY` - Sports DB API key for sports data
- `RAPIDAPI_KEY` - RapidAPI key for stock data
- `ABSTRACT_API_KEY` - Abstract API key for holidays data

## 🔧 How to Set Environment Variables in Supabase

### **Step 1: Access Your Development Project**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your **development project** (not production)
3. Navigate to **Settings** → **Edge Functions**

### **Step 2: Set Environment Variables**
1. In the Edge Functions settings, find **"Environment variables"**
2. Click **"Add environment variable"**
3. Add each variable one by one:

#### **Variable 1: SUPABASE_URL**
- **Name**: `SUPABASE_URL`
- **Value**: `https://xqkmpkfqoisqzznnvlox.supabase.co` (your dev project URL)

#### **Variable 2: SUPABASE_SERVICE_ROLE_KEY**
- **Name**: `SUPABASE_SERVICE_ROLE_KEY`
- **Value**: Your development project service role key
- **To find this**: Go to Settings → API → Copy the "service_role" key

#### **Variable 3: OPENAI_API_KEY**
- **Name**: `OPENAI_API_KEY`
- **Value**: Your OpenAI API key
- **Get one**: https://platform.openai.com/api-keys

#### **Variable 4: NEWSAPI_KEY**
- **Name**: `NEWSAPI_KEY`
- **Value**: Your News API key
- **Get one**: https://newsapi.org/register

#### **Variable 5: SPORTSDB_API_KEY**
- **Name**: `SPORTSDB_API_KEY`
- **Value**: Your Sports DB API key
- **Get one**: https://www.thesportsdb.com/api.php

#### **Variable 6: RAPIDAPI_KEY**
- **Name**: `RAPIDAPI_KEY`
- **Value**: Your RapidAPI key
- **Get one**: https://rapidapi.com/

#### **Variable 7: ABSTRACT_API_KEY**
- **Name**: `ABSTRACT_API_KEY`
- **Value**: Your Abstract API key
- **Get one**: https://www.abstractapi.com/

### **Step 3: Save and Deploy**
1. Click **"Save"** after adding each variable
2. Go to **Edge Functions** → **daily-content**
3. Click **"Deploy"** to redeploy with new environment variables

## 🧪 Testing the Setup

### **Test 1: Check Environment Variables**
```bash
# Test the daily-content function
curl -X POST "https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/daily-content" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json"
```

### **Test 2: Check Function Logs**
1. Go to Supabase Dashboard → Edge Functions → daily-content
2. Click **"Logs"** to see if there are any errors
3. Look for environment variable validation errors

### **Test 3: Test All Functions**
```bash
# Test generate-audio function
curl -X POST "https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-audio" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test audio generation"}'

# Test generate-alarm-audio function
curl -X POST "https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-alarm-audio" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"alarm_id": "test-alarm-id"}'
```

## 🔍 Troubleshooting

### **Error: "Missing environment variables"**
- **Cause**: One or more required environment variables are not set
- **Solution**: Double-check all 7 variables are set in Supabase

### **Error: "Invalid API key"**
- **Cause**: API key is incorrect or expired
- **Solution**: Verify API key is valid and has proper permissions

### **Error: "Rate limit exceeded"**
- **Cause**: API usage limit reached
- **Solution**: Check API usage limits or upgrade plan

### **Function still returns 500 after setup**
- **Cause**: Environment variables not applied to deployed functions
- **Solution**: Redeploy the functions after setting environment variables

## 📊 Expected Results

After setting up environment variables correctly:

✅ **daily-content function**: Returns 200 with content data
✅ **generate-audio function**: Returns 200 with audio URL
✅ **generate-alarm-audio function**: Returns 200 with alarm audio URL
✅ **All triggers**: Work properly with 13 triggers active
✅ **No 500 errors**: Functions respond successfully

## 🔄 Next Steps

1. **Set all environment variables** in Supabase development project
2. **Redeploy functions** to apply the new environment variables
3. **Test each function** to ensure they work
4. **Verify triggers** are working properly
5. **Update documentation** once everything is working

## 📞 Need Help?

If you encounter issues:
1. Check the Supabase function logs for specific error messages
2. Verify all API keys are valid and active
3. Ensure you're setting variables in the correct project (development, not production)
4. Redeploy functions after setting environment variables 