# Connecting to Supabase

This guide provides a streamlined process to connect your local development environment to the OneAlarm Supabase project.

## 🚀 Quick Start (2-Minute Setup)

**If you're setting up for the first time or reconnecting:**

```bash
# 1. Check if Supabase CLI is installed
which supabase

# 2. Link to the project (do this ONCE in your project root)
supabase link --project-ref joyavvleaxqzksopnmjs

# 3. Set up environment variables (if .env doesn't exist)
cp .env.example .env  # or create manually

# 4. Verify connection
supabase functions list
supabase migration list

# 5. Run migration validation (CRITICAL STEP)
bash scripts/validate-migrations-connection.sh

# 6. Test system status
bash scripts/check-system-status.sh
```

**Expected Results:**
- ✅ Functions show as ACTIVE
- ✅ Migrations show as synced (Local | Remote)
- ✅ Migration validation passes (SAFE TO PROCEED)
- ✅ System status check passes

## 📋 Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- Access to the OneAlarm project dashboard
- Environment variables configured (see below)

## 🔧 Environment Variables Setup

### Option 1: Use Existing .env File (Recommended)
The project already includes a `.env` file with the correct keys:

```bash
# Source the environment variables
source .env

# Verify they're loaded
echo $SUPABASE_URL
echo $SUPABASE_SERVICE_ROLE_KEY
```

### Option 2: Create New .env File
If `.env` doesn't exist, create it with:

```bash
# Supabase Configuration
SUPABASE_URL=https://joyavvleaxqzksopnmjs.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxOTA3NjUsImV4cCI6MjA2NTc2Njc2NX0.LgCoghiKkmVzXMxHyNy6Xzzevmhq5DDEmJevm75M
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og
```

## 🔗 Project Linking

### Step 1: Link to Project
```bash
supabase link --project-ref joyavvleaxqzksopnmjs
```

**What happens:**
- Connects to remote database
- Sets up migration tracking
- May show Docker warnings (ignore for remote-only development)

### Step 2: Verify Connection
```bash
# Check functions status
supabase functions list

# Check migration sync
supabase migration list

# Test database access
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/users?select=count" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

## ✅ Connection Verification

### 🚨 CRITICAL: Migration Validation
**Always run this before making any database changes:**

```bash
# Run comprehensive migration validation
bash scripts/validate-migrations-connection.sh
```

**Expected Output:**
```
🔍 Migration Validation for Connection
=============================================

1. Checking migration sync status...
✅ Migration tracking is active
   Local migrations: 14
   Synced migrations: 14
✅ All migrations are in sync

2. Checking function deployment status...
✅ Functions are deployed and active
   Active functions: 5/6

3. Validating database connectivity...
✅ Database connectivity confirmed

4. Checking key tables...
✅ Users table accessible (396 users)
✅ Alarms table accessible (544 alarms)

5. Checking recent system activity...
✅ System logs accessible
   Recent activity detected

🎉 Migration Validation Complete
=====================================
✅ Connection Status: SAFE TO PROCEED
```

**If validation fails:**
- **DO NOT proceed** with database changes
- Follow the repair instructions provided by the script
- Contact the team if you need help resolving migration issues

### Quick Health Check
```bash
# Test function health
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-alarm-audio" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"

# Expected response:
# {"status":"healthy","timestamp":"2025-06-29T06:00:41.627Z","function":"generate-alarm-audio"}
```

### System Status Check
```bash
# Run comprehensive system check
bash scripts/check-system-status.sh
```

**Expected Results:**
- ✅ All functions ACTIVE
- ✅ Queue processing working
- ✅ Database tables accessible
- ✅ Environment variables set
- ✅ Storage bucket configured

## 🗄️ Database Status

### Current System State (June 2025)
- **Users**: 396+ active users
- **Alarms**: 544+ configured alarms
- **Audio Files**: 7,232+ generated files
- **Queue Items**: 340+ pending tasks
- **Functions**: All 5 functions ACTIVE
- **Migrations**: 14 migrations in sync

### Key Tables
```bash
# Check table counts
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/users?select=count" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"

curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/alarms?select=count" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

## 🚀 Development Commands

### Function Management
```bash
# Deploy specific function
supabase functions deploy daily-content
supabase functions deploy generate-audio
supabase functions deploy generate-alarm-audio

# Deploy all functions
supabase functions deploy

# View function logs
supabase functions logs daily-content
supabase functions logs generate-audio
```

