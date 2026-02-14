#!/bin/bash
# Setup OAuth credentials for Kubernetes on GCP
# This automates everything EXCEPT the initial OAuth client creation
# (which must be done manually due to Google API limitations)

set -e

PROJECT_ID=$(gcloud config get-value project)
SECRET_NAME="${GOOGLE_OAUTH_SECRET_NAME:-google-calendar-oauth-creds}"
K8S_SECRET_NAME="${K8S_SECRET_NAME:-calendar-creds}"
NAMESPACE="${K8S_NAMESPACE:-default}"
CREDS_FILE="${1:-gcp-oauth.keys.json}"

echo "🔧 OAuth Credentials Setup for K8s"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project ID:    $PROJECT_ID"
echo "Creds file:    $CREDS_FILE"
echo "GCP Secret:    $SECRET_NAME"
echo "K8s Secret:    $K8S_SECRET_NAME"
echo "K8s Namespace: $NAMESPACE"
echo ""

# Check if credentials file exists
if [ ! -f "$CREDS_FILE" ]; then
  echo "❌ Error: Credentials file not found: $CREDS_FILE"
  echo ""
  echo "📝 Manual step required (one-time setup):"
  echo ""
  echo "1. Open: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
  echo "2. Click 'CREATE CREDENTIALS' → 'OAuth client ID'"
  echo "3. Application type: 'Desktop app'"
  echo "4. Name: google-calendar-mcp (or any name)"
  echo "5. Click 'Create' and download JSON"
  echo "6. Save as: $CREDS_FILE"
  echo "7. Run this script again: $0"
  echo ""
  exit 1
fi

echo "✓ Found credentials file: $CREDS_FILE"

# Validate JSON
if ! jq empty "$CREDS_FILE" 2>/dev/null; then
  echo "❌ Error: Invalid JSON in $CREDS_FILE"
  exit 1
fi

echo "✓ JSON is valid"

# Convert to compact JSON
JSON_CREDS=$(cat "$CREDS_FILE" | jq -c .)

# Store in GCP Secret Manager
echo ""
echo "📦 Storing in GCP Secret Manager..."
if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
  echo "  → Secret already exists, adding new version..."
  echo -n "$JSON_CREDS" | gcloud secrets versions add "$SECRET_NAME" \
    --data-file=- \
    --project="$PROJECT_ID"
else
  echo "  → Creating new secret..."
  echo -n "$JSON_CREDS" | gcloud secrets create "$SECRET_NAME" \
    --data-file=- \
    --replication-policy="automatic" \
    --project="$PROJECT_ID"
fi

echo "✓ Stored in Secret Manager: projects/$PROJECT_ID/secrets/$SECRET_NAME"

# Create K8s secret (if kubectl available)
echo ""
if command -v kubectl &>/dev/null; then
  echo "🔐 Creating Kubernetes secret..."
  
  # Check if namespace exists
  if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    kubectl create secret generic "$K8S_SECRET_NAME" \
      --from-literal=GOOGLE_OAUTH_CREDENTIALS_JSON="$JSON_CREDS" \
      --namespace="$NAMESPACE" \
      --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✓ K8s secret created: $K8S_SECRET_NAME (namespace: $NAMESPACE)"
  else
    echo "⚠️  Namespace '$NAMESPACE' not found. Skipping K8s secret creation."
    echo "    Create namespace first: kubectl create namespace $NAMESPACE"
  fi
else
  echo "ℹ️  kubectl not found - skipping K8s secret creation"
  echo "   You can create it manually later:"
  echo "   kubectl create secret generic $K8S_SECRET_NAME \\"
  echo "     --from-literal=GOOGLE_OAUTH_CREDENTIALS_JSON='$JSON_CREDS' \\"
  echo "     --namespace=$NAMESPACE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Usage in Kubernetes:"
echo ""
echo "apiVersion: v1"
echo "kind: Pod"
echo "spec:"
echo "  containers:"
echo "  - name: mcp-server"
echo "    env:"
echo "    - name: GOOGLE_OAUTH_CREDENTIALS_JSON"
echo "      valueFrom:"
echo "        secretKeyRef:"
echo "          name: $K8S_SECRET_NAME"
echo "          key: GOOGLE_OAUTH_CREDENTIALS_JSON"
echo ""
echo "🔍 Verify Secret Manager:"
echo "  gcloud secrets versions list $SECRET_NAME --project=$PROJECT_ID"
echo ""
echo "🔍 Verify K8s Secret:"
echo "  kubectl get secret $K8S_SECRET_NAME -n $NAMESPACE -o yaml"
