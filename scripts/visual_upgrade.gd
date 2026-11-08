extends Node3D
## Visual-only art pass for Godot 4.7.2. No combat systems.
var steel: StandardMaterial3D
var dark: StandardMaterial3D
var deck: StandardMaterial3D
var trim: StandardMaterial3D
var glass: StandardMaterial3D
var glow: StandardMaterial3D
var rubber: StandardMaterial3D

func _ready() -> void:
	steel=_mat(Color(0.30,0.32,0.31),0.48,0.52)
	dark=_mat(Color(0.045,0.052,0.05),0.34,0.62)
	deck=_mat(Color(0.19,0.21,0.20),0.25,0.88)
	trim=_mat(Color(0.43,0.45,0.42),0.48,0.55)
	glass=_mat(Color(0.11,0.14,0.13,0.28),0.32,0.2)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glow=_mat(Color(0.58,0.54,0.40),0.08,0.62)
	glow.emission_enabled=true; glow.emission=Color(0.025,0.018,0.006)
	rubber=_mat(Color(0.055,0.065,0.07),0.05,0.9)
	# Procedural micro-roughness breaks up the otherwise perfectly uniform paint.
	# These are generated locally by Godot; no paid texture pack is required.
	steel.roughness_texture = _roughness_texture(1701, 0.045)
	deck.roughness_texture = _roughness_texture(1702, 0.075)
	trim.roughness_texture = _roughness_texture(1703, 0.055)
	_replace_blocky_hull()
	_exterior_detail()
	_superstructure_finish()
	_interior_superstructure_finish()
	_bridge_furnishings()
	_hangar_interior_finish()

func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color; m.metallic=metal; m.roughness=rough
	return m

func _roughness_texture(seed_value: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.normalize = true
	texture.noise = noise
	return texture

func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material, bevel:=0.025) -> MeshInstance3D:
	var mesh:=BoxMesh.new(); mesh.size=size
	var obj:=MeshInstance3D.new(); obj.name=label; obj.mesh=mesh; obj.position=pos; obj.material_override=mat
	parent.add_child(obj)
	return obj

func _cylinder(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, mat: Material, sides:=16) -> MeshInstance3D:
	var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=sides
	var obj:=MeshInstance3D.new(); obj.name=label; obj.mesh=mesh; obj.position=pos; obj.material_override=mat; parent.add_child(obj)
	return obj

func _sphere(parent: Node3D, label: String, pos: Vector3, scale: Vector3, mat: Material) -> void:
	var mesh:=SphereMesh.new(); mesh.radius=0.5; mesh.height=1.0; mesh.radial_segments=20; mesh.rings=12
	var obj:=MeshInstance3D.new(); obj.name=label; obj.mesh=mesh; obj.position=pos; obj.scale=scale; obj.material_override=mat; parent.add_child(obj)

func _frustum_box(parent: Node3D, label: String, center: Vector3, bottom: Vector2, top: Vector2, height: float, mat: Material) -> MeshInstance3D:
	var points := PackedVector3Array([
		Vector3(-bottom.x * 0.5, 0.0, -bottom.y * 0.5),
		Vector3(bottom.x * 0.5, 0.0, -bottom.y * 0.5),
		Vector3(bottom.x * 0.5, 0.0, bottom.y * 0.5),
		Vector3(-bottom.x * 0.5, 0.0, bottom.y * 0.5),
		Vector3(-top.x * 0.5, height, -top.y * 0.5),
		Vector3(top.x * 0.5, height, -top.y * 0.5),
		Vector3(top.x * 0.5, height, top.y * 0.5),
		Vector3(-top.x * 0.5, height, top.y * 0.5)
	])
	var faces := PackedInt32Array([
		0, 2, 1, 0, 3, 2,
		4, 5, 6, 4, 6, 7,
		0, 1, 5, 0, 5, 4,
		1, 2, 6, 1, 6, 5,
		2, 3, 7, 2, 7, 6,
		3, 0, 4, 3, 4, 7
	])
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in faces:
		tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := tool.commit()
	var obj := MeshInstance3D.new()
	obj.name = label
	obj.mesh = mesh
	obj.position = center
	obj.material_override = mat
	parent.add_child(obj)
	return obj

