
[![Made with AI](https://img.shields.io/badge/Made_with-AI_assistance-blue)](docs/AI-USAGE.md)

# Harmony

> Harmony is an Android-first local music library and player. It scans the
> device for downloaded audio files on first launch, keeps a local library of
> discovered tracks, and lets the user play real files stored on the device.

**Android releases:** https://github.com/Nathan-is-in-CS/Harmony/releases
**Demo video:** `docs/demo.mp4` (add when available)
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University
**Author:** Harmony project team

This repository contains the full source, documents and assets for the Harmony
project. The app is offline-first and keeps user data locally using Hive.
External lyric sites are optional links opened in the device browser; core
library, playback, metadata, and lyric storage remain local.

AI assistance used: GitHub Copilot was used during earlier project setup and documentation. Claude Code was used only during Week 3 for prompting, validation, debugging, and code suggestions; final code decisions and validation were done by the project owner.

## Visuals

Design system and mockups are in `docs/`:

- [Harmony UI Design System image](docs/Harmony%20UI%20Design%20System.png)
- [High-level mockup PDF](docs/High-level%20mockup%20Of%20Harmony.pdf)

 ## What it does

 - Scans the local device for available audio files on first launch.
 - Builds a searchable music library from the user's downloaded tracks.
 - Plays real local audio files directly from device storage.
 - Lets users enter and edit each song's BPM and key signature locally. Key
   editing uses a dropdown containing the standard major and minor signatures;
   songs without metadata remain optional and are shown as not set. BPM and key
   are entered manually and marked as verified by the user; the app does not
   perform automatic key/BPM analysis.
 - Supports synced lyric import from pasted text, LRC files, and external lyric
   sites.
 - Stores local app settings and library state using Hive without cloud setup.

 ## Built with

 | | |
 | --- | --- |
 | Framework | Flutter (Dart) |
 | Storage | Hive (hive, hive_flutter) — offline-first local data |
 | Audio | audioplayers — local playback |
 | Android access | permission_handler, path_provider |

 ## Running locally

 Requirements: Flutter SDK installed.

 ```bash
 flutter pub get
 flutter run -d emulator-5554
 ```

 For a local Android emulator test, run the app directly on an attached emulator.

 ## Installing an Android build

 Download the latest APK from the [GitHub Releases](https://github.com/Nathan-is-in-CS/Harmony/releases)
 page and install it on an Android device. Android may require enabling
 installation from this source in the device's security settings. Current
 releases are community testing builds and are not distributed through Google
 Play.

 ## Privacy and secrets

 Harmony is an offline-only app by design. All user metadata (tracks, BPM/key
 information, lyrics, verified values, and settings) is stored locally on the
 device using Hive. There are no
 external API keys or cloud services required for the core app. Sample data and
 screenshots in this repository contain no real personal information.

 ## Project documentation

 | Document | |
 | --- | --- |
 | [Proposal](docs/Proposalv2.md) | problem, users, scope, and data model |
 | [Mockup and wireframes](docs/02-mockup.md) | visual mockups and screens |
 | [Design system](docs/03-design-system.md) | palette, type scale and component guidance |
 | [Weekly reports](docs/04-weekly-reports.md) | development progress (weekly) |
 | [Demo video](docs/05-demo-video.md) | final demo recording |
 | [Start here](START-HERE.md) | how this repo is organised and final checklist |

 ## Status

 - Setup: project structure, Android permissions, and local storage are complete.
 - Library screen: device scan and a local audio library are working.
 - Player flow: local file playback, track selection, playback modes, and
   playback-state handling are implemented, including randomized shuffle.
 - Metadata: user-editable BPM and standard key-signature selection are
   implemented without forcing metadata entry.
 - Lyrics: optional import and display of synced lyrics are implemented, with
   lyrics reset correctly when tracks change.
 - UI: Harmony Design System v2 is implemented across Library, Player, Settings,
   calibration, lyrics, and mini-player surfaces with reusable theme widgets.
 - Distribution: Android APK test releases are built through GitHub Actions and
   published through GitHub Releases.

 ## Branching & releases

 - `main`: stable production-ready code.
 - `feature/*`: feature branches for focused changes.
 - Versioned Android APK/AAB files are published through GitHub Releases.

 To create a release, push a version tag such as `v1.0.0`. GitHub Actions will
 run the checks, build the Android APK, and attach it to the generated release.
 The current build uses the Android debug signing key for direct testing; a
 private release keystore should be configured before distributing through the
 Google Play Store.

 GitHub Releases are the distribution channel for Android builds. Source code,
 documentation, and release notes remain available in the repository.

 ## Credits

 - See `pubspec.yaml` for the main package dependencies.

 ## Open source

 Harmony is released under the MIT License. Contributions, bug reports, and
 feature suggestions are welcome through GitHub Issues and Pull Requests.

 ## AI use

GitHub Copilot was used for earlier project scaffolding and documentation.
Claude Code was used only during Week 3 for prompting, validation, debugging,
and code suggestions; final decisions and code remain authored and validated
by the project owner.

 ## Licence

 MIT, see [LICENSE](LICENSE).
