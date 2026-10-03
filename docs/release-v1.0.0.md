<p align="center">
  <img src="https://raw.githubusercontent.com/Nathan-is-in-CS/Harmony/v1.0.0/assets/icon/harmony_icon.png"
     alt="Harmony logo"
     width="160">
</p>

<h1 align="center">Harmony</h1>

<p align="center">
  <strong>Official Launch · Version 1.0.0</strong>
</p>

<p align="center">
  A focused local music library and player for organizing rehearsal tracks by tempo and key.
</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#download">Download</a> •
  <a href="#whats-new">What's New</a>
</p>

---

## About

Harmony v1.0.0 is the official launch of an Android-first, offline-first music
library and player for musicians working with downloaded audio files, rough demos,
vocal stems, and rehearsal recordings.

The application scans local audio files, organizes them into a searchable library,
and provides local playback and user-managed music metadata. Track information,
lyrics, verified values, and settings remain stored locally on the device, keeping
the core Harmony experience available without cloud setup.

## Features

| Feature | Description |
|---|---|
| Local Library | Scan the device for downloaded audio files and browse them in a searchable library. |
| Local Playback | Play real audio files stored on the device. |
| BPM and Key Metadata | Enter and edit BPM and standard major or minor key signatures manually. |
| User Verification | Mark manually entered BPM and key information as verified. |
| Synced Lyrics | Import and display synced lyrics from pasted text or LRC files. |
| Playback Controls | Use track selection, playback modes, and randomized shuffle. |
| Offline Storage | Keep library state, metadata, lyrics, verified values, and settings local with Hive. |
| Harmony UI System | Use the redesigned Library, Player, Settings, lyrics, calibration, and mini-player surfaces. |

## Download

<p align="center">
  <a href="[https://github.com/Nathan-is-in-CS/Harmony/releases/download/v1.0.0/Harmony-v1.0.0.apk]">
    <strong>Download the official Harmony v1.0.0 APK</strong>
  </a>
</p>

**APK filename:** `Harmony-v1.0.0.apk`

## Installation

1. Download `Harmony-v1.0.0.apk` using the link above.
2. Open the APK on an Android device.
3. If prompted, allow installation from the relevant source in Android settings.
4. Follow the on-screen installation instructions.
5. Launch Harmony and grant the requested storage permissions so the app can scan
   for local audio files.

## What's New

### Official Launch · v1.0.0

- Official first release of Harmony.
- Added local audio scanning and searchable library browsing.
- Added local playback with track selection, playback modes, and shuffle.
- Added manual BPM and key entry with user verification.
- Added synced lyric import and display.
- Added local Hive storage for library data, metadata, lyrics, and settings.
- Added the Harmony Design System v2 across the primary app surfaces.
- Added automated Android APK release packaging through GitHub Actions.

## Release Notes and Limitations

- This Android release uses the configured debug signing key. A private release
  keystore should be configured before distributing through the Google Play Store.
- External lyric sites open as optional links in the device browser.

## Technologies Used

- Flutter
- Dart
- Hive and Hive Flutter
- audioplayers
- permission_handler
- path_provider
- url_launcher
- file_picker

## Developers

<p align="center">
  <strong>Nathan-is-in-Cs</strong><br>
</p>

## Closing

Thank you for choosing Harmony v1.0.0. We welcome feedback that can help improve
the app for musicians organizing and rehearsing with local audio files.
