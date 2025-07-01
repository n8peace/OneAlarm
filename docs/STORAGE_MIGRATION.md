# Storage Migration: S3 to Supabase Storage

## Overview
This document outlines the migration from AWS S3 to Supabase Storage for audio file storage in the OneAlarm application.

## Changes Made

### 1. Service Layer Changes
- **File**: `supabase/functions/generate-audio/services.ts`
- **Change**: Replaced `S3Service` with `SupabaseStorageService`
- **Key Updates**:
  - Uses Supabase client for storage operations
  - Implements real upload functionality (no more mock)
  - Generates public URLs for uploaded files
  - Includes proper error handling

### 2. Configuration Updates
- **File**: `supabase/functions/generate-audio/config.ts`
- **Change**: Replaced S3 configuration with Supabase Storage configuration
- **New Settings**:
  ```typescript
  storage: {
    bucket: Deno.env.get('SUPABASE_STORAGE_BUCKET') || 'audio-files',
    pathPrefix: 'users',
    audioFolder: 'audio',
    fileExtension: 'mp3'
  }
  ```

### 3. Type Definitions
- **File**: `supabase/functions/generate-audio/types.ts`
- **Changes**:
  - `AudioGenerationResponse.s3BaseUrl` → `storageBaseUrl`
  - `GeneratedClip.s3Url` → `audioUrl`

### 4. API Response Updates
- **File**: `supabase/functions/generate-audio/index.ts`
- **Change**: Updated response structure to use storage configuration

### 5. Documentation Updates
- **File**: `supabase/functions/generate-audio/README.md`
- **Changes**:
  - Updated environment variables
  - Updated file structure examples
  - Updated response format examples
  - Changed references from S3 to Supabase Storage

### 6. Test Script Updates
- **File**: `scripts/test-audio-final.sh`
- **Change**: Updated comments to reference Supabase Storage

### 7. New Setup Script
- **File**: `scripts/setup-storage.sh`
- **Purpose**: Creates Supabase Storage bucket and sets up public access policies

## Environment Variables

### Removed (S3)
- `S3_BUCKET_NAME`
- `S3_REGION`
- `S3_BASE_URL`

### Added (Supabase Storage)
- `SUPABASE_STORAGE_BUCKET` (default: 'audio-files')

## File Structure
Files are stored in Supabase Storage with the same structure:
```
users/{userId}/audio/{clipId}.mp3
```

## Benefits of Migration

1. **Simplified Architecture**: No need for AWS SDK or S3 configuration
2. **Better Integration**: Native Supabase integration
3. **Cost Effective**: Supabase Storage is more cost-effective for this scale
4. **Easier Management**: Single platform for database and storage
5. **Real Implementation**: Replaces mock S3 implementation with actual functionality

## Setup Instructions

1. **Create Storage Bucket**:
   ```bash
   ./scripts/setup-storage.sh
   ```

2. **Set Environment Variable**:
   ```bash
   export SUPABASE_STORAGE_BUCKET=audio-files
   ```

3. **Test the Implementation**:
   ```bash
   ./scripts/test-audio-final.sh
   ```

## Migration Notes

- All existing database records with S3 URLs will need to be updated
- The new implementation generates real public URLs
- File uploads now actually work (no more mock implementation)
- Storage bucket must be created before first use
- Public read access is enabled for audio files

## Testing

After migration, test the following:
1. Audio file generation
2. File upload to Supabase Storage
3. Public URL accessibility
4. Database record creation
5. Error handling for upload failures 