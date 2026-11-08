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


# Tapered hull: 18 m maximum beam, 155.29 m overall length.
v = [
    (-8.5, -38, -1.4), (8.5, -38, -1.4),
    (9, -29, -1.5), (9, 37, -1.5),
    (-9, 37, -1.5), (-9, -29, -1.5),
    (-7.1, -38, 1), (7.1, -38, 1),
    (8.6, -29, 1), (8.6, 37, 1),
    (-8.6, 37, 1), (-8.6, -29, 1)
]
v = [(x, y * LONG_SCALE, z) for x, y, z in v]
f = [
    (0, 1, 7, 6), (1, 2, 8, 7), (2, 3, 9, 8),
    (3, 4, 10, 9), (4, 5, 11, 10), (5, 0, 6, 11),
    (6, 7, 8, 9, 10, 11), (0, 5, 4, 3, 2, 1)
]
me = bpy.data.meshes.new("HullMesh")
me.from_pydata(v, [], f)
me.materials.append(hull)
ob = bpy.data.objects.new("Continuous tapered hull", me)
bpy.context.collection.objects.link(ob)

cube("Flight deck", (0, 0, 1.05), (17.4, 75, .25), deck)
cube("Forecastle", (0, -25, 1.25), (15, 24, .3), deck)
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

for x in [-8.25, 8.25]:
    for y in range(-34, 37, 3):
        cube("Rail stanchion", (x, y, 2), (.12, .12, 1.65), metal)
    cube("Continuous handrail", (x, 1, 2.85), (.12, 72, .12), metal)

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
