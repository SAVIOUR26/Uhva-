# CLAUDE.md — UHVA Player

> This file is read by Claude Code to understand the project context, architecture,
> remaining work, and coding conventions. Follow all instructions here precisely.

---

## Project Identity

**App name:** UHVA Player
**Type:** Professional IPTV Player — Android Phone + Android TV
**Client:** Built by Thirdsan Enterprises Ltd, Kampala, Uganda
**Developer:** Saviour (Founder & CEO, Thirdsan Enterprises)
**Stack:** Flutter (Dart) + media_kit + Xtream Codes API

---

## IPTV Credentials (development / test)

```
Server:   http://ott1.co:8080
Username: umesh905
Password: 032026
```

These are pre-filled in `lib/screens/auth/login_screen.dart`.

---

## Architecture Overview

```
lib/
├── main.dart                         # Entry point — MediaKit.ensureInitialized(), provider
├── theme/app_theme.dart              # UHVA dark brand: primary #6C63FF, bg #07071A
├── models/models.dart                # XtreamUser, LiveChannel, VodStream, EpgEntry
├── services/
│   ├── xtream_service.dart           # All Xtream Codes API calls (singleton)
│   └── storage_service.dart          # SharedPreferences: creds, favourites, history
├── providers/app_provider.dart       # Central ChangeNotifier — all app state
├── screens/
│   ├── auth/login_screen.dart        # Login form (server URL + user + pass)
│   ├── home/home_screen.dart         # Phone: channel list + category pills + mini player
│   ├── home/tv_home_screen.dart      # TV: side nav + D-pad card grid + EPG row
│   ├── player/player_screen.dart     # Live channel fullscreen — media_kit + custom OSD
│   ├── player/vod_player_screen.dart # VOD fullscreen — media_kit + MaterialVideoControls
│   ├── vod/vod_screen.dart           # Movie poster grid + category filter
│   └── settings/settings_screen.dart # Account info, playback prefs, sign out
├── widgets/
│   ├── common/uhva_logo.dart         # Brand logo widget (icon + "UHVA Player" text)
│   └── channel/
│       ├── channel_tile.dart         # Channel row: logo + EPG progress + LIVE badge
│       └── category_bar.dart         # Horizontal scrollable category pills
└── utils/platform_utils.dart         # isTVScreen() — phone vs TV layout switch
```

**Platform routing:** `_RootRouter` in `main.dart` calls `PlatformUtils.isTVScreen(context)`
and renders either `HomeScreen` (phone) or `TvHomeScreen` (Android TV).

**State management:** Single `AppProvider` (ChangeNotifier + Provider).
All screens use `context.watch<AppProvider>()` or `context.read<AppProvider>()`.

**Video playback:** `media_kit` + `media_kit_video`. Always call
`MediaKit.ensureInitialized()` in `main()` before `runApp()`.

**API base:** All Xtream Codes calls go through `XtreamService` singleton
(`lib/services/xtream_service.dart`). Configure via `_xtream.configure(server, user, pass)`.

---

## Brand & Design Rules

- **Primary color:** `#6C63FF` (UhvaColors.primary)
- **Background:** `#07071A` (near-black, not pure black)
- **Surface:** `#0E0E24`
- **Card:** `#181832`
- **Live badge:** Red `#E53935`
- **Dark-first UI** — all screens use dark theme, no light mode
- **Typography:** Material3 defaults, weight 500 for titles, 400 for body
- Font sizes: channel names 13px, subtitles 10–11px, TV cards 11px
- TV cards: purple border `#6C63FF` 2px on focus, transparent otherwise
- Never use gradients except in OSD overlays (top/bottom gradient bars in player)

---

## Remaining Features to Build

Work through these **in order**. Each feature should be in its own commit.

### 1. Series / TV Shows screen
**File:** `lib/screens/series/series_screen.dart`
**File:** `lib/screens/series/series_detail_screen.dart`

Xtream Codes endpoints to use:
```
GET player_api.php?...&action=get_series_categories
GET player_api.php?...&action=get_series
GET player_api.php?...&action=get_series_info&series_id=N
```

