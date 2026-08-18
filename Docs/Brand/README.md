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

## Theme colour-token sheet

`MindBudget/Features/Shared/AppTheme.swift` is the only source of truth for skin colours. To review
every token across all three skins at once — including the categorical chart scale on its own
`canvas`, and WCAG contrast ratios against `surface` — generate the sheet:

```bash
python3 -B Scripts/theme_palette.py MindBudget/Features/Shared/AppTheme.swift /tmp/palette.html
```

Omit the output path to print the parsed values as JSON instead.

The sheet is generated, never hand-maintained, so it cannot drift from the theme the way a copied
palette would. For that reason it is deliberately **not** committed: regenerate it after any theme
change rather than reading a stale copy.

The parser understands the four declaration shapes the theme uses — a per-skin `switch`, a ternary
with an alias fallback, an alias plus `.opacity()`, and a named colour plus `.opacity()`. Aliases may
point at a token declared later in the file, and an alias keeps the alpha of the token it references.

The skin list comes from the `AppSkin` enum rather than a constant, so adding a skin widens the sheet
instead of being silently omitted. Anything the parser cannot resolve for every skin — or a layout
change that matches no token at all — raises rather than producing a quietly incomplete sheet. Run
its tests after changing either the parser or the shape of a theme declaration:

```bash
python3 -B Scripts/tests/test_theme_palette.py
```
