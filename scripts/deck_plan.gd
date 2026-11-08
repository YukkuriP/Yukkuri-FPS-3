extends Node3D
## Compartmented, walkable non-combat deck plan for a fictional Flight IIA-inspired simulator.
## Room arrangement is an illustrative game layout, not an authenticated naval general arrangement.

const DECK_Y := 1.25
const WALL_H := 3.8
const PASSAGE_HALF := 1.35
const HULL_HALF := 6.45

var wall_mat: StandardMaterial3D
var floor_mat: StandardMaterial3D
var trim_mat: StandardMaterial3D
var dark_mat: StandardMaterial3D
var glass_mat: StandardMaterial3D
var light_mat: StandardMaterial3D

func _ready() -> void:
	wall_mat = _mat(Color(0.48, 0.53, 0.54), 0.18, 0.82)
	floor_mat = _mat(Color(0.16, 0.20, 0.21), 0.32, 0.88)
	trim_mat = _mat(Color(0.34, 0.40, 0.42), 0.65, 0.38)
	dark_mat = _mat(Color(0.035, 0.055, 0.065), 0.35, 0.48)
	glass_mat = _mat(Color(0.018, 0.10, 0.13), 0.6, 0.2)
	light_mat = _mat(Color(0.18, 0.72, 0.76), 0.15, 0.3)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.025, 0.22, 0.25)
	_build_deck()
	_build_compartments()
	_build_passage_walls()
	_build_passage_details()
	_build_furniture()
	_build_helm_station()

func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	return m

func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var obj := MeshInstance3D.new()
	obj.name = label
	obj.mesh = mesh
	obj.position = pos
	obj.material_override = material
	parent.add_child(obj)
	if solid:
		var body := StaticBody3D.new()
		body.name = label + "_Collision"
		body.position = pos
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		parent.add_child(body)
	return obj

func _label(value: String, pos: Vector3, size: int = 28) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.font_size = size
	label.modulate = Color(0.76, 0.88, 0.88)
	label.outline_size = 6
	label.outline_modulate = Color(0.015, 0.025, 0.03)
	add_child(label)

func _build_deck() -> void:
	_box(self, "Continuous deck plating", Vector3(0, DECK_Y - 0.14, 2), Vector3(13.0, 0.28, 76), floor_mat, true)
	_box(self, "Passage ceiling", Vector3(0, DECK_Y + WALL_H, 2), Vector3(PASSAGE_HALF * 2.0, 0.18, 76), wall_mat)
	for x in [-HULL_HALF, HULL_HALF]:
		_box(self, "Outer bulkhead", Vector3(x, DECK_Y + WALL_H * 0.5, 2), Vector3(0.22, WALL_H, 76), wall_mat, true)
	# The centreline passage is continuous; each room opens into it through a real gap.

func _room_wall_x(x: float, z_center: float, door_z: float) -> void:
	var half_len := 4.8
	var gap_half := 0.9
	var left_len := door_z - gap_half - (z_center - half_len)
	var right_len := (z_center + half_len) - (door_z + gap_half)
	if left_len > 0.1:
		var left_center := z_center - half_len + left_len * 0.5
		_box(self, "Compartment partition", Vector3(x, DECK_Y + WALL_H * 0.5, left_center), Vector3(0.18, WALL_H, left_len), wall_mat, true)
	if right_len > 0.1:
		var right_center := door_z + gap_half + right_len * 0.5
		_box(self, "Compartment partition", Vector3(x, DECK_Y + WALL_H * 0.5, right_center), Vector3(0.18, WALL_H, right_len), wall_mat, true)
	_box(self, "Door header", Vector3(x, DECK_Y + WALL_H - 0.22, door_z), Vector3(0.24, 0.44, 1.8), trim_mat, true)
	_box(self, "Door threshold", Vector3(x, DECK_Y + 0.035, door_z), Vector3(0.28, 0.07, 1.8), trim_mat)

func _room_end_wall(z: float, side: int) -> void:
	var x_center := float(side) * (PASSAGE_HALF + (HULL_HALF - PASSAGE_HALF) * 0.5)
	var width := HULL_HALF - PASSAGE_HALF
	_box(self, "Transverse bulkhead", Vector3(x_center, DECK_Y + WALL_H * 0.5, z), Vector3(width, WALL_H, 0.18), wall_mat, true)

