```markdown
# Harmony Design System — Version 2

**App:** Harmony  
**Version:** 2.0  
**Style Target:** Grayscale / Monochromatic Utility Wireframe  
**Base Grid:** 8px  
**Dark mode:** Light only  

This document turns the Version 1 paper design system into Flutter-ready values (ColorScheme, TextTheme, spacing constants, and component contracts) that can be pasted into code.

---

## A. Palette as ColorScheme

Because the system is intentionally monochromatic (wireframe utility style), the palette is written out in full rather than generated from a single colorful seed.

```dart
final scheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF000000),          // Pure Black
  onPrimary: const Color(0xFFFFFFFF),        // White text/icons on primary
  secondary: const Color(0xFF4A4A4A),        // Dark Charcoal Gray
  onSecondary: const Color(0xFFFFFFFF),
  surface: const Color(0xFFF5F5F5),          // Very Light Gray (cards, sheets)
  onSurface: const Color(0xFF111111),        // Near Black (body text)
  error: const Color(0xFFCCCCCC),            // Medium Gray (destructive warnings)
  onError: const Color(0xFF111111),
  background: const Color(0xFFFFFFFF),       // Pure White
  onBackground: const Color(0xFF111111),
);
```

| Role        | Hex       | Color Name          | Used for                                      |
|-------------|-----------|---------------------|-----------------------------------------------|
| primary     | `#000000` | Pure Black          | Main high-contrast filled buttons, bold headers, active highlights |
| onPrimary   | `#FFFFFF` | Pure White          | Text and icons on primary                     |
| secondary   | `#4A4A4A` | Dark Charcoal Gray  | Outline buttons, slider nodes, pill selections |
| surface     | `#F5F5F5` | Very Light Gray     | Cards, dropdowns, list row backdrops          |
| onSurface   | `#111111` | Near Black          | Primary body text, form input text            |
| error       | `#CCCCCC` | Medium Gray         | Destructive action warnings (outlined text)   |
| background  | `#FFFFFF` | Pure White          | Universal screen background                   |

**Contrast check:** Body text (`#111111`) on background (`#FFFFFF`) and on surface (`#F5F5F5`) both exceed 4.5:1. Verified with WebAIM contrast checker.

**Dark mode decision:** Light only. No dark `ColorScheme` will be defined. Colors are never hardcoded outside this theme file.

---

## B. Type Scale as TextTheme

Clean functional sans-serif (Inter / Roboto / system default). Styles are mapped to named Flutter slots and used only by name.

```dart
textTheme: const TextTheme(
  // Hero Numeric → displayLarge (or headlineLarge if preferred)
  displayLarge: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800, // Extra Bold
    color: Color(0xFF111111),
  ),
  // Heading
  headlineSmall: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111111),
  ),
  // Sub-heading
  titleMedium: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600, // Semi-Bold
    color: Color(0xFF111111),
  ),
  // Body
  bodyMedium: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF111111),
  ),
  // Caption
  labelSmall: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w300, // Light
    color: Color(0xFF4A4A4A),
  ),
),
```

| Your style     | Flutter slot     | Size | Weight      | Used for                                      |
|----------------|------------------|------|-------------|-----------------------------------------------|
| Hero Numeric   | `displayLarge`   | 36   | Extra Bold  | BPM numbers & Key Signature letters           |
| Heading        | `headlineSmall`  | 20   | Bold        | Screen titles, modal headers                  |
| Sub-heading    | `titleMedium`    | 14   | Semi-Bold   | Section headers, card label tags              |
| Body           | `bodyMedium`     | 14   | Regular     | Song filenames, lyrics, form options          |
| Caption        | `labelSmall`     | 11   | Light       | Timestamps, counters, status pills            |

Usage rule (never write literal sizes):

```dart
Text('Harmony', style: Theme.of(context).textTheme.headlineSmall)
```

---

## C. Spacing as Constants

