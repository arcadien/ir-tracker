#!/usr/bin/env bash
# Update the slicer project and the renders from ir-tracker.scad (no STL kept: they go through a temp dir).
# usage: tools/build.sh [3mf|renders|all]   (default: all; close OrcaSlicer first)
set -euo pipefail
cd "$(dirname "$0")/.."
OPENSCAD=${OPENSCAD:-openscad}
command -v "$OPENSCAD" >/dev/null || OPENSCAD="/c/Program Files/OpenSCAD/openscad.com"
PYTHON=$(command -v python3 || command -v python)
WHAT=${1:-all}
PROJECT=ir-tracker.3mf
PARTS="arm cover_ft cover_b lid clamp_outer clamp_inner ball knob led_cap_F led_cap_T led_cap_B"

build_3mf() {
    if { tasklist 2>/dev/null; pgrep -fl orca-slicer 2>/dev/null; } | grep -qi orca-slicer; then echo "OrcaSlicer is open: close it first ($PROJECT not written)"; exit 1; fi
    TMP=$(mktemp -d)
    command -v cygpath >/dev/null && TMP=$(cygpath -m "$TMP")   # Windows OpenSCAD cannot read Git Bash /tmp paths
    trap 'rm -rf "$TMP"' RETURN
    for p in $PARTS; do
        "$OPENSCAD" -D "part=\"print_$p\"" -o "$TMP/irtracker_$p.stl" ir-tracker.scad 2>&1 | grep -E "WARNING|ERROR" || true
    done
    "$PYTHON" -I tools/refresh_3mf.py "$PROJECT" "$TMP"
}

build_renders() {
    mkdir -p renders
    R="--imgsize=1400,1100 --colorscheme=Tomorrow --viewall --autocenter"
    "$OPENSCAD" $R --camera=0,0,0,60,0,210,0 -D 'part="assembly"' -o renders/assembly.png ir-tracker.scad 2>/dev/null
    "$OPENSCAD" $R --camera=0,0,0,90,0,90,0 -D 'part="assembly"' -o renders/camera_view.png ir-tracker.scad 2>/dev/null   # from the camera (+x)
    "$OPENSCAD" $R --camera=0,0,0,0,0,0,0 -D 'part="assembly"' -o renders/side_view.png ir-tracker.scad 2>/dev/null     # from outside the head (+z), front to the right
    "$OPENSCAD" $R --camera=0,0,0,50,0,325,0 -D 'part="print_arm"' -o renders/arm_top.png ir-tracker.scad 2>/dev/null
    "$OPENSCAD" $R --camera=0,0,0,55,0,35,0 -D 'part="clamp_outer"' -o renders/clamp.png ir-tracker.scad 2>/dev/null
    echo "== renders/*.png"
}

case $WHAT in
    3mf) build_3mf ;;
    renders) build_renders ;;
    all) build_3mf; build_renders ;;
esac
