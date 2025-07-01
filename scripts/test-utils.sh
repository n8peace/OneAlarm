#!/bin/bash

# Shared test utilities for OneAlarm test scripts
# This file contains common functions used across multiple test scripts

set -e

# Source shared configuration
source ./scripts/config.sh

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${CYAN}$1${NC}"
    echo "====================================="
}

# Function to validate service role key
validate_service_role_key() {
    local service_role_key="$1"
    
    if [ -z "$service_role_key" ]; then
        print_error "Service role key is required"
        echo "Usage: $0 YOUR_SERVICE_ROLE_KEY"
        echo "Or set SUPABASE_SERVICE_ROLE_KEY environment variable"
        exit 1
    fi
}

# Function to create a test user
create_test_user() {
    local service_role_key="$1"
    local user_id="${2:-test-user-$(date +%s)}"
    local email="${3:-test+${user_id}@example.com}"
    
    print_info "Creating test user: $user_id"
    
    local response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/users" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{
            \"id\": \"$user_id\",
            \"email\": \"$email\",
            \"onboarding_done\": true,
            \"subscription_status\": \"trialing\"
        }")
    
    if [ $? -eq 0 ]; then
        print_success "Test user created: $user_id"
        echo "$user_id"
    else
        print_error "Failed to create test user"
        return 1
    fi
}

# Function to create test user preferences
create_test_preferences() {
    local service_role_key="$1"
    local user_id="$2"
    local preferences="${3:-{\"tts_voice\":\"alloy\",\"news_categories\":[\"general\"],\"include_weather\":true}}"
    
    print_info "Creating test preferences for user: $user_id"
    
    local response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/user_preferences" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{
            \"user_id\": \"$user_id\",
            \"preferences\": $preferences
        }")
    
    if [ $? -eq 0 ]; then
        print_success "Test preferences created for user: $user_id"
    else
        print_error "Failed to create test preferences"
        return 1
    fi
}

# Function to create a test alarm
create_test_alarm() {
    local service_role_key="$1"
    local user_id="$2"
    local alarm_time="${3:-08:00}"
    local timezone="${4:-America/New_York}"
    
    print_info "Creating test alarm for user: $user_id at $alarm_time $timezone"
    
    local response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/alarms" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{
            \"user_id\": \"$user_id\",
            \"alarm_time_local\": \"$alarm_time\",
            \"alarm_timezone\": \"$timezone\",
            \"active\": true
        }")
    
    if [ $? -eq 0 ]; then
        print_success "Test alarm created for user: $user_id"
    else
        print_error "Failed to create test alarm"
        return 1
    fi
}

# Function to create test weather data
create_test_weather() {
    local service_role_key="$1"
    local user_id="$2"
    local location="${3:-New York, NY}"
    
    print_info "Creating test weather data for user: $user_id"
    
    local response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/weather_data" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{
            \"user_id\": \"$user_id\",
            \"location\": \"$location\",
            \"current_temp\": 72,
            \"high_temp\": 80,
            \"low_temp\": 65,
            \"condition\": \"Partly Cloudy\",
            \"sunrise_time\": \"06:30\",
            \"sunset_time\": \"19:45\"
        }")
    
    if [ $? -eq 0 ]; then
        print_success "Test weather data created for user: $user_id"
    else
        print_error "Failed to create test weather data"
        return 1
    fi
}

# Function to test function health
test_function_health() {
    local service_role_key="$1"
    local function_name="$2"
    
    print_info "Testing $function_name health check"
    
    local response=$(curl -s -X GET "$SUPABASE_URL/functions/v1/$function_name" \
        -H "Authorization: Bearer $service_role_key")
    
    if echo "$response" | grep -q '"status":"healthy"'; then
        print_success "$function_name health check passed"
        return 0
    else
        print_error "$function_name health check failed"
        return 1
    fi
}

