#!/bin/bash

# Apply DELETE trigger fix to develop environment using direct API call
# This script uses the service role key to apply the migration directly

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Applying DELETE trigger fix to develop environment..."
echo "📍 Target: $DEVELOP_URL"
echo ""

# Check if we have the required environment variables
if [ -z "$DEV_SERVICE_ROLE_KEY" ]; then
    echo "❌ Error: DEV_SERVICE_ROLE_KEY environment variable is required"
    echo "   Please set it with: export DEV_SERVICE_ROLE_KEY=your_service_role_key"
    echo "   Get your service role key from: https://xqkmpkfqoisqzznnvlox.supabase.co/settings/api"
    echo "   Look for 'service_role' key (not anon key)"
    exit 1
fi

# Read the migration SQL
MIGRATION_SQL="$PROJECT_ROOT/supabase/migrations/20250707000012_add_delete_to_alarm_audio_queue_trigger.sql"

if [ ! -f "$MIGRATION_SQL" ]; then
    echo "❌ Error: Migration file not found: $MIGRATION_SQL"
    exit 1
fi

echo "📄 Migration file: $MIGRATION_SQL"
echo ""

# Read the SQL content
SQL_CONTENT=$(cat "$MIGRATION_SQL")

# Apply the migration using direct API call
echo "🚀 Applying migration via API..."
echo ""

# Make the API call to execute the SQL
RESPONSE=$(curl -s -X POST \
  "$DEVELOP_URL/rest/v1/rpc/exec_sql" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$SQL_CONTENT" | jq -R -s .)}")

echo "📄 API Response:"
echo "$RESPONSE"
echo ""

if [[ "$RESPONSE" == *"error"* ]]; then
    echo "❌ Error applying migration:"
    echo "$RESPONSE"
    exit 1
else
    echo "✅ Migration applied successfully!"
fi

echo ""
echo "🔍 To verify the changes:"
echo "1. Go to: $DEVELOP_URL/sql"
echo "2. Run: SELECT trigger_name, event_manipulation FROM information_schema.triggers WHERE trigger_name = 'alarm_audio_queue_trigger';"
echo "3. Expected result should show: INSERT, UPDATE, DELETE"
echo ""
echo "📋 Summary of changes:"
echo "   - Updated manage_alarm_audio_queue() function to handle DELETE operations"
echo "   - Modified alarm_audio_queue_trigger to include DELETE event"
echo "   - Added cleanup of audio_generation_queue when alarms are deleted"
echo "   - Enhanced logging for all operations (INSERT, UPDATE, DELETE)"
echo ""
echo "🎯 The develop environment now matches the main environment trigger configuration." 