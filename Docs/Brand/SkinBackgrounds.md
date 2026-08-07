# Skin background artwork

The owner-provided UI mockups are style references only. They are never cropped or shipped as
application backgrounds because they contain status-bar, text, amount, card, and control pixels.
Each shipping image below is a standalone portrait background with a deliberately quiet center so
localized content remains readable.

| Skin | Asset-catalog image | Pixel size |
| --- | --- | --- |
| Aurora Glow | `AuroraGlowBackground.imageset/aurora-glow-background.png` | 853 × 1844 |
| Warm Botanical | `WarmBotanicalBackground.imageset/warm-botanical-background.png` | 862 × 1824 |
| Neon Pulse | `NeonPulseBackground.imageset/neon-pulse-background.png` | 853 × 1844 |

All three images were generated with the built-in image-generation workflow and then copied into
`MindBudget/Resources/Assets.xcassets`. They are opaque and contain no text, icon, app control,
amount, logo, watermark, or phone chrome.

## Final prompt set

### Aurora Glow

```text
Use case: stylized-concept
Asset type: reusable full-screen portrait iPhone app background texture
Input images: Image 1 is a visual style reference only, not an edit target
Primary request: create the deep teal Aurora Glow background language from the reference as a clean standalone wallpaper
Scene/backdrop: near-black midnight teal base, soft luminous green-teal aurora ribbon drifting diagonally across the upper third, sparse tiny star particles, faint layered translucent wave ribbons near the lower edge
Style/medium: premium restrained cinematic digital background, subtle atmospheric depth, elegant glass-and-light mood
Composition/framing: vertical portrait; center and primary content zones remain quiet and readable; visual motifs stay mainly at the top-right and bottom-right edges
Lighting/mood: calm, private, refined, low contrast except soft teal glow
Color palette: black teal, emerald, cyan mint
Constraints: background only; no app UI, no cards, no buttons, no icons, no phone frame, no status bar, no currency symbols, no text, no logo, no watermark; avoid bright detail behind central text; no people or objects
```

### Warm Botanical

```text
Use case: stylized-concept
Asset type: reusable full-screen portrait iPhone app background texture
Input images: Image 1 is a visual style reference only, not an edit target
Primary request: create the warm botanical background language from the reference as a clean standalone wallpaper
Scene/backdrop: warm ivory handmade-paper surface with a barely visible fiber grain, soft morning sunlight, delicate olive-green leafy branch entering from the upper-right edge, gentle leaf shadows falling diagonally, one or two very faint botanical sprigs near the lower-left edge
Style/medium: premium editorial lifestyle background, natural and airy, realistic soft botanical details but restrained for app readability
Composition/framing: vertical portrait; large clean quiet center; foliage and shadows remain around edges and never crowd the UI content area
Lighting/mood: calm warm morning, soft natural light, comforting without looking decorative or childish
Color palette: cream, warm white, pale sage, muted olive, very light sand
Constraints: background only; no app UI, no cards, no buttons, no icons, no phone frame, no status bar, no coffee cup, no notebook, no currency symbols, no text, no logo, no watermark; no strong dark marks in the center
```

### Neon Pulse

```text
Use case: stylized-concept
Asset type: reusable full-screen portrait iPhone app background texture
Input images: Image 1 is a visual style reference only, not an edit target
Primary request: create the Neon Pulse background language from the reference as a clean standalone wallpaper
Scene/backdrop: deep midnight indigo and near-black navy base, restrained violet-magenta and electric-cyan light arcs, subtle perspective micro-grid fading into darkness, sparse glowing particles and tiny circuit-like dots, soft energy waves near the lower-right and upper-left edges
Style/medium: premium futuristic neon atmosphere, sophisticated and minimal rather than gaming wallpaper
Composition/framing: vertical portrait; the center remains quiet and readable; brighter neon detail is confined to outer edges and corners
Lighting/mood: focused, futuristic, calm, luminous but not flashy
Color palette: midnight navy, ultraviolet, electric blue, cyan
Constraints: background only; no app UI, no cards, no buttons, no icons, no phone frame, no status bar, no wallet, no currency symbols, no text, no logo, no watermark; avoid dense detail behind central content
```

## Runtime contract

`AppSkin.backgroundAssetName` is the exhaustive mapping. `MindBudgetThemeBackground` scales the
selected artwork to the current viewport, clips it, and adds only a light readability scrim. The
background is decorative and accessibility-hidden. Feature views continue to consume semantic
colors, so a future skin can supply new artwork and palette roles without duplicating screens.
