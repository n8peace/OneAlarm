#!/bin/bash

# Check and compare triggers between development and production environments

echo "🔍 Checking triggers in development and production environments..."
echo "================================================================"

# Development environment
DEV_PROJECT_REF="xqkmpkfqoisqzznnvlox"
DEV_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

# Production environment (from the branches list we saw earlier)
PROD_PROJECT_REF="joyavvleaxqzksopnmjs"
PROD_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcnZhaHhtb2tleXJmbmxhaXdkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQzMDI2NCwiZXhwIjoyMDY3MDA2MjY0fQ.C2x_AIkig4Fc7JSEyrkxve7E4uAwwvSRhPNDAeOfW-A"

echo "📊 DEVELOPMENT ENVIRONMENT ($DEV_PROJECT_REF)"
echo "--------------------------------------------"

# Check development triggers
DEV_TRIGGERS=$(curl -s -X GET \
  "https://$DEV_PROJECT_REF.supabase.co/rest/v1/rpc/get_triggers" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json")

if [ $? -eq 0 ] && [ "$DEV_TRIGGERS" != "null" ]; then
    echo "✅ Development triggers found:"
    echo "$DEV_TRIGGERS" | jq -r '.[] | "  • \(.trigger_name) on \(.table_name)"' 2>/dev/null || echo "$DEV_TRIGGERS"
else
    echo "❌ Could not fetch development triggers"
fi

echo ""
echo "📊 PRODUCTION ENVIRONMENT ($PROD_PROJECT_REF)"
echo "-------------------------------------------"

# Check production triggers
PROD_TRIGGERS=$(curl -s -X GET \
  "https://$PROD_PROJECT_REF.supabase.co/rest/v1/rpc/get_triggers" \
  -H "apikey: $PROD_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $PROD_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json")

if [ $? -eq 0 ] && [ "$PROD_TRIGGERS" != "null" ]; then
    echo "✅ Production triggers found:"
    echo "$PROD_TRIGGERS" | jq -r '.[] | "  • \(.trigger_name) on \(.table_name)"' 2>/dev/null || echo "$PROD_TRIGGERS"
else
    echo "❌ Could not fetch production triggers"
fi

echo ""
echo "🔍 COMPARISON"
echo "-------------"

# Try a simpler approach - check specific triggers we know should exist
echo "Checking key triggers..."

# Development key triggers
echo "Development:"
curl -s -X GET "https://$DEV_PROJECT_REF.supabase.co/rest/v1/rpc/check_trigger?trigger_name=calculate_next_trigger_trigger" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" 2>/dev/null | grep -q "exists" && echo "  ✅ calculate_next_trigger_trigger" || echo "  ❌ calculate_next_trigger_trigger"

curl -s -X GET "https://$DEV_PROJECT_REF.supabase.co/rest/v1/rpc/check_trigger?trigger_name=alarm_audio_queue_trigger" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" 2>/dev/null | grep -q "exists" && echo "  ✅ alarm_audio_queue_trigger" || echo "  ❌ alarm_audio_queue_trigger"

curl -s -X GET "https://$DEV_PROJECT_REF.supabase.co/rest/v1/rpc/check_trigger?trigger_name=on_preferences_updated" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" 2>/dev/null | grep -q "exists" && echo "  ✅ on_preferences_updated" || echo "  ❌ on_preferences_updated"

echo ""
echo "Production:"
curl -s -X GET "https://$PROD_PROJECT_REF.supabase.co/rest/v1/rpc/check_trigger?trigger_name=calculate_next_trigger_trigger" \
  -H "apikey: $PROD_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $PROD_SERVICE_ROLE_KEY" 2>/dev/null | grep -q "exists" && echo "  ✅ calculate_next_trigger_trigger" || echo "  ❌ calculate_next_trigger_trigger"

curl -s -X GET "https://$PROD_PROJECT_REF.supabase.co/rest/v1/rpc/check_trigger?trigger_name=alarm_audio_queue_trigger" \
  -H "apikey: $PROD_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $PROD_SERVICE_ROLE_KEY" 2>/dev/null | grep -q "exists" && echo "  ✅ alarm_audio_queue_trigger" || echo "  ❌ alarm_audio_queue_trigger"

curl -s -X GET "https://$PROD_PROJECT_REF.supabase.co/rest/v1/rpc/check_trigger?trigger_name=on_preferences_updated" \
  -H "apikey: $PROD_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $PROD_SERVICE_ROLE_KEY" 2>/dev/null | grep -q "exists" && echo "  ✅ on_preferences_updated" || echo "  ❌ on_preferences_updated" 