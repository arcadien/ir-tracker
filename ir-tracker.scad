// IR Tracker: a battery-powered 3-LED infrared head-tracking clip (TrackClip Pro geometry), clamped on the left fork
// of a HyperX Cloud II Wireless headset. 3 IR LEDs fixed in an open "<" frame (F-T, F-B), battery box right behind F
// (out of every LED's field of view), the whole clip aimed through one lockable ball joint under the box, on a clamp
// gripping the headset fork. Build guide: README.md; design notes: docs/design.md.
//
// Using another battery? Edit the "Your parts" section just below, then run tools/check.sh.
//
// Arm frame (LEDs, frame, box): origin = vertex LED (F) emitting-face centre, x = towards the front (camera), y = up,
// z = outwards (away from the head). LEDs emit towards +x: F is the farthest from the camera, T and B stand in front
// of it (docs/led-geometry.svg: LEDs emit to the right). Frame inner face at z = 0.
// Box frame: u down (switch end at the top, USB end at the bottom: cable from below for wired use), v backwards
// (away from F), z as above (left-handed in plan: the box is mirrored, its parts are symmetric enough).
// Clamp frame (clamp, ball): origin = centre of the fork straight part, same axes; fork 12 mm along x, 2.27 along z.
// Render one part: openscad -D 'part="print_arm"' -o arm.stl ir-tracker.scad

part = "assembly"; // assembly | check | arm | cover | lid | clamp_outer | clamp_inner | ball | knob | led_cap | print_<part>

$fn = 48;
eps = 0.01;

/* [Your parts: measure them and edit here, the battery box follows] */
// Battery pack: LiPo + charger board as one block, mm. u = length (vertical in the box, micro-USB end at the bottom),
// v = width, z = thickness (stacked away from the head). The box cavity, lid and screw positions are derived from it.
pack = [40, 20, 10];
pack_clr = 0.4;               // clearance around the pack, per axis
pack_top_room = 3;            // room above the pack for wires and the solder junction board (prototype 1: 3 mm too low)
sw_zone = 10;                 // cavity length above the pack for the slide switch (body 6.4 + shortened pins + wires)
lane = 3.5;                   // wire lane along the long wall on F's side (LED wires and resistors to the switch)
usb_zc = 3;                   // micro-USB centre above the pack bottom (connector centred on the pack's bottom end)
usb_window = [13, 8.5];       // notch for the plug overmold (width, height)
box_dy = 0;                   // box centre height relative to the F LED

/* [Print] */
line_w = 0.43;                // slicer wall line width (inner and outer walls 0.43 in ir-tracker.3mf)
layer_h = 0.2;
// width of n side-by-side perimeters (Orca / Slic3r spacing: lines overlap by layer_h * (1 - pi / 4))
function walls(n) = n * line_w - (n - 1) * layer_h * (1 - PI / 4);

/* [LEDs] */
led_pos = [[0, 0], [30, 40], [74, -70]];   // F, T, B emitting-face centres (x, y), TrackClip Pro (docs/led-geometry.svg)
led_dir = [1, 0];             // emission direction (arm frame): towards the camera, to the right on the drawing
led_names = ["F", "T", "B"];
led_body = 5;                 // square body, measured
led_h = 4.6;                  // overall height without legs (flange included), measured
led_flange = 5.75;            // square flange at the base, measured
led_flange_t = 1;             // measured
pocket = led_body + 0.2;      // body pocket (FDM holes print small)
cbore = led_flange + 0.25;    // flange counterbore (the flange stops on its front shoulder)
cbore_t = led_flange_t + 0.1;
leg_l = 4;                    // room behind the flange for the legs and their wire joints (resistors on the junction board)
leg_w = 3.5;                  // leg slot width, continues down through the plate into the wire channel
los = 20;                     // half angle of the cone kept clear in front of every LED (deg)

/* [Wire channel] */
ch_w = 3;                     // 2 to 4 wires (28 AWG) plus a 270 ohm resistor in heat-shrink (~2.5 mm)
ch_d = 5;                     // depth from the outer face, cover included
cov_w = ch_w + 2 * (walls(3) - walls(2));   // cover strip width: a one-line ledge each side under it
rib_wall = walls(2);          // arm side wall beside the cover: 2 lines (3 lines below it)
arm_w = cov_w + 2 * rib_wall; // arm width = the rib around the channel
cov_t = 0.8;

