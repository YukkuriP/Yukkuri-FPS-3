# Blender 4.x procedural ship exterior generator. Run from Scripting workspace.
import bpy
from mathutils import Vector

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)


def material(n, c, metal=.3, rough=.55):
    m = bpy.data.materials.new(n)
    m.diffuse_color = (*c, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*c, 1)
    p.inputs["Metallic"].default_value = metal
    p.inputs["Roughness"].default_value = rough
    return m


# The hull mesh spans y=-38..+38 source units (76 units overall).
# Scale every longitudinal position and dimension consistently so the
# generated model measures the published 155.29 m overall length.
PUBLISHED_LENGTH_M = 155.29
SOURCE_HALF_LENGTH = 38.0
LONG_SCALE = PUBLISHED_LENGTH_M / (SOURCE_HALF_LENGTH * 2.0)

hull = material("Naval grey hull", (.17, .22, .25), .72, .38)
deck = material("Non skid deck", (.28, .32, .33), .45, .7)
white = material("Superstructure", (.66, .70, .70), .25, .62)
glass = material("Bridge glazing", (.025, .11, .15), .75, .18)
metal = material("Fittings", (.43, .48, .49), .75, .32)


def cube(n, loc, dim, mat):
    loc = (loc[0], loc[1] * LONG_SCALE, loc[2])
    dim = (dim[0], dim[1] * LONG_SCALE, dim[2])
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.name = n
    o.dimensions = dim
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    b = o.modifiers.new("Edge bevel", "BEVEL")
    b.width = .035
    b.segments = 2
    o.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return o


# High-resolution lofted hull. Y=- is the bow; Y=+ is the stern.
# Each station is a closed transverse section: deck edge, shoulder,
# bilge and keel. The bow converges to a fine stem instead of a flat cap.
stations = [
    (-37.999, 0.025, 0.58),
    (-37.70, 0.55, 0.60),
    (-36.8, 1.65, 0.66),
    (-35.0, 3.15, 0.74),
    (-32.0, 5.05, 0.82),
    (-28.0, 6.90, 0.89),
    (-23.0, 8.05, 0.94),
    (-16.0, 8.72, 0.98),
    (-7.0, 9.0, 1.0),
    (8.0, 9.0, 1.0),
    (22.0, 8.92, 1.0),
    (32.0, 8.55, 0.99),
    (38.0, 7.95, 0.96),
]
ring_profile = [
    (-1.0, 0.92), (-0.94, 0.10), (-0.72, -0.78),
    (0.0, -1.48), (0.72, -0.78), (0.94, 0.10), (1.0, 0.92)
]
verts = []
for y, half_beam, flare in stations:
    for x_factor, z in ring_profile:
        verts.append((x_factor * half_beam, y * LONG_SCALE, z))
faces = []
ring_size = len(ring_profile)
for station_index in range(len(stations) - 1):
    a = station_index * ring_size
    b = (station_index + 1) * ring_size
    for j in range(ring_size - 1):
        faces.append((a + j, a + j + 1, b + j + 1, b + j))
# Close the stern; the forward stem is a fine, closed point.
faces.append(tuple(range((len(stations) - 1) * ring_size,
                         len(stations) * ring_size)))
faces.append(tuple(reversed(range(ring_size))))
hull_mesh = bpy.data.meshes.new("ArleighBurke_LoftedHull")
hull_mesh.from_pydata(verts, [], faces)
hull_mesh.materials.append(hull)
hull_mesh.update()
hull_obj = bpy.data.objects.new("Continuous lofted destroyer hull", hull_mesh)
bpy.context.collection.objects.link(hull_obj)
for poly in hull_mesh.polygons:
    poly.use_smooth = True
hull_obj.modifiers.new("Hull weighted normals", "WEIGHTED_NORMAL")
bpy.context.view_layer.update()
actual_length = hull_obj.dimensions.y
actual_beam = hull_obj.dimensions.x
if abs(actual_length - PUBLISHED_LENGTH_M) > 0.01:
    raise RuntimeError(f"Generated hull length mismatch: {actual_length:.3f} m")
if abs(actual_beam - 18.0) > 0.01:
    raise RuntimeError(f"Generated hull beam mismatch: {actual_beam:.3f} m")

# Raised forecastle deck follows the narrowing bow rather than ending as a
# rectangular slab. The top is a fan of quads between matching stations.
deck_verts = []
for y, half_beam, flare in stations:
    deck_verts.extend([
        (-half_beam * 0.985, y * LONG_SCALE, 0.965),
        ( half_beam * 0.985, y * LONG_SCALE, 0.965)
    ])
deck_faces = []
for i in range(len(stations) - 1):
    a = i * 2
    deck_faces.append((a, a + 1, a + 3, a + 2))
deck_mesh = bpy.data.meshes.new("FullLengthDeckMesh")
deck_mesh.from_pydata(deck_verts, [], deck_faces)
deck_mesh.materials.append(deck)
deck_obj = bpy.data.objects.new("Hull-following main deck", deck_mesh)
bpy.context.collection.objects.link(deck_obj)
deck_solid = deck_obj.modifiers.new("Deck plate thickness", "SOLIDIFY")
deck_solid.thickness = 0.08

# Bow stem reinforcement and paired anchor hawse openings.
def cylinder_between(name, p1, p2, radius, mat, vertices=24):
    direction = Vector(p2) - Vector(p1)
    midpoint = (Vector(p1) + Vector(p2)) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=direction.length,
        location=midpoint
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Fitting edge bevel", "BEVEL")
    bevel.width = 0.025
    bevel.segments = 3
    obj.modifiers.new("Fitting weighted normals", "WEIGHTED_NORMAL")
    return obj

