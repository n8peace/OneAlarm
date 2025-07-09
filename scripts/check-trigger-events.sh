#!/bin/bash

# Check trigger events for alarm_audio_queue_trigger
# This script verifies the current trigger configuration

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Checking trigger events for alarm_audio_queue_trigger..."
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

# Build connection string
CONNECTION_STRING="postgresql://postgres.xqkmpkfqoisqzznnvlox:${DEV_SERVICE_ROLE_KEY}@aws-0-us-west-1.pooler.supabase.com:6543/postgres"

echo "📊 Current trigger configuration:"
echo ""

# Query the trigger events
TRIGGER_INFO=$(psql "$CONNECTION_STRING" -t -c "
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'alarm_audio_queue_trigger'
ORDER BY event_manipulation;
")

echo "$TRIGGER_INFO"
echo ""

# Check if DELETE is included
if echo "$TRIGGER_INFO" | grep -q "DELETE"; then
    echo "✅ DELETE event is present in the trigger"
else
    echo "❌ DELETE event is missing from the trigger"
fi

echo ""
echo "📋 Expected events: INSERT, UPDATE, DELETE"
echo "🎯 The trigger should handle all three operations for proper queue management." 