/* [Frame] */
arm_t = 7;                    // arm height (z 0 .. arm_t): narrow and tall, room for a deep wire channel
flat_l = 8;                   // short flats behind T and B (carry their bosses)
fillet = 3;                   // concave fillets where branches meet
chamfer = 0.8;                // top edge chamfer (stepped, prints without support)
led_z = arm_t - ch_d + cbore / 2;   // LED axis height: flange bottom level with the channel floor, legs straight into it
boss_wall = walls(3);
cap_t = 1.2;                  // LED cap above the flange
cap_clr = 0.2;                // cap clearance each side in its slot (prototype 2: zero-clearance caps did not go in)
boss_top = led_z + cbore / 2 + cap_t;
boss_l = led_h + 0.1 + leg_l + boss_wall;   // along -x, from the LED face backwards
cap_l = led_h + 0.1 + leg_l;                 // cap seat length from the LED face: over the legs, up to the boss back wall
boss_hw = cbore / 2 + boss_wall;            // half width (y)

/* [Box] */
// derived from "Your parts" above (cav); the values below rarely need changing
sw_body = [12.95, 6.9];       // SS12D00G4 body (along the slide v, height z), measured
sw_depth = 6.4;               // body depth (u) from the lever face to the pin face, without pins and lever, measured
sw_fit = 0.1;                 // clearance each side in its pocket (light press fit)
sw_rib = walls(3);            // minimum pocket block width either side of the body
sw_lever_h = 5.15;
sw_lever = [3.88, 3.88];
sw_travel = 6;
rib_t = walls(3);             // room kept between the switch zone and the pack (no stop: the pack is hot-glued)
sw_window = [sw_lever[0] + sw_travel + 0.6, sw_lever[1] + 0.6];   // lever slot (v, z)
collar_d = 0;                 // no collar: the lever may stick out of the top end wall
box_wall = walls(3);
floor_t = 2;
mount_pad = 1;                // bosses on the floor around the flange screws (the pack rests on them): 3 mm of thread, tips flush
cav = [sw_zone + rib_t + pack[0] + pack_clr, pack[1] + pack_clr + lane, mount_pad + pack[2] + pack_clr + pack_top_room];
// micro-USB notch through the bottom end wall, open at the top (closed by the lid)
lid_t = 1.2;
lid_lip = 0.8;
lobe_r = 3.6;                 // lid screw lobes, 2 diagonal corners (M3 self-tapping, head on the lid)
m3_tap = 2.5;                 // M3 self-tapping into PETG (lid lobes)
floor_tap = 2.8;              // ball flange screws self-tap into the box floor (prototype 3: 2.5 had to be drilled out to 2.8)
m3_head = [5.4, 3];           // round head (d, height)
flange_screw_l = 6;           // M3 x 6 under the head, driven from the ball side through the flange into the floor

/* [Fork and clamp] */
fork_w = 12;                  // measured
fork_t = 2.27;                // measured
fork_free = 10;               // free space behind the fork (at least), measured
foam_t = 0.15;                // one layer of PVC electrical tape on each jaw (no foam at hand; was 1 mm EVA)
squeeze = 0.3;                // jaw travel past contact at the fork centre (tape + PETG flex; was 0.6 with foam)
clamp_len = 18;               // along the fork (straight part ~24)
ch_clr = 0.2;
cw = 2.5;                     // clamp outer wall
jaw_t = 5.5;
ext_l = 12;                   // front extension carrying the clamp screw
m3_clear = 3.4;
m3_hex = [5.7, 2.6];          // M3 nut pocket (across flats, depth)

/* [Ball joint] */
ball_d = 14;
ball_clr = 0.2;               // socket = ball_d + ball_clr
ball_over = 0.15;             // printed ball oversize: tighter in the socket, less pinch needed (prototype 2); socket unchanged
stem_d = 7;
stem_l = 13;                  // ball centre to flange: 6 mm of air under the flange for the M3 x 6 tips (prototype 2: 9, tips hit)
flange_d = 24;
flange_t = 3;
flange_screw_r = 8.5;
sock_x = 3.5;                 // socket centre (x) on the clamp
sock_base = 2;
sock_top_h = 2;               // socket top above the ball centre: snap interference ~0.4
sock_wall = 2.8;
lug_out = 7;                  // pinch lug outer face beyond the screw axis (prototype 2: 3.5 left 0.2 mm around the nut)
lug_up = 1.5;                 // lug top above the socket top, outside the ball opening (nut top wall)
mount_u = 0;                  // ball flange centre under the box, along u from the box centre
knob_d = 13;
knob_h = 6;

