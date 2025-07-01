# Duplicate Trigger Fix - Cascade Trigger Resolution

## Issue Summary

**Problem**: The `generate-audio` function was being called twice for each user preferences creation, causing duplicate audio generation and resource waste.

**Root Cause**: A cascade trigger effect where the `trigger_ensure_general_category` trigger was firing on both INSERT and UPDATE operations.

## Technical Details

### The Cascade Effect

1. **User preferences created** → INSERT trigger fires → calls generate-audio
2. **BEFORE INSERT trigger modifies record** → sets `news_categories = ARRAY['general']`
3. **UPDATE trigger fires** because record was modified → calls generate-audio again

### Original Problematic Trigger

```sql
-- This trigger was causing the cascade effect
CREATE TRIGGER trigger_ensure_general_category
  BEFORE INSERT OR UPDATE ON user_preferences  -- ❌ Fired on both INSERT and UPDATE
  FOR EACH ROW
  EXECUTE FUNCTION ensure_general_category();
```

### The Fix

**Migration**: `20250626030101_fix_cascade_trigger.sql`

```sql
-- Drop the existing trigger
DROP TRIGGER IF EXISTS trigger_ensure_general_category ON user_preferences;

-- Recreate the trigger to only fire on INSERT
CREATE TRIGGER trigger_ensure_general_category
  BEFORE INSERT ON user_preferences  -- ✅ Only fires on INSERT
  FOR EACH ROW
  EXECUTE FUNCTION ensure_general_category();
```

## Impact

### Before Fix
- ❌ Duplicate generate-audio function calls
- ❌ Duplicate audio file generation
- ❌ Wasted resources and processing time
- ❌ Confusing logs with duplicate entries

### After Fix
- ✅ Single generate-audio function call per user preferences creation
- ✅ Clean audio generation process
- ✅ Optimized resource usage
- ✅ Clear, non-duplicate logs

## Verification

### Test Results
- **Before**: Each user got 2 generate-audio calls (within seconds of each other)
- **After**: Each user gets exactly 1 generate-audio call

### Log Evidence
**Before Fix:**
```
05:28:58.523 - audio_generation_completed
05:28:58.553 - function_completed
05:29:01.363 - audio_generation_completed  (duplicate!)
05:29:01.4   - function_completed          (duplicate!)
```

**After Fix:**
```
05:30:57.695358 - preferences_updated_audio_trigger (single trigger)
05:31:17.885 - audio_generation_completed
05:31:17.939 - function_completed
```

## Related Files

- **Migration**: `supabase/migrations/20250626030101_fix_cascade_trigger.sql`
- **Fix Script**: `scripts/apply-cascade-fix.sh`
- **Test Script**: `scripts/create-test-user.sh`

## Prevention

To prevent similar issues in the future:

1. **Review trigger logic** - Ensure triggers don't cause cascade effects
2. **Test thoroughly** - Always test trigger behavior with real data
3. **Monitor logs** - Watch for duplicate function calls
4. **Use BEFORE INSERT ONLY** - When triggers modify data, avoid UPDATE triggers

## Status

✅ **RESOLVED** - The duplicate generate-audio function calls issue has been completely resolved. 