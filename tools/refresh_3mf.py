"""Refresh the meshes of an Orca / Bambu Studio 3MF project from stl/, keeping plates, placement and settings.

Every object whose mesh file is named `3D/Objects/<name>.stl_<n>.model` gets the mesh of `stl/<name>.stl`. The mesh
is stored centred on its bounding box (as the slicer does); the item keeps its x/y placement and rotation, its z is
reset so the part sits on the bed. The previous project is kept as `<project>.bak`.

usage: python -I tools/refresh_3mf.py project.3mf [stl_dir]
"""
import os
import re
import shutil
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mass import triangles  # noqa: E402


def mesh_xml(head, tris):
    """Return the object model file with the mesh replaced, plus the mesh centre and height."""
    pts = [p for t in tris for p in t]
    lo = [min(p[k] for p in pts) for k in range(3)]
    hi = [max(p[k] for p in pts) for k in range(3)]
    c = [(lo[k] + hi[k]) / 2 for k in range(3)]
    idx, verts, faces = {}, [], []
    for t in tris:
        f = []
        for p in t:
            key = tuple(round(p[k] - c[k], 5) for k in range(3))
            if key not in idx:
                idx[key] = len(verts)
                verts.append(key)
            f.append(idx[key])
        if len(set(f)) == 3:
            faces.append(f)
    v = "\n".join(f'     <vertex x="{a:g}" y="{b:g}" z="{z:g}"/>' for a, b, z in verts)
    tr = "\n".join(f'     <triangle v1="{a}" v2="{b}" v3="{d}"/>' for a, b, d in faces)
    mesh = f"<mesh>\n    <vertices>\n{v}\n    </vertices>\n    <triangles>\n{tr}\n    </triangles>\n   </mesh>"
    out = re.sub(r"<mesh>.*</mesh>", lambda _: mesh, head, flags=re.S)
    return out, c, hi[2] - lo[2]


def main(project, stl_dir="stl"):
    with zipfile.ZipFile(project) as z:
        files = {n: z.read(n) for n in z.namelist()}
    model = files["3D/3dmodel.model"].decode()
    cfg = files["Metadata/model_settings.config"].decode()
    for path in sorted(files):
        m = re.match(r"3D/Objects/(.+\.stl)_\d+\.model$", path)
        if not m:
            continue
        stl = os.path.join(stl_dir, m.group(1))
        if not os.path.exists(stl):
            print(f"skip {m.group(1)} (no {stl})")
            continue
        # every object using this mesh file (an Orca copy shares the mesh of its original)
        outers = re.findall(rf'<object id="(\d+)"[^>]*>\s*<components>\s*<component p:path="/{re.escape(path)}"', model)
        if not outers:
            print(f"skip {path} (no object uses it: empty file left by the slicer)")
            continue
        xml, c, h = mesh_xml(files[path].decode(), triangles(stl))
        files[path] = xml.encode()
        for outer in outers:
            model = re.sub(rf'(<item objectid="{outer}"[^>]*transform="(?:\S+ ){{11}})\S+"', rf'\g<1>{h / 2:g}"', model)
            b = re.search(rf'  <object id="{outer}">.*?</object>\n', cfg, re.S)
            block = b.group(0)
            for k, val in zip("xyz", c):
                block = re.sub(rf'(source_offset_{k}" value=")[^"]*', rf"\g<1>{val}", block)
            cfg = cfg[:b.start()] + block + cfg[b.end():]
        print(f"ok   {m.group(1)} ({len(outers)} object{'s' if len(outers) > 1 else ''})")
    files["3D/3dmodel.model"] = model.encode()
    files["Metadata/model_settings.config"] = cfg.encode()
    for n in [n for n in files if re.match(r"Metadata/plate_\d+\.json$", n)]:
        del files[n]   # stale slicer cache, rebuilt on open
    shutil.copy2(project, project + ".bak")
    with zipfile.ZipFile(project, "w", zipfile.ZIP_DEFLATED) as z:
        for n, d in files.items():
            z.writestr(n, d)
    print("written", project)


if __name__ == "__main__":
    main(*sys.argv[1:])
