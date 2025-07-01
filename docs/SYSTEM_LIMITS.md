# OneAlarm System Limits Documentation

## 🎯 Overview

This document tracks the current system limits and capacity constraints for the OneAlarm platform.

## 📊 Current Limits

### **Supabase Pro Plan Limits**

**Confirmed Limits:**
- **Edge Function Invocations per month**: 2,000,000
- **Memory per function**: 256MB
- **CPU time per request**: 2 seconds maximum
- **Wall clock duration**: 400 seconds (6 minutes 40 seconds)
- **Idle timeout**: 150 seconds
- **Function size**: 20MB maximum
- **Function count**: 500 Edge Functions per project
- **Additional invocations**: $2 per million beyond quota

**Key Insight**: No concurrent execution limit - only CPU time and wall clock duration limits per function.

**Where to find these limits:**
- Supabase Dashboard → Settings → Billing → Plan details
- Supabase Documentation: https://supabase.com/docs/guides/platform/limits
- Account Settings → Usage & Billing

### **OpenAI API Limits**

#### **gpt-4o-mini (TTS)**
- **TPM (Tokens Per Minute): 600,000**
- **RPM (Requests Per Minute): 5,000**
- **Model**: `gpt-4o-mini-tts`
- **Concurrent requests**: 3 (configured in our system)

#### **GPT-4o (Content Generation)**
- **TPM**: 600,000
- **RPM**: 5,000
- **Model**: `gpt-4o`
- **Max tokens per request**: 1,200 (combined script)

### **Third-Party API Limits**

#### **NewsAPI.org**
- **Free Plan**: 1,000 requests per day
- **Developer Plan**: 10,000 requests per day
- **Current Usage**: ~30 requests per day (4 categories × ~7-8 executions)

#### **RapidAPI Yahoo Finance** ⭐ **OPTIMIZED**
- **Free Plan**: 10,000 requests per month (updated quota)
- **Basic Plan**: 5,000 requests per month ($9.99/month)
- **Pro Plan**: 25,000 requests per month ($49.99/month)
- **Ultra Plan**: 100,000 requests per month ($99.99/month)
- **Current Usage**: ~720 requests per month (7.2% of limit)
- **Optimization**: Single API call for all 25 symbols (25x improvement)

#### **TheSportsDB API**
- **Free Plan**: 100 requests per day
- **Current Usage**: ~30 requests per day

#### **Abstract API (Holidays)**
- **Free Plan**: 1,000 requests per month
- **Current Usage**: ~30 requests per month

## 🚀 Current System Capacity

### **Audio Generation Function (`generate-alarm-audio`)**

#### **Per Function Invocation**
- **Alarms processed**: 25 per invocation (batch processing)
- **Max concurrent alarms**: 50 per batch
- **TTS requests**: 2 per alarm (weather + content)
- **Concurrent TTS**: 3 max (configurable)
- **Execution timeout**: 5 minutes (within 400s limit)
- **Memory limit**: 256MB (within limit)
- **Lead time**: 58 minutes before alarm

#### **System Throughput**
- **Current cron frequency**: Every 1 minute
- **Max alarms per hour**: 1,500 (25 alarms × 60 invocations)
- **Max alarms per day**: 36,000
- **Concurrent users supported**: ~7,500-15,000 users
- **Queue Processing**: Audio is generated 58 minutes before the scheduled alarm time
- **Parallel Processing**: 50 alarms can be processed concurrently per batch

### **Daily Content Function (`daily-content`)**

#### **Per Function Invocation**
- **News API calls**: 4 (one per category: general, business, technology, sports)
- **Sports API calls**: 1
- **Stock API calls**: 1 (optimized - all 7 symbols in single call)
- **Holiday API calls**: 1
- **Total API calls**: 7 (down from 10 with stock optimization)
- **Execution time**: ~5-10 seconds
- **Memory usage**: ~50MB

