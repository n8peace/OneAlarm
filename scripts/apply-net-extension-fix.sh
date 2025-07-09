#!/bin/bash

# Apply Net Extension Fix Migration
# This script applies the migration to remove all net extension calls from develop environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Develop environment details
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🔧 Applying Net Extension Fix Migration to Develop${NC}"
echo "=================================================="

# Test connection to develop environment
echo -e "${BLUE}ℹ️  Testing connection to develop environment...${NC}"
if curl -s -f "$DEVELOP_URL/rest/v1/" -H "apikey: $DEVELOP_SERVICE_KEY" > /dev/null; then
    echo -e "${GREEN}✅ Connection to develop environment successful${NC}"
else
    echo -e "${RED}❌ Failed to connect to develop environment${NC}"
    exit 1
fi

# Apply the migration directly
echo -e "${BLUE}ℹ️  Applying migration to remove all net extension calls...${NC}"

# Read the migration file and apply it
MIGRATION_SQL=$(cat supabase/migrations/20250707000007_remove_all_net_extension_calls.sql)

# Apply the migration using the REST API
RESPONSE=$(curl -s -X POST "$DEVELOP_URL/rest/v1/rpc/exec_sql" \
  -H "apikey: $DEVELOP_SERVICE_KEY" \
  -H "Authorization: Bearer $DEVELOP_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$MIGRATION_SQL" | jq -R -s .)}")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Migration applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply migration: $RESPONSE${NC}"
    exit 1
fi

echo -e "${BLUE}ℹ️  Migration completed successfully!${NC}"
echo ""
echo -e "${CYAN}🔍 Next steps:${NC}"
echo "1. Test user preferences update to verify net extension error is resolved"
echo "2. Check logs for any remaining issues"
echo "3. Verify triggers are working correctly without net extension calls" 