`get_series_info` returns:
```json
{
  "info": { "name": "", "cover": "", "plot": "", "genre": "", "rating": "" },
  "seasons": { "1": [...] },
  "episodes": { "1": [ { "id": "", "episode_num": 1, "title": "", "container_extension": "mkv" } ] }
}
```

Episode stream URL pattern:
```
http://SERVER/series/USERNAME/PASSWORD/EPISODE_ID.EXTENSION
```

UI requirements:
- Series list screen: same poster grid layout as VOD (`vod_screen.dart`)
- Series detail screen: show cover, plot, genre, rating at top; season selector tabs below; episode list with play button
- Reuse `VodPlayerScreen` for episode playback — just pass the episode URL as a `Media(url)`
- Add "Series" tab to `HomeScreen` tab bar (after Movies)
- Add "Series" to `TvHomeScreen` side nav

Add to `AppProvider`:
```dart
List<VodStream> _series = [];
List<StreamCategory> _seriesCategories = [];
Future<void> loadSeries() async { ... }
```

Add to `XtreamService`:
```dart
Future<List<StreamCategory>> getSeriesCategories() async { ... }
Future<List<VodStream>> getSeries({String? categoryId}) async { ... }
Future<Map<String, dynamic>> getSeriesInfo(String seriesId) async { ... }
```

---

### 2. EPG Full-Screen Guide
**File:** `lib/screens/epg/epg_screen.dart`

A horizontal timeline EPG grid, similar to a TV guide:
- Rows = channels (show top 30 from current category)
- Columns = time slots (current hour ± 4 hours visible, scrollable)
- Current time shown as a vertical purple line overlay
- Current programme highlighted with primary color background
- Tap a programme cell → show bottom sheet with title, description, time range
- "Watch Now" button in bottom sheet navigates to `PlayerScreen`

Data: use `XtreamService.getEpg()` per channel. Fetch in parallel with `Future.wait()`.

Access: add EPG icon button in `HomeScreen` AppBar. On TV, add "Guide" to side nav.

---

### 3. Parental PIN Lock
**File:** `lib/screens/settings/parental_screen.dart`
**File:** `lib/widgets/common/pin_gate.dart`

- 4-digit PIN stored encrypted in `SharedPreferences` using a simple XOR obfuscation with a hardcoded salt — not cryptography-grade, but sufficient for parental control UX
- `PinGate` widget wraps any screen: if PIN is set and content is locked, shows PIN entry overlay before revealing content
- Settings screen: "Parental Controls" section with toggle (Enable/Disable), Set PIN, Change PIN
- Lock individual categories: store `Set<String> lockedCategoryIds` in storage
- On phone: category pill shows a lock icon if locked
- On TV: locked categories show a lock overlay on the card

Add to `StorageService`:
```dart
Future<void> setPin(String pin) async { ... }
String? getPin() { ... }
Future<void> clearPin() async { ... }
Future<void> setLockedCategories(Set<String> ids) async { ... }
Set<String> getLockedCategories() { ... }
```

---

### 4. Search Screen (full)
**File:** `lib/screens/search/search_screen.dart`

- Unified search across Live TV + VOD + Series in one results list
- Debounce input 400ms before firing search
- Group results by type: "Live Channels", "Movies", "Series" section headers
- Empty state: show "Popular" — last 5 watched channels
- Tap result → navigate to appropriate player
- On TV: accessible via the "Search" side nav item + keyboard/remote input

---

### 5. App Icon & Splash Screen
**Tool:** `flutter_launcher_icons` + `flutter_native_splash`

Add to `pubspec.yaml` dev_dependencies:
```yaml
flutter_launcher_icons: ^0.13.1
flutter_native_splash: ^2.4.0
```

Add config to `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/icon.png"
  adaptive_icon_background: "#07071A"
  adaptive_icon_foreground: "assets/images/icon_foreground.png"

flutter_native_splash:
  color: "#07071A"
  image: "assets/images/splash_logo.png"
  android: true
  ios: false
  fullscreen: true
```

Create a 1024×1024 icon PNG: dark background `#07071A`, purple play triangle `#6C63FF`,
white "U" letterform. Save to `assets/images/icon.png`.

Run:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

### 6. Download / Catch-up (stretch goal)
Only implement if `channel.tvArchive == true` and `channel.tvArchiveDuration > 0`.

