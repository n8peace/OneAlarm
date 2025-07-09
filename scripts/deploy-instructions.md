# Complete Main to Develop Deployment Instructions

## Prerequisites
- Access to Supabase Dashboard for both main and develop projects
- Supabase CLI installed (optional, for edge functions)

## Step-by-Step Deployment

### 1. Apply Database Schema
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your **develop** project
3. Navigate to SQL Editor
4. Copy and paste the contents of `scripts/main-to-develop-complete-sync.sql`
5. Execute the migration
6. Verify all tables, functions, and triggers are created

### 2. Deploy Edge Functions
```bash
# Link to develop project
supabase link --project-ref xqkmpkfqoisqzznnvlox

# Deploy all functions
supabase functions deploy --project-ref xqkmpkfqoisqzznnvlox
```

### 3. Configure Storage
Follow the instructions in `scripts/storage-sync-instructions.md`

### 4. Set Environment Variables
In Supabase Dashboard → Settings → Edge Functions:
- `SUPABASE_URL`: https://xqkmpkfqoisqzznnvlox.supabase.co
- `SUPABASE_SERVICE_ROLE_KEY`: [Your develop service role key]
- `OPENAI_API_KEY`: [Your OpenAI API key]
- `NEWSAPI_KEY`: [Your News API key]
- `SPORTSDB_API_KEY`: [Your Sports DB API key]
- `RAPIDAPI_KEY`: [Your RapidAPI key]
- `ABSTRACT_API_KEY`: [Your Abstract API key]

### 5. Test the Deployment
```bash
# Test user preferences
./scripts/test-user-preferences-update.sh

# Test system functionality
./scripts/test-system-develop.sh
```

## Verification Checklist

- [ ] All tables created successfully
- [ ] All functions deployed
- [ ] All triggers working
- [ ] RLS policies applied
- [ ] Storage buckets configured
- [ ] Environment variables set
- [ ] Edge functions deployed
- [ ] Basic functionality tested

## Troubleshooting

### Net Extension Error
If you get "schema 'net' does not exist" errors:
1. Apply the fix migration: `supabase/migrations/20250707000010_fix_develop_net_extension_final.sql`
2. This removes net extension dependencies for develop environment

### Function Deployment Issues
1. Check environment variables are set
2. Verify Supabase CLI is linked to correct project
3. Check function logs in Supabase Dashboard

### Storage Issues
1. Verify bucket names match exactly
2. Check bucket policies
3. Test file uploads manually
