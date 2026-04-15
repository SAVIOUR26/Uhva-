# UHVA Player — GitHub Setup Guide
# Run all commands in PowerShell (Windows)

# ══════════════════════════════════════════════════════════════════
# STEP 1 — Extract the zip
# ══════════════════════════════════════════════════════════════════

# After downloading uhva_player.zip, extract it somewhere clean:
Expand-Archive -Path "$HOME\Downloads\uhva_player.zip" -DestinationPath "$HOME\Projects"
cd "$HOME\Projects\uhva_player"

# ══════════════════════════════════════════════════════════════════
# STEP 2 — Apply the media_kit updates from uhva_extras.zip
# ══════════════════════════════════════════════════════════════════
# Extract uhva_extras.zip too, then copy over the updated files:

# Replace pubspec.yaml
Copy-Item "$HOME\Downloads\uhva_extras\pubspec.yaml" -Destination ".\pubspec.yaml" -Force

# Replace main.dart
Copy-Item "$HOME\Downloads\uhva_extras\main.dart" -Destination ".\lib\main.dart" -Force

# Replace player screens with media_kit versions
Copy-Item "$HOME\Downloads\uhva_extras\player_screen.dart" `
  -Destination ".\lib\screens\player\player_screen.dart" -Force

Copy-Item "$HOME\Downloads\uhva_extras\vod_player_screen.dart" `
  -Destination ".\lib\screens\player\vod_player_screen.dart" -Force

# Copy CLAUDE.md to project root
Copy-Item "$HOME\Downloads\uhva_extras\CLAUDE.md" -Destination ".\CLAUDE.md" -Force

# Create GitHub Actions workflow directory and file
New-Item -ItemType Directory -Force -Path ".\.github\workflows"
Copy-Item "$HOME\Downloads\uhva_extras\.github\workflows\build.yml" `
  -Destination ".\.github\workflows\build.yml" -Force

# ══════════════════════════════════════════════════════════════════
# STEP 3 — Verify Flutter setup
# ══════════════════════════════════════════════════════════════════
flutter --version
flutter pub get
# Should complete with no errors

# ══════════════════════════════════════════════════════════════════
# STEP 4 — Create GitHub repo (do this in the browser first)
# ══════════════════════════════════════════════════════════════════
# 1. Go to https://github.com/new
# 2. Repo name: uhva-player
# 3. Private (recommended — client project)
# 4. Do NOT initialize with README (we're pushing our own)
# 5. Click "Create repository"
# 6. Copy the repo URL: https://github.com/YOUR_USERNAME/uhva-player.git

# ══════════════════════════════════════════════════════════════════
# STEP 5 — Initialize git and push
# ══════════════════════════════════════════════════════════════════
git init
git add .
git commit -m "feat: initial UHVA Player project — Flutter + Xtream Codes + media_kit"

# Set your remote (replace with your actual GitHub URL)
git remote add origin https://github.com/YOUR_USERNAME/uhva-player.git
git branch -M main
git push -u origin main

# ══════════════════════════════════════════════════════════════════
# STEP 6 — Watch the debug build run
# ══════════════════════════════════════════════════════════════════
# Go to: https://github.com/YOUR_USERNAME/uhva-player/actions
# You will see "UHVA Player — Build" workflow running automatically.
# After ~5 minutes, click the run → scroll down → "Artifacts"
# Download: debug-apks-XXXXXXX.zip — install on your device!

# ══════════════════════════════════════════════════════════════════
# STEP 7 — Connect Claude Code
# ══════════════════════════════════════════════════════════════════
# 1. Open terminal in the project folder
# 2. Run: claude
# 3. Claude Code will find CLAUDE.md automatically
# 4. First message to Claude Code:
#
#    "Read the CLAUDE.md and then start with feature #1 —
#     build the Series / TV Shows screen"
#
# Claude Code will:
#   - Read CLAUDE.md for full context
#   - Build series_screen.dart and series_detail_screen.dart
#   - Update AppProvider with series state
#   - Update XtreamService with series endpoints
#   - Add "Series" tab to HomeScreen and TV side nav

# ══════════════════════════════════════════════════════════════════
# STEP 8 — Release workflow (when ready for client)
# ══════════════════════════════════════════════════════════════════
# Tag a version to trigger the full release build:
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will:
#   1. Build release APKs (arm64, arm32, x86_64, universal)
#   2. Create a GitHub Release automatically
#   3. Attach all 4 APKs to the release
#   4. Show size table in the release notes
#
# Download URL will be:
# https://github.com/YOUR_USERNAME/uhva-player/releases/tag/v1.0.0

# ══════════════════════════════════════════════════════════════════
# OPTIONAL — Add keystore signing for client-ready APKs
# ══════════════════════════════════════════════════════════════════
# Generate keystore (run once, keep the .jks file safe!):
keytool -genkey -v -keystore uhva-release.jks -alias uhva -keyalg RSA -keysize 2048 -validity 10000

# Base64 encode it:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("uhva-release.jks")) | clip
# (now it's in your clipboard)

# Go to GitHub repo → Settings → Secrets and variables → Actions → New secret:
#   KEYSTORE_BASE64  = paste from clipboard
#   KEY_ALIAS        = uhva
#   KEY_PASSWORD     = (the password you set)
#   STORE_PASSWORD   = (the password you set)

# Next time you push a tag, APKs will be properly signed.

# ══════════════════════════════════════════════════════════════════
# USEFUL COMMANDS
# ══════════════════════════════════════════════════════════════════

# Install debug APK to connected phone:
adb install build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk

# Install to Android TV (same network):
adb connect 192.168.1.X:5555
adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

# Run on specific device:
flutter devices                          # list connected devices
flutter run -d <device_id>

# Check for issues before pushing:
flutter analyze
flutter test