func _build_compartments() -> void:
	var room_data := [
		{"name":"BRIDGE", "z":-27.0, "side":1},
		{"name":"CIC", "z":-15.0, "side":-1},
		{"name":"COMMUNICATIONS", "z":-3.0, "side":1},
		{"name":"MESS", "z":9.0, "side":-1},
		{"name":"ENGINEERING", "z":21.0, "side":1},
		{"name":"BERTHING", "z":33.0, "side":-1}
	]
	for item in room_data:
		var z: float = item.z
		var side: int = item.side
		var cx := float(side) * (PASSAGE_HALF + (HULL_HALF - PASSAGE_HALF) * 0.5)
		var width := HULL_HALF - PASSAGE_HALF
		_box(self, String(item.name) + " ceiling", Vector3(cx, DECK_Y + WALL_H, z), Vector3(width, 0.18, 9.6), wall_mat)
		_room_end_wall(z - 4.8, side)
		_room_end_wall(z + 4.8, side)
		_label(String(item.name), Vector3(cx - 1.8, DECK_Y + WALL_H - 0.55, z - 4.45), 24)
		_box(self, "Compartment sign", Vector3(float(side) * (PASSAGE_HALF + 0.15), DECK_Y + 2.95, z - 4.2), Vector3(0.06, 0.42, 1.8), dark_mat)
		_box(self, "Sign indicator", Vector3(float(side) * (PASSAGE_HALF + 0.11), DECK_Y + 2.95, z - 4.2), Vector3(0.035, 0.07, 0.8), light_mat)


func _build_passage_walls() -> void:
	var room_data := [
		{"z":-27.0, "side":1},
		{"z":-15.0, "side":-1},
		{"z":-3.0, "side":1},
		{"z":9.0, "side":-1},
		{"z":21.0, "side":1},
		{"z":33.0, "side":-1}
	]
	for side in [-1, 1]:
		var openings: Array[float] = []
		for room in room_data:
			if int(room.side) == side:
				openings.append(float(room.z))
		openings.sort()
		var cursor := -36.0
		for center in openings:
			var segment_end := center - 0.9
			if segment_end > cursor:
				var length := segment_end - cursor
				_box(self, "Passage bulkhead", Vector3(float(side) * PASSAGE_HALF, DECK_Y + WALL_H * 0.5, cursor + length * 0.5), Vector3(0.18, WALL_H, length), wall_mat, true)
			_box(self, "Door header", Vector3(float(side) * PASSAGE_HALF, DECK_Y + WALL_H - 0.22, center), Vector3(0.24, 0.44, 1.8), trim_mat, true)
			_box(self, "Door threshold", Vector3(float(side) * PASSAGE_HALF, DECK_Y + 0.035, center), Vector3(0.28, 0.07, 1.8), trim_mat)
			cursor = center + 0.9
		if cursor < 40.0:
			var length := 40.0 - cursor
			_box(self, "Passage bulkhead", Vector3(float(side) * PASSAGE_HALF, DECK_Y + WALL_H * 0.5, cursor + length * 0.5), Vector3(0.18, WALL_H, length), wall_mat, true)

func _build_passage_details() -> void:
	for z in range(-34, 40, 2):
		_box(self, "Deck seam", Vector3(0, DECK_Y + 0.006, float(z)), Vector3(2.45, 0.012, 0.025), dark_mat)
	for z in range(-32, 39, 6):
		_box(self, "Ceiling light housing", Vector3(0, DECK_Y + WALL_H - 0.12, float(z)), Vector3(1.1, 0.12, 0.32), dark_mat)
		var light := OmniLight3D.new()
		light.position = Vector3(0, DECK_Y + WALL_H - 0.35, float(z))
		light.light_color = Color(0.68, 0.82, 0.9)
		light.light_energy = 0.35
		light.omni_range = 5.5
		add_child(light)
	for side in [-1.0, 1.0]:
		_box(self, "Emergency guidance strip", Vector3(side * 1.22, DECK_Y + 0.08, 2), Vector3(0.035, 0.04, 72), light_mat)

