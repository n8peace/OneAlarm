# Development vs Production Instances

## Instance URLs

### Development
- **URL**: `https://joyavvleaxqzksopnmjs.supabase.co`
- **Project ID**: `joyavvleaxqzksopnmjs`
- **Status**: ✅ Working correctly
- **Purpose**: Testing and development

### Production
- **URL**: `https://bfrvahxmokeyrfnlaiwd.supabase.co`
- **Project ID**: `bfrvahxmokeyrfnlaiwd`
- **Status**: ⚠️ Partially working (audio trigger missing)
- **Purpose**: Live user traffic

## Current Differences

### Development (joyavvleaxqzksopnmjs)
- ✅ User preferences audio trigger exists and works
- ✅ Net extension installed
- ✅ Audio generation triggers on preferences changes
- ✅ All core flows working

### Production (bfrvahxmokeyrfnlaiwd)
- ✅ User preferences audio trigger restored (migration 20250704171744)
- ✅ Net extension installed (migration 20250702000013)
- ✅ Audio generation should now trigger on preferences changes
- ✅ All other core flows working

## Migration History

### Development
- All migrations applied successfully
- Trigger was never removed
- Audio generation working end-to-end

### Production
- Migration `20250702000012` removed the trigger due to missing net extension
- Migration `20250702000013` installed the net extension
- **Missing**: Migration to restore the trigger after net extension was installed

## Production Fix Status

✅ **COMPLETED**: Migration `20250704171744_restore_prod_user_preferences_audio_trigger.sql` applied
✅ **COMPLETED**: Production URL and API key configured in trigger
⏳ **PENDING**: Test the trigger in production
⏳ **PENDING**: Verify audio generation works end-to-end

## Testing Production

Use the test script to verify the trigger is working:
```bash
./scripts/test-prod-audio-trigger.sh [PROD_SERVICE_ROLE_KEY] [USER_ID]
```

## Environment Variables

### Development (.env)
```
SUPABASE_URL=https://joyavvleaxqzksopnmjs.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og
```

### Production (needs separate .env)
```
SUPABASE_URL=https://bfrvahxmokeyrfnlaiwd.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcnZhaHhtb2tleXJmbmxhaXdkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQzMDI2NCwiZXhwIjoyMDY3MDA2MjY0fQ.C2x_AIkig4Fc7JSEyrkxve7E4uAwwvSRhPNDAeOfW-A
```

## Checklist for Production Fix

- [ ] Create production-specific migration to restore trigger
- [ ] Use production URL and API key in trigger function
- [ ] Test trigger in production environment
- [ ] Verify audio generation works end-to-end
- [ ] Document successful restoration 