#### **System Throughput**
- **Cron frequency**: Every hour at minute 3
- **Daily executions**: 24
- **Monthly API usage**:
  - NewsAPI: ~960 requests (24 × 4 categories)
  - RapidAPI: ~720 requests (24 × 1 call) ⭐ **25x improvement**
  - SportsDB: ~720 requests (24 × 30 days)
  - Abstract API: ~720 requests (24 × 30 days)

### **Processing Pipeline**

#### **Weather Audio Generation**
- **Duration**: ~30 seconds target
- **TTS time**: ~30-60 seconds
- **Storage size**: ~100-200KB per file

#### **Content Audio Generation**
- **Duration**: ~3-4 minutes target
- **TTS time**: ~2-3 minutes
- **Storage size**: ~1-2MB per file

## 📈 Capacity Calculations

### **Supabase Pro Plan Analysis**

#### **Monthly Invocation Capacity**
- **Limit**: 2,000,000 invocations per month
- **Current usage**: 36,000 invocations per day × 30 days = 1,080,000 per month
- **Utilization**: 54% of monthly limit
- **Headroom**: 46% remaining

#### **CPU Time Analysis**
- **Limit**: 2 seconds CPU time per request
- **Our usage**: Primarily I/O bound (API calls, storage)
- **CPU utilization**: Very low (mostly waiting for OpenAI APIs)
- **Headroom**: Significant CPU time available

#### **Wall Clock Duration Analysis**
- **Limit**: 400 seconds (6 minutes 40 seconds)
- **Current usage**: ~3-4 minutes per alarm
- **Headroom**: 2-3 minutes remaining per invocation

### **OpenAI Rate Limit Analysis**

#### **Per Alarm (2 TTS requests)**
- Weather TTS: ~1 minute
- Content TTS: ~2-3 minutes
- **Total TTS time per alarm**: ~3-4 minutes

#### **Hourly Capacity (OpenAI Limits)**
- **RPM limit**: 5,000 requests/minute
- **TPM limit**: 600,000 tokens/minute
- **Our usage**: 2 TTS requests per alarm
- **Theoretical max alarms/hour**: 150,000 (5,000 RPM × 60 minutes ÷ 2 requests)
- **Practical max alarms/hour**: Limited by processing time, not rate limits

#### **Processing Time Analysis**
- **TTS processing time**: ~3-4 minutes per alarm
- **Batch processing**: 25 alarms per function invocation
- **Concurrent processing**: 50 alarms per batch
- **Maximum concurrent alarms**: 50 alarms processing simultaneously
- **Hourly throughput**: 1,500 alarms/hour (25 alarms × 60 invocations)
- **Daily throughput**: 36,000 alarms/day

### **Storage Analysis**

#### **Per User Per Day**
- **Weather audio**: 2 files × 200KB = 400KB
- **Content audio**: 2 files × 1.5MB = 3MB
- **Total per user per day**: ~3.4MB

#### **System Storage (1000 users)**
- **Daily storage**: 3.4GB
- **Monthly storage**: ~100GB
- **48-hour retention**: Reduces storage by ~50%

## 🚨 Current Bottlenecks

### **Primary Bottlenecks**
1. **TTS Generation Time**: ~3-4 minutes per alarm (I/O bound)
2. **Function Timeout**: 400 seconds (6.67 minutes) per invocation
3. **Batch Size**: Currently limited to 25 alarms per invocation
4. **Concurrent Processing**: Limited to 50 alarms per batch

### **Secondary Bottlenecks**
1. **Storage Operations**: File upload time
2. **Database Operations**: Queue processing
3. **API Latency**: OpenAI response times

## 💡 Optimization Opportunities

### **Immediate (No Code Changes)**
- **Current cron frequency**: Already optimized to every 1 minute
- **No concurrent execution limit**: Can run unlimited functions simultaneously
- **Monitor Supabase Pro limits**: We're using 54% of monthly capacity

### **Short-term (Code Changes)**
- **Increase batch size**: Process 20-30 alarms per invocation (2-3x improvement)
- **Increase concurrent processing**: Process 100+ alarms per batch (2x improvement)
- **Optimize function execution time**: Reduce from 3-4 minutes to 2-3 minutes per alarm
- **Parallel TTS generation**: Already configured for 3 concurrent requests