// ---------- derived ----------
F = led_pos[0]; T = led_pos[1]; B = led_pos[2];
function unit(v) = v / norm(v);
box_u = [0, -1];                                // box u axis down (switch at the top, USB at the bottom)
box_v = [-1, 0];                                // box v axis backwards (-x)
function led_xyz(i) = [led_pos[i][0], led_pos[i][1], led_z];
box_c = F + [-(boss_l - 1 + cav[1] / 2 + box_wall), box_dy];   // inner long wall overlapping the back of F's boss by 1
function box_pt(u, v) = box_c + box_u * u + box_v * v;
box_top = floor_t + cav[2];
pack_u = cav[0] / 2 - (pack[0] + pack_clr) / 2;
pack_v = cav[1] / 2 - (pack[1] + pack_clr) / 2;
lane_v = -cav[1] / 2 + lane / 2;
sw_v = pack_v;
lobes = [[-cav[0] / 2 - 1.6, cav[1] / 2 + 1.6], [cav[0] / 2 + 1.6, -cav[1] / 2 - 1.6]];
q_t = F + (T - F) * 0.25;                       // T / B runs leave their branch here, close to F
q_b = F + (B - F) * 0.15;
// channel ends in the wire lane, through a slot at the foot of the inner long wall (box frame)
e_f = [0, lane_v];
e_t = [(q_t - box_c) * box_u, lane_v];   // level with the branch point: short runs hugging F
e_b = [(q_b - box_c) * box_u, lane_v];
mount = box_pt(mount_u, 0);
function leg_pt(i) = led_pos[i] - [led_h + 0.2 + leg_l / 2, 0];
sw_z = floor_t + sw_body[1] / 2;                // switch seated on the floor, lever centred on the body

zf = fork_t / 2;
z_jaw_in = zf + foam_t;                         // outer jaw inner face
z_out = z_jaw_in + cw;                          // clamp outer face
zj_top = -(zf + foam_t);                        // inner jaw top (tape just touching)
z_wb = zj_top + squeeze + 0.2;                  // clamp underside: room above the inner jaw for its full travel (side walls key the fork edges)
zj_bot = zj_top - jaw_t;
x_ch = fork_w / 2 + ch_clr;                     // channel half width
cx0 = -(x_ch + cw + ext_l);                     // clamp front end
cx1 = x_ch + cw;                                // clamp back end
x_cs = cx0 + ext_l / 2;                         // clamp screw
x_ridge = cx1 - 1.2;                            // fulcrum ridge on the inner jaw (back end)
lift = function(x) squeeze * (x_ridge - x) / x_ridge;   // jaw lift at x for `squeeze` at the fork centre
relief = lift(cx0) - (z_wb - zj_top) + 0.4;     // jaw top lowered in front of the fork: no stop before full squeeze
zb = z_out + sock_base + ball_d / 2;            // ball centre
sock_r = (ball_d + ball_clr) / 2 + sock_wall;
sock_top = zb + sock_top_h;
sock_open = 2 * sqrt(pow((ball_d + ball_clr) / 2, 2) - pow(sock_top_h, 2));
pinch_y = sock_r + 0.8;
pinch_z = zb - 1;
lug = [sock_x - 6, sock_x + 6];
lug_in = (sock_open + 1) / 2 + 0.5;            // raised lug top starts outside the ball entry chamfer
nut_r = m3_hex[0] / cos(30) / 2;               // nut corner radius (corners along y in the lug, flats along z)
arm_z0 = zb + stem_l + flange_t;                // frame inner face (clamp frame)

// ---------- checks ----------
// clear cone in front of an LED: a solid spanning z0..z1 at 2D point p must not come within it
function dz_span(z, z0, z1) = z < z0 ? z0 - z : (z > z1 ? z - z1 : 0);
function blocks(i, p, z0, z1) = let(L = led_pos[i], dx = p[0] - L[0])
    dx > 0 && norm([p[1] - L[1], dz_span(led_z, z0, z1)]) < dx * tan(los) + cbore / 2;
