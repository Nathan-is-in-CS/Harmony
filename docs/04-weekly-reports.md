# Weekly reports

One entry per week, newest at the top, written **during** that week. Five minutes
each. They are the record of how the project actually went, and they make your
final reflection almost write itself.

---

## Week 1 (19 Sep 2026 to 25 Sep 2026)

**Done this week**
- set up the Harmony Flutter project structure and confirmed the app runs as a working base application
- initialized Hive local storage and opened the `tracks_box` database for offline-first track management
- built the initial library screen showing a searchable track list with local metadata
- added the initial local data flow so the app had something visible to test and review
- updated the project README and project docs to match the app purpose and setup workflow

**In progress**
- building the player screen and playback controls
- validating the local audio device scan and playback flow
- finishing the documentation, AI-use, and security/privacy work for hand-in

**Blocked or stuck on**
- the player and playback flow were still incomplete at the start of the week
- the remaining work requires more complex UI and logic than the initial library foundation
- some local playback details still need emulator validation for real device audio files

**Decisions made, and why**
- kept the app offline-first and local-device focused using Hive and real Android storage access
- planned the work incrementally to keep the project realistic and testable while building the playback flow
- focused on establishing a working foundation before expanding into the full music-player experience

**Hours spent, roughly:** 6-8

**Next week I will:**
- build the player screen and playback controls
- continue refining the local audio scan and playback flow
- finish the final documentation and project hand-off materials

---

## Week 2 (26 Sep 2026 to 2 Oct 2026)

**Done this week**
- set up the Flutter project and verified the Android emulator workflow
- built the local-device audio scan flow and library view for real audio files
- implemented the central playback controller to keep one source of truth for track, queue, and state
- fixed the player UI state sync issues, including the mini-player song and slider behavior
- added regression tests for scan logic and player slider guards
- continued the required documentation and repo hygiene work for final hand-in

**In progress**
- validating playback on the emulator with real local audio files across storage cases
- final polishing of the library/settings flow and player UX
- finishing the AI usage and security/privacy documentation required for the project

**Blocked or stuck on**
- some local audio formats behave differently depending on Android playback and file type, so runtime verification is still needed on the emulator for edge cases
- a few playback states needed architecture fixes rather than UI-only patches, which took longer than expected

**Decisions made, and why**
- kept the app fully local/offline and removed sample/demo music to match the project goal of scanning real device audio
- centralized playback state instead of duplicating it across screens to avoid stale UI values and broken queue logic
- kept the mini-player simple and status-focused rather than adding extra controls that would reintroduce stale state issues

**Hours spent, roughly:** 8-10

**Next week I will:**
- validate playback with multiple real audio file types on the emulator
- finish the remaining documentation and security checklist items
- prepare the final project hand-off and demo evidence

---

Copy this block:

---

## Week N (date to date)

**Done this week**
-

**In progress**
-

**Blocked or stuck on**
-

**Decisions made, and why**
-

**Hours spent, roughly:**

**Next week I will:**
-

---
