# App Icon source and export contract

The three SVG files in this directory are editable reconstructions of the geometry and palette in
the matching 1024×1024 App Icon PNG handoff. Keep the source canvas square and do not add rounded
corners; iOS owns the final mask. The enlarged pace mark is based on the owner-approved August 2026
redesign. The current shipping PNGs are opaque flattened copies of that handoff; the tinted
appearance uses grayscale luminance layers rather than a transparent white silhouette so the
filled segment, remaining track, and pace marker remain distinguishable.

| Appearance | Source | Asset-catalog output |
| --- | --- | --- |
| Standard | `Docs/Brand/AppIcon.svg` | `MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` |
| Dark | `Docs/Brand/AppIcon-Dark.svg` | `MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Dark.png` |
| Tinted | `Docs/Brand/AppIcon-Tinted.svg` | `MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Tinted.png` |

Export with librsvg so the rasterization is explicit and repeatable:

```bash
rsvg-convert -w 1024 -h 1024 Docs/Brand/AppIcon.svg \
  -o MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
rsvg-convert -w 1024 -h 1024 Docs/Brand/AppIcon-Dark.svg \
  -o MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Dark.png
rsvg-convert -w 1024 -h 1024 Docs/Brand/AppIcon-Tinted.svg \
  -o MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Tinted.png
```

After export, visually compare all three appearances, verify they remain opaque 1024×1024 images,
then intentionally refresh `AppIconSources.sha256` with:

```bash
shasum -a 256 \
  Docs/Brand/AppIcon.svg \
  Docs/Brand/AppIcon-Dark.svg \
  Docs/Brand/AppIcon-Tinted.svg \
  MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
  MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Dark.png \
  MindBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Tinted.png \
  > Docs/Brand/AppIconSources.sha256
```

`Scripts/check-release-readiness.sh` verifies that manifest. A source or PNG change therefore
cannot silently leave the repository's declared source/artifact pair out of sync.