# Function to test function endpoint
test_function_endpoint() {
    local service_role_key="$1"
    local function_name="$2"
    local payload="$3"
    
    print_info "Testing $function_name endpoint"
    
    local response=$(curl -s -X POST "$SUPABASE_URL/functions/v1/$function_name" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $service_role_key" \
        -d "$payload")
    
    echo "$response"
}

# Function to check queue status
check_queue_status() {
    local service_role_key="$1"
    
    print_info "Checking audio generation queue status"
    
    local response=$(curl -s -X GET "$SUPABASE_URL/rest/v1/audio_generation_queue?select=*&order=created_at.desc&limit=5" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" \
        -H "Content-Type: application/json")
    
    if [ $? -eq 0 ]; then
        local queue_count=$(echo "$response" | jq '. | length')
        print_success "Queue check successful - Items in queue: $queue_count"
        echo "$queue_count"
    else
        print_error "Failed to check queue status"
        return 1
    fi
}

# Function to clean up test data
cleanup_test_data() {
    local service_role_key="$1"
    local user_id="$2"
    
    print_info "Cleaning up test data for user: $user_id"
    
    # Delete alarms
    curl -s -X DELETE "$SUPABASE_URL/rest/v1/alarms?user_id=eq.$user_id" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" >/dev/null
    
    # Delete user preferences
    curl -s -X DELETE "$SUPABASE_URL/rest/v1/user_preferences?user_id=eq.$user_id" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" >/dev/null
    
    # Delete weather data
    curl -s -X DELETE "$SUPABASE_URL/rest/v1/weather_data?user_id=eq.$user_id" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" >/dev/null
    
    # Delete user
    curl -s -X DELETE "$SUPABASE_URL/rest/v1/users?id=eq.$user_id" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key" >/dev/null
    
    print_success "Test data cleaned up for user: $user_id"
}

# Function to wait for processing
wait_for_processing() {
    local seconds="${1:-3}"
    print_info "Waiting $seconds seconds for processing..."
    sleep "$seconds"
}

# Function to validate response
validate_response() {
    local response="$1"
    local expected_field="$2"
    
    if echo "$response" | grep -q "$expected_field"; then
        print_success "Response validation passed"
        return 0
    else
        print_error "Response validation failed - expected: $expected_field"
        return 1
    fi
}

# Function to check if a table exists
check_table_exists() {
    local service_role_key="$1"
    local table_name="$2"
    
    local response=$(curl -s -X GET "$SUPABASE_URL/rest/v1/$table_name?select=count" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key")
    
    if echo "$response" | grep -q "count"; then
        return 0
    else
        return 1
    fi
}

# Function to get table count
get_table_count() {
    local service_role_key="$1"
    local table_name="$2"
    
    local response=$(curl -s -X GET "$SUPABASE_URL/rest/v1/$table_name?select=count" \
        -H "Authorization: Bearer $service_role_key" \
        -H "apikey: $service_role_key")
    
    echo "$response" | jq -r '.[0].count' 2>/dev/null || echo "0"
}

# Function to wait for a condition
wait_for_condition() {
    local condition_func="$1"
    local timeout="${2:-30}"
    local interval="${3:-1}"
    local description="${4:-condition}"
    
    print_info "Waiting for $description (timeout: ${timeout}s)"
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if eval "$condition_func"; then
            print_success "$description met"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    print_error "Timeout waiting for $description"
    return 1
}

# Function to check if jq is available
check_jq_available() {
    if ! command -v jq >/dev/null 2>&1; then
        print_warning "jq is not installed. JSON responses will not be formatted."
        print_info "Install jq for better output formatting: brew install jq (macOS) or apt-get install jq (Ubuntu)"
        return 1
    fi
    return 0
}

# Function to format JSON response
format_json() {
    local json="$1"
    if check_jq_available; then
        echo "$json" | jq '.' 2>/dev/null || echo "$json"
    else
        echo "$json"
    fi
}

# Export functions for use in other scripts
export -f print_info
export -f print_success
export -f print_warning
export -f print_error
export -f print_header
export -f validate_service_role_key
export -f create_test_user
export -f create_test_preferences
export -f create_test_alarm
export -f cleanup_test_data
export -f check_table_exists
export -f get_table_count
export -f wait_for_condition
export -f check_jq_available
export -f format_json 