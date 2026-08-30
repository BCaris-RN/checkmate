# WO-R1 — Motion Specification

**For:** Codex (WO-R2 Step 2) — implement against these numbers
**Principle:** motion is most of why chess.com feels better than a board renderer. Not the art. The art is second.

---

## Why this matters more than the art

A piece that teleports reads as a state change. A piece that travels reads as a *move* — an action a person took. That difference is most of the perceived quality gap, and it costs nothing in assets.

Every value below is a starting point tuned for a phone held at arm's length and passed between two people. Adjust on device, not in theory.

---

## Core timings

| Event | Duration | Curve | Notes |
|---|---|---|---|
| Piece lift | 90ms | `easeOut` | scale 1.0 → 1.08, elevation 0 → 8 |
| Piece glide | 180ms base | `easeInOutCubic` | see distance scaling below |
| Piece settle | 110ms | `easeOutBack` (overshoot 1.05) | the small bounce that sells the landing |
| Capture exit | 140ms | `easeIn` | scale → 0.7, opacity → 0 |
| Illegal move | 280ms | `elasticIn`, damped | 3 oscillations, ±6px, decreasing |
| Check pulse | 600ms | `easeInOut` | repeat 2×, king square only |
| Checkmate | 800ms | `easeOutCubic` | see below |
| Board flip | 550ms | `easeInOutCubic` | see below — this is the signature |

### Distance scaling for glide

A queen crossing seven ranks should not take seven times a pawn's step. Scale sub-linearly:

```
duration = 180ms + (distance_in_squares × 12ms)
```

Capped at 260ms. A one-square move is 192ms; a seven-square move is 264ms → clamped to 260ms. The move stays quick while long moves still read as travelling further.

---

## Capture

The timing detail that matters: **start the captured piece's exit 40ms before the capturing piece arrives.** If both animate on the same clock the sprites visibly overlap and it looks like a bug. Staggering reads as displacement.

```
t=0     capturing piece begins glide
t=D-40  captured piece begins scale-down and fade
t=D     capturing piece lands, settle begins
t=D+100 captured piece fully gone
```

---

## Board flip — the signature moment

This is hot-seat. The device passes between two people after every move, and **chess.com has no equivalent** because chess.com isn't played this way. Get this right and it becomes the thing people remember.

It should feel like *handing something over*, not like a screen transition.

```
Phase 1  (0-200ms)   Board lifts and shrinks slightly.
                     scale 1.0 → 0.94, elevation rises.
                     The board is being picked up.

Phase 2  (200-400ms) Rotation through 180°.
                     Rotate about the board's centre, not the screen's.
                     Pieces rotate WITH the board, then counter-rotate
                     individually in the last 80ms so they land upright.
                     A knight facing backwards ruins it.

Phase 3  (400-550ms) Settle. scale 0.94 → 1.0, elevation falls.
                     Slight overshoot. The board is set back down.
```

Coordinate labels cross-fade at the midpoint rather than rotating — rotating text is unreadable at any point in the arc.

Add a **light haptic at phase 3 onset**. On mobile that single vibration does more for perceived quality than any visual polish in this document, and it costs one line.

---

## Check and checkmate

**Check** — pulse the king's square only. Border colour animates to the theme's alert token and back, twice, 600ms each. Do not shake the board and do not tint the whole screen. Both are common and both make the position harder to read at exactly the moment the player needs to read it.

**Checkmate** — earn the ending:

```
0-200ms    Everything except the two kings desaturates to 40%.
200-600ms  Losing king rotates 75° and drops 8px. It topples.
600-800ms  Result banner fades up from the bottom.
```

The topple is worth building. It's the one moment in a chess app where a small flourish is unambiguously correct.

---

## Illegal move

Shake the *piece*, never the board. Board shake implies the game broke; piece shake says "not that square."

3 oscillations, ±6px horizontal, 280ms, amplitude decaying. Pair it with a brief red tint on the attempted destination square. No sound — this fires often enough that a sound becomes an irritant fast.

---

## Accessibility and performance

**Respect `MediaQuery.disableAnimations`.** When set, all durations go to zero and state changes apply instantly. Not shortened — zero. Motion sensitivity is real, and a fast animation is still an animation.

Consider a settings toggle beyond the OS flag. Some people simply want the board to snap.

**Performance floor:** 60fps on a mid-range Android device. The glide animates one piece; the board should not rebuild. If profiling shows full-board rebuilds per frame, the widget tree is wrong — fix the tree rather than shortening the animation.

`RepaintBoundary` around the board grid. Squares are static between moves and should not repaint when a piece moves over them.

---

## Sound — deliberately out of scope

No audio dependency exists in `pubspec.yaml` and none should be added in this work order.

When it comes: piece placement (a soft wooden click), capture (slightly heavier), check (a short tone), game end. Nothing else. Chess audio goes wrong by having too much, not too little — and this game is played in a house where someone may be sleeping.

---

## Acceptance

Play a full game on a real phone, passing it back and forth, before signing off.

1. Do pieces travel rather than teleport?
2. Does the flip feel like handing the device over?
3. Is the board *more* readable during check, not less?
4. Does the checkmate land as an ending?
5. Does an illegal move say "not there" without saying "something broke"?
6. Does it hold 60fps with a full board?
7. With `disableAnimations` on, is everything instant?

Question 2 is the one that matters. It's the only one chess.com can't answer.