func _replace_blocky_hull() -> void:
	# Smooth, high-resolution non-weapon hull shell. The parent is scaled 2x
	# longitudinally, so local length is exactly 155.29 / 2 metres.
	var old_hull:=get_parent().get_node_or_null("Hull")
	if old_hull != null: old_hull.visible=false
	var old_bow:=get_parent().get_node_or_null("Bow")
	if old_bow != null: old_bow.visible=false
	var old_main_deck := get_parent().get_node_or_null("Main deck")
	if old_main_deck != null: old_main_deck.visible = false
	var old_forecastle := get_parent().get_node_or_null("Forecastle")
	if old_forecastle != null: old_forecastle.visible = false
	var old_upper_bridge := get_parent().get_node_or_null("Upper bridge")
	if old_upper_bridge != null: old_upper_bridge.visible = false
	var old_funnel := get_parent().get_node_or_null("Funnel")
	if old_funnel != null: old_funnel.visible = false

	# (longitudinal position, half beam). Bow is negative Z.
	var control: Array[Vector2] = [
		Vector2(-38.8225, 0.10),
		Vector2(-38.45, 0.85),
		Vector2(-37.5, 2.15),
		Vector2(-35.5, 4.15),
		Vector2(-32.0, 5.95),
		Vector2(-27.0, 7.25),
		Vector2(-20.0, 8.25),
		Vector2(-10.0, 8.85),
		Vector2(8.0, 9.0),
		Vector2(22.0, 8.95),
		Vector2(31.0, 8.65),
		Vector2(36.0, 8.15),
		Vector2(38.2, 7.15),
		Vector2(38.8225, 0.10)
	]
	var stations: Array[Vector2] = []
	const SUBDIVISIONS := 6
	for i in range(control.size() - 1):
		var p0: Vector2 = control[maxi(0, i - 1)]
		var p1: Vector2 = control[i]
		var p2: Vector2 = control[i + 1]
		var p3: Vector2 = control[mini(control.size() - 1, i + 2)]
		for step in range(SUBDIVISIONS):
			var t := float(step) / float(SUBDIVISIONS)
			var t2 := t * t
			var t3 := t2 * t
			var z := p1.x + (p2.x - p1.x) * t
			var w := 0.5 * ((2.0 * p1.y) + (-p0.y + p2.y) * t
				+ (2.0*p0.y - 5.0*p1.y + 4.0*p2.y - p3.y) * t2
				+ (-p0.y + 3.0*p1.y - 3.0*p2.y + p3.y) * t3)
			stations.append(Vector2(z, clampf(w, 0.10, 9.0)))
	stations.append(control[control.size() - 1])

	# Transverse profile: deck edge, shoulder, bilge and keel.
	var profile: Array[Vector2] = [
		Vector2(1.0, 0.86),
		Vector2(0.96, 0.10),
		Vector2(0.72, -0.82),
		Vector2(0.0, -1.52),
		Vector2(-0.72, -0.82),
		Vector2(-0.96, 0.10),
		Vector2(-1.0, 0.86)
	]
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for station in stations:
		for point in profile:
			vertices.append(Vector3(point.x * station.y, point.y, station.x))
	var ring_size := profile.size()
	for ring in range(stations.size() - 1):
		for edge in range(ring_size - 1):
			var a := ring * ring_size + edge
			var b := a + 1
			var c := (ring + 1) * ring_size + edge + 1
			var d := (ring + 1) * ring_size + edge
			indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
	# Close the bow and stern ends.
	var first := PackedInt32Array()
	for i in range(ring_size):
		first.append(i)
	for i in range(1, ring_size - 1):
		indices.append_array(PackedInt32Array([first[0], first[i + 1], first[i]]))
	var last_start := (stations.size() - 1) * ring_size
	for i in range(1, ring_size - 1):
		indices.append_array(PackedInt32Array([last_start, last_start + i, last_start + i + 1]))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		var vertex: Vector3 = vertices[index]
		st.set_uv(Vector2(vertex.x * 0.18, vertex.z * 0.12))
		st.add_vertex(vertex)
	# Weld duplicate triangle vertices before normal generation. Without this,
	# the loft shades faceted even though its station curve is smooth.
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	var hull_mat := _mat(Color(0.18, 0.22, 0.24), 0.62, 0.46)
	hull_mat.roughness_texture = steel.roughness_texture
	hull_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, hull_mat)
	var hull := MeshInstance3D.new()
	hull.name = "HighResolutionLoftedHull"
	hull.mesh = mesh
	hull.position.z = 2.0
	add_child(hull)


