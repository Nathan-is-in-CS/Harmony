Project README (copy this into your workspace `project/README.md`)
=====================================================================

Project: Harmony

Live link: https://Nathan-is-in-CS.github.io/Harmony/

Short description
-----------------

Harmony is an offline-first practice assistant for musicians. It organises
local audio files by tempo (BPM) and key, provides a small player with synced
lyrics, and tools to calibrate and verify automated analysis locally.

How to run the project
----------------------

From the project repository root:

```bash
flutter pub get
flutter run -d web-server --web-port 8080
```

Open http://localhost:8080 to preview the app inside a phone frame.

Links
-----

- Project repo: https://github.com/Nathan-is-in-CS/Harmony
- Live demo (GitHub Pages): https://Nathan-is-in-CS.github.io/Harmony/

Notes for the grader
--------------------

- The app is offline-first and stores user data locally using Hive.
- Screens and design assets are inside the `docs/` folder.
- The active development branch for the first feature is `feature/player`.

Files submitted
---------------

- Source code (Flutter app) — `lib/` and `pubspec.yaml`
- Proposal and mockup — `docs/Proposalv2.md`, `docs/High-level mockup Of Harmony.pdf`
- Design system visual — `docs/Harmony UI Design System.png`

How I tested the app
--------------------

- Ran `flutter analyze` and `flutter run -d web-server` locally.

Notes about privacy
-------------------

- All user data is local only (Hive boxes). No external services or keys
  required for the core app.

Replace the sections above if you want different wording. Copy this into the
workspace `project/README.md` and commit there to complete the course pointer.
