#!/bin/bash

# Fix Production Schema Script
# This script applies the migration to fix production schema issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Production Schema Fix Script${NC}"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "supabase/config.toml" ]; then
    echo -e "${RED}❌ Error: Not in Supabase project directory${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Error: Supabase CLI not found${NC}"
    echo "Please install Supabase CLI: https://supabase.com/docs/guides/cli"
    exit 1
fi

echo -e "${YELLOW}⚠️  WARNING: This will modify your production database schema${NC}"
echo -e "${YELLOW}⚠️  Make sure you have a backup before proceeding${NC}"
echo ""

# Confirm with user
read -p "Are you sure you want to proceed with fixing the production schema? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Operation cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}📋 Checking current migration status...${NC}"

# Check migration status
supabase migration list

echo ""
echo -e "${BLUE}🔍 Validating migration file...${NC}"

# Check if the migration file exists
if [ ! -f "supabase/migrations/20250701000010_fix_production_schema_sync.sql" ]; then
    echo -e "${RED}❌ Error: Migration file not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Migration file found${NC}"

echo ""
echo -e "${BLUE}🚀 Applying migration to production...${NC}"

# Apply the migration
if supabase db push; then
    echo -e "${GREEN}✅ Migration applied successfully!${NC}"
else
    echo -e "${RED}❌ Migration failed${NC}"
    echo "Please check the error messages above and try again"
    exit 1
fi

echo ""
echo -e "${BLUE}📊 Verifying migration status...${NC}"

# Check migration status again
supabase migration list

echo ""
echo -e "${BLUE}🔍 Running schema validation...${NC}"

# Run schema validation
if [ -f "scripts/validate-schema.sh" ]; then
    ./scripts/validate-schema.sh
else
    echo -e "${YELLOW}⚠️  Schema validation script not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Production schema fix completed!${NC}"
echo ""
echo -e "${BLUE}📚 Summary of changes:${NC}"
echo "• Removed obsolete columns from alarms table (name, time, days_of_week, status, etc.)"
echo "• Removed obsolete columns from user_preferences table (onboarding fields)"
echo "• Removed user_id from daily_content table (now global content)"
echo "• Added missing columns to audio table (expires_at, audio_url)"
echo "• Created missing tables (weather_data, user_events, audio_generation_queue)"
echo "• Added proper indexes and RLS policies"
echo ""
echo -e "${BLUE}✅ Production schema is now in sync with development${NC}" 