func _exterior_detail() -> void:
	# Hull waterline belt and bow/stern detailing
	# Waterline belt follows the lower hull taper instead of using a rectangular slab.
	for z in range(-34, 38, 4):
		var t := clampf((float(z) + 38.0) / 68.0, 0.0, 1.0)
		var half_width := lerpf(4.2, 6.16, t)
		if z > 28:
			half_width = lerpf(6.16, 4.9, clampf((float(z) - 28.0) / 11.5, 0.0, 1.0))
		for side in [-1.0, 1.0]:
			_box(self,"Waterline belt segment",Vector3(side * half_width,-2.34,float(z)),Vector3(0.12,0.12,4.0),dark,0)
	for side in [-1.0,1.0]:
		for z in range(-38,39,2):
			var t := clampf((float(z) + 38.0) / 66.0, 0.0, 1.0)
			var half_width := lerpf(6.0, 8.8, t)
			if z > 28:
				half_width = lerpf(8.8, 7.0, clampf((float(z) - 28.0) / 10.0, 0.0, 1.0))
			_box(self,"Hull rubbing strake segment",Vector3(side * (half_width * 0.99),-0.9,float(z)),Vector3(0.13,0.18,2.1),trim)
			if z % 4 == 0:
				_box(self,"Hull plate seam",Vector3(side * (half_width * 1.002),-0.9,float(z)),Vector3(0.025,2.0,0.045),dark,0)
	# Deck safety lines and painted zones
	for x in [-7.5,7.5]:
		_box(self,"Deck edge safety stripe",Vector3(x,1.125,2),Vector3(0.09,0.025,70),steel)
	for z in range(-33,37,5):
		_box(self,"Deck expansion strip",Vector3(0,1.14,float(z)),Vector3(16.8,0.018,0.035),dark,0)
	# Bow anchor housings and mooring fittings (non-functional visual props)
	for side in [-1.0,1.0]:
		_box(self,"Anchor hawse plate",Vector3(side*5.6,-0.35,-36.0),Vector3(1.0,0.08,1.0),dark)
		_cylinder(self,"Mooring bollard",Vector3(side*6.4,1.45,-31),0.17,0.55,trim)
		_cylinder(self,"Mooring bollard",Vector3(side*6.4,1.45,34),0.17,0.55,trim)
	# Detailed bridge window band and framing
	for i in range(9):
		var x:float=-4.8+float(i)*1.2
		_box(self,"Bridge window",Vector3(x,4.8,-29.63),Vector3(0.92,2.8,0.045),glass,0)
		_box(self,"Bridge window mullion",Vector3(x+0.51,4.8,-29.68),Vector3(0.055,2.95,0.07),trim,0)
	_box(self,"Bridge visor",Vector3(0,6.55,-29.8),Vector3(11.8,0.16,0.55),steel)
	# Antenna/radar silhouettes and sensor domes; purely decorative
	_box(self,"Mast cross beam",Vector3(0,12.2,-21),Vector3(7.0,0.16,0.16),trim)
	_box(self,"Mast diagonal",Vector3(0,10.5,-21),Vector3(0.13,4.4,0.13),trim)
	for x in [-2.7,2.7]:
		_cylinder(self,"Sensor drum",Vector3(x,11.3,-21),0.42,0.7,steel,24)
		_sphere(self,"Sensor dome",Vector3(x,11.72,-21),Vector3(1.0,0.38,1.0),trim)
	_box(self,"Mast platform",Vector3(0,9.3,-21),Vector3(5.5,0.16,3.4),steel)
	# Funnel cap, vents and exhaust grilles
	_box(self,"Funnel cap",Vector3(0,9.55,15),Vector3(4.4,0.22,4.4),dark)
	for x in [-1.2,-0.4,0.4,1.2]:
		_box(self,"Funnel vent",Vector3(x,9.68,15),Vector3(0.12,0.06,2.7),trim,0)
	# Hangar facade panels, doors and lamps
	for x in [-4.5,-3.0,-1.5,0,1.5,3.0,4.5]:
		_box(self,"Hangar door rib",Vector3(x,4.0,34.22),Vector3(0.055,4.0,0.06),trim,0)
	for x in [-4.8,4.8]:
		var lamp:=OmniLight3D.new(); lamp.position=Vector3(x,6.8,34); lamp.light_color=Color(0.45,0.8,1); lamp.light_energy=0.7; lamp.omni_range=5; add_child(lamp)
	# Lifeboat-like covered service craft as non-operational deck dressing
	for side in [-1.0,1.0]:
		var pod:=_box(self,"Covered service pod",Vector3(side*6.0,4.4,9),Vector3(1.7,1.0,5.2),steel)
		pod.material_override=trim
		_box(self,"Pod cradle",Vector3(side*6.0,3.75,9),Vector3(2.0,0.18,5.6),dark)
	# Deck lights and small bollards
	for z in range(-32,35,8):
		for side in [-1.0,1.0]:
			_box(self,"Deck light base",Vector3(side*7.8,1.25,float(z)),Vector3(0.28,0.16,0.28),dark)
			var l:=OmniLight3D.new(); l.position=Vector3(side*7.8,1.55,float(z)); l.light_color=Color(0.65,0.82,1); l.light_energy=0.25; l.omni_range=2.8; add_child(l)

