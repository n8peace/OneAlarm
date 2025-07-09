#!/bin/bash

# Apply Trigger Sync from Main to Develop
# This script applies the sync migration to make develop triggers match main

set -e

echo "=== Apply Trigger Sync: Main to Develop ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "scripts/sync-triggers-main-to-develop.sql" ]; then
    echo -e "${RED}Error: sync-triggers-main-to-develop.sql not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo -e "${YELLOW}This script will sync triggers from main to develop environment${NC}"
echo ""
echo "Key changes:"
echo "- Replace develop trigger function with main version"
echo "- Use net.http_post to call generate-audio directly"
echo "- Match exact main environment behavior"
echo ""

read -p "Do you want to proceed? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Step 1: Displaying the sync migration${NC}"
echo ""

# Show the migration content
echo "Migration content:"
echo "=================="
cat scripts/sync-triggers-main-to-develop.sql
echo ""

echo -e "${YELLOW}Step 2: Instructions to apply${NC}"
echo ""
echo "To apply this sync:"
echo "1. Go to your DEVELOP Supabase project SQL editor"
echo "2. Copy and paste the entire content above"
echo "3. Execute the SQL"
echo ""
echo "This will:"
echo "✅ Drop existing triggers and function"
echo "✅ Create the exact main environment function"
echo "✅ Recreate triggers to match main"
echo "✅ Log the sync operation"
echo ""

echo -e "${YELLOW}Step 3: Verification${NC}"
echo ""
echo "After applying, verify the sync worked by:"
echo "1. Creating or updating user preferences"
echo "2. Checking logs for 'preferences_updated_audio_trigger' entries"
echo "3. Verifying generate-audio is called automatically"
echo ""

echo -e "${GREEN}Sync script ready to apply!${NC}"
echo ""
echo "The key difference is that main uses:"
echo "  PERFORM net.http_post(...)  -- Direct HTTP call"
echo ""
echo "While develop was using:"
echo "  INSERT INTO audio_generation_queue(...)  -- Queue-based approach"
echo ""
echo "This should fix the automatic audio generation issue." 