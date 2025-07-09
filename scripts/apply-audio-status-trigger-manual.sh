#!/bin/bash

# Manual audio status trigger fix for develop environment
# This script outputs the SQL to be executed manually in the Supabase dashboard

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Audio Status Trigger Fix for Develop Environment"
echo "=================================================="
echo "📍 Target: $DEVELOP_URL"
echo ""

# Read the migration SQL
MIGRATION_SQL="$PROJECT_ROOT/supabase/migrations/20250707000013_add_on_audio_status_change_trigger.sql"

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
echo "   SELECT trigger_name, event_manipulation, event_object_table FROM information_schema.triggers WHERE trigger_name = 'on_audio_status_change';"
echo ""
echo "5. Expected result should show:"
echo "   - trigger_name: on_audio_status_change"
echo "   - event_manipulation: UPDATE"
echo "   - event_object_table: audio"
echo ""
echo "📋 Summary of changes:"
echo "   - Created log_offline_issue() function to handle audio status changes"
echo "   - Added on_audio_status_change trigger on audio table"
echo "   - Trigger fires AFTER UPDATE and logs status changes"
echo "   - Enhanced logging for audio status monitoring"
echo ""
echo "🎯 The develop environment now has the missing audio status change trigger." 