func _superstructure_finish() -> void:
	# Non-combat ship architecture: layered deckhouse, access fittings, rails,
	# ventilation, hatches and practical service details.
	for side in [-1.0, 1.0]:
		_box(self, "Bridge wing deck", Vector3(side * 6.15, 3.05, -22.0), Vector3(1.0, 0.16, 12.5), deck)
		for z in range(-28, -15, 2):
			_cylinder(self, "Bridge wing stanchion", Vector3(side * 6.55, 3.72, float(z)), 0.035, 1.25, trim, 10)
		_box(self, "Bridge wing handrail", Vector3(side * 6.55, 4.34, -21.5), Vector3(0.07, 0.07, 12.0), trim)
		for z in range(-30, 34, 6):
			_box(self, "Hull service access cover", Vector3(side * 8.88, -0.2, float(z)), Vector3(0.035, 0.55, 1.0), steel)
		for z in [8.0, 13.0, 18.0]:
			_box(self, "Aft ventilation recess", Vector3(side * 6.52, 4.0, z), Vector3(0.045, 1.25, 1.75), dark, 0)
			for row in range(7):
				_box(self, "Ventilation louvre", Vector3(side * 6.48, 3.48 + float(row) * 0.17, z), Vector3(0.055, 0.045, 1.55), trim, 0)
	for i in range(9):
		var x := -4.8 + float(i) * 1.2
		_box(self, "Bridge glazing lower gasket", Vector3(x, 3.34, -29.72), Vector3(1.12, 0.045, 0.08), rubber, 0)
		_box(self, "Bridge glazing upper gasket", Vector3(x, 6.26, -29.72), Vector3(1.12, 0.045, 0.08), rubber, 0)
		_box(self, "Bridge window wiper motor", Vector3(x, 3.42, -29.82), Vector3(0.16, 0.10, 0.12), dark, 0)
	for z in [-10.0, 5.0, 20.0, 31.0]:
		_box(self, "Weather deck access door", Vector3(0.0, 3.2, z), Vector3(1.15, 2.15, 0.10), steel)
		_box(self, "Access door inset", Vector3(0.0, 3.2, z - 0.06), Vector3(0.88, 1.82, 0.025), dark, 0)
		_cylinder(self, "Access door handle", Vector3(0.39, 3.2, z - 0.10), 0.045, 0.18, trim, 10)
	for y in [9.2, 10.6, 12.0]:
		_box(self, "Mast cross member", Vector3(0, y, -21), Vector3(6.2 - (y - 9.2) * 0.7, 0.10, 0.12), trim)
	for side in [-1.0, 1.0]:
		var brace := _box(self, "Mast diagonal brace", Vector3(side * 1.2, 10.6, -21), Vector3(0.09, 3.0, 0.09), trim)
		brace.rotation.z = side * 0.22
	for z in [-31.0, -24.0, -12.0, 2.0, 17.0, 30.0, 36.0]:
		for side in [-1.0, 1.0]:
			_cylinder(self, "Deck bollard base", Vector3(side * 7.2, 1.22, z), 0.16, 0.10, dark, 12)
			_cylinder(self, "Deck bollard", Vector3(side * 7.2, 1.42, z), 0.09, 0.38, trim, 12)
			_box(self, "Deck drain cover", Vector3(side * 6.9, 1.13, z + 0.7), Vector3(0.22, 0.025, 0.42), dark, 0)

	# Tapered bridge tier and weathered, layered glazing.
	_frustum_box(self, "Tapered upper bridge", Vector3(0.0, 6.95, -21.0), Vector2(9.0, 10.0), Vector2(7.6, 8.8), 2.15, steel)
	for i in range(5):
		var x := -3.0 + float(i) * 1.5
		_box(self, "Upper bridge forward window", Vector3(x, 8.05, -25.52), Vector3(1.18, 1.05, 0.055), glass, 0)
		_box(self, "Upper bridge window mullion", Vector3(x + 0.62, 8.05, -25.56), Vector3(0.055, 1.15, 0.08), trim, 0)
	_box(self, "Upper bridge brow", Vector3(0.0, 8.72, -25.62), Vector3(8.4, 0.14, 0.5), dark)
	# Twin exhaust trunks with caps, rain lips and service grilles.
	for side in [-1.0, 1.0]:
		_frustum_box(self, "Exhaust trunk", Vector3(side * 2.05, 6.25, 14.0), Vector2(2.35, 3.1), Vector2(1.9, 2.7), 3.7, steel)
		_box(self, "Exhaust rain cap", Vector3(side * 2.05, 10.02, 14.0), Vector3(2.25, 0.18, 2.95), dark)
		for row in range(5):
			_box(self, "Exhaust louvre", Vector3(side * 2.05, 8.0 + float(row) * 0.27, 12.43), Vector3(1.35, 0.07, 0.05), trim, 0)
	# Tall, practical communications mast details and antenna whips.
	for side in [-1.0, 1.0]:
		var whip := _cylinder(self, "Communications whip antenna", Vector3(side * 2.2, 14.2, -21.0), 0.025, 3.0, trim, 8)
		whip.rotation.z = side * 0.08
		_box(self, "Mast equipment platform", Vector3(side * 1.9, 11.0, -21.0), Vector3(1.5, 0.10, 1.5), steel)
	# Hangar door has inset panels, perimeter seals and warning lamps.
	_box(self, "Hangar door perimeter frame", Vector3(0.0, 4.0, 34.18), Vector3(8.9, 4.45, 0.18), trim)
	_box(self, "Hangar door inset panel", Vector3(0.0, 4.0, 34.06), Vector3(8.5, 4.05, 0.06), steel)
	_box(self, "Hangar outer door leaf", Vector3(0.0, 4.0, 34.65), Vector3(8.2, 3.85, 0.14), steel)
	for y in [2.25, 3.1, 4.0, 4.9, 5.75]:
		_box(self, "Hangar door horizontal stiffener", Vector3(0.0, y, 34.57), Vector3(7.9, 0.055, 0.035), trim, 0)
	for x in [-3.0, 0.0, 3.0]:
		_box(self, "Hangar door vertical seam", Vector3(x, 4.0, 34.575), Vector3(0.035, 3.6, 0.035), dark, 0)
	_box(self, "Hangar door inspection hatch", Vector3(3.2, 4.0, 34.56), Vector3(0.75, 1.05, 0.035), dark, 0)
	_box(self, "Hangar door access handle", Vector3(2.85, 4.0, 34.50), Vector3(0.07, 0.28, 0.08), trim, 0)
	# Outer aft-facing closure skin sits proud of the frame so it cannot be hidden
	# by the hangar shell's rear face.
	var hangar_closure_mat := _mat(Color(0.76, 0.77, 0.73), 0.08, 0.92)
	hangar_closure_mat.emission_enabled = true
	hangar_closure_mat.emission = Color(0.28, 0.29, 0.26)
	_box(self, "Aft hangar closure skin", Vector3(0.0, 4.0, 36.0), Vector3(8.25, 3.8, 0.16), hangar_closure_mat)
	var closure_face := MeshInstance3D.new()
	closure_face.name = "Hangar closure face panel"
	var closure_quad := QuadMesh.new()
	closure_quad.size = Vector2(8.15, 3.72)
	closure_face.mesh = closure_quad
	closure_face.position = Vector3(0.0, 4.0, 36.24)
	var closure_face_mat := _mat(Color(0.72, 0.74, 0.71), 0.02, 0.92)
	closure_face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	closure_face_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	closure_face_mat.emission_enabled = true
	closure_face_mat.emission = Color(0.22, 0.23, 0.21)
	closure_face.material_override = closure_face_mat
	add_child(closure_face)
	for side in [-1.0, 1.0]:
		_box(self, "Hangar closure vertical edge frame", Vector3(side * 4.0, 4.0, 36.12), Vector3(0.12, 3.7, 0.08), trim)
	_box(self, "Hangar closure top frame", Vector3(0.0, 5.92, 36.12), Vector3(8.2, 0.12, 0.08), trim)
	_box(self, "Hangar closure bottom frame", Vector3(0.0, 2.08, 36.12), Vector3(8.2, 0.12, 0.08), trim)
	_box(self, "Hangar closure outer top frame", Vector3(0.0, 5.92, 36.36), Vector3(8.2, 0.12, 0.08), trim)
	_box(self, "Hangar closure outer bottom frame", Vector3(0.0, 2.08, 36.36), Vector3(8.2, 0.12, 0.08), trim)
	for y in [2.3, 3.15, 4.0, 4.85, 5.7]:
		_box(self, "Aft hangar closure rib", Vector3(0.0, y, 36.11), Vector3(7.9, 0.075, 0.055), trim, 0)
		_box(self, "Aft hangar outer rib", Vector3(0.0, y, 36.36), Vector3(7.9, 0.07, 0.06), trim, 0)
	for x in [-3.4, -2.3, -1.15, 0.0, 1.15, 2.3, 3.4]:
		_box(self, "Hangar door recessed rib", Vector3(x, 4.0, 34.0), Vector3(0.045, 3.85, 0.035), dark, 0)
	for side in [-1.0, 1.0]:
		_box(self, "Hangar door safety lamp", Vector3(side * 4.65, 6.45, 34.0), Vector3(0.22, 0.16, 0.12), glow, 0)

	# Longitudinal deckhouse plating, welded seams and external service access.
	for side in [-1.0, 1.0]:
		for z in range(-29, -12, 2):
			_box(self, "Forward deckhouse vertical seam", Vector3(side * 6.02, 4.0, float(z)), Vector3(0.035, 5.25, 0.055), dark, 0)
		for z in [-27.0, -21.0, -15.0]:
			_box(self, "Forward deckhouse access panel", Vector3(side * 6.045, 3.9, z), Vector3(0.045, 1.15, 1.3), steel)
			_box(self, "Forward access panel inset", Vector3(side * 6.075, 3.9, z), Vector3(0.02, 0.82, 0.95), dark, 0)
		_box(self, "Forward deckhouse belt seam", Vector3(side * 6.03, 2.35, -21.0), Vector3(0.045, 0.08, 16.0), trim, 0)
		for z in range(5, 23, 2):
			_box(self, "Aft deckhouse vertical seam", Vector3(side * 6.53, 3.6, float(z)), Vector3(0.035, 4.5, 0.055), dark, 0)
		for z in [7.0, 13.0, 19.0]:
			_box(self, "Aft deckhouse service hatch", Vector3(side * 6.56, 3.55, z), Vector3(0.04, 1.0, 1.2), steel)
			_box(self, "Aft service hatch inset", Vector3(side * 6.59, 3.55, z), Vector3(0.02, 0.72, 0.92), dark, 0)
		_box(self, "Aft deckhouse belt seam", Vector3(side * 6.54, 2.15, 14.0), Vector3(0.045, 0.08, 18.0), trim, 0)
	# Covered utility craft with a rounded hull silhouette instead of plain boxes.
	for side in [-1.0, 1.0]:
		var craft := MeshInstance3D.new()
		var craft_mesh := CapsuleMesh.new()
		craft_mesh.radius = 0.38
		craft_mesh.height = 3.8
		craft.mesh = craft_mesh
		craft.position = Vector3(side * 6.0, 4.35, 9.0)
		craft.rotation.x = PI * 0.5
		craft.scale = Vector3(1.0, 1.0, 1.3)
		craft.material_override = steel
		add_child(craft)
		_box(self, "Utility craft cradle rail", Vector3(side * 6.0, 3.78, 9.0), Vector3(2.0, 0.12, 5.8), dark)
	# External access ladders and handrails on service faces.
	for z in [-10.0, 20.0]:
		for rung in range(8):
			_box(self, "External ladder rung", Vector3(6.63, 2.0 + float(rung) * 0.38, z), Vector3(0.10, 0.055, 0.62), trim, 0)
		for side in [-1.0, 1.0]:
			_box(self, "External ladder rail", Vector3(6.63, 3.35, z + side * 0.36), Vector3(0.10, 3.0, 0.07), steel)

	# Faceted, inward-raked deckhouse sides break up the flat box silhouette.
	for side in [-1.0, 1.0]:
		var forward_facet := _box(self, "Forward deckhouse raked side panel", Vector3(side * 6.08, 4.05, -21.0), Vector3(0.16, 5.65, 16.6), steel)
		forward_facet.rotation.z = side * 0.075
		var aft_facet := _box(self, "Aft deckhouse raked side panel", Vector3(side * 6.60, 3.65, 13.0), Vector3(0.16, 4.9, 18.2), steel)
		aft_facet.rotation.z = side * 0.055
		for z in [-27.0, -22.0, -17.0]:
			_box(self, "Forward deckhouse panel reveal", Vector3(side * 6.18, 4.0, z), Vector3(0.035, 4.8, 0.07), dark, 0)
		for z in [7.0, 13.0, 19.0]:
			_box(self, "Aft deckhouse panel reveal", Vector3(side * 6.69, 3.6, z), Vector3(0.035, 4.0, 0.07), dark, 0)
	# Aft upper service gallery with guardrails and deck-level floodlight housings.
	for side in [-1.0, 1.0]:
		for z in [25.0, 29.0, 33.0]:
			_box(self, "Aft gallery support", Vector3(side * 5.7, 5.0, z), Vector3(0.14, 2.4, 0.14), trim)
		_box(self, "Aft gallery handrail", Vector3(side * 5.7, 6.25, 29.0), Vector3(0.08, 0.08, 8.0), trim)
		for z in [24.0, 31.0]:
			_box(self, "Aft floodlight housing", Vector3(side * 5.45, 6.1, z), Vector3(0.35, 0.25, 0.55), dark)

	# Bridge wing side glazing and weather-deck observation windows.
	for side in [-1.0, 1.0]:
		for z in [-27.0, -24.0, -21.0, -18.0, -15.0]:
			_box(self, "Bridge wing side window gasket", Vector3(side * 6.16, 5.55, z), Vector3(0.055, 1.05, 1.25), dark, 0)
			_box(self, "Bridge wing side window glass", Vector3(side * 6.20, 5.55, z), Vector3(0.035, 0.88, 1.08), glass, 0)
		for z in [6.0, 10.0, 14.0, 18.0, 22.0]:
			_box(self, "Aft service room window frame", Vector3(side * 6.65, 4.55, z), Vector3(0.05, 0.62, 0.9), dark, 0)
			_box(self, "Aft service room window glass", Vector3(side * 6.69, 4.55, z), Vector3(0.025, 0.48, 0.72), glass, 0)
		# Hinged weather doors and compact ventilation panels on the side shell.
		for z in [-12.0, 2.0, 24.0]:
			_box(self, "Weather deck side access door", Vector3(side * 6.16, 3.1, z), Vector3(0.06, 1.9, 0.95), steel)
			_box(self, "Weather deck door inset", Vector3(side * 6.20, 3.1, z), Vector3(0.025, 1.55, 0.68), dark, 0)
			_cylinder(self, "Weather deck door handle", Vector3(side * 6.24, 3.1, z - 0.28), 0.045, 0.18, trim, 10)

