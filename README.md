# UHVA Player

**Professional IPTV Player for Android Phone & Android TV**
Built with Flutter · Xtream Codes API · ExoPlayer (via better_player)

---

## Features

- Live TV streaming (HLS / MPEG-TS)
- VOD / Movies with poster grid
- EPG programme guide with live progress
- Category filtering and search
- Favourites and watch history
- Full-screen player with OSD overlay (channel name, show info, next up)
- Adaptive layout — phone list view + Android TV card grid
- D-pad / remote navigation for Android TV
- Dark premium UI with UHVA brand identity

---

## Credentials (pre-configured)

| Field    | Value                    |
|----------|--------------------------|
| Server   | http://ott1.co:8080      |
| Username | umesh905                 |
| Password | 032026                   |

These are filled by default on the login screen.

---

## Project Structure

```
lib/
├── main.dart                        # App entry, provider setup, root router
├── theme/
│   └── app_theme.dart               # UHVA colors, ThemeData
├── models/
│   └── models.dart                  # XtreamUser, LiveChannel, VodStream, EpgEntry
├── services/
│   ├── xtream_service.dart          # All Xtream Codes API calls
│   └── storage_service.dart         # SharedPreferences: credentials, favourites, history
├── providers/
│   └── app_provider.dart            # Central state: auth, channels, search, VOD
├── screens/
│   ├── auth/
│   │   └── login_screen.dart        # Login form
│   ├── home/
│   │   ├── home_screen.dart         # Phone home: channel list + mini player
│   │   └── tv_home_screen.dart      # Android TV home: side nav + card grid + EPG
│   ├── player/
│   │   ├── player_screen.dart       # Live channel fullscreen player + OSD
│   │   └── vod_player_screen.dart   # VOD fullscreen player
│   ├── vod/
│   │   └── vod_screen.dart          # Movie grid with category filter
│   └── settings/
│       └── settings_screen.dart     # Account info, playback prefs, sign out
├── widgets/
│   ├── common/
│   │   └── uhva_logo.dart           # Reusable brand logo widget
│   └── channel/
│       ├── channel_tile.dart        # Channel row with logo, EPG progress, live badge
│       └── category_bar.dart        # Horizontal scrollable category pills
└── utils/
    └── platform_utils.dart          # Phone vs TV detection
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x (`flutter --version`)
- Android Studio with Android SDK
- Android device or emulator (API 21+)
- Android TV emulator or physical TV device

### 1. Clone & install dependencies

```bash
cd uhva_player
flutter pub get
```

### 2. Run on phone

```bash
flutter run
```

### 3. Run on Android TV

In Android Studio, create an Android TV emulator:
- API 26+
- ABI: x86_64
- Device: Android TV (1080p)

```bash
flutter run -d <tv_emulator_id>
```

Or sideload the APK:
```bash
flutter build apk --release
adb connect <tv_ip>:5555
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 4. Build release APK

```bash
# Phone APK
flutter build apk --release --target-platform android-arm64

# Split APKs (smaller size)
flutter build apk --split-per-abi
```

---

## Xtream Codes API Reference

The app uses these endpoints:

| Endpoint | Purpose |
|---|---|
| `player_api.php?username=X&password=Y` | Auth + user info |
| `&action=get_live_categories` | Live channel categories |
| `&action=get_live_streams` | All live channels |
| `&action=get_live_streams&category_id=N` | Channels in category |
| `&action=get_vod_categories` | VOD categories |
| `&action=get_vod_streams` | All VOD movies |
| `&action=get_simple_data_table&stream_id=N` | EPG for channel |

Stream URL pattern:
```
http://SERVER/live/USERNAME/PASSWORD/STREAM_ID.m3u8
http://SERVER/movie/USERNAME/PASSWORD/STREAM_ID.EXT
```

---

## Android TV Remote Navigation

The TV home screen uses Flutter's `Focus` system with `LogicalKeyboardKey.select` for D-pad OK button. Navigation works with:

- **D-pad up/down/left/right** — move focus between cards
- **OK / Select** — open channel / play
- **Back** — return to previous screen

---

## Customisation

### Change brand color
Edit `lib/theme/app_theme.dart`:
```dart
static const primary = Color(0xFF6C63FF); // change this
```

### Add more stream types
Extend `XtreamService` in `lib/services/xtream_service.dart` with:
- `get_series` — TV series
- `get_series_categories`
- `get_series_info&series_id=N`

### Add parental PIN lock
In `StorageService`, add a `savePin()` / `checkPin()` method and wrap the player screen with a PIN gate widget.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| provider | ^6.1.1 | State management |
| better_player | ^0.0.84 | HLS/MPEG-TS video playback |
| dio | ^5.4.0 | HTTP client for API calls |
| cached_network_image | ^3.3.1 | Channel logo caching |
| shared_preferences | ^2.2.2 | Local credential/settings storage |
| xml | ^6.3.0 | EPG XML parsing |
| connectivity_plus | ^5.0.2 | Network state detection |
| flutter_spinkit | ^5.2.0 | Loading indicators |
| fluttertoast | ^8.2.4 | Toast messages |

---

## Built by

Thirdsan Enterprises Ltd — Kampala, Uganda
Developer: [Your name]
