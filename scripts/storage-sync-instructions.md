# Storage Synchronization Instructions

## Overview
Storage buckets and files need to be synchronized manually between environments.

## Steps to Sync Storage

### 1. Access Supabase Dashboard
- Go to [Supabase Dashboard](https://supabase.com/dashboard)
- Select your **main** project first
- Navigate to Storage

### 2. Export Storage from Main
- Go to Storage → Buckets
- Note down all bucket names and configurations
- For each bucket, download important files if needed

### 3. Configure Storage in Develop
- Switch to your **develop** project
- Go to Storage → Buckets
- Create the same buckets with identical configurations:
  - `audio-files` (public bucket)
  - `background-audio` (public bucket)
  - Any other buckets from main

### 4. Copy Files (if needed)
- Upload important files from main to develop
- This is optional for development environment

### 5. Verify Storage Configuration
- Test file uploads in develop
- Verify bucket policies match main

## Bucket Configurations

### audio-files bucket
- **Public bucket**: Yes
- **File size limit**: 50MB
- **Allowed MIME types**: audio/*

### background-audio bucket
- **Public bucket**: Yes
- **File size limit**: 50MB
- **Allowed MIME types**: audio/*

## Storage Policies
The RLS policies for storage will be created automatically when you create the buckets.
