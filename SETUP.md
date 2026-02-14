# Google Calendar MCP - Quick Setup

Complete setup guide for Google Calendar MCP server OAuth authentication.

## Prerequisites

- Google Cloud account
- Project with billing enabled (free tier works)

## Setup Steps

### 1. Enable Google Calendar API

1. Go to [API Library](https://console.cloud.google.com/apis/library)
2. Search "Google Calendar API"
3. Click **Enable**

### 2. Create OAuth Credentials

1. Go to [Credentials](https://console.cloud.google.com/apis/credentials)
2. Click **Create Credentials** → **OAuth client ID**
3. Configure consent screen if prompted:
   - User Type: **External**
   - App name: Your app name
   - User support email: Your email
   - Developer contact: Your email
4. Application type: **Desktop app**
5. Name: `google-calendar-mcp` (or any name)
6. Click **Create**
7. Download JSON credentials file

### 3. Add Test Users

**Important:** Apps in Testing mode only allow pre-approved users.

1. Go to [Audience](https://console.cloud.google.com/auth/audience)
2. Click **+ ADD USERS**
3. Enter your email address
4. Click **Save**

**Alternative:** Publish app (shows "unverified" warning but works for any user)

### 4. Configure MCP Server

Add to your MCP client configuration (e.g., `~/.gemini/antigravity/mcp_config.json` for Antigravity, or `~/Library/Application Support/Claude/claude_desktop_config.json` for Claude Desktop):

```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "npx",
      "args": ["@dongtran/google-calendar-mcp"],
      "env": {
        "GOOGLE_OAUTH_CREDENTIALS_JSON": "{\"installed\":{\"client_id\":\"YOUR_CLIENT_ID\",\"client_secret\":\"YOUR_CLIENT_SECRET\",\"redirect_uris\":[\"http://localhost\"]}}"
      }
    }
  }
}
```

**Note:** Replace `YOUR_CLIENT_ID` and `YOUR_CLIENT_SECRET` with values from your downloaded credentials JSON file.

### 5. First Authentication

1. Start your MCP client (e.g., Claude Desktop, Antigravity)
2. Call any calendar tool
3. Browser opens automatically
4. Login with test user email
5. Click **Allow**
6. Done! Token saved to `~/.config/google-calendar-mcp/tokens.json`

## Common Issues

### "Access blocked: [app] has not completed Google verification"
→ Add your email to test users (Step 3)

### "API has not been used in project before or is disabled"
→ Enable Google Calendar API (Step 1)

### "No authenticated accounts available"
→ Restart MCP client and retry

## Token Expiration

- **Testing mode:** Tokens expire after 7 days
- **Published mode:** Tokens don't expire

To avoid weekly re-auth:
1. Go to [OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent)
2. Click **Publish App**
3. Don't submit for verification

## Documentation

- [CREATE_OAUTH_CREDENTIALS.md](docs/CREATE_OAUTH_CREDENTIALS.md) - Detailed credential setup
- [ADD_TEST_USERS.md](docs/ADD_TEST_USERS.md) - Test user configuration
- [K8S_GCP_SETUP.md](docs/K8S_GCP_SETUP.md) - Kubernetes/GCP deployment
- [README.md](README.md) - Full documentation
