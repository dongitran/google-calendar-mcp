# Hướng Dẫn Tạo OAuth Credentials Trên GCP Console

## 📋 Tổng Quan

**Thời gian:** ~5 phút (lần đầu tiên)  
**Yêu cầu:** Google Cloud account + project

---

## Bước 1: Mở Google Cloud Console

**Link trực tiếp:**
```
https://console.cloud.google.com/apis/credentials
```

Hoặc navigate thủ công:
1. Vào https://console.cloud.google.com
2. Chọn project của bạn (hoặc tạo mới)
3. Menu ☰ →  **APIs & Services** → **Credentials**

---

## Bước 2: Enable Google Calendar API

Trước khi tạo credentials, cần enable API:

```
https://console.cloud.google.com/apis/library/calendar-json.googleapis.com
```

Hoặc:
1. Menu ☰ → **APIs & Services** → **Library**
2. Tìm "Google Calendar API"
3. Click **ENABLE**

✅ Đợi vài giây cho API được enable

---

## Bước 3: Cấu Hình OAuth Consent Screen (Nếu Chưa Có)

**⚠️ Bắt buộc trước khi tạo OAuth credentials**

### 3.1. Navigate đến OAuth Consent Screen:
```
https://console.cloud.google.com/apis/credentials/consent
```

Hoặc: **APIs & Services** → **OAuth consent screen**

### 3.2. Chọn User Type:

**Option A: External (Recommended cho testing)**
- Cho phép bất kỳ Google user nào authenticate
- Cần thêm test users nếu app chưa publish
- **Chọn cái này** nếu không có Google Workspace

**Option B: Internal**
- Chỉ dành cho Google Workspace organization
- Chỉ users trong org mới dùng được

👉 **Chọn "External"** → Click **CREATE**

### 3.3. Điền Thông Tin App:

**App information:**
- **App name:** `Google Calendar MCP Server` (hoặc tên bạn muốn)
- **User support email:** Email của bạn
- **Developer contact:** Email của bạn

**App domain** (optional - có thể bỏ qua cho testing):
- Application home page
- Privacy policy
- Terms of service

**Authorized domains** (optional - bỏ qua cho testing)

👉 Click **SAVE AND CONTINUE**

### 3.4. Thêm Scopes:

Click **ADD OR REMOVE SCOPES**

Tìm và chọn:
- ✅ `https://www.googleapis.com/auth/calendar`
- ✅ `https://www.googleapis.com/auth/calendar.events`

Hoặc search: **"Google Calendar API"**

👉 Click **UPDATE** → **SAVE AND CONTINUE**

### 3.5. Thêm Test Users (Cho External app):

Trong phần "Test users":
1. Click **ADD USERS**
2. Nhập email của bạn (email dùng để test)
3. Click **SAVE**

👉 **SAVE AND CONTINUE** → **BACK TO DASHBOARD**

✅ OAuth Consent Screen đã setup xong!

---

## Bước 4: Tạo OAuth Client ID

### 4.1. Navigate:
```
https://console.cloud.google.com/apis/credentials
```

Click **+ CREATE CREDENTIALS** (button phía trên)

### 4.2. Chọn Loại:

Click **OAuth client ID**

### 4.3. Chọn Application Type:

**Application type:** Chọn **Desktop app**

### 4.4. Đặt Tên:

**Name:** `google-calendar-mcp-desktop` (hoặc tên bạn muốn)

👉 Click **CREATE**

---

## Bước 5: Download Credentials

### Popup hiện ra với Client ID và Client Secret:

1. Click **DOWNLOAD JSON** (icon download ⬇️)
2. File sẽ download với tên dạng: `client_secret_123456-xyz.apps.googleusercontent.com.json`

### Rename file:
```bash
mv ~/Downloads/client_secret_*.json ~/Downloads/gcp-oauth.keys.json
```

Hoặc rename thủ công thành `gcp-oauth.keys.json`

✅ **Xong! Bạn đã có OAuth credentials file!**

---

## Bước 6: Sử Dụng Credentials

### Option A: Dùng trực tiếp với file path

