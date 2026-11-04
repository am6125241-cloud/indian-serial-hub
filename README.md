<div align="center">

# 📺 India Serial Hub

**A Professional Flutter OTT App for Live TV & Indian Serials — built for Android Mobile & Android TV**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Android%20TV-3DDC84?logo=android&logoColor=white)
![Version](https://img.shields.io/badge/Version-2.1.2-red)
![Min SDK](https://img.shields.io/badge/minSdk-21%20(Android%205.0)-green)

</div>

---

## 🎬 What is India Serial Hub?

India Serial Hub is a custom OTT (Over-The-Top) streaming application that plays **Live TV channels and shows from a user-provided M3U playlist**. It ships with a fully custom video player (fit modes, pinch zoom, PiP), a beautiful animated home screen, an in-app admin panel with usage analytics, and **first-class Android TV support with remote (D-pad) navigation**.

> The app does **not** ship with any content. You add your own playlist URL in the Admin Panel — see [Disclaimer](#-disclaimer-legal).

---

## ✨ Features

### 🎥 Custom Video Player
- **5 aspect-ratio fit modes** — Auto Fit, Zoom (Fill), Stretch, Force 16:9, Force 4:3
- **Pinch-to-zoom** 1x – 4x (video only — controls never distort) with on-screen reset pill
- **Picture-in-Picture** (PiP) support
- Play / Pause with animated center button, mute, buffering indicator, error-retry UI
- Previous / Next channel switching, in-player channel list
- **Wakelock** — screen stays on while watching
- LIVE badge + seek bar with position/duration

### 🏠 Home & Discovery
- Staggered **entrance animation** on channel cards (fade + slide + scale wave)
- **Smart category detection** (News, Entertainment, Movies, Sports, Kids, Music) from channel names
- **EPG (program guide)** with time-based schedules per category
- Live search, voice search (Android speech recognition), favorites, recently watched
- Channel view counts, night mode, data-saver mode
- Shimmer loading placeholders & empty-state onboarding

### 🛠 Admin Panel (password protected)
- **First-run setup**: you create your own admin password on first login (no default password in code)
- Usage analytics — app opens, sessions, channel views, favorites, watch history, registered devices
- **Playlist URL management** — set / update your M3U source anytime
- Change admin password, export app data to clipboard, clear all data

### 📺 Android TV Support
- Installs as a **Leanback launcher app** (shows in TV Apps section)
- Full **D-pad remote navigation** with glowing focus rings on every card
- First channel card auto-focused on TV devices
- TV-safe orientation handling (no portrait lock → no black-screen on TVs)
- Runs on **Android 5.0+** (minSdk 21) — works on old LED/Android TVs

### 🎮 TV Remote Controls (in player)

| Key | Action |
|---|---|
| **OK / Enter** | Play / Pause |
| **◀ / ▶** | Seek −10s / +10s |
| **▲ / ▼** | Next / Previous channel |
| **Back** | Exit player |

D-pad arrows also navigate the home grid; OK opens a channel.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android Studio / Android SDK (NDK 28.2.13676358)

### Build & Run
```bash
git clone https://github.com/am6125241-cloud/indian-serial-hub.git
cd indian-serial-hub
flutter pub get
flutter run            # debug on connected device
flutter build apk --release   # release APK
```
APK output: `build/app/outputs/flutter-apk/app-release.apk`

### Install on Android TV
1. Send the APK to your TV using **Send Files to TV** or a pen-drive
2. Enable **Unknown sources** in TV settings, then install
3. Find the app in your TV's **Apps section**

### Add your playlist
1. Open the app → **Settings tab → Admin Panel**
2. Create your admin password (first time only)
3. Paste your **M3U/M3U8 playlist URL** → Load
4. Done — channels appear on the home screen

---

## 🧰 Tech Stack

| Component | Detail |
|---|---|
| Framework | Flutter (Dart) |
| Video | `video_player` with a fully custom controls overlay |
| UI | Material 3 dark theme, `google_fonts`, `shimmer`, `flutter_spinkit` |
| Storage | `shared_preferences` (favorites, history, settings, analytics) |
| TV | Leanback launcher, D-pad focus traversal, `wakelock_plus` |
| Native bridges | MethodChannels — voice search & PiP |

### Project Structure
```
lib/main.dart          # Entire app (services, models, UI, player, admin)
android/               # Gradle config (Kotlin DSL), Leanback manifest, TV banner
assets/app_icon.png    # App icon
```

---

## 📋 Version History

- **2.1.2** — Removed all hardcoded playlist links (legal/clean repo); first-run playlist setup
- **2.1.1** — Android TV launch fix (no portrait lock on TV), full TV remote support, minSdk 21
- **2.1.0** — Custom player with fit modes & pinch zoom, TV focus rings, entrance animations
- **2.0.1** — Build fixes (NDK 28, resource merge)

---

## ⚠️ Disclaimer (Legal)

This app does **not** host, provide, or recommend any content (serials, videos, or channels). All streams come from an **M3U playlist URL that the user adds themselves** in the Admin Panel. The repository contains **no third-party content links or media files**. The developer is not the owner, host, or distributor of any third-party content. Use only playlists you are legally entitled to access.

---

<div align="center">

**Made with Flutter 💙**

</div>
