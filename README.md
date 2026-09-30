
[![Made with AI](https://img.shields.io/badge/Made_with-AI_assistance-blue)](AI-USAGE.md)

# Harmony

> Harmony is an Android-first local music library and player. It scans the
> device for downloaded audio files on first launch, keeps a local library of
> discovered tracks, and lets the user play real files stored on the device.

**Live demo:** https://Nathan-is-in-CS.github.io/Harmony/
**Demo video:** `docs/demo.mp4` (add when available)
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University
**Author:** Harmony project team

This repository contains the full source, documents and assets for the Harmony
project. The app is offline-first and keeps user data locally using Hive.

AI assistance used: GitHub Copilot was used throughout project setup, debugging, and document drafting; final code decisions and validation were done by the project owner.

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
   songs without metadata remain optional and are shown as not set.
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
   playback-state handling are implemented.
 - Metadata: user-editable BPM and standard key-signature selection are
   implemented without forcing metadata entry.
 - Lyrics: optional import and display of synced lyrics are implemented.

 ## Branching & deployment

 - `main`: production-ready code and deployment target for GitHub Pages.
 - `setup`: initial setup work (current branch).
 - `feature/*`: feature branches (e.g. `feature/player`, `feature/storage`).

 GitHub Pages is enabled for this repo; the live demo will appear at the link
 shown above once `main` receives a deployable build.

 ## Credits

 - See `pubspec.yaml` for the main package dependencies.

 ## AI use

 Assistant tools were used to scaffold project files and suggestions; final
 decisions and code remain authored by the project owner.

 ## Licence

 MIT, see [LICENSE](LICENSE).
