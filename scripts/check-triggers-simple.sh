#!/bin/bash

# Simple trigger check using direct SQL queries

echo "🔍 Checking triggers in development and production environments..."
echo "================================================================"

# Development environment
DEV_PROJECT_REF="xqkmpkfqoisqzznnvlox"
DEV_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

# Production environment
PROD_PROJECT_REF="joyavvleaxqzksopnmjs"
PROD_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcnZhaHhtb2tleXJmbmxhaXdkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQzMDI2NCwiZXhwIjoyMDY3MDA2MjY0fQ.C2x_AIkig4Fc7JSEyrkxve7E4uAwwvSRhPNDAeOfW-A"

echo "📊 DEVELOPMENT ENVIRONMENT ($DEV_PROJECT_REF)"
echo "--------------------------------------------"

# Check development triggers count
DEV_TRIGGER_COUNT=$(curl -s -X POST \
  "https://$DEV_PROJECT_REF.supabase.co/rest/v1/rpc/exec_sql" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT COUNT(*) as trigger_count FROM information_schema.triggers WHERE trigger_schema = '\''public'\'';"}' | jq -r '.[0].trigger_count' 2>/dev/null)

if [ "$DEV_TRIGGER_COUNT" != "null" ] && [ "$DEV_TRIGGER_COUNT" != "" ]; then
    echo "✅ Development triggers found: $DEV_TRIGGER_COUNT"
else
    echo "❌ Could not fetch development trigger count"
fi

# Get development trigger names
DEV_TRIGGER_NAMES=$(curl -s -X POST \
  "https://$DEV_PROJECT_REF.supabase.co/rest/v1/rpc/exec_sql" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = '\''public'\'' ORDER BY trigger_name;"}' | jq -r '.[] | "  • \(.trigger_name) on \(.event_object_table)"' 2>/dev/null)

if [ "$DEV_TRIGGER_NAMES" != "" ]; then
    echo "Development trigger details:"
    echo "$DEV_TRIGGER_NAMES"
else
    echo "❌ Could not fetch development trigger details"
fi

echo ""
echo "📊 PRODUCTION ENVIRONMENT ($PROD_PROJECT_REF)"
echo "-------------------------------------------"

# Check production triggers count
PROD_TRIGGER_COUNT=$(curl -s -X POST \
  "https://$PROD_PROJECT_REF.supabase.co/rest/v1/rpc/exec_sql" \
  -H "apikey: $PROD_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $PROD_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT COUNT(*) as trigger_count FROM information_schema.triggers WHERE trigger_schema = '\''public'\'';"}' | jq -r '.[0].trigger_count' 2>/dev/null)

if [ "$PROD_TRIGGER_COUNT" != "null" ] && [ "$PROD_TRIGGER_COUNT" != "" ]; then
    echo "✅ Production triggers found: $PROD_TRIGGER_COUNT"
else
    echo "❌ Could not fetch production trigger count"
fi

# Get production trigger names
PROD_TRIGGER_NAMES=$(curl -s -X POST \
  "https://$PROD_PROJECT_REF.supabase.co/rest/v1/rpc/exec_sql" \
  -H "apikey: $PROD_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $PROD_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = '\''public'\'' ORDER BY trigger_name;"}' | jq -r '.[] | "  • \(.trigger_name) on \(.event_object_table)"' 2>/dev/null)

if [ "$PROD_TRIGGER_NAMES" != "" ]; then
    echo "Production trigger details:"
    echo "$PROD_TRIGGER_NAMES"
else
    echo "❌ Could not fetch production trigger details"
fi

echo ""
echo "🔍 COMPARISON SUMMARY"
echo "--------------------"

if [ "$DEV_TRIGGER_COUNT" = "$PROD_TRIGGER_COUNT" ]; then
    echo "✅ Trigger counts match: $DEV_TRIGGER_COUNT triggers in both environments"
else
    echo "⚠️  Trigger counts differ: Dev=$DEV_TRIGGER_COUNT, Prod=$PROD_TRIGGER_COUNT"
fi

echo ""
echo "Expected triggers (from our setup script):"
echo "  • update_users_updated_at"
echo "  • update_user_preferences_updated_at"
echo "  • update_alarms_updated_at"
echo "  • update_daily_content_updated_at"
echo "  • update_audio_files_updated_at"
echo "  • update_audio_updated_at"
echo "  • trigger_sync_auth_to_public_user"
echo "  • on_auth_user_created"
echo "  • calculate_next_trigger_trigger"
echo "  • alarm_audio_queue_trigger"
echo "  • on_preferences_updated"
echo "  • on_preferences_inserted"
echo "  • on_audio_status_change" 