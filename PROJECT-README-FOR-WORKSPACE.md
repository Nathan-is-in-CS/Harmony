Project README (copy this into your workspace `project/README.md`)
=====================================================================

Project: Harmony

Android releases: https://github.com/Nathan-is-in-CS/Harmony/releases

Short description
-----------------

Harmony is an offline-first practice assistant for musicians. It organises
local audio files by tempo (BPM) and key, provides a small player with synced
lyrics, and lets users edit song information locally.

Song metadata is optional. When provided, BPM is entered by the user and key
signatures are selected from a standard major/minor key-signature dropdown;
newly discovered songs do not receive an automatic BPM or key placeholder.
Lyrics can be imported from pasted text, LRC files, or supported external sites.

How to run the project
----------------------

From the project repository root, for an Android emulator or connected device:

```bash
flutter pub get
flutter run
```

For automated checks:

```bash
flutter analyze --no-fatal-infos
flutter test
```

Links
-----

- Project repo: https://github.com/Nathan-is-in-CS/Harmony
- Android releases: https://github.com/Nathan-is-in-CS/Harmony/releases

The official v1.0.0 Android build is shared through GitHub Releases. Google Play
distribution is not currently part of the project scope.

Notes for the grader
--------------------

- The app is offline-first and stores user data locally using Hive.
- Audio playback, queue controls, and playback modes are available from the
  player screen.
- The lyrics import sheet avoids narrow-screen button overflow and supports
  paste, LRC import, and external lyric sites.
- Screens and design assets are inside the `docs/` folder.
- Development work is organized in `feature/*` branches and merged into
  `main` for stable releases.

Files submitted
---------------

- Source code (Flutter app) — `lib/` and `pubspec.yaml`
- Proposal and mockup — `docs/Proposalv2.md`, `docs/High-level mockup Of Harmony.pdf`
- Design system visual — `docs/Harmony UI Design System.png`

How I tested the app
--------------------

- The GitHub release workflow runs `flutter analyze --no-fatal-infos` and
  `flutter test` before building an APK.
- The Android APK has been tested on an emulator with local audio files.
- The v1.0.0 release includes generated Android and web launcher icons from the
  Harmony app icon assets.

Notes about privacy
-------------------

- All user data is local only (Hive boxes). No external services or keys
  required for the core app.

Replace the sections above if you want different wording. Copy this into the
workspace `project/README.md` and commit there to complete the course pointer.
