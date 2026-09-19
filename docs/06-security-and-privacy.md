# Security and privacy

This repository is public. Fill this in honestly and date it; it is checked as
part of grading.

**Last checked:** 2026-09-17

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| Track metadata (title, bpm, keySignature, isUserVerified) | locally in Hive (`tracks_box`) | only the device user |
| Lyric blobs | locally in Hive (`lyrics_box`) | only the device user |
| App settings | locally in Hive (`settings_box`) | only the device user |

## Secrets

- Values my app needs at run time: None for core functionality (Harmony is
  designed as an offline-first app). If future cloud features are added the
  keys will be documented here.
- Where they live locally: `.env` is git-ignored (no secrets in the repo now).
- Where the deploy workflow gets them: N/A (no deploy-time secrets required).
- Anything my deployed web build carries that a visitor could read: none.

## What protects the data on the service side

- Nothing leaves the device for the current MVP. All user data (track
  metadata, lyrics, and preferences) are stored locally using Hive and are not
  transmitted to any remote service.

## Checklist

- [x] `.env` (or `env.json`) is in `.gitignore`, and `.env.example` is committed
- [x] `git log -p | grep -i "api_key\|secret\|password\|token"` finds nothing real
- [x] No service account file, keystore or `service_role` key anywhere in the repo
- [x] Security rules or RLS policies written and tested, not left open — N/A (no backend)
- [x] No real personal data in sample data, screenshots or the video
- [x] No course or university credentials anywhere
- [x] Anyone whose data appears in a test was asked first — N/A

If you found and revoked a key while doing this, say so here. Catching it is the
right outcome, not an embarrassment.

No keys were found in this repository during the review on 2026-09-17.