func _interior_superstructure_finish() -> void:
	var liner := _mat(Color(0.47, 0.48, 0.45), 0.08, 0.92)
	var inset := _mat(Color(0.26, 0.29, 0.28), 0.22, 0.78)
	var seal := _mat(Color(0.12, 0.14, 0.13), 0.18, 0.85)
	# Interior-facing liners on the actual deckhouse shell, not floating outside it.
	for side in [-1.0, 1.0]:
		for z in range(-30, -13, 3):
			_box(self, "Bridge bulkhead liner panel", Vector3(side * 5.77, 4.0, float(z)), Vector3(0.045, 3.45, 2.65), liner)
			_box(self, "Bridge liner joint", Vector3(side * 5.73, 4.0, float(z) + 1.34), Vector3(0.025, 3.45, 0.045), seal, 0)
		for z in range(5, 23, 3):
			_box(self, "Aft bulkhead liner panel", Vector3(side * 6.27, 3.55, float(z)), Vector3(0.045, 3.1, 2.65), liner)
			_box(self, "Aft liner joint", Vector3(side * 6.23, 3.55, float(z) + 1.34), Vector3(0.025, 3.1, 0.045), seal, 0)
		_box(self, "Bridge lower kick strip", Vector3(side * 5.73, 2.35, -21.5), Vector3(0.06, 0.35, 15.0), inset)
		_box(self, "Aft lower kick strip", Vector3(side * 6.23, 2.15, 14.0), Vector3(0.06, 0.35, 17.0), inset)
		for z in [-28.0, -22.0, -16.0, 7.0, 13.0, 19.0]:
			var hatch_z: float = z
			var hatch_y: float = 4.0 if z < 0.0 else 3.55
			var wall_x: float = side * (5.70 if z < 0.0 else 6.20)
			_box(self, "Electrical service cabinet", Vector3(wall_x, hatch_y, hatch_z), Vector3(0.06, 1.1, 0.9), inset)
			_box(self, "Electrical cabinet inset", Vector3(wall_x - side * 0.04, hatch_y, hatch_z), Vector3(0.025, 0.82, 0.65), liner, 0)
			for row in range(4):
				_box(self, "Cabinet ventilation slot", Vector3(wall_x - side * 0.06, hatch_y - 0.25 + float(row) * 0.16, hatch_z), Vector3(0.02, 0.025, 0.52), seal, 0)
	# Warm ceiling fixtures, conduit and cable trays.
	for z in [-29.0, -23.0, -17.0, 7.0, 13.0, 19.0]:
		var y := 5.0 if z < 0.0 else 5.7
		_box(self, "Ceiling light housing interior", Vector3(0.0, y, z), Vector3(1.65, 0.12, 0.42), inset)
		_box(self, "Ceiling diffuser interior", Vector3(0.0, y - 0.07, z), Vector3(1.35, 0.035, 0.26), glow, 0)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0.0, y - 0.18, z)
		lamp.light_color = Color(0.82, 0.78, 0.67)
		lamp.light_energy = 1.0
		lamp.omni_range = 6.5
		add_child(lamp)


