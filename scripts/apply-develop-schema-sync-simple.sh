#!/bin/bash

# Simple version of the schema sync migration
# This script applies the migration in smaller chunks to avoid issues

set -e

# Development environment configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to execute a single SQL statement
execute_sql() {
    local sql="$1"
    local description="$2"
    
    log_info "Executing: $description"
    
    local response
    response=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
        -H "Content-Type: application/json" \
        -H "apikey: ${DEVELOP_SERVICE_KEY}" \
        -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
        -d "{\"sql\": \"$sql\"}")
    
    if echo "$response" | grep -q "error"; then
        log_error "Failed: $description"
        echo "Response: $response"
        return 1
    else
        log_success "Completed: $description"
        return 0
    fi
}

# Main migration execution
main() {
    echo "Starting DEVELOP schema sync migration..."
    echo "=========================================="
    
    # Test connectivity first
    log_info "Testing connectivity..."
    local test_response
    test_response=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/" \
        -H "apikey: ${DEVELOP_SERVICE_KEY}" \
        -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")
    
    if echo "$test_response" | grep -q "swagger"; then
        log_success "Connected to develop environment"
    else
        log_error "Cannot connect to develop environment"
        echo "Response: $test_response"
        exit 1
    fi
    
    # Show warning
    echo ""
    log_warning "This will make significant changes to the DEVELOP database!"
    echo "  • Drop the 'audio_files' table entirely"
    echo "  • Change column nullability constraints"
    echo "  • Modify data types and defaults"
    echo "  • Drop and add columns"
    echo ""
    read -p "Do you want to proceed? (yes/no): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_warning "Migration cancelled"
        exit 0
    fi
    
    # Execute migrations in chunks
    
    # 1. Add created_at to alarms
    execute_sql "ALTER TABLE alarms ADD COLUMN IF NOT EXISTS created_at timestamp without time zone DEFAULT now();" "Add created_at to alarms"
    
    # 2. Change user_id nullability in alarms
    execute_sql "ALTER TABLE alarms ALTER COLUMN user_id DROP NOT NULL;" "Make user_id nullable in alarms"
    
    # 3. Change timestamp types in alarms
    execute_sql "ALTER TABLE alarms ALTER COLUMN updated_at TYPE timestamp without time zone;" "Change updated_at type in alarms"
    execute_sql "ALTER TABLE alarms ALTER COLUMN next_trigger_at TYPE timestamp without time zone;" "Change next_trigger_at type in alarms"
    
    # 4. Change timezone_at_creation to NOT NULL
    execute_sql "ALTER TABLE alarms ALTER COLUMN timezone_at_creation SET NOT NULL;" "Make timezone_at_creation NOT NULL"
    
    # 5. Audio table changes
    execute_sql "ALTER TABLE audio ALTER COLUMN user_id DROP NOT NULL;" "Make user_id nullable in audio"
    execute_sql "ALTER TABLE audio RENAME COLUMN file_url TO audio_url;" "Rename file_url to audio_url"
    execute_sql "ALTER TABLE audio RENAME COLUMN duration TO duration_seconds;" "Rename duration to duration_seconds"
    execute_sql "ALTER TABLE audio ADD COLUMN IF NOT EXISTS alarm_id uuid REFERENCES alarms(id);" "Add alarm_id to audio"
    
    # 6. Drop audio_files table
    execute_sql "DROP TABLE IF EXISTS audio_files CASCADE;" "Drop audio_files table"
    
    # 7. Audio generation queue changes
    execute_sql "ALTER TABLE audio_generation_queue ALTER COLUMN status SET NOT NULL;" "Make status NOT NULL in queue"
    execute_sql "ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS retry_count integer DEFAULT 0;" "Add retry_count to queue"
    execute_sql "ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS max_retries integer DEFAULT 3;" "Add max_retries to queue"
    execute_sql "ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS error_message text;" "Add error_message to queue"
    execute_sql "ALTER TABLE audio_generation_queue ADD COLUMN IF NOT EXISTS processed_at timestamp with time zone;" "Add processed_at to queue"
    execute_sql "ALTER TABLE audio_generation_queue DROP COLUMN IF EXISTS updated_at;" "Drop updated_at from queue"
    
    # 8. Daily content changes
    execute_sql "ALTER TABLE daily_content ALTER COLUMN date DROP NOT NULL;" "Make date nullable in daily_content"
    execute_sql "ALTER TABLE daily_content DROP COLUMN IF EXISTS news_summary;" "Drop news_summary from daily_content"
    execute_sql "ALTER TABLE daily_content DROP COLUMN IF EXISTS weather_summary;" "Drop weather_summary from daily_content"
    execute_sql "ALTER TABLE daily_content DROP COLUMN IF EXISTS stock_summary;" "Drop stock_summary from daily_content"
    execute_sql "ALTER TABLE daily_content DROP COLUMN IF EXISTS holiday_info;" "Drop holiday_info from daily_content"
    execute_sql "ALTER TABLE daily_content DROP COLUMN IF EXISTS updated_at;" "Drop updated_at from daily_content"
    execute_sql "ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS holidays text;" "Add holidays to daily_content"
    execute_sql "ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS general_headlines text;" "Add general_headlines to daily_content"
    execute_sql "ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS business_headlines text;" "Add business_headlines to daily_content"
    execute_sql "ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS technology_headlines text;" "Add technology_headlines to daily_content"
    execute_sql "ALTER TABLE daily_content ADD COLUMN IF NOT EXISTS sports_headlines text;" "Add sports_headlines to daily_content"
    execute_sql "ALTER TABLE daily_content ALTER COLUMN created_at TYPE timestamp without time zone;" "Change created_at type in daily_content"
    
    # 9. Logs changes
    execute_sql "ALTER TABLE logs ALTER COLUMN event_type DROP NOT NULL;" "Make event_type nullable in logs"
    execute_sql "ALTER TABLE logs ALTER COLUMN created_at TYPE timestamp without time zone;" "Change created_at type in logs"
    
    # 10. User events changes
    execute_sql "ALTER TABLE user_events ALTER COLUMN user_id DROP NOT NULL;" "Make user_id nullable in user_events"
    execute_sql "ALTER TABLE user_events ALTER COLUMN event_type DROP NOT NULL;" "Make event_type nullable in user_events"
    execute_sql "ALTER TABLE user_events DROP COLUMN IF EXISTS event_data;" "Drop event_data from user_events"
    execute_sql "ALTER TABLE user_events ALTER COLUMN created_at TYPE timestamp without time zone;" "Change created_at type in user_events"
    
    # 11. User preferences changes
    execute_sql "ALTER TABLE user_preferences DROP COLUMN IF EXISTS id;" "Drop id from user_preferences"
    execute_sql "ALTER TABLE user_preferences ALTER COLUMN user_id SET NOT NULL;" "Make user_id NOT NULL in user_preferences"
    execute_sql "ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;" "Drop existing primary key"
    execute_sql "ALTER TABLE user_preferences ADD PRIMARY KEY (user_id);" "Add primary key on user_id"
    execute_sql "ALTER TABLE user_preferences ALTER COLUMN include_weather SET DEFAULT true;" "Set include_weather default"
    execute_sql "ALTER TABLE user_preferences ALTER COLUMN tts_voice DROP DEFAULT;" "Drop tts_voice default"
    execute_sql "ALTER TABLE user_preferences DROP COLUMN IF EXISTS created_at;" "Drop created_at from user_preferences"
    execute_sql "ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false;" "Add onboarding_completed"
    execute_sql "ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS onboarding_step integer DEFAULT 0;" "Add onboarding_step"
    execute_sql "ALTER TABLE user_preferences ALTER COLUMN updated_at TYPE timestamp without time zone;" "Change updated_at type in user_preferences"
    
    # 12. Users changes
    execute_sql "ALTER TABLE users ALTER COLUMN email DROP NOT NULL;" "Make email nullable in users"
    execute_sql "ALTER TABLE users ALTER COLUMN created_at TYPE timestamp without time zone;" "Change created_at type in users"
    execute_sql "ALTER TABLE users ALTER COLUMN last_login TYPE timestamp without time zone;" "Change last_login type in users"
    execute_sql "ALTER TABLE users DROP COLUMN IF EXISTS updated_at;" "Drop updated_at from users"
    
    # 13. Weather data changes
    execute_sql "ALTER TABLE weather_data ALTER COLUMN location TYPE character varying(255);" "Change location type in weather_data"
    execute_sql "ALTER TABLE weather_data ALTER COLUMN current_temp TYPE integer;" "Change current_temp type in weather_data"
    execute_sql "ALTER TABLE weather_data ALTER COLUMN high_temp TYPE integer;" "Change high_temp type in weather_data"
    execute_sql "ALTER TABLE weather_data ALTER COLUMN low_temp TYPE integer;" "Change low_temp type in weather_data"
    execute_sql "ALTER TABLE weather_data ALTER COLUMN condition TYPE character varying(100);" "Change condition type in weather_data"
    execute_sql "ALTER TABLE weather_data DROP COLUMN IF EXISTS temperature;" "Drop temperature from weather_data"
    execute_sql "ALTER TABLE weather_data DROP COLUMN IF EXISTS humidity;" "Drop humidity from weather_data"
    execute_sql "ALTER TABLE weather_data DROP COLUMN IF EXISTS wind_speed;" "Drop wind_speed from weather_data"
    
    # 14. Log completion
    execute_sql "INSERT INTO logs (event_type, meta) VALUES ('schema_migration_completed', '{\"migration\": \"20250707000011_sync_develop_to_main_schema\", \"description\": \"Synced develop schema to match main\"}');" "Log migration completion"
    
    log_success "Schema sync migration completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Test the application functionality"
    echo "  2. Verify data integrity"
    echo "  3. Run the schema comparison script again to confirm sync"
}

main "$@" 