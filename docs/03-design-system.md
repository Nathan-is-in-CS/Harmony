# Design system

Paste in the design system you submitted, and replace it with the final version
when the project is done. It is also the reference you open every time you build
a new screen, so keeping it current helps you more than it helps anyone reading.

**Design system visual**

The design system visual is included in the repository. See:

- [Harmony UI Design System image](Harmony%20UI%20Design%20System.png)
- [High-level mockup PDF](High-level%20mockup%20Of%20Harmony.pdf)

The implemented Flutter theme and reusable UI primitives are in
`lib/theme/harmony_theme.dart` and `lib/widgets/harmony_widgets.dart`.

Figma, Canva, Excalidraw, Google Slides or Docs exported to PDF all work. A
reader should be able to see your app's look in one glance, without reading a
table.

## Palette

- Background: `#FFFFFF`
- Surface: `#F5F5F5`
- Primary: `#000000`
- Secondary: `#4A4A4A`
- Body text: `#111111`
- Border: `#CCCCCC`

## Type scale

The app uses the Flutter theme's display, headline, title, body, and label
styles for the Version 2 scale. Inter is the intended family; no Inter font
files are bundled, so the platform sans-serif fallback is used.

## Spacing

The implemented spacing constants are `s8`, `s16`, `s24`, and `s32`. Cards,
buttons, inputs, and badges use 4px corners with 1px borders and no elevation.

## Components

One row per reusable widget: what it is, which file it lives in, what parameters
it takes, which screens use it.

| Widget | File | Used by |
| --- | --- | --- |
| `HarmonyHeaderBar` | `lib/widgets/harmony_widgets.dart` | Library, Player, Settings |
| `HarmonyCard` | `lib/widgets/harmony_widgets.dart` | Library, Player, Settings |
| `HarmonyMetricCard` | `lib/widgets/harmony_widgets.dart` | Player |
| `HarmonyStatusBadge` | `lib/widgets/harmony_widgets.dart` | Library rows |
| `HarmonySectionLabel` | `lib/widgets/harmony_widgets.dart` | All redesigned screens |

## Changes since the last version

- Replaced the seeded beige Material theme with the monochrome Version 2 theme.
- Restyled Library, Player, Settings, calibration, lyrics, and mini-player UI.
- Kept playback, scanning, metadata, verification, lyrics, and Hive behavior unchanged.
- Omitted mockup-only AI, backup, cache, compact-row, and automatic-analysis controls.