func _bridge_furnishings() -> void:
	var chair_mat := _mat(Color(0.12, 0.14, 0.14), 0.28, 0.72)
	var cushion_mat := _mat(Color(0.28, 0.30, 0.28), 0.05, 0.94)
	for x in [-2.8, 2.8]:
		var base := _cylinder(self, "Bridge chair pedestal", Vector3(x, 1.55, -25.2), 0.12, 0.55, steel, 16)
		_cylinder(self, "Bridge chair foot ring", Vector3(x, 1.45, -25.2), 0.34, 0.055, trim, 16)
		_box(self, "Bridge chair seat", Vector3(x, 1.92, -25.2), Vector3(0.72, 0.16, 0.72), cushion_mat)
		_box(self, "Bridge chair back", Vector3(x, 2.35, -25.52), Vector3(0.72, 0.78, 0.16), chair_mat)
		for side in [-1.0, 1.0]:
			_box(self, "Bridge chair arm", Vector3(x + side * 0.36, 2.08, -25.2), Vector3(0.10, 0.12, 0.58), chair_mat)
	# A practical overhead cable ladder and wall-mounted document holders.
	for x in [2.0, 3.8, 5.6]:
		_box(self, "Bridge overhead cable ladder", Vector3(x, 4.95, -22.0), Vector3(0.12, 0.10, 14.0), trim)
	for z in [-25.0, -21.0, -17.0]:
		_box(self, "Bridge document holder", Vector3(5.72, 3.4, z), Vector3(0.10, 0.58, 0.72), chair_mat)


	# Dedicated helm lighting at the working stations.
	for z in [-28.0, -25.0, -22.0]:
		var bridge_lamp := OmniLight3D.new()
		bridge_lamp.position = Vector3(4.0, 4.55, z)
		bridge_lamp.light_color = Color(0.88, 0.84, 0.74)
		bridge_lamp.light_energy = 1.8
		bridge_lamp.omni_range = 9.0
		bridge_lamp.shadow_enabled = true
		add_child(bridge_lamp)

