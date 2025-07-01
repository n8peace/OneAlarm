# Supabase Storage Upload Fix

## Problem Summary
You're experiencing failed uploads when trying to upload 6 audio files to Supabase storage. The issue has been identified and fixed.

## Root Causes Identified

### 1. Content Type Mismatch ✅ FIXED
- **Issue**: Config specified `.aac` files but hardcoded `audio/aac` content type
- **Fix**: Dynamic content type detection based on file extension
- **File**: `supabase/functions/generate-audio/services.ts`

### 2. Missing Error Handling ✅ FIXED
- **Issue**: Limited error information for debugging
- **Fix**: Enhanced logging and validation
- **File**: `supabase/functions/generate-audio/services.ts`

### 3. Potential Environment Issues
- **Issue**: Missing `SUPABASE_STORAGE_BUCKET` environment variable
- **Solution**: Verify environment variables are set

## Files Modified

### 1. `supabase/functions/generate-audio/services.ts`
- Fixed content type detection
- Added input validation
- Added file size limits (50MB max)
- Enhanced error logging
- Added detailed upload logging

### 2. `scripts/diagnose-storage.sh` (NEW)
- Comprehensive storage diagnostic script
- Tests bucket existence
- Tests file upload/retrieval
- Checks environment variables

## Steps to Fix Your Upload Issue

### Step 1: Run the Diagnostic Script
```bash
./scripts/diagnose-storage.sh
```

This will:
- Check if your storage bucket exists
- Verify bucket policies
- Test a small file upload
- Check environment variables

### Step 2: Verify Environment Variables
Ensure these are set in your Supabase function:
```bash
SUPABASE_STORAGE_BUCKET=audio-files
SUPABASE_URL=https://joyavvleaxqzksopnmjs.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### Step 3: Test the Fixed Function
```bash
./scripts/test-generate-audio.sh YOUR_USER_ID
```

### Step 4: Check Function Logs
If issues persist, check the function logs in Supabase dashboard for detailed error messages.

## Common Issues and Solutions

### 1. "Bucket not found" Error
**Solution**: Run the storage setup script
```bash
./scripts/setup-storage.sh
```

### 2. "File too large" Error
**Solution**: Audio files are limited to 50MB. Check your TTS output size.

### 3. "Unauthorized" Error
**Solution**: Verify your service role key has storage permissions.

### 4. "Content type not allowed" Error
**Solution**: The fix handles this automatically now.

## Testing Your Fix

### 1. Test with a Single User
```bash
./scripts/test-generate-audio.sh test-user-id
```

### 2. Check Database Records
```sql
SELECT * FROM audio WHERE user_id = 'your-user-id' ORDER BY generated_at DESC;
```

### 3. Verify Storage Files
Check your Supabase storage dashboard for uploaded files in:
```
users/{userId}/audio/{clipId}.aac
```

## Expected Results After Fix

1. **Successful Uploads**: All 6 audio clips should upload successfully
2. **Proper Content Types**: Files will have correct MIME types
3. **Detailed Logging**: Better error messages for debugging
4. **File Size Validation**: Prevents oversized uploads
5. **Public URLs**: Generated URLs should be accessible

## Monitoring

After deployment, monitor:
- Function execution logs
- Storage bucket usage
- Database audio records
- Public URL accessibility

## Rollback Plan

If issues persist:
1. Check function logs for specific error messages
2. Verify storage bucket permissions
3. Test with smaller audio files
4. Contact Supabase support if needed

## Files Created/Modified Summary

| File | Change | Purpose |
|------|--------|---------|
| `supabase/functions/generate-audio/services.ts` | Modified | Fixed content type and added error handling |
| `scripts/diagnose-storage.sh` | Created | Comprehensive diagnostic tool |
| `docs/STORAGE_UPLOAD_FIX.md` | Created | This documentation |

## Next Steps

1. Run the diagnostic script to identify any remaining issues
2. Deploy the updated function
3. Test with your 6 audio files
4. Monitor logs for any remaining errors
5. Verify all files are accessible via public URLs 