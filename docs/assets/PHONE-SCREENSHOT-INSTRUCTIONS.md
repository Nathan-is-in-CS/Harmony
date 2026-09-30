Phone screenshots (how to export and include)
===========================================

This file explains two quick ways to export phone-sized screenshots for the
README from the provided mockup PDF (`docs/High-level mockup Of Harmony.pdf`) or
the design-system image. Use whichever is easiest for you.

Option A — ImageMagick (command-line, reproducible)

1. Install ImageMagick (https://imagemagick.org). On Windows use the
   installer and ensure `magick` is on your PATH.
2. From the repository root, run (example extracts page 2 as PNG and resizes):

```
magick -density 150 "docs/High-level mockup Of Harmony.pdf[1]" -resize 420x800 docs/assets/screen-library.png
magick -density 150 "docs/High-level mockup Of Harmony.pdf[2]" -resize 420x800 docs/assets/screen-player.png
magick -density 150 "docs/High-level mockup Of Harmony.pdf[3]" -resize 420x800 docs/assets/screen-settings.png
```

Notes:
- The page index in ImageMagick starts at 0. The example above extracts pages 2–4 (change indexes as needed).
- `-density` improves rasterisation quality; `-resize` sets a phone-sized image.

Option B — Online PDF to PNG

1. Open `docs/High-level mockup Of Harmony.pdf` in a local PDF viewer.
2. Use a screenshot tool (Snipping Tool on Windows, or Screenshot on macOS) to capture the phone region at high resolution and save as PNG into `docs/assets/`.

Including screenshots in the README

After you export the images, add them to the README (already uses these paths):

```
| Library | Player | Settings |
| --- | --- | --- |
| ![Library](docs/assets/screen-library.png) | ![Player](docs/assets/screen-player.png) | ![Settings](docs/assets/screen-settings.png) |
```

If you want, run the ImageMagick commands above and tell me when they're created — I will commit the generated images into the repo for you. If you prefer I can create low-resolution placeholder images here instead.
