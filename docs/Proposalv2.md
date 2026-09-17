# 1. Proposal, version 2

## App name
Harmony

## The problem, in one sentence
Musicians working with rough demos, vocal stems, or live rehearsal recordings struggle to organize tracks by key/tempo telemetry and manually verify automatic audio analysis without messy physical ledgers.

## Who is this for
- **Who specifically uses this?** Rehearsing musicians, gigging bandleaders, and indie songwriters managing collections of unreleased local audio demos and stems.
- **What do they do today instead?** They write key/BPM notes in smartphone memo apps, rename audio files with messy titles (e.g., `Demo_120BPM_AMinor_v2.mp3`), or manually search digital audio workstation (DAW) project folders during rehearsal.

---

## Core features (MVP), revised

| # | Feature | Still in the MVP? | Flutter pieces it needs | Honest estimate |
| - | --- | --- | --- | --- |
| 1 | **Track Library List & Search** | keep | `ListView.builder`, `TextField`, `Card`, `IconButton` | 5 hours |
| 2 | **Player & Sync Lyric View** | keep | `SingleChildScrollView`, `Slider`, `Row`, `Column`, `Text` | 6 hours |
| 3 | **Interactive Rhythm Tap Pad** | keep | `GestureDetector`, `Container`, `DateTime` math | 3 hours |
| 4 | **Calibration Bottom Sheet** | keep | `showModalBottomSheet`, `DropdownButtonFormField`, `ElevatedButton` | 4 hours |
| 5 | **Settings & Cache Clear** | keep | `ListView`, `Switch`, `Slider`, `AlertDialog` | 3 hours |

**Total Estimated Hours:** 21 hours

---

## Stretch goals
1. **Real-time FFT Waveform Display:** Replace standard progress slider track with interactive graphical waveform renders using custom painters.
2. **Batch Metadata Exporter:** Export calibrated song key/BPM indices into a downloadable JSON/CSV file.
3. **Cloud Stem Backup:** Sync local verified tracks to cloud storage (Supabase Bucket).

---

## NEW: How my app saves data

- **If two different people install my app, should they see the same data?** No. Harmony is a personalized local studio assistant. Each user maintains their own local song library, tempo adjustments, and custom verified scale tags.
- **Roughly how many records does my app hold in a realistic week of use?** Approximately 50 to 200 track metadata records, along with a small key-value map for application settings.
- **My choice:** `hive` / `hive_flutter` (or local SQLite/`sqflite` fallback with `shared_preferences` for quick settings).
- **Why this one and not the others?** Local key-value/document storage like Hive requires zero server infrastructure or backend auth setup, keeping initial development lightweight and reliable offline. The accepted tradeoff is that user data won't automatically sync across multiple devices without a separate export feature.
- **What I save, concretely:** 
  - `TrackModel` class (`String id`, `String title`, `String path`, `double bpm`, `String keySignature`, `bool isUserVerified`) saved under the `'tracks_box'` collection.
  - User display settings (notation preference, time window slider value) saved under `'settings_box'`.
- **Have I tried it yet?** Yes, I ran a local persistence spike storing `TrackModel` instances locally and reading them back into `ListView.builder` widgets upon app restart.

---

## NEW: One thing I want to add that the course did not teach

- **Feature:** Audio Playback & Real-time Tap Tempo Math Engine (`audioplayers` + `path_provider`).
- **Which package:** `audioplayers` (for background audio streaming and position tracking).
- **Runs where you develop:** Yes (iOS, Android, macOS, Web).
- **If it does not run on web:** Fallback to sample asset audio files loaded via standard HTML5 web audio nodes.
- **Core feature or stretch goal:** Core feature (music playback and tempo tapping are central to the app's practice workflow).

---

## NEW: How my project runs when someone else opens it

- **I am keeping the `device_preview` wrapper:** Yes.
- **My app runs in a browser with `flutter run -d web-server`, start to finish, with every screen reachable:** Yes.
- **Anything that needs real hardware degrades to sample data instead of crashing:** Yes (falls back to bundled local demo audio assets if device storage permission is unavailable).
- **My project will live in a public repository in my own GitHub account. Secrets/Keys plan:** Not applicable—Harmony operates entirely offline and requires no external API keys or confidential credentials.

---

## Data the app remembers

| Thing | Fields | Where it is saved |
| --- | --- | --- |


| **Track Record** | `id` (String), `filepath` (String), `bpm` (double), `keySignature` (String), `isUserVerified` (bool) | Hive / Local Database (`'tracks_box'`) |
| **Lyric Segment** | `trackId` (String), `lyricsBlob` (String) | Hive / Local Database (`'lyrics_box'`) |
| **AppSettings** | `notationStyle` (String), `timeWindow` (double), `performanceMode` (bool) | `shared_preferences` or Hive (`'settings_box'`) |

---

## Screens

1. **Track Library Screen (Home Base):** Full file search, track statistics summary, and vertical song item list.
2. **Player and Practice Workspace View:** Song telemetry indicators (BPM/Key), synchronized scrolling lyrics viewer, and interactive rhythm tap pad.
3. **Edit Calibration Dialog (Bottom-Sheet Modal):** Dropdown property adjusters for base key and musical scale override with Save/Cancel triggers.
4. **Application Settings Screen:** Management options for cache clearing, display preferences, and analysis sliders.

---

## Risks, revised

- **The risk I named last time (Audio/Local Storage Integration):** Still a risk, but manageable. Testing showed that reading local asset metadata in Flutter is smooth, though device file permission handling varies across platforms.
  - *First step:* Implement fallback sample audio tracks inside `assets/` so the app works seamlessly even without storage permissions.
  - *Target date:* Next Friday.
- **A new risk I did not see before (Rhythm Tap Tempo Accuracy):** Tapping rapidly on screen triggers multiple micro-rebuilds, which could cause frame drops during live playback.
  - *First step:* Isolate the tap pad state within a modular `StatefulWidget` or `ValueNotifier` to avoid re-rendering the entire parent player widget tree.
  - *Target date:* Two weeks from today.

---

## What changed, and why

| Section | Prelim said | Now says | Why it changed |
| --- | --- | --- | --- |

| **App Scope** | Ambiguous multi-track organizer proposal | Precise 4-screen local practice utility | M4/M5 modules clarified exact screen costs and layout limits. |
| **Data Persistence** | Undecided cloud backend | Offline-first local storage (`hive` / `shared_preferences`) | Offline speed and low setup overhead fit the timeline better than complex cloud databases. |
| **Rhythm Mechanics** | Basic BPM display | Interactive Tap Rhythm Pad in Player workspace | Interactive tapping provides instant value for musicians verifying song tempos. |
| **Calibration View** | Full dedicated edit page | Bottom-Sheet Modal (`showModalBottomSheet`) | Keeps the user in the context of the Player screen while tweaking song data. |