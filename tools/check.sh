#!/usr/bin/env bash
# Render every printable part of ir-tracker.scad and check the LED geometry.
# Fails on any OpenSCAD WARNING/ERROR (asserts included), an empty mesh, or a wrong LED position / distance.
# usage: tools/check.sh
set -uo pipefail
cd "$(dirname "$0")/.."
OPENSCAD=${OPENSCAD:-openscad}
command -v "$OPENSCAD" >/dev/null || OPENSCAD="/c/Program Files/OpenSCAD/openscad.com"
PYTHON=$(command -v python3 || command -v python)
TMP=$(mktemp -d)
command -v cygpath >/dev/null && TMP=$(cygpath -m "$TMP")   # Windows OpenSCAD cannot read Git Bash /tmp paths
trap 'rm -rf "$TMP"' EXIT
PARTS="assembly arm cover_ft cover_b lid clamp_outer clamp_inner ball knob led_cap_F led_cap_T led_cap_B"
fail=0

for p in $PARTS; do
    pp=print_$p; [ $p == assembly ] && pp=assembly
    out=$("$OPENSCAD" -D "part=\"$pp\"" -o "$TMP/$p.stl" ir-tracker.scad 2>&1)
    size=$(stat -c %s "$TMP/$p.stl" 2>/dev/null || echo 0)
    if echo "$out" | grep -qE "WARNING|ERROR" || [ "$size" -lt 1024 ]; then
        echo "FAIL $p (stl $size bytes)"; echo "$out" | grep -E "WARNING|ERROR|assert" | head -5; fail=1
    else
        echo "ok   $p"
    fi
done

# LED positions (arm frame) and pairwise distances, from the spec: F (0,0), T (30,40), B (74,-70)
expected='ECHO: "LED", "F", 0, 0
ECHO: "LED", "T", 30, 40
ECHO: "LED", "B", 74, -70
ECHO: "DEPTH", "F", 0
ECHO: "DEPTH", "T", 30
ECHO: "DEPTH", "B", 74
ECHO: "DIST", "F-T", 50
ECHO: "DIST", "F-B", 101.863
ECHO: "DIST", "T-B", 118.474'
out=$("$OPENSCAD" -D 'part="check"' -o "$TMP/check.echo" ir-tracker.scad 2>&1)
got=$(grep -E '^ECHO: "(LED|DEPTH|DIST)"' "$TMP/check.echo" 2>/dev/null | tr -d '\r')
if [ "$got" == "$expected" ] && ! echo "$out" | grep -qE "WARNING|ERROR"; then
    echo "ok   geometry"
else
    echo "FAIL geometry"; echo "$out" | grep -E "WARNING|ERROR" | head -5; diff <(echo "$expected") <(echo "$got"); fail=1
fi
# covers: channel kept out of the cleared bands in front of the LEDs, each cover printed in one piece
out=$("$OPENSCAD" -D 'part="cover_leak"' -o "$TMP/cover_leak.stl" ir-tracker.scad 2>&1)
shells=$("$PYTHON" -I tools/shells.py "$TMP"/cover_ft.stl "$TMP"/cover_b.stl "$TMP"/arm.stl 2>/dev/null | awk '{print $NF}' | tr '\n' ' ')
if echo "$out" | grep -q "top level object is empty" && [ "$shells" == "1 1 1 " ]; then
    echo "ok   covers and arm (one piece each, covers clear of the LED bands)"
else
    echo "FAIL covers (shells: $shells; band leak: $([ -s "$TMP/cover_leak.stl" ] && echo yes || echo no))"; fail=1
fi
# field of view: nothing of the clip (arm, covers, lid, caps) inside the clear cone in front of any LED
out=$("$OPENSCAD" -D 'part="fov_leak"' -o "$TMP/fov_leak.stl" ir-tracker.scad 2>&1)
if echo "$out" | grep -q "top level object is empty" && ! echo "$out" | grep -qE "WARNING: [^C]|ERROR"; then
    echo "ok   field of view (±20° cone clear in front of every LED)"
else
    echo "FAIL field of view (something inside an LED cone: render part=fov_leak)"; echo "$out" | grep -E "WARNING|ERROR" | head -3; fail=1
fi
# switch pocket: the ribs inside the cavity are really in the printed part (prototype 2 lost them to the cavity cut)
out=$("$OPENSCAD" -D 'part="rib_probe"' -o "$TMP/rib_probe.stl" ir-tracker.scad 2>&1)
if ! echo "$out" | grep -q "top level object is empty" && [ -s "$TMP/rib_probe.stl" ]; then
    echo "ok   switch pocket ribs present"
else
    echo "FAIL switch pocket ribs missing from the arm"; fail=1
fi
# F run: open trench through the box wall (prototype 3 could not be wired through the tunnel)
out=$("$OPENSCAD" -D 'part="trench_probe"' -o "$TMP/trench_probe.stl" ir-tracker.scad 2>&1)
if echo "$out" | grep -q "top level object is empty"; then
    echo "ok   F wire trench open through the box wall"
else
    echo "FAIL F wire run still bridged in the box wall (render part=trench_probe)"; fail=1
fi
# LED caps cover the legs and the resistor joint
out=$("$OPENSCAD" -D 'part="cap_probe"' -o "$TMP/cap_probe.stl" ir-tracker.scad 2>&1)
if ! echo "$out" | grep -q "top level object is empty" && [ "$("$PYTHON" -I tools/shells.py "$TMP/cap_probe.stl" 2>/dev/null | awk '{print $NF}')" == "3" ]; then
    echo "ok   LED caps cover the legs"
else
    echo "FAIL LED caps do not reach over the legs (render part=cap_probe)"; fail=1
fi
# mass budget: solid PETG (100 % infill, upper bound), 2 knobs; < 41 g with the 8 g pack + switch, screws and LEDs
mass=$("$PYTHON" -I tools/mass.py "$TMP"/{arm,cover_ft,cover_b,lid,clamp_outer,clamp_inner,ball,knob,knob,led_cap_F,led_cap_T,led_cap_B}.stl 2>/dev/null | awk '/^total/ {print $2}')
if [ -n "$mass" ] && awk -v m="$mass" 'BEGIN {exit !(m <= 32)}'; then
    echo "ok   mass $mass g (solid, budget 32)"
else
    echo "FAIL mass ${mass:-?} g (solid, budget 32)"; fail=1
fi
[ $fail -eq 0 ] && echo "ALL PASS" || echo "CHECK FAILED"
exit $fail