8px base grid.

```dart
class AppSpacing {
  static const double xs = 4;   // half-step when needed
  static const double sm = 8;   // tight
  static const double md = 16;  // standard / screen edge
  static const double lg = 24;  // larger section gaps
  static const double xl = 32;
}
```

| Decision                  | Value |
|---------------------------|-------|
| Base unit                 | 8 px  |
| Screen edge padding       | 16 px (`AppSpacing.md`) |
| Gap between list items    | 8 px  (`AppSpacing.sm`) |
| Gap between sections      | 16 px (`AppSpacing.md`) |
| Tight inner card padding  | 8 px  (`AppSpacing.sm`) |

Usage:

```dart
padding: const EdgeInsets.all(AppSpacing.md)
```

---

## D. Components as Files

Every repeated piece from the wireframes/mockups is listed with its file path and constructor parameters. Components receive data + callbacks only; they never own `setState`.

| Component                  | File                                    | Constructor parameters                                      | Appears on                     |
|----------------------------|-----------------------------------------|-------------------------------------------------------------|--------------------------------|
| `HarmonyHeaderBar`         | `lib/widgets/harmony_widgets.dart`     | `String title`, `Widget? leading`, `Widget? trailing` | Library, Player, Settings |
| `HarmonyCard`              | `lib/widgets/harmony_widgets.dart`     | `Widget child`, optional padding | Library, Player, Settings |
| `HarmonyMetricCard`        | `lib/widgets/harmony_widgets.dart`     | `String label`, `String value`, optional caption | Player |
| `HarmonyStatusBadge`       | `lib/widgets/harmony_widgets.dart`     | `HarmonyStatusVariant variant` | Library rows |
| `HarmonySectionLabel`      | `lib/widgets/harmony_widgets.dart`     | `String text` | All redesigned screens |

**Rules followed:**
- Components take data and callbacks, never `setState`.
- Constructors are `const` wherever possible.

---

## E. Assembled Theme File (ready to paste)

```dart
// lib/theme.dart
import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF4A4A4A),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    onSurface: Color(0xFF111111),
    error: Color(0xFFCCCCCC),
    onError: Color(0xFF111111),
    background: Color(0xFFFFFFFF),
    onBackground: Color(0xFF111111),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF111111)),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111111)),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF111111)),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: Color(0xFF4A4A4A)),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFFF5F5F5),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      side: BorderSide(color: Color(0xFFCCCCCC), width: 1),
    ),
    margin: EdgeInsets.all(8),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF4A4A4A),
      side: const BorderSide(color: Color(0xFF4A4A4A)),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  ),
);
```

---

## What Changed, and Why

| Element       | Version 1 (prelim)              | Version 2 (now)                                      | Why it changed                                                                 |
|---------------|---------------------------------|------------------------------------------------------|--------------------------------------------------------------------------------|
| Palette       | 6 hand-picked grayscale roles   | Full `ColorScheme` with explicit roles + contrast check | Needed real Flutter roles and verified 4.5:1 body-text contrast               |
| Dark mode     | Not mentioned                   | Explicitly “light only”                              | Avoid future hard-coded colors; cheaper to decide now                         |
| Type scale    | Named styles with sizes/weights | Mapped to Flutter `TextTheme` slots                  | So every `Text` widget can use `Theme.of(context).textTheme.…` by name        |
| Spacing       | 8 / 16 px rules                 | Named `AppSpacing` constants                         | One place to change the entire grid                                           |
| Components    | Visual descriptions only        | File paths + constructor parameters                  | Turns drawings into buildable widgets that take data + callbacks              |
| Theme file    | Did not exist                   | Complete `lib/theme/harmony_theme.dart` implementation | Single source of truth for the current app UI |

All decisions were confirmed against the original monochromatic wireframe intent and the screens that actually appear in the Harmony wireframes (Library, Player, Settings, Calibration Modal).
```
