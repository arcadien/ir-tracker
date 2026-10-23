# IR Tracker — design notes

Design document for the clip (2026-10-17, revised up to 2026-10-23). Build guide: [README](../README.md). Model: `ir-tracker.scad`.

## History

**Prototype 1 abandoned
(2026-10-18): its LEDs pointed backwards** (drawing read with the front on the wrong side, see "LED geometry").
v2 (open "<" frame, box right behind F) printed as **prototype 2** (2026-10-18, Eryone PETG Orange): good overall.
Its fit fixes are in the model (bridge behind the LED bosses opened, caps single plates with 0.2 clearance, pinch-nut
lug widened, switch pocket blocks that really print, no pack stop, M3 round-head screws, ball +0.15 and stem +4,
clamp retuned for electrical tape). **Prototype 3** (all parts, ~4 h 10 min) printed 2026-10-19:
F could not be wired (cut free by hand), flange holes drilled to 2.8, switch stops cut off. Fixed in the model: F wire
trench open through the box wall (closed by the lid), LED caps reach back over the legs and the resistor joint,
flange holes 2.8, no switch stops. Open: the clamp slides down the fork until it stops on the fork (harmless); a
second clamp screw on the other side of the fork is being considered.

**Final build** (2026-10-22): works. The battery block was thicker than planned, so the ball flange screws were
driven from the ball side into the box floor (now in the model: tapped floor with 1 mm bosses, clearance holes in the
flange); a small perfboard junction carries the LED branches and resistors; the F LED leads were too short to wire
comfortably (the guide now says to leave them long). The battery and box dimensions were gathered at the top of the
SCAD file (`/* [Your parts] */`).

## Intent

A DIY replacement for a TrackIR active clip (TrackClip Pro style): a 3D-printed device clamped on a PC gaming
headset that holds 3 infrared LEDs at the exact positions TrackIR expects, powered by an on-board LiPo with USB
charging and a power switch. The whole clip can be aimed by a few degrees towards the camera.

Success: the TrackIR software recognises the clip as a TrackClip Pro geometry, tracking is stable, the clip does not
shift on the headset during play, and it can be removed without leaving a mark.

### Goals
- LED geometry identical to the TrackClip Pro ([led-geometry.svg](led-geometry.svg)).
- Tool-less, non-destructive mounting on the headset (no drilling, no glue on the headset).
- Self-powered: LiPo + charger, switch, charging possible without dismounting.
- Aiming of the whole clip (pitch and yaw, ~±15°), lockable; LEDs fixed relative to each other.
- Parametric OpenSCAD model, printable without supports where possible.
- **Lighter than the commercial clip it replaces: < 41 g battery included**, target ~30 g; rounded,
  pleasant shapes.

### Non-goals
- No electronics design beyond wiring (no PCB, no LED driver, no battery gauge).
- No support for other headsets beyond what the parameters allow.

### Anti-goals (failure even if it "works")
- Clip slides or rotates on the fork while playing → tracking drift.
- Hinders the detachable microphone (left earcup, front-bottom jack) or the earcup swivel.
- Scratches the anodised fork.
- Loose dangling wires.

## Constraints and measured data

### Headset (measured)
- HyperX Cloud II Wireless, clip on the **left** side.
- Mount on the left red aluminium **fork** (yoke) above the earcup: section **12 × 2.27 mm**, straight portion
  **~24 mm** long from the top before the bottom curve.
- More than **10 mm** free space between the fork inner face and the earcup → the inner jaw fits behind the fork.
- Fold-flat with the clip on is **not** required (headset stays on the PC); only the small earcup tilt while worn
  must remain free.
- The detachable mic plugs into the left earcup (front-bottom): keep that area clear.

### LED geometry ([led-geometry.svg](led-geometry.svg), side profile, **front (camera) to the right**, mm)
Origin = vertex LED (F). x positive = towards the front (camera), y positive = up. The LEDs emit to the right on the
drawing (2026-10-18): F is the farthest from the camera, T and B stand 30 and 74 mm in front of it (TrackClip
Pro). `tools/check.sh` pins this depth order.
- F: (0, 0) — vertex of the profile, at the back.
- T (top): (30, 40).
- B (bottom): (74, −70).
- Coordinates are taken at the centre of each LED emitting face. The arm outline follows the image: straight
  segments F→T (with a short horizontal flat at the top) and F→B (with a short horizontal flat at the bottom),
  rounded tip at F.
- The profile plane is parallel to the side of the head; LEDs point forward (+x) towards the camera.

