#!/bin/bash

# Manual DELETE trigger fix for develop environment
# This script outputs the SQL to be executed manually in the Supabase dashboard

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 DELETE Trigger Fix for Develop Environment"
echo "============================================="
echo "📍 Target: $DEVELOP_URL"
echo ""

# Read the migration SQL
MIGRATION_SQL="$PROJECT_ROOT/supabase/migrations/20250707000012_add_delete_to_alarm_audio_queue_trigger.sql"

if [ ! -f "$MIGRATION_SQL" ]; then
    echo "❌ Error: Migration file not found: $MIGRATION_SQL"
    exit 1
fi

echo "📄 Migration file: $MIGRATION_SQL"
echo ""
echo "🚀 To apply this migration:"
echo ""
echo "1. Go to: $DEVELOP_URL/sql"
echo "2. Copy and paste the following SQL:"
echo ""
echo "============================================="
echo "START SQL - COPY BELOW THIS LINE"
echo "============================================="
echo ""

# Output the SQL content
cat "$MIGRATION_SQL"

echo ""
echo "============================================="
echo "END SQL - COPY ABOVE THIS LINE"
echo "============================================="
echo ""
echo "3. Click 'Run' to execute the migration"
echo ""
echo "4. Verify the changes by running:"
echo "   SELECT trigger_name, event_manipulation FROM information_schema.triggers WHERE trigger_name = 'alarm_audio_queue_trigger';"
echo ""
echo "5. Expected result should show: INSERT, UPDATE, DELETE"
echo ""
echo "📋 Summary of changes:"
echo "   - Updated manage_alarm_audio_queue() function to handle DELETE operations"
echo "   - Modified alarm_audio_queue_trigger to include DELETE event"
echo "   - Added cleanup of audio_generation_queue when alarms are deleted"
echo "   - Enhanced logging for all operations (INSERT, UPDATE, DELETE)"
echo ""
echo "🎯 The develop environment will then match the main environment trigger configuration." 