func _hangar_interior_finish() -> void:
	var rack_mat := _mat(Color(0.25, 0.28, 0.28), 0.32, 0.72)
	var safety := _mat(Color(0.55, 0.42, 0.16), 0.08, 0.82)
	# Practical hangar wall liners, overhead beams and equipment storage.
	for side in [-1.0, 1.0]:
		for z in [24.0, 27.0, 30.0, 33.0]:
			_box(self, "Hangar interior wall panel", Vector3(side * 5.78, 4.5, z), Vector3(0.06, 4.4, 2.7), steel)
			_box(self, "Hangar wall panel seam", Vector3(side * 5.74, 4.5, z + 1.38), Vector3(0.025, 4.2, 0.04), dark, 0)
		_box(self, "Hangar equipment rack", Vector3(side * 5.1, 3.4, 26.0), Vector3(0.65, 2.4, 3.8), rack_mat)
		for row in range(4):
			_box(self, "Hangar rack shelf", Vector3(side * 5.1, 2.5 + float(row) * 0.48, 26.0), Vector3(0.82, 0.07, 3.5), trim)
		_box(self, "Hangar safety floor stripe", Vector3(side * 4.4, 1.28, 28.0), Vector3(0.12, 0.025, 10.0), safety, 0)
	for z in [23.0, 27.0, 31.0, 33.0]:
		_box(self, "Hangar overhead beam", Vector3(0.0, 7.55, z), Vector3(11.6, 0.18, 0.22), trim)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0.0, 7.0, z)
		lamp.light_color = Color(0.82, 0.79, 0.7)
		lamp.light_energy = 0.72
		lamp.omni_range = 8.0
		add_child(lamp)
	# Workbench and mobile service trolley as visual dressing.
	_box(self, "Hangar workbench", Vector3(-3.7, 2.0, 29.5), Vector3(1.8, 0.16, 2.2), rack_mat)
	_box(self, "Hangar workbench cabinet", Vector3(-3.7, 1.55, 29.5), Vector3(1.55, 0.8, 1.9), dark)
	_box(self, "Hangar service trolley", Vector3(3.7, 1.7, 29.5), Vector3(1.1, 0.75, 1.5), steel)

