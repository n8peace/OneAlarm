#!/bin/bash

# Shared configuration for OneAlarm scripts
# Source this file in other scripts: source ./scripts/config.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Environment-specific configuration
ENVIRONMENT="${ENVIRONMENT:-production}"

# Supabase configuration with environment-specific URLs
if [ "$ENVIRONMENT" = "development" ]; then
    # Development environment
    SUPABASE_URL="${SUPABASE_URL:-}"
    SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
    SUPABASE_BRANCH="${SUPABASE_BRANCH:-develop}"
else
    # Production environment (default)
    SUPABASE_URL="${SUPABASE_URL:-}"
    SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
    SUPABASE_BRANCH="${SUPABASE_BRANCH:-main}"
fi

SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

# Construct branch-specific URL if needed
if [ -n "$SUPABASE_BRANCH" ] && [ "$SUPABASE_BRANCH" != "main" ]; then
    SUPABASE_BRANCH_URL="${SUPABASE_URL}/branches/${SUPABASE_BRANCH}"
else
    SUPABASE_BRANCH_URL="$SUPABASE_URL"
fi

# Function URLs (use branch URL if available)
FUNCTION_BASE_URL="${SUPABASE_BRANCH_URL:-$SUPABASE_URL}"
FUNCTION_URLS=(
    "daily-content:${FUNCTION_BASE_URL}/functions/v1/daily-content"
    "generate-audio:${FUNCTION_BASE_URL}/functions/v1/generate-audio"
    "generate-alarm-audio:${FUNCTION_BASE_URL}/functions/v1/generate-alarm-audio"
    "cleanup-audio-files:${FUNCTION_BASE_URL}/functions/v1/cleanup-audio-files"
)

# Validation functions
validate_environment() {
    local missing_vars=()
    
    if [ -z "$SUPABASE_URL" ]; then
        missing_vars+=("SUPABASE_URL")
    fi
    
    if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
        missing_vars+=("SUPABASE_SERVICE_ROLE_KEY")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required environment variables:${NC}"
        for var in "${missing_vars[@]}"; do
            echo -e "  - ${YELLOW}$var${NC}"
        done
        echo ""
        echo -e "${BLUE}Please set these variables in your .env file or environment:${NC}"
        echo "  SUPABASE_URL=https://your-project.supabase.co"
        echo "  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key"
        echo ""
        echo -e "${PURPLE}To get your service role key:${NC}"
        echo "1. Go to ${SUPABASE_URL}/settings/api"
        echo "2. Copy the 'service_role' key (not the anon key)"
        return 1
    fi
    
    return 0
}

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${CYAN}🔍 $1${NC}"
}

# Function to get function URL by name
get_function_url() {
    local function_name="$1"
    for url_pair in "${FUNCTION_URLS[@]}"; do
        IFS=':' read -r name url <<< "$url_pair"
        if [ "$name" = "$function_name" ]; then
            echo "$url"
            return 0
        fi
    done
    return 1
}

# Function to make authenticated API calls
make_api_call() {
    local method="$1"
    local url="$2"
    local data="$3"
    local auth_header="Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
    
    if [ -n "$data" ]; then
        curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -H "$auth_header" \
            -d "$data"
    else
        curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -H "$auth_header"
    fi
}

# Function to check if jq is available
check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq is not installed. JSON responses will not be formatted."
        log_info "Install jq for better output formatting: brew install jq (macOS) or apt-get install jq (Ubuntu)"
        return 1
    fi
    return 0
}

# Function to format JSON response
format_json() {
    local json="$1"
    if check_jq; then
        echo "$json" | jq '.' 2>/dev/null || echo "$json"
    else
        echo "$json"
    fi
}

# Function to display current environment info
show_environment_info() {
    echo -e "${CYAN}🌍 Environment Information:${NC}"
    echo -e "  Environment: ${YELLOW}$ENVIRONMENT${NC}"
    echo -e "  Supabase URL: ${BLUE}$SUPABASE_URL${NC}"
    echo -e "  Project Ref: ${BLUE}$SUPABASE_PROJECT_REF${NC}"
    echo -e "  Branch: ${BLUE}$SUPABASE_BRANCH${NC}"
    if [ "$SUPABASE_BRANCH_URL" != "$SUPABASE_URL" ]; then
        echo -e "  Branch URL: ${BLUE}$SUPABASE_BRANCH_URL${NC}"
    fi
}

# Export functions and variables
export -f validate_environment
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_step
export -f get_function_url
export -f make_api_call
export -f check_jq
export -f format_json
export -f show_environment_info

# Export color variables
export RED GREEN YELLOW BLUE PURPLE CYAN NC
export SUPABASE_URL SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY
export SUPABASE_PROJECT_REF SUPABASE_BRANCH SUPABASE_BRANCH_URL
export FUNCTION_URLS ENVIRONMENT 