### Database Operations
```bash
# IMPORTANT: Always run migration validation first
bash scripts/validate-migrations-connection.sh

# Apply migrations (only if validation passes)
supabase db push

# Check migration status
supabase migration list

# Repair migration tracking (if needed)
supabase migration repair --status applied <migration_id>
```

### Testing
```bash
# Create test user
bash scripts/create-test-user.sh

# Test audio generation
bash scripts/test-generate-audio.sh <USER_ID>

# End-to-end test
bash scripts/test-system.sh e2e
```

## 🔍 Troubleshooting

### Common Issues & Quick Fixes

**1. Migration validation fails**
```bash
# Check migration status
supabase migration list

# If migrations are out of sync, DO NOT run db push
# Instead, repair the tracking:
supabase migration repair --status applied <migration_id>

# Re-run validation
bash scripts/validate-migrations-connection.sh
```

**2. "Invalid API key" errors**
```bash
# Ensure both headers are set
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/users?select=count" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

**3. Migration tracking out of sync**
```bash
# Check current status
supabase migration list

# Repair if needed (DO NOT run db push first!)
supabase migration repair --status applied <migration_id>
```

**4. Docker errors**
- **Ignore Docker errors** for remote-only development
- Local Docker is only needed for local database development

**5. Function health check fails**
```bash
# Check if functions are deployed
supabase functions list

# Redeploy if needed
supabase functions deploy <function-name>
```

**6. Environment variables not found**
```bash
# Export manually
export SUPABASE_URL="https://joyavvleaxqzksopnmjs.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# Or source .env file
source .env
```

## 📊 Monitoring & Status

### Real-time Monitoring
- **Dashboard**: https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs
- **Functions**: https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs/functions
- **Database**: https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs/editor
- **Storage**: https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs/storage

### System Health Indicators
```bash
# Check recent activity
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/logs?select=event_type,created_at&order=created_at.desc&limit=5" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"

# Check queue status
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/generate-alarm-audio" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{}'
```

## 🎯 Production Status

### ✅ Fully Operational (June 2025)
- **All Functions**: Deployed and active
- **Database**: Optimized and populated
- **Storage**: Configured with proper policies
- **Monitoring**: Comprehensive logging active
- **Queue Processing**: Running every minute
- **Daily Content**: Generating for all 4 news categories

### Key Features Verified
- ✅ Multi-category news system (general, business, technology, sports)
- ✅ Timezone-aware alarm scheduling
- ✅ Queue-based audio processing (25 alarms per batch)
- ✅ Generic audio files (48 pre-generated files)
- ✅ Real-time subscriptions for SwiftUI

## 📚 Quick Reference

### Essential Commands
```bash
# Link project
supabase link --project-ref joyavvleaxqzksopnmjs

# Check status
supabase functions list && supabase migration list

# CRITICAL: Validate migrations before any changes
bash scripts/validate-migrations-connection.sh

# Deploy functions
supabase functions deploy daily-content

# Test system
bash scripts/check-system-status.sh
```

### Project Information
- **Project ID**: `joyavvleaxqzksopnmjs`
- **URL**: https://joyavvleaxqzksopnmjs.supabase.co
- **Dashboard**: https://supabase.com/dashboard/project/joyavvleaxqzksopnmjs

### Support Resources
- [Supabase CLI Docs](https://supabase.com/docs/guides/cli)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Database Migrations](https://supabase.com/docs/guides/cli/migrations)

---

## 🛠️ Migration Sync & Repair (2025 Update)

**Production-Safe Migration Management:**
- If your environments are already in sync but migration tracking is not, use:
  ```bash
  supabase migration repair --status applied <migration_id>
  ```
  to mark migrations as applied without running them.
- This is the preferred approach for keeping develop and main in sync when the schema is already correct.

**Manual SQL Execution (if needed):**
- If a migration is marked as applied but the SQL was not executed (e.g., table still exists), manually run the migration SQL in the Supabase dashboard.
- Example: If `audio_files` table removal migration was marked as applied but the table still exists, copy the SQL from `supabase/migrations/20250709000001_remove_audio_files_table.sql` and run it in the SQL editor for your main project.

**Summary:**
- Never reset production or re-run all migrations if the schema is already correct.
- Use migration repair for tracking, and manual SQL for any missed changes.
- This ensures safe, production-grade schema management with CI/CD.

**🎉 You're now connected and ready to develop!**

The OneAlarm system is fully operational and ready for production use. All functions are active, the database is optimized, and monitoring is in place.

**⚠️ Remember: Always run `bash scripts/validate-migrations-connection.sh` before making any database changes!** 