for side in (-1, 1):
    # Hawse pipe rims sit just above the forward deck edge.
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.31, minor_radius=0.075,
        major_segments=32, minor_segments=12,
        location=(side * 2.25, -34.2 * LONG_SCALE, 1.02),
        rotation=(1.5708, 0, 0)
    )
    rim = bpy.context.object
    rim.name = "Anchor hawse pipe rim"
    rim.data.materials.append(metal)
    # Recessed dark center makes the opening legible from normal viewing angles.
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=32, radius=0.245, depth=0.035,
        location=(side * 2.25, -34.16 * LONG_SCALE, 1.02),
        rotation=(1.5708, 0, 0)
    )
    opening = bpy.context.object
    opening.name = "Anchor hawse pipe opening"
    opening.data.materials.append(glass)

# Heavy anchor stocks and flukes, mounted symmetrically on the bow cheeks.
for side in (-1, 1):
    cylinder_between(
        "Anchor shank",
        (side * 2.35, -34.0 * LONG_SCALE, 0.82),
        (side * 2.35, -35.8 * LONG_SCALE, -0.15),
        0.12, metal
    )
    cylinder_between(
        "Anchor crossbar",
        (side * 2.35 - 0.55, -35.75 * LONG_SCALE, -0.12),
        (side * 2.35 + 0.55, -35.75 * LONG_SCALE, -0.12),
        0.09, metal
    )
    for dx in (-0.38, 0.38):
        cylinder_between(
            "Anchor fluke",
            (side * 2.35 + dx, -35.75 * LONG_SCALE, -0.12),
            (side * 2.35 + dx * 1.35, -36.35 * LONG_SCALE, -0.52),
            0.10, metal
        )

cube("Forward superstructure", (0, -20, 4), (12, 17, 5.8), white)
cube("Bridge tier", (0, -21, 7.7), (9, 10, 1.9), white)
cube("Bridge glass", (0, -28.55, 6.5), (10.5, .1, 1.2), glass)
cube("Aft superstructure", (0, 13, 3.7), (13, 19, 5), white)
cube("Funnel", (0, 15, 7.1), (4, 4, 3.6), hull)
cube("Hangar", (0, 28, 4.6), (12, 12, 5.8), white)
cube("Hangar door", (0, 34.1, 4), (8.5, .12, 4), glass)

cube("Mast lower", (0, -21, 10.2), (.8, .8, 5), metal)
cube("Mast yard", (0, -21, 12), (6.5, .2, .2), metal)
cube("Mast top", (0, -21, 13.4), (.4, .4, 2.5), metal)
for x in [-2, 2]:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=24, ring_count=12, radius=.8,
        location=(x, -21 * LONG_SCALE, 10.1)
    )
    bpy.context.object.name = "Antenna radome"
    bpy.context.object.data.materials.append(white)

# Side rails follow the narrowing hull sheer instead of remaining parallel.
def beam_at(source_y):
    for idx in range(len(stations) - 1):
        y0, b0, _ = stations[idx]
        y1, b1, _ = stations[idx + 1]
        if y0 <= source_y <= y1:
            t = (source_y - y0) / (y1 - y0)
            return b0 + (b1 - b0) * t
    return stations[0][1] if source_y < stations[0][0] else stations[-1][1]

for side in (-1, 1):
    rail_points = []
    for source_y in range(-35, 37, 2):
        x = side * (beam_at(float(source_y)) * 0.94)
        rail_points.append((x, source_y, 2.0))
        cube("Rail stanchion", (x, source_y, 2), (.12, .12, 1.65), metal)
    for idx in range(len(rail_points) - 1):
        p0 = rail_points[idx]
        p1 = rail_points[idx + 1]
        cylinder_between(
            "Continuous handrail segment",
            (p0[0], p0[1] * LONG_SCALE, 2.85),
            (p1[0], p1[1] * LONG_SCALE, 2.85),
            0.055, metal, vertices=12
        )

for y in range(-34, 37, 4):
    cube("Deck expansion seam", (0, y, 1.22), (16, .035, .012), metal)

for x in [-6.5, 6.5]:
    for y in [-30, -25, -15, 0, 10, 20, 33]:
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=.22, depth=.65,
            location=(x, y * LONG_SCALE, 1.55)
        )
        bpy.context.object.name = "Deck bollard"
        bpy.context.object.data.materials.append(metal)

for x in [-6.08, 6.08]:
    for y in range(-25, -16, 2):
        cube("Bridge side window", (x, y, 6.1), (.035, 1.2, .55), glass)

bpy.ops.object.light_add(type='AREA', location=(18, -28 * LONG_SCALE, 35))
bpy.context.object.data.energy = 4500
bpy.context.object.data.shape = 'DISK'
bpy.context.object.data.size = 18
bpy.ops.object.camera_add(location=(75, -90 * LONG_SCALE, 58))
cam = bpy.context.object
cam.rotation_euler = (Vector((0, 0, 2)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
bpy.context.scene.camera = cam

bpy.ops.wm.save_as_mainfile(filepath="//fleet_destroyer_exterior.blend")
bpy.ops.export_scene.gltf(filepath="//fleet_destroyer_exterior.glb", export_format='GLB')
print(f"Export complete: {PUBLISHED_LENGTH_M:.2f} m overall length")