### **Long-term (Architecture Changes)**
- **Microservices architecture**: Separate GPT, TTS, and storage services
- **CDN for audio distribution**: Reduce storage bandwidth
- **Caching and pre-generation**: Generate common audio patterns

## 📊 Maximum Theoretical Capacity

### **With Current Architecture (25 alarms per invocation, 50 concurrent)**
- **Batch processing**: 25 alarms per function invocation
- **Concurrent processing**: 50 alarms per batch
- **Processing time**: ~3-4 minutes per alarm
- **Maximum concurrent alarms**: 50 alarms processing simultaneously
- **Hourly capacity**: 1,500 alarms/hour (25 alarms × 60 invocations)
- **Daily capacity**: 36,000 alarms/day
- **User capacity**: ~7,500-15,000 users (assuming 1-2 alarms per user)

### **With Increased Batch Size (30 alarms per invocation)**
- **Batch processing**: 30 alarms per function invocation
- **Concurrent processing**: 50 alarms per batch
- **Processing time**: ~4-5 minutes per batch
- **Maximum concurrent alarms**: 50 alarms processing simultaneously
- **Hourly capacity**: 1,800 alarms/hour (30 alarms × 60 invocations)
- **Daily capacity**: 43,200 alarms/day
- **User capacity**: ~9,000-18,000 users

### **With Optimized Processing (2 minutes per alarm)**
- **Batch processing**: 10 alarms per function invocation
- **Concurrent processing**: 50 alarms per batch
- **Processing time**: ~2 minutes per alarm
- **Maximum concurrent alarms**: 50 alarms processing simultaneously
- **Hourly capacity**: 1,500 alarms/hour (50 alarms × 30 batches)
- **Daily capacity**: 36,000 alarms/day
- **User capacity**: ~7,500-15,000 users

## 📊 Monitoring Metrics

### **Key Performance Indicators**
- Function execution time
- TTS generation time
- Queue processing delay
- Storage usage
- Error rates
- OpenAI API usage
- Supabase invocation count
- CPU time utilization
- Memory usage

### **Alert Thresholds**
- Function timeout > 4 minutes
- Queue delay > 5 minutes
- Storage usage > 80%
- Error rate > 5%
- OpenAI rate limit hits
- Supabase invocations > 1.5M per month (75% of limit)
- CPU time > 1.5 seconds (75% of limit)
- Memory usage > 200MB (80% of limit)
- Batch processing delay > 10 minutes
- Concurrent processing utilization > 80%

## 🎯 Recent Optimizations

### **Stock API Optimization (June 2025)**
- **Before**: 25 separate API calls to RapidAPI Yahoo Finance
- **After**: 1 API call with all 25 symbols combined
- **Improvement**: 25x reduction in API calls
- **Impact**: 
  - Faster daily content generation
  - Lower RapidAPI usage (720 vs 18,000 requests/month)
  - Better reliability (fewer network calls)
  - Comprehensive market coverage (25 symbols across 6 sectors)
- **Quota Status**: 7.2% of 10,000 monthly limit (comfortably within free tier)

### **Multi-Category News Support**
- **Categories**: General, Business, Technology, Sports
- **Parallel Processing**: All categories fetched simultaneously
- **User Preferences**: Personalized news selection per user
- **Storage**: One row per category per day

- The backend only logs `audio_not_cached_in_time` for expiring alarm audio (with `expires_at` set).
- Persistent user-specific audio (the 29 general clips) are excluded from this log event and will not trigger caching warnings.

---

**Last Updated**: June 2025
**Supabase Pro Limits**: 2M invocations/month, 256MB memory, 2s CPU time, 400s wall clock
**Current Capacity**: ~7,500-15,000 users (1,500 alarms/hour, 36,000 alarms/day)
**Batch Processing**: 25 alarms per invocation, 50 concurrent per batch
**Cron Frequency**: Every 1 minute
**Stock API**: Optimized to 1 call for all 25 symbols (25x efficiency improvement)
**RapidAPI Quota**: 10,000 requests/month (7.2% current usage) 