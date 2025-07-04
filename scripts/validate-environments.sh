#!/bin/bash

# OneAlarm Environment Validation Script
# This script validates both production and development environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROD_PROJECT_REF="${PROD_PROJECT_REF:-joyavvleaxqzksopnmjs}"
DEV_PROJECT_REF="${DEV_PROJECT_REF:-xqkmpkfqoisqzznnvlox}"
BRANCH_NAME="${BRANCH_NAME:-develop}"

echo -e "${BLUE}🔍 OneAlarm Environment Validation${NC}"
echo "=================================="

# Function to test environment
test_environment() {
    local env_name=$1
    local project_ref=$2
    local branch_suffix=$3
    
    echo -e "${BLUE}Testing $env_name Environment${NC}"
    echo "--------------------------------"
    
    # Construct URL
    local base_url="https://$project_ref.supabase.co"
    if [ "$branch_suffix" != "" ]; then
        base_url="$base_url/branches/$branch_suffix"
    fi
    
    echo -e "${YELLOW}🔗 Base URL: $base_url${NC}"
    
    # Test daily-content function
    echo -e "${BLUE}Testing daily-content function...${NC}"
    response=$(curl -s -w "\n%{http_code}" -X GET $base_url/functions/v1/daily-content)
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ daily-content function is healthy (HTTP $http_code)${NC}"
    else
        echo -e "${RED}❌ daily-content function failed (HTTP $http_code)${NC}"
        echo "Response: $(echo "$response" | head -n -1)"
    fi
    
    # Test generate-alarm-audio function
    echo -e "${BLUE}Testing generate-alarm-audio function...${NC}"
    response=$(curl -s -w "\n%{http_code}" -X GET $base_url/functions/v1/generate-alarm-audio)
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ generate-alarm-audio function is healthy (HTTP $http_code)${NC}"
    else
        echo -e "${RED}❌ generate-alarm-audio function failed (HTTP $http_code)${NC}"
        echo "Response: $(echo "$response" | head -n -1)"
    fi
    
    # Test generate-audio function
    echo -e "${BLUE}Testing generate-audio function...${NC}"
    response=$(curl -s -w "\n%{http_code}" -X GET $base_url/functions/v1/generate-audio)
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ generate-audio function is healthy (HTTP $http_code)${NC}"
    else
        echo -e "${YELLOW}⚠️ generate-audio function returned HTTP $http_code${NC}"
        echo "Response: $(echo "$response" | head -n -1)"
    fi
    
    echo ""
}

# Test Production Environment
test_environment "Production" $PROD_PROJECT_REF ""

# Test Development Environment
test_environment "Development" $DEV_PROJECT_REF $BRANCH_NAME

# Summary
echo -e "${BLUE}📊 Environment Summary${NC}"
echo "========================"
echo -e "${GREEN}Production URL:${NC} https://$PROD_PROJECT_REF.supabase.co"
echo -e "${GREEN}Development URL:${NC} https://$DEV_PROJECT_REF.supabase.co/branches/$BRANCH_NAME"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Set up GitHub secrets (see docs/GITHUB_SECRETS_SETUP.md)"
echo "2. Test GitHub Actions workflows"
echo "3. Deploy to develop branch using CI/CD"
echo "4. Run end-to-end tests on both environments" 