### Components
- **Power pack**: LiPo + charger board from a bike lamp, total block **20 × 40 × 10 mm**, **micro-USB** on one of the
  long faces.
- **LEDs**: 3 × IR, square body **5 × 5 mm** with a **small flange at the base**; resistor already in heat-shrink on
  one leg.
- **Switch**: mini slide switch SS12D00G4: body 12.95 × 6.9, lever 5.15, overall 18.39,
  3 pins (1P2T).

## Decided design

### Mounting — fork clamp
- Two-jaw clamp gripping the straight part of the fork over ~18 mm.
- Channel 12.4 × 2.5 mm (fork + clearance); side lips key on the rectangular section → no rotation around the fork.
- One layer of PVC electrical tape on each jaw (`foam_t` 0.15; protects anodising, adds friction). 1 mm EVA foam also
  works with `foam_t = 1`, `squeeze = 0.6` (prototype 2 was printed for foam and did not grip without it).
- Clamped by one M3 round-head screw (Ø 5.4 × 3) glued in a knurled printed knob, nut trapped in the inner jaw (tool-less);
  the inner jaw tilts on a fulcrum ridge at the back (the screw cannot cross the fork).
- Between clamp and arm: the aiming ball joint (see LEDs), so the LED triangle can be set vertical and pointed at
  the camera when the headset is worn; it also absorbs any fork roll.
- The clip is held near F, where the "<" is widest (like the commercial clip): ball under the box, box right behind F, as close to the fork as possible (stability).
  T and B reach forward; B ends front-low, outwards of the earcup by the clamp + ball stack (check the mic boom).

### LEDs — fixed, whole clip aimed
- **No per-LED adjustment**: individual aiming would distort the triangle seen by TrackIR. The 3 LEDs
  are fixed in the arm, all parallel, pointing forward.
- Each LED drops into a slot open towards the outside (pocket 5.2, counterbore 6.0); the flange stops on the
  counterbore shoulder → the face lands exactly on its position; a press-fit cap closes the slot over the LED, its legs and the resistor joint, no glue.
- Aiming is done for the whole clip at the clamp-to-arm joint: **one ball joint** (Ø14 ball in a split socket,
  pitch / yaw / roll, ±20° and more, stepless), locked by one M3 knob. Replaces the two serrated joints first
  planned (two Hirth joints pushed the LEDs ~40 mm away from the fork; 60 teeth on Ø24 is at
  the limit of a 0.4 nozzle).
- LED body height **4.60 mm** (without legs), base flange **1 mm** thick, flange outline **5.75 × 5.75 mm**
  (0.75 mm larger than the body in total, measured).

### Electronics
- Wiring: pack output + → switch → 3 LEDs in parallel, each with its own 270 Ω 1 % resistor (the LEDs come from a clip that used a single 6 Ω resistor, dropped) → pack −.
- Pack: LiPo 3.7 V nominal (~4.2 V full), **240 mAh**. No boost converter (not needed:
  the original TrackClip Pro runs unregulated on a CR2032).
- LED current **~9 mA** each: 270 Ω 1 %, measured Vf 1.27 V @ 20 mA (940 nm GaAs, flat-top wide angle). Tracking holds down to
  ~4 mA on the dedicated B525 webcam (IR-cut filter removed, developed film as IR-pass filter, opentrack PointTracker),
  so 270 Ω keeps ~1.7× margin even at the 3.0 V LiPo cutoff (~6.7 mA). Runtime ~8 h. Play with the USB cable when the pack is flat.
  Original single resistor measured **6 Ω**: not reused (at 4.2 V it would push far beyond the LED rating).
- The switch cuts only the LED line, wired in the switch zone at the top end of the box. If the bike-lamp board does not charge with the switch off, wiring is
  unchanged: switch on to charge.
- Micro-USB centred on the bottom end of the pack (board end), notch in the box bottom end wall: the cable comes
  from below, so the clip can run wired when the battery is empty.
- Wires run in a channel in the **outer** face (3 wide × 4.2 under the cover: 2–4 wires 28 AWG plus a 270 Ω
  resistor in heat-shrink; open upwards as printed: no overhang; press-fit covers),
  all behind the LEDs: F straight back into the box (open trench through its boss and the box wall, closed by the lid: prototype 3 could not be wired through a tunnel), T and B down their
  branch then across to the box, entering through slots at the foot of the inner long wall. The plate carries a rib
  around every run (the T / B ribs also brace the branches to the box), so each cover is one solid piece (checked by
  `tools/check.sh`).