box_probe = [for (u = [-cav[0] / 2 - box_wall - collar_d, 0, cav[0] / 2 + box_wall], v = [-cav[1] / 2 - box_wall, 0, cav[1] / 2 + box_wall]) box_pt(u, v)];
boss_probe = [for (j = [0:2], dx = [-boss_l, 0], dy = [-boss_hw, boss_hw]) led_pos[j] + [dx, dy]];
assert(led_dir == [1, 0], "the model assumes LEDs emitting towards +x");
assert(pocket >= led_body + 0.1 && cbore >= led_flange + 0.2, "LED pocket too tight");
assert(led_z - cbore / 2 >= arm_t - ch_d - eps, "LED slot deeper than the wire channel");   // line of sight: fov_leak test
for (i = [0:2]) {
    assert(len([for (p = box_probe) if (blocks(i, p, 0, box_top + lid_t)) 1]) == 0, str("box in the field of view of LED ", led_names[i]));
    assert(len([for (p = boss_probe) if (blocks(i, p, 0, boss_top)) 1]) == 0, str("LED boss in the field of view of LED ", led_names[i]));
}
assert(usb_window[0] >= 13 && usb_window[1] >= 8.5, "USB window size");
assert(pack_v - usb_window[0] / 2 > lane_v + 2.6 / 2 + 1, "USB notch runs into the B wire entry");
assert(pack_v - usb_window[0] / 2 > -cav[1] / 2, "USB notch runs into the lane wall");
assert(sw_body[0] <= cav[1] && sw_body[1] <= cav[2] && sw_depth <= sw_zone, "switch does not fit the cavity");
assert(sw_v - sw_body[0] / 2 - sw_fit - sw_rib >= lane_v + lane / 2, "switch pocket rib runs into the wire lane");
assert(sw_v + sw_body[0] / 2 + sw_fit + sw_rib <= cav[1] / 2, "switch pocket rib runs into the long wall");
assert(abs(sw_v) + sw_window[0] / 2 + 1.2 <= cav[1] / 2, "switch slot runs into the long walls");
assert(lane >= 2.5, "wire lane too narrow");
assert(arm_t - ch_d >= floor_t, "wire channel lower than the cavity floor: the wires cannot step into the box");
assert(clamp_len <= 24 - 2, "clamp longer than the fork straight part");
assert(-zj_bot - zf <= fork_free - 2, "inner jaw too thick for the space behind the fork");
assert(z_wb - zj_top >= squeeze, "ridge / foam: no squeeze left");
assert(z_jaw_in - z_wb >= fork_t * 0.6, "clamp side walls too shallow to key the fork");
assert(jaw_t - relief >= m3_hex[1] + 1, "inner jaw front too thin for the nut");
assert(lift(-x_ch) <= relief + (z_wb - zj_top) - 0.2, "inner jaw hits the front wall before full squeeze");
assert(abs(x_cs - sock_x) >= sock_r + knob_d / 2 + 1.5, "clamp knob too close to the socket");
assert(pinch_y + lug_out - nut_r >= 1.2 && sock_top + lug_up - pinch_z - m3_hex[0] / 2 >= 1.2, "pinch nut wall too thin");
assert(lug_in <= pinch_y - nut_r / 2 - 0.5, "raised lug top does not cover the nut top flat");
assert(ball_d + ball_over - sock_open >= 0.25 && ball_d + ball_over - sock_open <= 0.6, "ball snap interference");
assert(flange_screw_r - m3_head[0] / 2 >= (stem_d + 4) / 2 + 0.2 && flange_screw_r + m3_clear / 2 <= flange_d / 2 - 1.5, "flange screw circle");
assert(lobe_r >= m3_head[0] / 2 + 0.6, "lid lobes too small for the M3 heads");
assert(flange_screw_l <= flange_t + floor_t + mount_pad && flange_screw_l - flange_t >= 2.5, "flange screws: tips must stay in the floor with enough thread");

