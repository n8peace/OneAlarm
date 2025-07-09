# Quick Start: Main to Develop Synchronization

## 🚀 Fast Track (5 minutes)

### 1. Apply Database Schema
```bash
# Copy the SQL file content
cat scripts/main-to-develop-complete-sync.sql

# Paste into Supabase Dashboard SQL Editor and execute
```

### 2. Deploy Edge Functions
```bash
supabase link --project-ref xqkmpkfqoisqzznnvlox
supabase functions deploy --project-ref xqkmpkfqoisqzznnvlox
```

### 3. Set Environment Variables
In Supabase Dashboard → Settings → Edge Functions, add:
- `SUPABASE_URL`: https://xqkmpkfqoisqzznnvlox.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: [Your develop service role key]
- `OPENAI_API_KEY`: [Your OpenAI API key]
- `NEWSAPI_KEY`: [Your News API key]
- `SPORTSDB_API_KEY`: [Your Sports DB API key]
- `RAPIDAPI_KEY`: [Your RapidAPI key]
- `ABSTRACT_API_KEY`: [Your Abstract API key]

### 4. Test
```bash
./scripts/test-user-preferences-update.sh
```

## 📁 Files Generated
- `scripts/main-to-develop-complete-sync.sql` - Complete database sync
- `scripts/storage-sync-instructions.md` - Storage setup guide
- `scripts/deploy-instructions.md` - Detailed deployment guide
- `scripts/quick-start-sync.md` - This quick start guide

## ⚠️ Important Notes
- This will completely overwrite the develop environment
- The develop environment will have net extension dependency
- Apply the net extension fix if you want to avoid those issues
