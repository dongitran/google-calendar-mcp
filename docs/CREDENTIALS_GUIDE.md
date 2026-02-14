# Getting OAuth Credentials for GOOGLE_OAUTH_CREDENTIALS_JSON

## Understanding Credential Types

Google Cloud has different types of credentials:

1. **OAuth Client Credentials** (what we need) - For user-facing applications
2. **Service Account Keys** - For server-to-server authentication
3. **Application Default Credentials (ADC)** - For gcloud CLI

## How to Get OAuth Credentials

### ❌ Cannot use `gcloud` CLI directly

The `gcloud` CLI cannot create OAuth client credentials. You must use the Google Cloud Console.

**Why?** OAuth client credentials require:
- Consent screen configuration
- Redirect URIs setup
- Manual download of client secret

These are only available through the Console UI.

### ✅ Method 1: Google Cloud Console (Recommended)

**Step-by-step:**

1. **Go to Google Cloud Console**
   ```
   https://console.cloud.google.com/apis/credentials
   ```

2. **Select or create a project**

3. **Configure OAuth consent screen** (if not done)
   - Click "OAuth consent screen" in left menu
   - Choose "External" user type
   - Fill in app name and support email
   - Add scopes: `https://www.googleapis.com/auth/calendar`

4. **Create OAuth client ID**
   - Click "+ CREATE CREDENTIALS" → "OAuth client ID"
   - Application type: **Desktop app**
   - Name: `google-calendar-mcp` (or any name)
   - Click "Create"

5. **Download JSON**
   - Click the download icon next to your credential
   - Save as `gcp-oauth.keys.json`

### ✅ Method 2: Use our helper script

Once you have the JSON file:

```bash
# Run the helper script
./scripts/export-credentials-json.sh ./path/to/gcp-oauth.keys.json

# This will output the export command ready to copy
```

### ✅ Method 3: Manual conversion

If you already have `gcp-oauth.keys.json`:

```bash
# Option A: One-liner (requires jq)
export GOOGLE_OAUTH_CREDENTIALS_JSON=$(cat gcp-oauth.keys.json | jq -c .)

# Option B: Without jq (less clean but works)
export GOOGLE_OAUTH_CREDENTIALS_JSON='{"installed":{"client_id":"YOUR_CLIENT_ID","project_id":"YOUR_PROJECT","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"YOUR_CLIENT_SECRET","redirect_uris":["http://localhost"]}}'
```

## Common Confusion

### 🤔 "Can I use Service Account instead?"

**No**, for Google Calendar MCP you need OAuth credentials because:
- Calendar API requires user consent for accessing personal calendars
- Service accounts have their own separate calendars (not user's calendar)
- OAuth allows users to grant permission to access their calendars

### 🤔 "What about Application Default Credentials (ADC)?"

ADC (`gcloud auth application-default login`) creates credentials for:
- Your local development environment
- Server applications using your user account

But it's **not suitable** for MCP servers that need to act on behalf of different users.

## File Format

Your `gcp-oauth.keys.json` should look like this:

```json
{
  "installed": {
    "client_id": "123456-xyz.apps.googleusercontent.com",
    "project_id": "your-project-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_secret": "GOCSPX-xxxxxxxxxxxxx",
    "redirect_uris": ["http://localhost"]
  }
}
```

For `GOOGLE_OAUTH_CREDENTIALS_JSON`, use the **minified version** (no whitespace):

```bash
{"installed":{"client_id":"123456-xyz.apps.googleusercontent.com","project_id":"your-project-id","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"GOCSPX-xxxxxxxxxxxxx","redirect_uris":["http://localhost"]}}
```

## Alternative: Direct Format

You can also use the direct format (without the `installed` wrapper):

```bash
export GOOGLE_OAUTH_CREDENTIALS_JSON='{"client_id":"...","client_secret":"...","redirect_uris":["http://localhost:3000/oauth2callback"]}'
```

Both formats are supported!

## Security Best Practices

⚠️ **Important:**
- Never commit credentials to git
- Use secrets management in production (Kubernetes Secrets, AWS Secrets Manager, etc.)
- Rotate credentials periodically
- Use environment-specific credentials for dev/staging/prod

## Quick Reference

| Method | Use Case | Command |
|--------|----------|---------|
| Helper Script | Convert file to env var | `./scripts/export-credentials-json.sh gcp-oauth.keys.json` |
| Manual with jq | Quick conversion | `export GOOGLE_OAUTH_CREDENTIALS_JSON=$(cat FILE \| jq -c .)` |
| Environment File | File path (backward compatible) | `export GOOGLE_OAUTH_CREDENTIALS=./gcp-oauth.keys.json` |
| Direct Input | CI/CD, Docker | Set env var directly in platform |

## Troubleshooting

### "File not found"
Make sure your JSON file is in the correct location or provide the full path.

### "Invalid JSON"
Validate your JSON first:
```bash
cat gcp-oauth.keys.json | jq .
```

### "Permission denied"
Make the script executable:
```bash
chmod +x scripts/export-credentials-json.sh
```
