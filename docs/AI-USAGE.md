# AI usage

This project used GitHub Copilot during the earlier setup and documentation work. Claude Code was used only during Week 3 as a prompting and validation assistant for coding, debugging, and code suggestions. The work below is recorded honestly: these tools accelerated parts of the work, but the final product was shaped by project decisions, manual corrections, and validation by the project owner. Harmony itself has no AI or automatic key/BPM analysis features.

## 1. How I used AI

### Entry 1 — project scaffolding and repo structure
- Date: 2026-09-17
- Tool: GitHub Copilot
- What I asked for: “Set up a Flutter project for a local music app, including Android-first structure and starter files.”
- What it gave back: initial project files, boilerplate app structure, and a starter app.
- What I kept/changed: I kept the Flutter project layout and converted it into the Harmony app structure; I removed placeholder content and replaced it with the project-specific app plan.
- Commit: `b768605` — Initial commit

### Entry 2 — documentation setup and project guidance
- Date: 2026-09-19
- Tool: GitHub Copilot
- What I asked for: “Draft the project README and starter documentation based on the course requirements.”
- What it gave back: the initial documentation outline and repo organization guidance.
- What I kept/changed: I adapted the wording to match the actual app and course instructions, then revised the README to describe the real offline/local-file workflow.
- Commit: `d69bce3` — docs: add screenshot instructions and workspace project README draft

### Entry 3 — local device scan planning
- Date: 2026-09-20
- Tool: GitHub Copilot
- What I asked for: “Design a local Android audio scanner that finds downloaded audio files and ignores app/private folders.”
- What it gave back: a first-pass file traversal approach plus filtering ideas for audio extensions and Android storage paths.
- What I kept/changed: I used the structure as the base, then adjusted the logic to fit real device scanning, deduplication, and protection against system folders.
- Commit: `3d5892e` — feat: add initial player screen and local playback flow

### Entry 4 — playback state architecture
- Date: 2026-09-21
- Tool: GitHub Copilot
- What I asked for: “Build a single playback controller that keeps queue, current track, and play state in sync.”
- What it gave back: the concept of a centralized controller and notifier-based state.
- What I kept/changed: I kept the controller model and then rewrote the queue and playback logic to match the actual app requirement: one source of truth and no duplicated state between screens.
- Commit: `3d5892e` — feat: add initial player screen and local playback flow

### Entry 5 — player screen and mini-player fixes
- Date: 2026-09-22
- Tool: GitHub Copilot
- What I asked for: “Help fix the player screen and mini-player so that current song, progress, and play state stay aligned.”
- What it gave back: a set of state-sync suggestions and rebuild patterns.
- What I kept/changed: I kept the direction but corrected the root cause: the app’s state was split across components, so I fixed it by making the controller authoritative and by recalculating progress/duration from the actual player values.
- Commit: `3d5892e` — feat: add initial player screen and local playback flow

### Entry 6 — final documentation and compliance cleanup
- Date: 2026-09-26
- Tool: GitHub Copilot
- What I asked for: “Draft the weekly report, README badge credit, and AI usage file in the course-required format.”
- What it gave back: the skeleton and wording for the project reporting and compliance sections.
- What I kept/changed: I adapted the wording to the actual project status, kept the findings honest, and inserted the final badge, AI credit, and security review details.
- Commit: `4fe7afd` — Update:Docs

### Entry 7 — manual-only workflow and documentation correction
- Date: 2026-10-03
- Tool: Claude Code
- What I asked for: “Update the Harmony documentation to match the removal of AI and automatic analysis features, and record that BPM and key are entered and verified manually.”
- What it gave back: prompts, validation feedback, debugging help, and code suggestions for the Settings cleanup and related documentation updates.
- What I kept/changed: I kept the changes minimal, removed the obsolete AI stat and suggestions setting from the Settings flow, changed scan wording that implied automatic analysis, and documented the manual-only workflow. No AI or automatic analysis feature was added.

## 2. Where the AI got it wrong

### Issue 1 — it suggested demo/sample music instead of real local audio
- What it gave me: a design direction that relied on sample tracks and demo music lists.
- What was wrong: the project requirement was to scan and play downloaded audio already on the local device, not to ship sample media.
- What I did instead: I changed the app to scan the actual Android device storage, filter out system folders, and build the library from real audio files.
- Commit: `3d5892e` — feat: add initial player screen and local playback flow

### Issue 2 — it proposed split playback state across screens
- What it gave me: several UI suggestions that duplicated track and play state in both the player and library views.
- What was wrong: those states drifted apart and caused the wrong song to appear in the mini-player and broken next/previous behavior.
- What I did instead: I centralized playback state in a single controller and let the UI listen to that source of truth.
- Commit: `3d5892e` — feat: add initial player screen and local playback flow

### Issue 3 — it treated durations and sliders as seconds-based values
- What it gave me: a basic slider model that did not match the underlying audio player values.
- What was wrong: the app was mixing seconds and milliseconds, so the position bar reset or jumped incorrectly.
- What I did instead: I forced the slider to use the actual player values and reset the progress when a track changed, which fixed the mismatch.
- Commit: `3d5892e` — feat: add initial player screen and local playback flow

### Issue 4 — earlier wording implied automatic metadata analysis
- What was wrong: earlier Settings and proposal wording referred to an AI stat, AI suggestions, analysis sliders, and automatic key/BPM analysis even though Harmony's actual workflow is manual.
- What I did instead: I removed the obsolete Settings controls and updated the documentation and scan labels to state that users enter BPM and key values themselves, then mark them as verified.

## 3. Who wrote what

### Parts I wrote myself
| File | Commit | What I wrote and why |
| --- | --- | --- |
| `lib/screens/library_screen.dart` | `3d5892e` | I shaped the local library behavior, including device scan, filtering, queue building, and the library-level actions. This is the user-facing heart of the app because it decides what audio appears and how the user interacts with it. |
| `lib/screens/player_screen.dart` | `3d5892e` | I wrote the playback UX and the coordination between the track view, queue controls, and the audio state. I kept the controls simple and connected to the actual player so the UI reflects device playback instead of stale assumptions. |
| `lib/main.dart` | `b768605` and later edits | I made the app bootstrap decisions and selected the app flow and initialization strategy for the project. The entry point is mine because it is the path that launches the Harmony experience. |
| `docs/04-weekly-reports.md` | `4fe7afd` | I wrote the weekly project record on a real timeline so the project history reflects what happened, not what I expected to happen. |
| `lib/screens/settings_screen.dart` | working tree cleanup | I removed obsolete AI and non-functional settings and cleared stale Hive keys, preserving only settings that match the current workflow. |
| `docs/Proposalv2.md` and project README/docs | working tree cleanup | I updated the project description to match manual BPM/key entry and user verification, with no automatic analysis feature. |

### One piece of AI-written code I understand best
| File | Commit | Why I kept it, and how I checked it |
| --- | --- | --- |
| `lib/src/platform_io_nonweb.dart` | `3d5892e` | This file was scaffolded with AI help to handle local file scanning and audio extension filtering. I kept the structure because it was a good foundation for Android device traversal, but I reviewed and adjusted the actual rules so it respects the real app requirements, blocks protected directories, and avoids duplicates. |

This is a fair split: GitHub Copilot assisted with earlier code generation and documentation, while Claude Code was used only in Week 3 for prompting, validation, debugging, and code suggestions. The final design choices, manual-only metadata workflow, tuning, and corrections were made by me to match the real device-first app requirement.