// ---------- helpers ----------
module stroke(a, b, w = arm_w) hull() { translate(a) circle(d = w); translate(b) circle(d = w); }
module path(pts, w) for (i = [0:len(pts) - 2]) stroke(pts[i], pts[i + 1], w);
module at_box() translate(box_c) multmatrix([[box_u[0], box_v[0], 0, 0], [box_u[1], box_v[1], 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]) children();
module rrect(size, r) offset(r = r) offset(delta = -r) square(size, center = true);
// 2D outline extruded with a stepped chamfer on the top edge (and a small one at the bed)
module slab(h, c = chamfer, steps = 3) {
    translate([0, 0, 0.3]) linear_extrude(h - c - 0.3 + eps) children();
    linear_extrude(0.3 + eps) offset(delta = -0.3) children();
    for (k = [1:steps]) translate([0, 0, h - c + (k - 1) * c / steps]) linear_extrude(c / steps + (k < steps ? eps : 0)) offset(delta = -k * c / steps) children();
}
module knurl_cyl(d, h) difference() {
    cylinder(d = d, h = h);
    for (a = [0:30:359]) rotate(a) translate([d / 2 + 0.2, 0, -eps]) cylinder(d = 1.6, h = h + 2 * eps, $fn = 12);
    translate([0, 0, h - 0.6]) difference() { cylinder(d = d + 1, h = 1); cylinder(d1 = d, d2 = d - 1.4, h = 0.7); }
}
// clear cone in front of an LED (from 0.3 mm ahead of the face, out to 150 mm)
module fov_cone(i, l = 150) translate(led_xyz(i) + [0.3, 0, 0]) rotate([0, 90, 0])
    cylinder(r1 = cbore / 2, r2 = cbore / 2 + l * tan(los), h = l);
module hex(af, h) cylinder(d = af / cos(30), h = h, $fn = 6);

// ---------- frame ----------
module boss_2d(i) translate(led_pos[i] - [boss_l / 2, 0]) rrect([boss_l, 2 * boss_hw], 1);
module box_2d() at_box() offset(r = 1.5) offset(delta = -1.5) union() {
    rrect([cav[0] + 2 * box_wall, cav[1] + 2 * box_wall], 2.5);
    for (p = lobes) translate(p) circle(r = lobe_r);
}
module branches_2d() {
    // the arms are the ribs around the wire runs (channels_2d); only the flats behind T and B are added
    stroke(T, T - [flat_l, 0]);
    stroke(B, B - [flat_l, 0]);
}
module plate_2d() union() {
    difference() {
        offset(r = -fillet) offset(delta = fillet) { branches_2d(); channels_2d(arm_w); }
        led_bands_2d();   // nothing of the plate in front of an LED face
    }
    for (i = [0:2]) boss_2d(i);
}
// the channel runs behind the LEDs: down each branch, then across to the box (the plate follows the channel, a rib
// of plate around every run, so the cover is never over thin air and the T / B runs brace the branches to the box)
channel_paths = [   // [cover piece, run]
    [0, [leg_pt(0), box_pt(e_f[0], e_f[1])]],                  // F wires (tunnel through the boss and the box wall)
    [0, [leg_pt(1), q_t, box_pt(e_t[0], e_t[1])]],             // T wires
    [1, [leg_pt(2), q_b, box_pt(e_b[0], e_b[1])]]];            // B wires
module channels_2d(w, j = -1) for (c = channel_paths) if (j < 0 || c[0] == j) path(c[1], w);
module led_bands_2d() for (L = led_pos) translate([L[0], L[1] - cbore / 2 - 0.5]) square([20, cbore + 1]);

// LED slot, open at the top: the LED drops in from outside, the flange sets the face exactly on led_pos
module led_slot(i) translate([led_pos[i][0], led_pos[i][1], 0]) mirror([1, 0, 0]) {
    x1 = led_h - led_flange_t;
    translate([-1, -pocket / 2, led_z - pocket / 2]) cube([x1 + 1 + eps, pocket, boss_top]);
    translate([x1, -cbore / 2, led_z - cbore / 2]) cube([cbore_t, cbore, boss_top]);
    translate([x1 + cbore_t - eps, -leg_w / 2, arm_t - ch_d]) cube([leg_l, leg_w, boss_top + 1]);   // down to the channel floor
    translate([-1, -cbore / 2, led_z + cbore / 2]) cube([cap_l + 1, cbore, boss_top]);        // cap seat, one rectangle
}
// LED cap: a single rectangular plate on the flange top, over the LED, its legs and the resistor joint (prototype 2:
// stepped cap was fiddly; prototype 3: legs left open behind the flange)
module led_cap_shape(i) translate([led_pos[i][0], led_pos[i][1], 0]) mirror([1, 0, 0])
    translate([0, -cbore / 2 + cap_clr, led_z + cbore / 2]) cube([cap_l - cap_clr, cbore - 2 * cap_clr, boss_top - led_z - cbore / 2]);

module box_cuts() at_box() {
    translate([-cav[0] / 2, -cav[1] / 2, floor_t]) cube([cav[0], cav[1], cav[2] + 1]);
    // micro-USB notch through the bottom (+u) end wall, open at the top (the lid closes it), down through the floor if needed
    translate([cav[0] / 2 - eps, pack_v - usb_window[0] / 2, max(-eps, floor_t + mount_pad + usb_zc - usb_window[1] / 2)])
        cube([box_wall + 3, usb_window[0], box_top + 1]);
    // switch lever slot through the top (-u) end wall and its collar (lever along -u, sliding along v)
    translate([-cav[0] / 2 - box_wall - collar_d - 1, sw_v - sw_window[0] / 2, sw_z - sw_window[1] / 2]) cube([box_wall + collar_d + 1 + eps, sw_window[0], sw_window[1]]);
    // lid screws (the flange screw holes are cut in arm(), through the screw pad)
    for (p = lobes) translate([p[0], p[1], floor_t]) cylinder(d = m3_tap, h = cav[2] + 1);
}
module box_solid() slab(box_top, 0.4, 1) box_2d();
// inside the cavity: added after box_cuts (prototype 2: the cavity cut had removed them)
module box_inner() {
    at_box() {
        // switch pocket: a solid block either side of the body, from the body to the long wall (+v) and to the wire
        // lane (-v), on the floor and against the end wall (prototype 2: thin free-standing ribs were fragile)
        y_in = sw_v - sw_body[0] / 2 - sw_fit;   // body faces
        y_out = sw_v + sw_body[0] / 2 + sw_fit;
        for (y = [[lane_v + lane / 2, y_in], [y_out, cav[1] / 2 + eps]]) translate([-cav[0] / 2 - eps, y[0], floor_t - eps])
            cube([sw_depth + sw_fit + eps, y[1] - y[0], sw_body[1] + eps]);
        // screw bosses under the pack (it rests on them), kept out of the wire lane (the holes are cut in arm())
        intersection() {
            for (a = [90, 210, 330]) translate([mount_u, 0, floor_t - eps]) rotate(a) translate([flange_screw_r, 0, 0]) cylinder(d = floor_tap + 2 * walls(3), h = mount_pad + eps);
            translate([pack_u - (pack[0] + pack_clr) / 2, pack_v - (pack[1] + pack_clr) / 2, 0]) cube([pack[0] + pack_clr, pack[1] + pack_clr, 10]);
        }
        // no stops behind the body (prototype 3: they kept the switch from sliding in; the two side blocks hold it)
        if (collar_d > 0) translate([-cav[0] / 2 - box_wall - collar_d, sw_v - sw_window[0] / 2 - 1.2, 0])
            cube([collar_d + box_wall / 2, sw_window[0] + 2.4, sw_z + sw_window[1] / 2 + 1.2]);                   // lever collar
    }
}

module arm_shell() difference() {
    union() {
        difference() { slab(arm_t) plate_2d(); for (i = [0:2]) fov_cone(i); }   // branch roots near F kept out of its cone
        for (i = [0:2]) slab(boss_top, 0.6, 2) boss_2d(i);
        box_solid();
    }
    for (i = [0:2]) led_slot(i);
    // wire channel, open on the outer face (prints without overhang); a short bridged tunnel through the LED bosses
    // and the box end walls; cover recess only on the open runs
    translate([0, 0, arm_t - ch_d]) linear_extrude(ch_d + eps) channels_2d(ch_w);
    translate([0, 0, arm_t - cov_t]) linear_extrude(cov_t + eps) cover_2d();
    // channel open to the top through the back of the LED bosses (prototype 2: the bridge there blocked the wires)
    translate([0, 0, arm_t - eps]) linear_extrude(boss_top) difference() {
        intersection() { channels_2d(ch_w); union() for (i = [0:2]) boss_2d(i); }
        box_2d();
    }
    // F run: a trench through the box wall, open to the top and closed by the lid (prototype 3: the tunnel could not be wired)
    translate([0, 0, arm_t - ch_d]) linear_extrude(box_top + 1) intersection() { path(channel_paths[0][1], ch_w); box_2d(); }
    box_cuts();
}
module arm() difference() {
    union() { arm_shell(); box_inner(); }
    at_box() for (a = [90, 210, 330]) translate([mount_u, 0, 0]) rotate(a) translate([flange_screw_r, 0, -eps]) cylinder(d = floor_tap, h = floor_t + mount_pad + 1);
}

module cover_2d(j = -1) difference() {
    channels_2d(cov_w, j);
    box_2d();
    for (i = [0:2]) boss_2d(i);
}
module cover(j) translate([0, 0, arm_t - cov_t]) linear_extrude(cov_t) cover_2d(j);
module led_cap(i = 0) led_cap_shape(i);
module lid() translate([0, 0, box_top]) difference() {
    union() {
        slab(lid_t, 0.6, 2) box_2d();
        // locating lip inside the walls (not over the notch / lane corners)
        at_box() translate([0, 0, -lid_lip]) linear_extrude(lid_lip + eps) difference() {
            square([cav[0] - 0.3, cav[1] - 0.3], center = true);
            square([cav[0] - 2.7, cav[1] - 2.7], center = true);
        }
    }
    at_box() for (p = lobes) translate([p[0], p[1], -lid_lip - eps]) cylinder(d = m3_clear, h = lid_t + lid_lip + 1);
}

// ---------- clamp ----------
module socket_body() {
    translate([sock_x, 0, z_out - eps]) cylinder(r = sock_r, h = sock_top - z_out + eps);
    // 45 deg cone under the socket rim where it overhangs the clamp body (the fork channel is cut out of it)
    translate([sock_x, 0, z_wb]) cylinder(r1 = sock_r - (z_out - z_wb), r2 = sock_r, h = z_out - z_wb);
    // pinch lug on +y, 45 deg underside (prints without support)
    translate([lug[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(lug[1] - lug[0]) polygon([
        [0, z_out - 0.5], [clamp_len / 2 - 1, z_out - 0.5], [pinch_y + lug_out, z_out + pinch_y + lug_out + 0.5 - clamp_len / 2],
        [pinch_y + lug_out, sock_top + lug_up], [lug_in, sock_top + lug_up], [lug_in, sock_top], [0, sock_top]]);
}
module clamp_outer() difference() {
    union() {
        translate([(cx0 + cx1) / 2, 0, z_wb]) slab(z_out - z_wb, 0.6, 2) rrect([cx1 - cx0, clamp_len], 2);
        socket_body();
    }
    translate([-x_ch, -clamp_len, z_wb - eps]) cube([2 * x_ch, 2 * clamp_len, z_jaw_in - z_wb + eps]);
    translate([x_cs, 0, z_wb - 1]) cylinder(d = m3_clear, h = 20);
    // ball socket, snap opening, entry chamfer
    translate([sock_x, 0, zb]) sphere(d = ball_d + ball_clr, $fn = 64);
    translate([sock_x, 0, sock_top - 0.6]) cylinder(d1 = sock_open - 0.1, d2 = sock_open + 1, h = 0.6 + eps);
    // pinch slot (+y half only), screw, nut trap on the -x face
    translate([sock_x - 0.75, 0, z_out + sock_base]) cube([1.5, pinch_y + lug_out + 1, sock_top]);
    translate([lug[0] - eps, pinch_y, pinch_z]) rotate([0, 90, 0]) cylinder(d = m3_clear, h = lug[1] - lug[0] + 1);
    translate([lug[0] - eps, pinch_y, pinch_z]) rotate([0, 90, 0]) rotate(30) hex(m3_hex[0], m3_hex[1]);
}
module clamp_inner() difference() {
    union() {
        translate([(cx0 + cx1) / 2, 0, zj_bot]) slab(jaw_t, 0.4, 1) rrect([cx1 - cx0, clamp_len], 2);
        translate([x_ridge - 1, -clamp_len / 2 + 1, zj_top - eps]) cube([2, clamp_len - 2, z_wb - zj_top + eps]);   // fulcrum ridge
    }
    // jaw top lowered in front of the fork: the jaw tilts about the ridge without hitting the front wall
    translate([cx0 - 1, -clamp_len, zj_top - relief]) cube([-x_ch - cx0 + 1, 2 * clamp_len, 10]);
    translate([x_cs, 0, zj_bot - 1]) cylinder(d = m3_clear, h = 20);
    translate([x_cs, 0, zj_bot - eps]) hex(m3_hex[0], m3_hex[1]);   // nut trap (underside)
}

// ball + stem + flange, clamp frame orientation (ball centre at the origin, flange on top)
module ball() {
    sphere(d = ball_d + ball_over, $fn = 64);
    cylinder(d = stem_d, h = stem_l + eps);
    h0 = ball_d / 2 * cos(45);                  // 45 deg cone under the ball when printed flange down
    translate([0, 0, h0]) cylinder(r1 = ball_d / 2 * sin(45), r2 = stem_d / 2, h = ball_d / 2 * sin(45) - stem_d / 2);
    translate([0, 0, stem_l - 2]) cylinder(d1 = stem_d, d2 = stem_d + 4, h = 2 + eps);
    translate([0, 0, stem_l]) difference() {
        cylinder(d = flange_d, h = flange_t);
        for (a = [90, 210, 330]) rotate(a) translate([flange_screw_r, 0, -eps]) cylinder(d = m3_clear, h = flange_t + 1);
    }
}
// round-head M3 screw captured in the knob (tight head pocket at the top, glued: a round head alone would spin)
module knob() difference() {
    knurl_cyl(knob_d, knob_h);
    translate([0, 0, -eps]) cylinder(d = m3_clear, h = knob_h + 1);
    translate([0, 0, knob_h - m3_head[1] + eps]) cylinder(d = m3_head[0] + 0.1, h = m3_head[1]);   // tight, plus a drop of glue
}

// ---------- assembly ----------
module arm_assembled() {
    arm();
    color("dimgray") for (j = [0:1]) cover(j);
    color("dimgray") lid();
    for (i = [0:2]) color("dimgray") led_cap(i);
    for (i = [0:2]) color("purple") translate(led_xyz(i)) rotate([0, -90, 0]) {
        translate([-led_body / 2, -led_body / 2, 0]) cube([led_body, led_body, led_h - led_flange_t]);
        translate([-led_flange / 2, -led_flange / 2, led_h - led_flange_t]) cube([led_flange, led_flange, led_flange_t]);
    }
    color("gold", 0.6) at_box() translate([pack_u - pack[0] / 2, pack_v - pack[1] / 2, floor_t + mount_pad]) cube(pack);
}
module assembly() {
    color("red") translate([-fork_w / 2, -12, -zf]) cube([fork_w, 24, fork_t]);
    color("slategray") { clamp_outer(); clamp_inner(); }
    color("dimgray") {
        translate([x_cs, 0, z_out + knob_h]) rotate([180, 0, 0]) knob();
        translate([lug[1] + knob_h, pinch_y, pinch_z]) rotate([0, -90, 0]) knob();
    }
    translate([sock_x, 0, zb]) color("dimgray") ball();
    color("lightgray") translate([sock_x - mount[0], -mount[1], arm_z0]) arm_assembled();
}

// ---------- parts ----------
if (part == "check") {
    for (i = [0:2]) echo("LED", led_names[i], led_pos[i][0], led_pos[i][1]);
    // depth along the emission direction: F the farthest from the camera (TrackClip Pro, LEDs emit to the right on the drawing)
    for (i = [0:2]) echo("DEPTH", led_names[i], led_pos[i] * led_dir);
    for (p = [[0, 1], [0, 2], [1, 2]])
        echo("DIST", str(led_names[p[0]], "-", led_names[p[1]]), round(norm(led_pos[p[1]] - led_pos[p[0]]) * 1000) / 1000);
    cube(1);
}
if (part == "assembly") assembly();
if (part == "arm") arm_assembled();
if (part == "cover") for (j = [0:1]) cover(j);
// check: no channel / cover in the cleared band in front of an LED; tools/check.sh expects this to be empty
if (part == "cover_leak") linear_extrude(1) intersection() { channels_2d(cov_w); led_bands_2d(); }
// check: nothing of the clip inside the clear cone in front of an LED (fov_cone)
if (part == "fov_leak") intersection() {
    union() { arm(); for (j = [0:1]) cover(j); lid(); for (i = [0:2]) led_cap(i); }
    union() for (i = [0:2]) fov_cone(i);
}
// check: the switch pocket ribs survive the cavity cut (tools/check.sh expects this NOT to be empty)
if (part == "rib_probe") intersection() {
    arm();
    at_box() translate([-cav[0] / 2 + 1, sw_v + sw_body[0] / 2 + sw_fit + 0.1, floor_t + 1]) cube([1, sw_rib - 0.2, 1]);
}
// check: the F run is open to the top through the box wall, closed by the lid (prototype 3: the tunnel there could
// not be wired); tools/check.sh expects this to be empty
if (part == "trench_probe") intersection() {
    arm();
    translate([0, 0, arm_t - ch_d + 0.1]) linear_extrude(box_top - arm_t + ch_d - 0.2) intersection() { path(channel_paths[0][1], ch_w - 0.4); box_2d(); }
}
// check: each LED cap reaches back over the legs (prototype 3: legs and resistor joint left open); expects NOT empty
if (part == "cap_probe") for (i = [0:2]) intersection() {
    led_cap(i);
    translate([led_pos[i][0] - led_h - 0.1 - leg_l + 0.5, led_pos[i][1] - 0.5, 0]) cube([1, 1, boss_top + 1]);
}
if (part == "lid") lid();
if (part == "clamp_outer") clamp_outer();
if (part == "clamp_inner") clamp_inner();
if (part == "ball") ball();
if (part == "knob") knob();
if (part == "led_cap") for (i = [0:2]) led_cap(i);

// print orientation: every part flat on z = 0
if (part == "print_arm") arm();                                         // inner face down, LED slots and box open up
if (part == "print_cover_ft") translate([0, 0, cov_t - arm_t]) cover(0);                                 // F + T run
if (part == "print_cover_b") translate([0, 0, cov_t - arm_t]) cover(1);                                 // B run
if (part == "print_lid") translate([0, 0, lid_t + box_top]) rotate([180, 0, 0]) lid();   // outer face down, lip up
if (part == "print_clamp_outer") translate([0, 0, -z_wb]) clamp_outer();  // fork channel on the bed, socket up
if (part == "print_clamp_inner") translate([0, 0, -zj_bot]) clamp_inner();
if (part == "print_ball") translate([0, 0, stem_l + flange_t]) rotate([180, 0, 0]) ball();   // flange down
if (part == "print_knob") knob();
for (i = [0:2]) if (part == str("print_led_cap_", led_names[i])) translate([-led_pos[i][0], -led_pos[i][1], boss_top]) rotate([180, 0, 0]) led_cap(i);
