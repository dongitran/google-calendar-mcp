# OAuth Credentials for GCP/K8s Environments

## TL;DR for K8s on GCP

**Bad news:** Google không cung cấp REST API public để tạo OAuth client credentials tự động.

**Good news:** Có các workarounds phù hợp cho K8s/GCP workflow:

## Option 1: One-time Setup + Secret Management ⭐ RECOMMENDED

### Setup (chỉ làm 1 lần):
```bash
# 1. Tạo OAuth credentials qua Console (1 lần duy nhất)
# → https://console.cloud.google.com/apis/credentials

# 2. Download JSON file → gcp-oauth.keys.json

# 3. Convert sang JSON string
JSON_CREDS=$(cat gcp-oauth.keys.json | jq -c .)

# 4. Store trong GCP Secret Manager (recommended cho production)
echo -n "$JSON_CREDS" | gcloud secrets create google-calendar-oauth-creds \
  --data-file=- \
  --replication-policy="automatic" \
  --project=YOUR_PROJECT_ID

# Hoặc lưu trong K8s Secret
kubectl create secret generic google-calendar-creds \
  --from-literal=GOOGLE_OAUTH_CREDENTIALS_JSON="$JSON_CREDS" \
  --namespace=your-namespace
```

### Usage trong K8s:

**Option A: GCP Secret Manager (recommended)**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: calendar-mcp
spec:
  serviceAccountName: workload-identity-sa  # với Workload Identity
  containers:
  - name: mcp-server
    image: your-image
    env:
    - name: GOOGLE_OAUTH_CREDENTIALS_JSON
      valueFrom:
        secretKeyRef:
          name: google-calendar-oauth-creds  # từ CSI driver
          key: creds
  volumes:
  - name: secrets
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "gcp-secrets"
```

**Option B: K8s Secret trực tiếp**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: calendar-mcp
spec:
  containers:
  - name: mcp-server
    image: your-image
    env:
    - name: GOOGLE_OAUTH_CREDENTIALS_JSON
      valueFrom:
        secretKeyRef:
          name: google-calendar-creds
          key: GOOGLE_OAUTH_CREDENTIALS_JSON
```

---

## Option 2: Terraform (Infrastructure as Code)

Terraform **CŨNG KHÔNG** tạo được OAuth client credentials tự động, nhưng có thể manage consent screen:

```hcl
# terraform/main.tf
resource "google_project_service" "calendar_api" {
  project = var.project_id
  service = "calendar-json.googleapis.com"
}

# Note: OAuth client credentials MUST be created manually
# This is a Google limitation - no API exists for this
data "external" "oauth_reminder" {
  program = ["bash", "-c", <<-EOT
    echo '{"note": "Create OAuth credentials manually at https://console.cloud.google.com/apis/credentials"}'
  EOT
  ]
}

output "oauth_credentials_reminder" {
  value = "⚠️ Manual step required: Create OAuth client ID at ${data.external.oauth_reminder.result.note}"
}
```

---

## Option 3: gcloud Script với Browser Automation (Advanced)

Nếu bạn **thực sự** muốn automate, có thể dùng browser automation:

```bash
#!/bin/bash
# scripts/create-oauth-credentials-automated.sh
# WARNING: This uses puppeteer/selenium - fragile and not recommended

# Requires: gcloud, node, puppeteer
PROJECT_ID=$(gcloud config get-value project)

# Use puppeteer to automate Console UI
node <<'EOF'
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  // Get gcloud auth token
  const token = process.env.GCLOUD_ACCESS_TOKEN;
  
  // Navigate to credentials page
  await page.goto('https://console.cloud.google.com/apis/credentials');
  
  // ... automate clicking through UI (VERY FRAGILE)
  // This breaks whenever Google updates the UI
  
  await browser.close();
})();
EOF
```

**⚠️ Không recommend** vì:
- Fragile (UI thay đổi là break)
- Cần browser automation tools
- Phức tạp và khó maintain

