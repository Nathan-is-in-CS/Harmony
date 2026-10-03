# 1. Proposal, version 2

## App name
Harmony

## The problem, in one sentence
Musicians working with rough demos, vocal stems, or live rehearsal recordings struggle to organize tracks by key and tempo, and to record and verify that information themselves, without messy physical ledgers.

## Who is this for
- **Who specifically uses this?** Rehearsing musicians, gigging bandleaders, and indie songwriters managing collections of unreleased local audio demos and stems.
- **What do they do today instead?** They write key/BPM notes in smartphone memo apps, rename audio files with messy titles (e.g., `Demo_120BPM_AMinor_v2.mp3`), or manually search digital audio workstation (DAW) project folders during rehearsal.

---

## Core features (MVP), revised

| # | Feature | Still in the MVP? | Flutter pieces it needs | Honest estimate |
| - | --- | --- | --- | --- |
| 1 | **Track Library List & Search** | keep | `ListView.builder`, `TextField`, `Card`, `IconButton` | 5 hours |
| 2 | **Player & Sync Lyric View** | keep | `SingleChildScrollView`, `Slider`, `Row`, `Column`, `Text` | 6 hours |
| 3 | **Local Device Audio Scan** | keep | `permission_handler`, `path_provider`, file traversal | 4 hours |
| 4 | **Track Metadata / Calibration View** | keep | `showModalBottomSheet`, `DropdownButtonFormField`, `ElevatedButton` | 4 hours |
| 5 | **Settings & Cache Clear** | keep | `ListView`, `Switch`, `Slider`, `AlertDialog` | 3 hours |

**Total Estimated Hours:** 22 hours

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

- **Feature:** Local Audio Playback & Device File Scanning (`audioplayers` + `path_provider` + Android storage permissions).
- **Which package:** `audioplayers` (for local audio playback and position tracking).
- **Runs where you develop:** Yes (Android-first, with local file access for device audio).
- **If it does not run on web:** The production scope is focused on local device playback rather than web demo audio.
- **Core feature or stretch goal:** Core feature (local playback and file discovery are central to the app's workflow).

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
2. **Player and Practice Workspace View:** Local audio playback controls, track details, and synced lyrics/notes viewer.
3. **Edit Calibration Dialog (Bottom-Sheet Modal):** Dropdown property adjusters for track metadata and local verification state with Save/Cancel triggers.
4. **Application Settings Screen:** Management options for cache clearing, scan reset, verified metadata export, and verification behavior.

---

## Risks, revised

- **The risk I named last time (Audio/Local Storage Integration):** Still a risk, but manageable. Testing showed that reading local audio files in Flutter is smooth, though device file permission handling varies across Android storage layouts.
  - *First step:* Confirm the scan logic works with the app's first-start local device discovery flow.
  - *Target date:* Next Friday.
- **A new risk I did not see before (Duplicate Local File Paths):** Android can expose the same file through multiple path aliases, leading to duplicate library entries.
  - *First step:* Canonicalize and deduplicate file paths before saving tracks to Hive.
  - *Target date:* This sprint.

---

## What changed, and why

| Section | Prelim said | Now says | Why it changed |
| --- | --- | --- | --- |

| **App Scope** | Ambiguous multi-track organizer proposal | Precise 4-screen local practice utility | M4/M5 modules clarified exact screen costs and layout limits. |
| **Data Persistence** | Undecided cloud backend | Offline-first local storage (`hive` / `shared_preferences`) | Offline speed and low setup overhead fit the timeline better than complex cloud databases. |
| **Audio Workflow** | Basic file access and sample playback | Local device scan and playback from downloaded media | The app is centered on the user's actual device library rather than demo content. |
| **Calibration View** | Full dedicated edit page | Bottom-Sheet Modal (`showModalBottomSheet`) | Keeps the user in the context of the Player screen while tweaking track metadata. |
| **Analysis features** | Settings included analysis sliders and implied automatic key/BPM analysis | Manual key/BPM entry plus user verification only; no AI or automatic analysis | Keeps the scope achievable and matches what the app actually does. |