```bash
export GOOGLE_OAUTH_CREDENTIALS=./gcp-oauth.keys.json
npx @dongtran/google-calendar-mcp auth
```

### Option B: Convert sang JSON string

```bash
# Dùng script helper
./scripts/export-credentials-json.sh gcp-oauth.keys.json

# Hoặc thủ công
export GOOGLE_OAUTH_CREDENTIALS_JSON=$(cat gcp-oauth.keys.json | jq -c .)
```

### Option C: Setup cho K8s/GCP

```bash
./scripts/setup-oauth-for-k8s.sh gcp-oauth.keys.json
```

---

## 🎯 Quick Commands

**Open Console directly to create credentials:**
```bash
open "https://console.cloud.google.com/apis/credentials?project=$(gcloud config get-value project)"
```

**Enable Calendar API:**
```bash
gcloud services enable calendar-json.googleapis.com
```

**Check enabled APIs:**
```bash
gcloud services list --enabled | grep calendar
```

---

## 📸 Visual Guide

### Credentials Page Layout:
```
┌─────────────────────────────────────────────────────┐
│  APIs & Services > Credentials                      │
├─────────────────────────────────────────────────────┤
│  [+ CREATE CREDENTIALS ▼]   [+ CREATE]              │
│                                                      │
│  OAuth 2.0 Client IDs                               │
│  ┌─────────────────────────────────────────────┐   │
│  │ Name              Type         Created       │   │
│  │ my-desktop-app    Desktop app  Jan 15, 2024 │⬇️ │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

Click **⬇️** để download JSON file

---

## 🔧 Troubleshooting

### "OAuth consent screen is not configured"
→ Quay lại **Bước 3** và setup OAuth consent screen

### "API not enabled"
→ Enable Google Calendar API:
```bash
gcloud services enable calendar-json.googleapis.com
```

### "Download button không thấy"
→ Click vào credential name, rồi click **DOWNLOAD JSON** trong detail page

### "File JSON không đúng format"
→ Verify structure:
```bash
cat gcp-oauth.keys.json | jq .
```

Should có structure:
```json
{
  "installed": {
    "client_id": "...",
    "project_id": "...",
    "auth_uri": "...",
    "token_uri": "...",
    "client_secret": "...",
    "redirect_uris": ["..."]
  }
}
```

---

## 🔒 Security Best Practices

1. **Không commit vào git:**
   ```bash
   echo "gcp-oauth.keys.json" >> .gitignore
   ```

2. **Store trong secret manager:**
   ```bash
   gcloud secrets create google-calendar-oauth \
     --data-file=gcp-oauth.keys.json
   ```

3. **Restrict permissions:**
   ```bash
   chmod 600 gcp-oauth.keys.json
   ```

4. **Rotate định kỳ:**
   - Tạo OAuth client mới
   - Migrate users
   - Delete client cũ

---

## ✅ Next Steps

Sau khi có credentials file:

1. **Test locally:**
   ```bash
   export GOOGLE_OAUTH_CREDENTIALS=./gcp-oauth.keys.json
   npx @dongtran/google-calendar-mcp auth
   ```

2. **Setup cho production:**
   ```bash
   ./scripts/setup-oauth-for-k8s.sh gcp-oauth.keys.json
   ```

3. **Deploy application** với credentials configured

---

## 📚 Related Docs

- [CREDENTIALS_GUIDE.md](./CREDENTIALS_GUIDE.md) - Chi tiết về credential types
- [K8S_GCP_SETUP.md](./K8S_GCP_SETUP.md) - K8s deployment với GCP
- [GCLOUD_OAUTH_RESEARCH.md](./GCLOUD_OAUTH_RESEARCH.md) - Research về gcloud options

---

## 🆘 Need Help?

**Console không load?**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

**Permission denied?**
- Check bạn có role `roles/owner` hoặc `roles/editor` trong project
- Hoặc ít nhất: `roles/iam.serviceAccountAdmin`

**Vẫn stuck?**
- Check [official Google docs](https://developers.google.com/identity/protocols/oauth2)
- Hoặc xem README.md của project này
