"""Print the number of separate shells (connected pieces) of each STL given.

usage: python -I tools/shells.py part.stl ...
"""
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0].rsplit("\\", 1)[0])
from mass import triangles  # noqa: E402


def shells(path):
    parent = {}

    def find(a):
        while parent.setdefault(a, a) != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for tri in triangles(path):
        keys = [tuple(round(c, 4) for c in v) for v in tri]
        for k in keys[1:]:
            parent[find(k)] = find(keys[0])
    return len({find(k) for k in list(parent)})


for p in sys.argv[1:]:
    print(p, shells(p))
