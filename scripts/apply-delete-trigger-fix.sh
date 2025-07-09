#!/bin/bash

# Apply DELETE trigger fix to develop environment
# This script adds DELETE event handling to the alarm_audio_queue_trigger

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Applying DELETE trigger fix to develop environment..."
echo "📍 Target: $DEVELOP_URL"
echo ""

# Check if we have the required environment variables
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "❌ Error: SUPABASE_ACCESS_TOKEN environment variable is required"
    echo "   Please set it with: export SUPABASE_ACCESS_TOKEN=your_token"
    echo "   Get your token from: https://supabase.com/dashboard/account/tokens"
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

# Apply the migration using Supabase CLI
echo "🚀 Applying migration..."
echo ""

# Extract project reference from URL
PROJECT_REF=$(echo "$DEVELOP_URL" | sed 's|https://||' | sed 's|\.supabase\.co||')

# Apply the migration
supabase db push --project-ref "$PROJECT_REF" --include-all

echo ""
echo "✅ Migration applied successfully!"
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