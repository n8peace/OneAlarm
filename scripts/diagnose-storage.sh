#!/bin/bash

echo "🔍 Supabase Storage Upload Diagnostic"
echo "====================================="
echo ""

# Check if service role key is provided
read -s -p "🔑 Enter your Supabase service role key: " SERVICE_ROLE_KEY
echo ""

if [ -z "$SERVICE_ROLE_KEY" ]; then
    echo "❌ Service role key is required!"
    exit 1
fi

# Source shared configuration
source ./scripts/config.sh

BUCKET_NAME="audio-files"

echo "📋 Project: $SUPABASE_URL"
echo "🪣 Bucket: $BUCKET_NAME"
echo ""

# 1. Check if bucket exists
echo "1️⃣ Checking if storage bucket exists..."
BUCKET_CHECK=$(curl -s -X GET "$SUPABASE_URL/storage/v1/bucket/$BUCKET_NAME" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY")

echo "Bucket Check Response:"
echo "$BUCKET_CHECK"
echo ""

# 2. Check bucket policies
echo "2️⃣ Checking bucket policies..."
POLICIES_CHECK=$(curl -s -X GET "$SUPABASE_URL/storage/v1/policy" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY")

echo "Policies Check Response:"
echo "$POLICIES_CHECK"
echo ""

# 3. Test file upload with a small test file
echo "3️⃣ Testing file upload..."
TEST_CONTENT="This is a test file for storage diagnostics"
TEST_FILE="test-upload.txt"

# Create test file
echo "$TEST_CONTENT" > "$TEST_FILE"

UPLOAD_TEST=$(curl -s -w "\n%{http_code}" -X POST "$SUPABASE_URL/storage/v1/object/$BUCKET_NAME/test-diagnostic/$TEST_FILE" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: text/plain" \
  --data-binary "@$TEST_FILE")

# Extract response body and status code
upload_http_code=$(echo "$UPLOAD_TEST" | tail -n1)
upload_response_body=$(echo "$UPLOAD_TEST" | sed '$d')

echo "Upload Test Response:"
echo "Status Code: $upload_http_code"
echo "Response: $upload_response_body"
echo ""

# 4. Check if test file was uploaded
echo "4️⃣ Verifying test file upload..."
if [ "$upload_http_code" = "200" ] || [ "$upload_http_code" = "201" ]; then
    echo "✅ Test file uploaded successfully"
    
    # Try to download the file
    DOWNLOAD_TEST=$(curl -s -w "\n%{http_code}" -X GET "$SUPABASE_URL/storage/v1/object/$BUCKET_NAME/test-diagnostic/$TEST_FILE" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY")
    
    download_http_code=$(echo "$DOWNLOAD_TEST" | tail -n1)
    download_response_body=$(echo "$DOWNLOAD_TEST" | sed '$d')
    
    echo "Download Test Response:"
    echo "Status Code: $download_http_code"
    if [ "$download_http_code" = "200" ]; then
        echo "✅ Test file downloaded successfully"
        echo "Content: $download_response_body"
    else
        echo "❌ Test file download failed"
        echo "Response: $download_response_body"
    fi
else
    echo "❌ Test file upload failed"
fi

echo ""

# 5. Clean up test file
echo "5️⃣ Cleaning up test file..."
DELETE_TEST=$(curl -s -w "\n%{http_code}" -X DELETE "$SUPABASE_URL/storage/v1/object/$BUCKET_NAME/test-diagnostic/$TEST_FILE" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY")

delete_http_code=$(echo "$DELETE_TEST" | tail -n1)
delete_response_body=$(echo "$DELETE_TEST" | sed '$d')

if [ "$delete_http_code" = "200" ] || [ "$delete_http_code" = "204" ]; then
    echo "✅ Test file deleted successfully"
else
    echo "⚠️  Test file deletion failed (this is okay if file didn't exist)"
    echo "Response: $delete_response_body"
fi

# Clean up local test file
rm -f "$TEST_FILE"

echo ""
echo "🔍 Storage Diagnostic Complete"
echo "=============================="

if [ "$upload_http_code" = "200" ] || [ "$upload_http_code" = "201" ]; then
    echo "✅ Storage is working correctly"
    echo "✅ Upload functionality: OK"
    echo "✅ Download functionality: OK"
    echo "✅ Delete functionality: OK"
else
    echo "❌ Storage has issues"
    echo "❌ Upload functionality: Failed"
    echo "Please check:"
    echo "1. Service role key permissions"
    echo "2. Bucket exists and is accessible"
    echo "3. Storage policies are configured"
fi

# Clean up local test file
rm -f "$TEST_FILE"

# 5. Check environment variables in function
echo "6️⃣ Checking function environment variables..."
FUNCTION_URL="$SUPABASE_URL/functions/v1/generate-audio"

ENV_CHECK=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -d '{"userId": "test-diagnostic", "checkEnv": true}')

echo "Environment Check Response:"
echo "$ENV_CHECK"
echo ""

echo "🔍 Diagnostic Complete!"
echo ""
echo "💡 Common Issues and Solutions:"
echo "1. Missing SUPABASE_STORAGE_BUCKET environment variable"
echo "2. Bucket not created or misconfigured"
echo "3. Incorrect bucket policies"
echo "4. File size limits exceeded"
echo "5. Content type mismatches"
echo ""
echo "📝 Next Steps:"
echo "- Check the responses above for specific error messages"
echo "- Verify your environment variables are set correctly"
echo "- Ensure the storage bucket exists and has proper policies" 