func _build_furniture() -> void:
	# Furnishings are kept clear of the doorway and passage collision volumes.
	# Bridge: forward-facing windows and a compact helm station.
	for i in range(7):
		var x := -4.7 + float(i) * 1.45
		_box(self, "Bridge window", Vector3(x, DECK_Y + 2.8, -31.45), Vector3(1.25, 1.15, 0.07), glass_mat)
		_box(self, "Window mullion", Vector3(x + 0.30, DECK_Y + 2.8, -31.5), Vector3(0.06, 1.28, 0.1), trim_mat)
	# Crew operations / briefing room: generic training display wall, no weapon-control detail.
	_box(self, "Briefing display wall", Vector3(-4.1, DECK_Y + 2.4, -19.1), Vector3(3.7, 1.65, 0.16), dark_mat)
	for i in range(4):
		_box(self, "Briefing display", Vector3(-5.25 + float(i) * 0.78, DECK_Y + 2.45, -19.0), Vector3(0.68, 1.15, 0.035), glass_mat)
	# Communications racks
	for x in [3.0, 4.6, 5.9]:
		_box(self, "Communications rack", Vector3(x, DECK_Y + 1.45, -4.2), Vector3(0.9, 2.8, 1.0), dark_mat, true)
		for row in range(5):
			_box(self, "Rack module", Vector3(x, DECK_Y + 0.55 + float(row) * 0.43, -4.73), Vector3(0.72, 0.28, 0.05), trim_mat)
	# Mess tables and seating
	for x in [-4.2, -2.4]:
		_box(self, "Mess table", Vector3(x, DECK_Y + 0.95, 9.4), Vector3(1.35, 0.12, 2.4), trim_mat, true)
		for z in [8.5, 10.3]:
			_box(self, "Mess seat", Vector3(x, DECK_Y + 0.48, z), Vector3(0.7, 0.12, 0.7), dark_mat, true)
	_box(self, "Serving counter", Vector3(-4.0, DECK_Y + 1.1, 12.1), Vector3(3.5, 0.95, 0.75), wall_mat, true)
	# Machinery cabinets and pipework
	for x in [3.0, 4.55, 5.9]:
		_box(self, "Machinery cabinet", Vector3(x, DECK_Y + 1.45, 21.0), Vector3(0.9, 2.65, 1.25), trim_mat, true)
	for x in [3.1, 5.8]:
		var pipe := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.12
		cylinder.bottom_radius = 0.12
		cylinder.height = 7.2
		pipe.mesh = cylinder
		pipe.position = Vector3(x, DECK_Y + 2.3, 23.0)
		pipe.material_override = trim_mat
		add_child(pipe)
	# Berthing bunks and lockers
	for z in [30.2, 32.5, 34.8, 37.1]:
		_box(self, "Bunk frame", Vector3(-4.0, DECK_Y + 0.75, z), Vector3(3.4, 0.35, 0.9), trim_mat, true)
		_box(self, "Bunk mattress", Vector3(-4.0, DECK_Y + 0.96, z), Vector3(3.25, 0.12, 0.82), wall_mat, true)
	for z in [30.5, 33.0, 35.5, 38.0]:
		_box(self, "Crew locker", Vector3(-6.0, DECK_Y + 1.25, z), Vector3(0.65, 2.3, 0.75), dark_mat, true)

func _build_helm_station() -> void:
	var wheel := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.43
	torus.outer_radius = 0.5
	wheel.mesh = torus
	wheel.position = Vector3(0.0, DECK_Y + 1.65, -27.8)
	wheel.rotation.x = PI * 0.5
	wheel.material_override = trim_mat
	add_child(wheel)
	var body := StaticBody3D.new()
	body.position = wheel.position
	body.set_meta("control", "helm")
	var hit := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.62
	hit.shape = shape
	body.add_child(hit)
	add_child(body)
	_box(self, "Helm pedestal", Vector3(0.0, DECK_Y + 0.65, -27.8), Vector3(0.9, 1.25, 0.8), dark_mat)
