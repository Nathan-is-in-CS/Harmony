<!--
  This is your project's front page. Replace every placeholder below.
  It is the first thing your instructor and any future employer will read, and
  the live link in it is how your project gets opened for grading.

  New here? Read START-HERE.md first. Delete this comment when you are done.
-->

 # Harmony

 > Harmony is an offline-first practice assistant for rehearsing musicians. It
 > scans and organises local audio tracks by tempo (BPM) and key, provides a
 > lightweight player with synced lyrics, and tools to calibrate and verify
 > automated analysis.

 **Live demo:** https://Nathan-is-in-CS.github.io/Harmony/
 **Demo video:** `docs/demo.mp4` (add when available)
 **Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University
 **Author:** (add your name here)

 This repository contains the full source, documents and assets for the Harmony
 project. The app is offline-first and keeps user data locally using Hive.

 ## Screenshots

 Add phone-sized screenshots to `docs/assets/` and replace these placeholders:

 | Library | Player | Settings |
 | --- | --- | --- |
 | ![Library](docs/assets/screen-library.png) | ![Player](docs/assets/screen-player.png) | ![Settings](docs/assets/screen-settings.png) |

 ## What it does

 - Scans local audio files and displays a searchable track library.
 - Shows BPM and key telemetry per track and a simple player with synced lyrics.
 - Lets users calibrate and lock verified tempo/key values locally.

 ## Built with

 | | |
 | --- | --- |
 | Framework | Flutter (Dart) |
 | Storage | Hive (hive, hive_flutter) — offline-first local data |
 | Audio | audioplayers — playback and position tracking |
 | Dev tools | device_preview — phone frame for web preview |

 ## Running locally

 Requirements: Flutter SDK installed.

 ```bash
 flutter pub get
 flutter run -d web-server --web-port 8080
 ```

 Open http://localhost:8080 to preview the app inside the device frame.

 ## Privacy and secrets

 Harmony is an offline-only app by design. All user metadata (tracks, verified
 values, settings) is stored locally on the device using Hive. There are no
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

 - Setup: package metadata and local storage scaffolding done.
 - Library screen: Hive-backed sample list (see `lib/screens/library_screen.dart`).
 - Next: Player UI, tap-tempo pad, and adapters for Hive models.

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
