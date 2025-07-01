# Cleanup Audio Files Edge Function

This Edge Function automatically cleans up expired audio files from both the database and Supabase Storage.

## Overview

The function removes audio files that have exceeded their 48-hour expiration period, helping to manage storage costs and maintain database performance.

## Features

- **Automatic Cleanup**: Removes expired audio files from database and storage
- **48-Hour Expiration**: Respects the configured 48-hour expiration period
- **Dual Cleanup**: Deletes both database records and storage files
- **Error Handling**: Graceful handling of storage deletion failures
- **Health Check**: GET endpoint for monitoring function health
- **Comprehensive Logging**: Detailed logging for monitoring and debugging

## API Endpoints

### Health Check
```
GET /functions/v1/cleanup-audio-files
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "version": "1.0.0",
  "function": "cleanup-audio-files"
}
```

### Cleanup Execution
```
POST /functions/v1/cleanup-audio-files
```

**Response:**
```json
{
  "success": true,
  "message": "Cleanup completed: 5 database records deleted, 4 storage files deleted",
  "result": {
    "databaseRecordsDeleted": 5,
    "storageFilesDeleted": 4,
    "errors": ["Failed to delete storage file alarm-audio/weather/file1.aac: File not found"],
    "success": true
  },
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## How It Works

### 1. Find Expired Files
- Queries the `audio` table for records where `expires_at < now()`
- Only processes records with valid `audio_url` values

### 2. Delete Storage Files
- Extracts file paths from audio URLs
- Deletes files from Supabase Storage bucket `audio-files`
- Handles errors gracefully and continues with other files

### 3. Delete Database Records
- Removes all expired records from the `audio` table
- Uses the same expiration criteria as step 1

### 4. Report Results
- Returns detailed statistics on what was cleaned up
- Includes any errors encountered during storage deletion

## Configuration

### Environment Variables
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for database and storage access

### Storage Bucket
- **Bucket Name**: `audio-files`
- **File Structure**: `alarm-audio/{weather|content}/{filename}.aac`

## Error Handling

### Storage Deletion Failures
- If a storage file can't be deleted (e.g., already deleted), the error is logged but doesn't stop the process
- Database records are still deleted even if storage cleanup fails
- All errors are returned in the response for monitoring

### Database Errors
- Database errors will cause the entire cleanup to fail
- Detailed error messages are returned in the response

## Monitoring

### Logs
The function logs all operations to the `logs` table:
- `cleanup_audio_files_started`: When cleanup begins
- `cleanup_audio_files_completed`: When cleanup finishes successfully
- `cleanup_audio_files_failed`: When cleanup encounters errors

### Metrics
Track these metrics for monitoring:
- Number of database records deleted
- Number of storage files deleted
- Number of errors encountered
- Execution time

## Usage

### Manual Execution
```bash
curl -X POST "https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/cleanup-audio-files" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

### Automated Execution
Set up a cron job to run this function every hour:
```bash
# Cron schedule: Every hour
0 * * * * curl -X POST "https://joyavvleaxqzksopnmjs.supabase.co/functions/v1/cleanup-audio-files" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

## Security

- Requires service role key for authentication
- Only deletes expired files (respects 48-hour expiration)
- Validates file paths before deletion
- Comprehensive error logging for audit trails

## Performance

- Processes files in batches to avoid timeouts
- Uses database indexes for efficient queries
- Minimal impact on system performance
- Designed to run quickly (typically < 30 seconds)

## Troubleshooting

### Common Issues

1. **No files deleted**: Check if files have actually expired (48 hours)
2. **Storage deletion errors**: Files may have been manually deleted
3. **Database errors**: Check service role key and permissions
4. **Timeout errors**: Reduce batch size or increase function timeout

### Debugging

1. Check function logs in Supabase dashboard
2. Review the `logs` table for cleanup events
3. Verify expiration timestamps in the `audio` table
4. Test with a small number of expired files first 