Catch-up URL pattern:
```
http://SERVER/timeshift/USERNAME/PASSWORD/DURATION/START_TIME/STREAM_ID.m3u8
```

Where `START_TIME` is formatted as `YYYY-MM-DD:HH-MM`.

Add a "Catch-up" button in the player OSD that opens a bottom sheet with a
timeline of the last N hours (from EPG data). Tapping a time slot builds the
catch-up URL and loads it in a new `Player` instance.

---

## Coding Conventions

- **Dart style:** `flutter analyze` must pass with zero errors before committing
- **File naming:** `snake_case.dart` always
- **Widget naming:** `PascalCase`, private helpers prefix with `_`
- **No hardcoded strings** in UI — use constants or pass via constructor
- **No print() statements** — use `debugPrint()` only in dev, remove before release
- **Null safety:** Dart 3 null safety everywhere, no `!` force-unwrap unless truly safe
- **Imports order:** dart: → package: → relative (separated by blank lines)
- **State:** all business logic in `AppProvider` or a dedicated provider, never in widgets
- **Colors:** always reference `UhvaColors.*` constants — never raw hex in widget files
- **Media_kit:** create `Player()` in `initState()`, dispose in `dispose()`, always call `WakelockPlus.enable()` on play and `WakelockPlus.disable()` on dispose

---

## GitHub Actions CI/CD

Workflow file: `.github/workflows/build.yml`

| Trigger | Job | Output |
|---------|-----|--------|
| Push to `main` or `develop` | `build_debug` | Debug APKs uploaded as artifacts (14-day retention) |
| Tag `v*.*.*` (e.g. `v1.0.0`) | `build_release` | Signed release APKs + GitHub Release created automatically |

**To trigger a release:**
```powershell
git tag v1.0.0
git push origin v1.0.0
```

**To add signing** (optional but recommended before giving to client):
1. Generate keystore on your machine
2. Base64 encode it and add as GitHub secret `KEYSTORE_BASE64`
3. Add secrets: `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`
4. The workflow auto-detects and signs if secrets exist

---

## API Quick Reference

```
Base: http://ott1.co:8080/player_api.php?username=umesh905&password=032026

Auth:           &action=  (no action = auth check)
Live cats:      &action=get_live_categories
Live streams:   &action=get_live_streams[&category_id=N]
VOD cats:       &action=get_vod_categories
VOD streams:    &action=get_vod_streams[&category_id=N]
Series cats:    &action=get_series_categories
Series list:    &action=get_series[&category_id=N]
Series info:    &action=get_series_info&series_id=N
EPG:            &action=get_simple_data_table&stream_id=N

Stream URLs:
  Live:     http://SERVER/live/USER/PASS/STREAM_ID.m3u8
  VOD:      http://SERVER/movie/USER/PASS/STREAM_ID.EXT
  Series:   http://SERVER/series/USER/PASS/EPISODE_ID.EXT
  Catchup:  http://SERVER/timeshift/USER/PASS/DURATION/YYYY-MM-DD:HH-MM/STREAM_ID.m3u8
```

---

## Known Issues / Watch Out For

1. **media_kit on Android** — must include `media_kit_libs_android_video` in `pubspec.yaml` or video will be audio-only
2. **Xtream EPG titles** — some servers return base64-encoded titles. `XtreamService._decodeBase64Safe()` handles this
3. **TV focus** — always wrap interactive TV widgets in `Focus()` with `onKeyEvent` for D-pad `LogicalKeyboardKey.select`
4. **Cleartext HTTP** — `android:usesCleartextTraffic="true"` is set in `AndroidManifest.xml` — required because the server uses HTTP not HTTPS
5. **Orientation lock** — `PlayerScreen` locks to landscape in `initState()` and restores portrait in `dispose()`. Always do both or the phone gets stuck landscape
6. **WakelockPlus** — always pair `enable()` in initState with `disable()` in dispose

---

## Commit Message Convention

```
feat: add series screen with season/episode navigation
feat: add EPG full-screen guide
feat: add parental PIN lock
fix: handle null EPG response on channels without guide
fix: restore portrait orientation after player close
chore: update pubspec to media_kit 1.1.10
```

---

## Contact

Saviour — Thirdsan Enterprises Ltd
Kampala, Uganda
