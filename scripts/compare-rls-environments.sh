#!/bin/bash

# Compare RLS policies between dev and prod environments
# This script helps identify differences in RLS configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo -e "${BLUE}🔍 RLS Policy Comparison Tool${NC}"
    echo "====================================="
    echo ""
    echo "Usage: ./scripts/compare-rls-environments.sh"
    echo ""
    echo "This script compares RLS policies between dev and prod environments"
    echo "to identify configuration differences that might cause permission issues."
    exit 1
}

# Environment URLs and keys
DEV_URL="https://joyavvleaxqzksopnmjs.supabase.co"
DEV_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og"

PROD_URL="https://bfrvahxmokeyrfnlaiwd.supabase.co"
PROD_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcnZhaHhtb2tleXJmbmxhaXdkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQzMDI2NCwiZXhwIjoyMDY3MDA2MjY0fQ.C2x_AIkig4Fc7JSEyrkxve7E4uAwwvSRhPNDAeOfW-A"

echo -e "${BLUE}🔍 RLS Policy Comparison Tool${NC}"
echo "====================================="
echo ""

# Function to make API call
make_api_call() {
    local url="$1"
    local key="$2"
    local endpoint="$3"
    
    curl -s -X GET "$url$endpoint" \
        -H "Authorization: Bearer $key" \
        -H "apikey: $key" \
        -H "Content-Type: application/json"
}

# Function to get RLS policies
get_rls_policies() {
    local url="$1"
    local key="$2"
    local env_name="$3"
    
    echo -e "${YELLOW}📋 Getting RLS policies for $env_name...${NC}"
    
    # Get all RLS policies
    local policies=$(make_api_call "$url" "$key" "/rest/v1/rpc/get_rls_policies")
    
    if echo "$policies" | jq -e '.' >/dev/null 2>&1; then
        echo "$policies" > "temp_${env_name}_policies.json"
        echo -e "${GREEN}✅ Retrieved RLS policies for $env_name${NC}"
    else
        echo -e "${RED}❌ Failed to get RLS policies for $env_name${NC}"
        echo "Response: $policies"
        return 1
    fi
}

# Function to compare policies
compare_policies() {
    echo -e "${BLUE}📊 Comparing RLS Policies${NC}"
    echo "====================================="
    
    if [ -f "temp_dev_policies.json" ] && [ -f "temp_prod_policies.json" ]; then
        echo -e "${CYAN}🔍 Comparing policy counts...${NC}"
        
        DEV_COUNT=$(jq 'length' temp_dev_policies.json)
        PROD_COUNT=$(jq 'length' temp_prod_policies.json)
        
        echo "• Dev policies: $DEV_COUNT"
        echo "• Prod policies: $PROD_COUNT"
        
        if [ "$DEV_COUNT" = "$PROD_COUNT" ]; then
            echo -e "${GREEN}✅ Policy counts match${NC}"
        else
            echo -e "${RED}❌ Policy counts differ${NC}"
        fi
        
        echo ""
        echo -e "${CYAN}🔍 Checking for missing policies in prod...${NC}"
        
        # Get policy names from dev
        jq -r '.[] | "\(.tablename).\(.policyname)"' temp_dev_policies.json | sort > temp_dev_policy_names.txt
        
        # Get policy names from prod
        jq -r '.[] | "\(.tablename).\(.policyname)"' temp_prod_policies.json | sort > temp_prod_policy_names.txt
        
        # Find missing in prod
        MISSING_IN_PROD=$(comm -23 temp_dev_policy_names.txt temp_prod_policy_names.txt)
        
        if [ -n "$MISSING_IN_PROD" ]; then
            echo -e "${RED}❌ Missing policies in prod:${NC}"
            echo "$MISSING_IN_PROD" | sed 's/^/  • /'
        else
            echo -e "${GREEN}✅ All dev policies exist in prod${NC}"
        fi
        
        echo ""
        echo -e "${CYAN}🔍 Checking for extra policies in prod...${NC}"
        
        # Find extra in prod
        EXTRA_IN_PROD=$(comm -13 temp_dev_policy_names.txt temp_prod_policy_names.txt)
        
        if [ -n "$EXTRA_IN_PROD" ]; then
            echo -e "${YELLOW}⚠️  Extra policies in prod:${NC}"
            echo "$EXTRA_IN_PROD" | sed 's/^/  • /'
        else
            echo -e "${GREEN}✅ No extra policies in prod${NC}"
        fi
        
    else
        echo -e "${RED}❌ Policy files not found${NC}"
        return 1
    fi
}

# Function to check specific table policies
check_table_policies() {
    local table_name="$1"
    
    echo ""
    echo -e "${BLUE}📋 Checking policies for $table_name${NC}"
    echo "====================================="
    
    # Get dev policies for table
    DEV_TABLE_POLICIES=$(jq -r ".[] | select(.tablename == \"$table_name\") | .policyname" temp_dev_policies.json 2>/dev/null || echo "")
    PROD_TABLE_POLICIES=$(jq -r ".[] | select(.tablename == \"$table_name\") | .policyname" temp_prod_policies.json 2>/dev/null || echo "")
    
    echo "Dev policies: $DEV_TABLE_POLICIES"
    echo "Prod policies: $PROD_TABLE_POLICIES"
    
    if [ "$DEV_TABLE_POLICIES" = "$PROD_TABLE_POLICIES" ]; then
        echo -e "${GREEN}✅ $table_name policies match${NC}"
    else
        echo -e "${RED}❌ $table_name policies differ${NC}"
    fi
}

# Main execution
echo -e "${YELLOW}🔍 Step 1: Getting RLS policies from both environments${NC}"

# Get policies from dev
get_rls_policies "$DEV_URL" "$DEV_KEY" "dev"

# Get policies from prod
get_rls_policies "$PROD_URL" "$PROD_KEY" "prod"

echo ""
echo -e "${YELLOW}🔍 Step 2: Comparing policies${NC}"
compare_policies

echo ""
echo -e "${YELLOW}🔍 Step 3: Checking specific table policies${NC}"
check_table_policies "user_preferences"
check_table_policies "users"
check_table_policies "alarms"

echo ""
echo -e "${BLUE}📋 Summary${NC}"
echo "====================================="

# Cleanup
rm -f temp_dev_policies.json temp_prod_policies.json temp_dev_policy_names.txt temp_prod_policy_names.txt

echo -e "${GREEN}✅ RLS comparison complete!${NC}"
echo ""
echo -e "${CYAN}💡 Next steps:${NC}"
echo "• If policies differ, create a migration to sync them"
echo "• Check if the 'net' schema permissions are correctly set"
echo "• Verify service role has proper permissions for triggers" 