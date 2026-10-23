"""Print the volume and PETG mass (100 % infill, upper bound) of every STL given.

usage: python -I tools/mass.py stl/*.stl
"""
import struct
import sys

PETG = 1.27e-3  # g / mm3


def triangles(path):
    with open(path, "rb") as f:
        data = f.read()
    tris = []
    if data[:5] == b"solid" and b"facet" in data[:300]:
        verts = [tuple(map(float, l.split()[1:4])) for l in data.decode().splitlines() if l.strip().startswith("vertex")]
        tris = [verts[i:i + 3] for i in range(0, len(verts), 3)]
    else:
        n = struct.unpack("<I", data[80:84])[0]
        for i in range(n):
            v = struct.unpack("<12f", data[84 + 50 * i:84 + 50 * i + 48])
            tris.append((v[3:6], v[6:9], v[9:12]))
    return tris


def volume(path):
    s = 0.0
    for a, b, c in triangles(path):
        s += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) + a[2] * (b[0] * c[1] - b[1] * c[0]))
    return abs(s) / 6


if __name__ == "__main__":
    total = 0
    for p in sys.argv[1:]:
        v = volume(p)
        total += v
        print(f"{p:32s} {v / 1000:7.2f} cm3 {v * PETG:6.1f} g")
    print(f"{'total':32s} {'':11s} {total * PETG:6.1f} g")
