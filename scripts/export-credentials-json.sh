#!/bin/bash

# Script to export Google OAuth credentials as JSON string for GOOGLE_OAUTH_CREDENTIALS_JSON
# Usage: ./scripts/export-credentials-json.sh [path-to-credentials-file]

set -e

# Default credentials file path
CREDS_FILE="${1:-./gcp-oauth.keys.json}"

# Check if file exists
if [ ! -f "$CREDS_FILE" ]; then
    echo "Error: Credentials file not found: $CREDS_FILE" >&2
    echo "" >&2
    echo "Usage: $0 [path-to-credentials-file]" >&2
    echo "Example: $0 ./gcp-oauth.keys.json" >&2
    echo "" >&2
    echo "To download OAuth credentials:" >&2
    echo "1. Go to https://console.cloud.google.com/apis/credentials" >&2
    echo "2. Click 'Create Credentials' > 'OAuth client ID'" >&2
    echo "3. Choose 'Desktop app' as application type" >&2
    echo "4. Download the JSON file" >&2
    exit 1
fi

# Read and minify JSON (remove whitespace)
JSON_CONTENT=$(cat "$CREDS_FILE" | jq -c .)

echo "✓ Successfully read credentials from: $CREDS_FILE"
echo ""
echo "📋 Copy the export command below to set the environment variable:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "export GOOGLE_OAUTH_CREDENTIALS_JSON='$JSON_CONTENT'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Tips:"
echo "  • For Docker: ENV GOOGLE_OAUTH_CREDENTIALS_JSON='$JSON_CONTENT'"
echo "  • For .env file: Add the export command to your .env file"
echo "  • For CI/CD: Add as a secret in your CI/CD platform"
echo ""
echo "🔒 Security reminder: Keep this value secret. Don't commit to git!"
