# GitHub MCP Authentication Fix

## 🔍 Root Cause

The GitHub MCP failed with **"Bad credentials"** because the environment variable `GITHUB_PERSONAL_ACCESS_TOKEN` is **NOT SET**.

**Evidence:**
```json
// From mcp.json
"env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
}
```

The MCP config expects this environment variable, but when we checked:
```powershell
PS> $env:GITHUB_PERSONAL_ACCESS_TOKEN
# (empty - not set!)
```

---

## ✅ The Fix (Choose One Method)

### **Method 1: Set Environment Variable (Recommended)**

#### Step 1: Create GitHub Personal Access Token
1. Go to https://github.com/settings/tokens/new
2. Token name: `VS Code MCP Server`
3. Expiration: Choose your preference (90 days recommended)
4. Select scopes:
   - ✅ `repo` (Full control of private repositories) - **REQUIRED**
   - ✅ `workflow` (Update GitHub Action workflows) - Optional
   - ✅ `admin:org` (Full control of orgs) - Optional for org repos
5. Click **Generate token**
6. **COPY THE TOKEN** (you won't see it again!)

#### Step 2: Set Environment Variable (Permanent)
```powershell
# Add to your PowerShell profile (permanent)
[System.Environment]::SetEnvironmentVariable('GITHUB_PERSONAL_ACCESS_TOKEN', 'YOUR_TOKEN_HERE', 'User')

# Verify it's set
$env:GITHUB_PERSONAL_ACCESS_TOKEN
```

#### Step 3: Restart VS Code
Environment variables require VS Code restart to take effect.

---

### **Method 2: Direct Token in Config (Less Secure)**

Edit: `c:\Users\Romar\AppData\Roaming\Code\User\profiles\-2bd0103b\mcp.json`

Replace:
```json
"env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
}
```

With:
```json
"env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN_HERE"
}
```

⚠️ **Security Risk**: Token is stored in plain text!

---

### **Method 3: Use GitHub CLI (Easiest)**

Don't use MCP at all - just use GitHub CLI:

```powershell
# Install GitHub CLI
winget install --id GitHub.cli

# Login (one-time)
gh auth login

# Create repo and push
gh repo create windows-auto-theme-switcher --public --source=. --push
```

---

## 🧪 Verify the Fix

After setting the token, test it:

```powershell
# Restart VS Code first, then run this in terminal
node -e "console.log(process.env.GITHUB_PERSONAL_ACCESS_TOKEN ? 'Token is set!' : 'Token NOT set')"
```

Then try creating the repo again with the MCP tool.

---

## 📝 Summary

**What was wrong:** No GitHub token configured  
**Why it failed:** MCP couldn't authenticate to GitHub API  
**The fix:** Create token → Set environment variable → Restart VS Code  
**Fastest solution:** Use GitHub CLI instead (`gh repo create`)

---

## Token Scopes Explained

For creating repositories, you need:
- **`repo`**: Full control - can create, read, write, delete repos
- **`public_repo`**: Only public repos (if you only create public repos)
- **`workflow`**: Needed if your repos use GitHub Actions

For the AutoThemeSwitcher project (public repo), minimum scope: `repo`
