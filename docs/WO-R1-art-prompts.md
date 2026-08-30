# WO-R1 — Piece Art Generation Prompts

**For:** Gemini Pro (paste directly)
**Output:** 12 pieces × 6 themes = 72 assets
**Target:** `assets/pieces/<theme_slug>/<color>_<piece>.png`

---

## Read this before generating anything

**The constraint that governs every decision: these render at 44 pixels on a phone that two people pass back and forth.** One of them is nine years old.

That means:

- **Silhouette is everything.** At 44px you identify a piece by its outline, not its detail. If knight and bishop are confusable in black-and-white at thumbnail size, the set has failed regardless of how it looks at 512px.
- **Do not redesign the Staunton silhouette.** It is 175 years of legibility research. Theme the surface, the material, the palette — never the shape language. A "creative" knight is an unplayable knight.
- **Test small, always.** Judge every output shrunk to 44px before accepting it. Beautiful at full size and mush at thumbnail is the default failure mode.
- **Both orientations.** The board flips between turns. Nothing may read as upside-down or wrong-way-round.
- **Both square colours.** Every piece must hold contrast on light AND dark squares. A dark piece that vanishes on a dark square is a bug.

---

## Master prompt

Paste this first, then one theme block per generation run.

```
You are producing chess piece art for a mobile game played on a phone passed
between two players, one of them a child. Pieces render at 44 pixels.

Produce 12 pieces: king, queen, rook, bishop, knight, pawn — in two colours
(light and dark).

NON-NEGOTIABLE RULES
1. Keep the classic Staunton silhouette exactly. Theme the material and
   palette. Never alter the shape language that distinguishes the pieces.
2. Optimise for readability at 44px. Test every piece shrunk down before
   you consider it done. Silhouette clarity beats surface detail.
3. Flat or subtle 2.5D. No photorealism, no heavy texture, no scene.
4. One consistent light source across all 12 pieces: upper-left, soft.
5. Transparent background. Piece centred with a small margin.
6. Square canvas, 512x512, for downscaling.
7. Light and dark sets must be distinguishable by VALUE, not just hue.
   Verify by desaturating to greyscale.
8. Both sets must hold contrast against both a light square and a dark
   square. State which square colours you assumed.

DELIVER
- 12 images
- The hex values you used
- A note on any piece whose silhouette needed care to stay readable small
```

---

## Theme blocks

### 1. Chrome Vanguard
```
Theme: Chrome Vanguard. Brushed metal and industrial precision. Light set is
polished chrome with cool highlights; dark set is gunmetal with a darker
anodised finish. Sharp bevels, machined edges, restrained specular. Feels
engineered rather than carved. Board squares assumed: pale steel and slate.
```

### 2. Crystal Vault
```
Theme: Crystal Vault. Cut glass and faceted mineral. Light set is clear
quartz with soft internal refraction; dark set is smoky obsidian glass.
Faceted planes, subtle translucency, edge light. Must stay legible despite
transparency — silhouette holds even where the body is see-through. Board
squares assumed: frosted white and deep indigo.
```

### 3. Gilded Court
```
Theme: Gilded Court. Classical and regal without being fussy. Light set is
warm brushed gold; dark set is aged bronze with a dark patina. Fine engraved
detail at crown and base only — keep the body clean so it survives
downscaling. Board squares assumed: cream and deep burgundy.
```

### 4. Carbon Night
```
Theme: Carbon Night. Modern matte minimalism. Light set is bone white with a
soft matte finish; dark set is carbon black with a woven texture hint. Almost
no specular. Relies entirely on silhouette and value contrast — the strictest
test of whether the shapes work. Board squares assumed: light grey and near-black.
```

### 5. Obsidian Relic
```
Theme: Obsidian Relic. Ancient, volcanic, weathered. Light set is pale carved
basalt with chipped edges; dark set is black obsidian with a glassy fracture
sheen. Slight asymmetry and wear, as if excavated. Wear must not soften the
silhouette. Board squares assumed: ash grey and charcoal.
```

### 6. Aurora Myth
```
Theme: Aurora Myth. Luminous and otherworldly. Light set glows pale cyan-white
with a soft inner light; dark set is deep violet with aurora-green rim light.
The glow is a rim effect, not a bloom — it must not blur the outline. Highest
risk theme for 44px legibility; be conservative with the glow. Board squares
assumed: dark navy and near-black.
```

---

## Naming and delivery

```
assets/pieces/chrome_vanguard/light_king.png
assets/pieces/chrome_vanguard/light_queen.png
assets/pieces/chrome_vanguard/light_rook.png
assets/pieces/chrome_vanguard/light_bishop.png
assets/pieces/chrome_vanguard/light_knight.png
assets/pieces/chrome_vanguard/light_pawn.png
assets/pieces/chrome_vanguard/dark_king.png
... same six for dark
```

Theme slugs: `chrome_vanguard`, `crystal_vault`, `gilded_court`, `carbon_night`, `obsidian_relic`, `aurora_myth`

These paths match the loader Codex is building in WO-R2. Any theme folder that is missing or incomplete falls back to the current glyph rendering, so partial delivery is safe — ship one theme at a time.

---

## Acceptance test

Before adding a set to the repo, shrink all 12 to 44px, place them on both square colours, and answer:

1. Can you tell knight from bishop instantly?
2. Can you tell queen from king instantly?
3. Does every piece hold against both square colours?
4. Does the set still read when desaturated to greyscale?

Any no means regenerate that piece. This test is the whole point — a set that fails it is worse than the glyphs it replaces.

---

## Priority

Generate **Carbon Night** first. It is the strictest test: no specular, no texture, no colour tricks — pure silhouette and value. If a set works there, the shape language is sound and the other five are surface treatments over a proven base. If it fails there, the problem is the shapes, and every other theme would have inherited it.