func _interior_detail() -> void:
	# Floor panels, ceiling cable trays and door frames make the passage feel built.
	for z in range(-29,42,2):
		_box(self,"Non-slip floor seam",Vector3(0,1.375,float(z)),Vector3(13.25,0.012,0.025),dark,0)
	for x in [-5.9,-3.0,0.0,3.0,5.9]:
		_box(self,"Ceiling cable tray",Vector3(x,5.05,5),Vector3(0.16,0.16,72),steel)
	for z in [-31,-18,-3,15,27,43]:
		_box(self,"Bulkhead reinforcement",Vector3(0,5.0,float(z)),Vector3(13.1,0.12,0.22),trim)
		for side in [-1.0,1.0]:
			_box(self,"Door jamb",Vector3(side*2.6,3.15,float(z)),Vector3(0.16,3.3,0.3),trim)
		_box(self,"Door header",Vector3(0,4.78,float(z)),Vector3(5.3,0.16,0.3),trim)
	# Wall-mounted status lamps and compartment labels
	for z in [-28,-14,2,18,30,40]:
		for side in [-1.0,1.0]:
			_box(self,"Compartment placard",Vector3(side*6.68,4.45,float(z)),Vector3(0.045,0.38,1.2),dark,0)
			_box(self,"Placard indicator",Vector3(side*6.64,4.45,float(z)),Vector3(0.035,0.08,0.65),glow,0)
			var light:=OmniLight3D.new(); light.position=Vector3(side*6.2,4.1,float(z)); light.light_color=Color(0.55,0.8,0.9); light.light_energy=0.22; light.omni_range=3.0; add_child(light)
	# Console pedestals, keyboards and indicator strips
	for pos in [Vector3(-3.8,1.85,-24),Vector3(3.8,1.85,-24),Vector3(-4.2,1.85,-10),Vector3(0,1.85,-10),Vector3(4.2,1.85,-10),Vector3(-5.4,1.85,5),Vector3(0,1.85,20),Vector3(4.2,1.85,20)]:
		_box(self,"Console foot rail",pos+Vector3(0,-0.57,0.42),Vector3(1.95,0.09,0.12),trim)
		_box(self,"Console keyboard deck",pos+Vector3(0,0.56,0.48),Vector3(1.5,0.08,0.42),dark)
		for i in range(8):
			_box(self,"Console key",pos+Vector3(-0.62+float(i)*0.18,0.62,0.48),Vector3(0.11,0.035,0.18),glow,0)
	# Berths, lockers and personal storage
	for side in [-1.0,1.0]:
		for z in [32,36,40]:
			_box(self,"Berth mattress",Vector3(side*4.5,2.22,float(z)),Vector3(2.0,0.18,0.88),_mat(Color(0.32,0.39,0.43),0.0,0.95))
			_box(self,"Berth pillow",Vector3(side*4.5,2.34,float(z)-0.32),Vector3(0.7,0.12,0.45),_mat(Color(0.62,0.65,0.62),0.0,0.9))
		_box(self,"Crew locker bank",Vector3(side*6.0,3.1,35.5),Vector3(0.9,2.8,5.5),steel)
		for z in [33.5,35.5,37.5]:
			_box(self,"Locker door",Vector3(side*5.52,3.1,z),Vector3(0.04,0.82,1.65),dark,0)
			_cylinder(self,"Locker handle",Vector3(side*5.48,3.1,z),0.045,0.12,trim,10)
	# Pipes and ventilation grilles in the machinery space
	for x in [-5.6,-4.8,4.8,5.6]:
		_cylinder(self,"Service pipe",Vector3(x,4.65,20),0.10,9.0,trim,12)
	for z in [17,21,25]:
		_box(self,"Ventilation grille",Vector3(5.9,4.7,float(z)),Vector3(0.08,0.8,1.4),dark,0)
		for i in range(5):
			_box(self,"Vent slat",Vector3(5.84,4.42+float(i)*0.14,float(z)),Vector3(0.06,0.035,1.25),trim,0)
	# Warm practical lighting and emergency strips
	for z in range(-29,43,6):
		_box(self,"Ceiling light housing",Vector3(0,5.12,float(z)),Vector3(1.5,0.08,0.38),dark,0)
		var lamp:=OmniLight3D.new(); lamp.position=Vector3(0,4.8,float(z)); lamp.light_color=Color(0.72,0.84,1); lamp.light_energy=0.32; lamp.omni_range=7.0; add_child(lamp)
	for side in [-1.0,1.0]:
		_box(self,"Emergency floor strip",Vector3(side*6.55,1.43,5),Vector3(0.04,0.035,72),glow,0)