---

## Option 4: Hybrid Approach (Best Practice) ⭐

**Workflow cho K8s trên GCP:**

### 1. Initial Setup (Manual - Once per project)
```bash
# Tạo OAuth credentials qua Console
# → Download JSON
# → Store trong Secret Manager

# Script tự động hóa việc store:
./scripts/setup-oauth-for-k8s.sh
```

### 2. CI/CD Integration
```yaml
# .github/workflows/deploy.yml hoặc Cloud Build
steps:
  - name: Get OAuth credentials from Secret Manager
    run: |
      gcloud secrets versions access latest \
        --secret=google-calendar-oauth-creds \
        --project=$PROJECT_ID > /tmp/oauth-creds.json
      
  - name: Deploy to K8s with credentials
    run: |
      kubectl create secret generic calendar-creds \
        --from-file=oauth.json=/tmp/oauth-creds.json \
        --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Application Usage
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calendar-mcp
spec:
  template:
    spec:
      containers:
      - name: mcp-server
        image: gcr.io/PROJECT/calendar-mcp:latest
        env:
        - name: GOOGLE_OAUTH_CREDENTIALS_JSON
          valueFrom:
            secretKeyRef:
              name: calendar-creds
              key: oauth.json
```

---

## Complete Automation Script for K8s

Tớ tạo script helper để automate phần có thể automate:

```bash
#!/bin/bash
# scripts/setup-oauth-for-k8s.sh

set -e

PROJECT_ID=$(gcloud config get-value project)
SECRET_NAME="google-calendar-oauth-creds"
K8S_SECRET_NAME="calendar-creds"
NAMESPACE="${K8S_NAMESPACE:-default}"

echo "🔧 Setting up OAuth credentials for K8s..."
echo "Project: $PROJECT_ID"
echo ""

# Check if credentials file exists
if [ ! -f "gcp-oauth.keys.json" ]; then
  echo "❌ Error: gcp-oauth.keys.json not found"
  echo ""
  echo "📝 Manual step required:"
  echo "1. Go to: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
  echo "2. Create OAuth client ID (Desktop app type)"
  echo "3. Download JSON as 'gcp-oauth.keys.json' in current directory"
  echo "4. Run this script again"
  exit 1
fi

echo "✓ Found gcp-oauth.keys.json"

# Convert to compact JSON
JSON_CREDS=$(cat gcp-oauth.keys.json | jq -c .)

# Store in GCP Secret Manager
echo "📦 Storing in GCP Secret Manager..."
if gcloud secrets describe $SECRET_NAME --project=$PROJECT_ID &>/dev/null; then
  echo "  Secret already exists, creating new version..."
  echo -n "$JSON_CREDS" | gcloud secrets versions add $SECRET_NAME \
    --data-file=- \
    --project=$PROJECT_ID
else
  echo "  Creating new secret..."
  echo -n "$JSON_CREDS" | gcloud secrets create $SECRET_NAME \
    --data-file=- \
    --replication-policy="automatic" \
    --project=$PROJECT_ID
fi

echo "✓ Stored in Secret Manager: $SECRET_NAME"

# Create K8s secret
echo ""
echo "🔐 Creating Kubernetes secret..."
kubectl create secret generic $K8S_SECRET_NAME \
  --from-literal=GOOGLE_OAUTH_CREDENTIALS_JSON="$JSON_CREDS" \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✓ K8s secret created: $K8S_SECRET_NAME (namespace: $NAMESPACE)"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Usage in your K8s deployment:"
echo "  env:"
echo "  - name: GOOGLE_OAUTH_CREDENTIALS_JSON"
echo "    valueFrom:"
echo "      secretKeyRef:"
echo "        name: $K8S_SECRET_NAME"
echo "        key: GOOGLE_OAUTH_CREDENTIALS_JSON"