### Frame and battery box (revised 2026-10-18: LEDs facing forward)
- Open "<" frame like the TrackClip Pro: F–T and F–B branches only, short flats behind T and B carrying their
  bosses. The arms carry no load (prototype 1): each arm is just the rib around its wire channel, **5 wide ×
  7 high** (walls 1.0, 0.7 beside the cover), running from the box to its LED; rounded fillets, chamfered edges.
  The former T–B branch is gone: it crossed F's line of sight; anything near F is cut out of its cone.
- **Nothing of the clip inside a ±20° cone in front of any LED**: asserts on the box and bosses, plus a geometric
  test in `tools/check.sh` (arm, covers, lid and caps intersected with the cones must be empty).
- The box stands upright right behind F (inner long wall against F's boss), long axis vertical: behind every LED,
  near the ball, so the pack balances the forward arms. Walls 1.2, floor 2, lid 1.2 with a locating lip.
- Cavity: switch zone at the top end: the switch sits on the floor in a pocket (a rib either side of its 12.95 mm
  body, 6.4 deep, 0.1 clearance: slide loads go into the ribs, no stops: prototype 3's stops kept the switch from sliding in), lever through a slot in the top end
  wall (it may stick out, no collar:
  it need not be discreet), pack (no stop: hot-glued where wanted), and a 3.5 mm wire lane along the inner long wall
  (F side) for the LED wires. Height: pack + 3 mm of room for wires above it (prototype 1: box 3 mm too low).
- Micro-USB: **centred on the pack's end, board side** (measured) → notch 13 × 8.5 through the bottom end wall,
  open at the top (closed by the lid), cable exits downwards. Alternative kept in reserve: a micro-USB
  breakout (14.23 × 15.65, plug along the 15.65 side).
- Lid: 2 × M3 self-tapping in rounded corner lobes. Ball flange: 3 × M3 × 6 driven from the ball side through clearance
  holes in the flange, self-tapping into the 2 mm floor plus 1 mm bosses (`mount_pad`) under the pack, tips flush
  (final build: the screws could not be driven from inside the box once the pack was in, and their heads raised it).
- Mass budget: < 41 g with the 8 g pack + switch (measured); `tools/check.sh` fails above 32 g of solid PETG.

### Manufacturing
- OpenSCAD, one parametric file `ir-tracker.scad`; parts exported straight into the slicer project `ir-tracker.3mf` (no STL kept): arm + box, two wire-channel covers, lid,
  three LED caps, clamp jaws, ball, knob (print 2).
- Material: PETG (prototype 1: Eryone PETG Orange).

## Left to the builder
- Exact location of the clamp on the profile and the arm-to-head offset needed to clear the earcup.
- Wall thicknesses, fillets, print orientation, split lines.
- Joint serration count, LED pocket tolerances, exposed as parameters.
- Wire channel routing and cross-section.
- Lid design details.

## Parts, print, assembly

Rebuild: `tools/check.sh` (renders every part, fails on any warning / assert / wrong LED geometry), then
`tools/build.sh` (Orca closed): exports every part through a temp dir straight into `ir-tracker.3mf`
(`tools/refresh_3mf.py`: keeps plates, placement and settings, previous file kept as `.bak`) and redraws `renders/`. All parts PETG, 0.2 mm layers (0.12 recommended for the ball and the
socket; prototype 1 printed all at 0.2), no supports.

| Part | Object in `ir-tracker.3mf` | Qty | Print orientation |
|---|---|---|---|
| Arm + LED bosses + battery box | `irtracker_arm` | 1 | inner face down, LED slots and box open up |
| Wire-channel covers: F + T run (one Y piece), B run | `irtracker_cover_ft`, `irtracker_cover_b` | 1 + 1 | flat |
| Box lid | `irtracker_lid` | 1 | flat |
| LED caps (one per LED) | `irtracker_led_cap_F`, `_T`, `_B` | 1 + 1 + 1 | flat |
| Clamp, outer jaw + ball socket | `irtracker_clamp_outer` | 1 | fork channel down (12.4 mm bridge), socket up on a 45° cone |
| Clamp, inner jaw | `irtracker_clamp_inner` | 1 | flat |
| Ball + stem + flange | `irtracker_ball` | 1 | flange down |
| Knob (clamp, socket pinch) | `irtracker_knob` | 2 | flat |

Hardware: M3 **round head** (Ø 5.4 × 3) ×2, 16 mm for the clamp, 18 mm for the socket pinch (16 leaves only 0.6 mm
past the nut) (heads glued in the knobs: a round head alone spins) + 2 M3 nuts (pressed in the inner jaw and the pinch
lug); M3×6 round head ×3 (from the ball side through the flange into the box floor, holes 2.8), M3×6 self-tapping ×2 (lid); electrical tape,
2 × 12 × 18 mm (one layer per jaw); 3 × 270 Ω 1 % 1/4 W (5 bands red-violet-black-black-brown; check with an ohmmeter, a 270 kΩ was mistaken for one).

Assembly:
1. Solder each LED to its 270 Ω resistor, heat-shrink; drop each LED in its slot from outside, emitting face
   forward (towards T / B's side, the camera), flange towards the back, legs down the slot into the wire channel;
   press the cap on top.
2. Run the wires in the channel (outer face) through the slots into the box; press the two covers in their recess.
3. Wire: pack + → switch (middle + one side pin) → the 3 LED branches in parallel → pack −. Press the switch body
   down into its pocket against the top end wall (a drop of glue on top only if it lifts), lever in the slot; LED wires along the lane. Pack hot-glued,
   micro-USB in front of its notch.
4. Ball flange against the inner face, 3 × M3×6 from the ball side into the floor bosses (before the pack). Lid with 2 × M3.
5. Foam on both jaws. Nut in the inner jaw, jaw behind the fork (towards the earcup), ridge at the back; screw +
   knob from outside. Snap the ball into the socket; nut in the pinch lug, screw + knob.
6. In TrackIR (TrackClip Pro profile): loosen the pinch knob, aim the clip so the 3 points are seen, upright, then
   tighten.

First-fit tuning (parameters in `ir-tracker.scad`): `box_dy` (box height relative to F), `mount_u` (ball position
along the box), `stem_l`
(distance from the fork), `usb_zc` (micro-USB height above the floor), `foam_t`,
`squeeze`.

### Slicer project

`ir-tracker.3mf` (OrcaSlicer, all 12 parts on one plate since 2026-10-18). 0.2 mm
layers, Arachne walls, **inner and outer walls 0.43 mm** (project setting; other features 0.45, top surface 0.4,
first layer 0.42), 15 % infill. Thin walls in the model are whole numbers of wall lines: `walls(n)` in `ir-tracker.scad`
(2 lines 0.82, 3 lines 1.20). Filament preset `Eryone PETG Orange` carries the
`Overture PETG Black` settings since 2026-10-17 (now 230 °C, first layer 235 °C, bed 80 °C, fan 30–45 %, overhang fan 90 %,
PA 0.65, min layer time 18 s) **except its own flow ratio 0.9975** (per spool); previous preset kept as `.json.bak`.
Anti-blob pass (bowden): retraction 4 mm, 40 / 35 mm/s, z-hop 0.4 normal lift, avoid crossing walls. **Firmware retraction**:
Orca emits `G10`/`G11`, the machine start G-code sends the filament's values with `SET_RETRACTION`, so they stay per
filament and can be tuned live in Mainsail (`SET_RETRACTION`, `GET_RETRACTION`); Klippain's
`[firmware_retraction]` (all 0) is the fallback. Orca disables wipe in this mode. Mesh refresh after a model change: `tools/build.sh`; `Arrange` in Orca if parts moved.

### First-fit checklist

| Check | Expected | If wrong |
|---|---|---|
| LED in its slot | flange seats on the shoulder, no force | `pocket` / `cbore` +0.1 |
| Ball in the socket | snaps in with a clear click (0.53 interference, ball printed +0.15) | too hard: `ball_over` down; play: `ball_over` up |
| Covers in the channel recess | press fit, flush with the plate | `cov_w` −0.1 |
| Clamp on the fork, one layer of electrical tape per jaw | grips before the screw runs out | `squeeze` up / `foam_t` |
| LED caps | drop in by hand, hold the flange | `cap_clr` ±0.05 |
| Switch in its pocket | slides in, held by the two side blocks | `sw_fit` |
| Switch lever in its slot | slides without rubbing (proto 2 rubbed) | `sw_window` +0.06 per side |
| Wires through the LED bosses and the F trench | pass without cutting anything; lid closes the F trench | `ch_w` |
| LED caps over the legs | cover the legs and the resistor joint, sit flush | `cap_l` / `cap_clr` |
| Flange screws into the box floor | M3×6 self-taps without drilling | `floor_tap` ±0.1 |
| Micro-USB facing its notch | plug enters without touching | measure the plug height on the pack → `usb_zc` |
| First layer / overhangs (orange PETG) | clean, no blobs | flow −2 % |
| Total mass | < 41 g with pack + switch | lighten `clamp_outer`, `ball` |
