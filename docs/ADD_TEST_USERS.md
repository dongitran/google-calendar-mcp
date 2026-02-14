# Adding Test Users to OAuth App

## Quick Fix for "Access blocked: main" Error

When your OAuth app is in **Testing mode**, only pre-approved test users can authenticate.

### Steps:

1. **Go to Audience page:**
   ```
   https://console.cloud.google.com/auth/audience?project=YOUR_PROJECT_ID
   ```
   
   *Replace `YOUR_PROJECT_ID` with your GCP project ID*

2. **Add test user:**
   - Click **"+ ADD USERS"** button
   - Enter email address (e.g., `youremail@gmail.com`)
   - Click **"SAVE"**

3. **Re-authenticate:**
   - Refresh the OAuth authorization page
   - Login with the added email
   - Click **"Allow"**
   - Done! ✅

### Alternative: Publish App (Not Recommended for Personal Use)

If you publish your app to production mode:
- ✅ Any user can authenticate without being added
- ❌ Google shows "This app isn't verified" warning
- ❌ Users must click "Advanced" → "Go to [unsafe]" to proceed

**For personal/development use, adding test users is simpler and safer.**

### Token Expiration in Testing Mode

- **Testing mode:** Tokens expire after **7 days** (requires re-authentication)
- **Published mode:** Tokens don't expire, but shows unverified warning

To avoid weekly re-auth while keeping Testing mode:
1. Go to [OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent)
2. Click **"PUBLISH APP"**
3. **Don't** submit for verification
4. Tokens will no longer expire after 7 days

---

**Note:** The correct page for adding test users is the **Audience** page, not the OAuth consent screen overview.
