extends Node3D
## Compartmented, walkable non-combat deck plan for a fictional Flight IIA-inspired simulator.
## Room arrangement is an illustrative game layout, not an authenticated naval general arrangement.

const DECK_Y := 1.25
const WALL_H := 3.8
const PASSAGE_HALF := 1.35
const HULL_HALF := 6.45
const STAIR_X := 4.45
const STAIR_Z := -6.0

var wall_mat: StandardMaterial3D
var floor_mat: StandardMaterial3D
var trim_mat: StandardMaterial3D
var dark_mat: StandardMaterial3D
var glass_mat: StandardMaterial3D
var light_mat: StandardMaterial3D
var ui_font: SystemFont
var active_door: Node3D
var active_door_side := 1

func _ready() -> void:
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo UI", "Meiryo", "Noto Sans CJK JP"])
	wall_mat = _mat(Color(0.57, 0.56, 0.51), 0.08, 0.9)
	floor_mat = _mat(Color(0.19, 0.21, 0.21), 0.12, 0.94)
	trim_mat = _mat(Color(0.31, 0.33, 0.32), 0.48, 0.62)
	dark_mat = _mat(Color(0.035, 0.055, 0.065), 0.35, 0.48)
	glass_mat = _mat(Color(0.018, 0.10, 0.13), 0.6, 0.2)
	light_mat = _mat(Color(0.72, 0.68, 0.53), 0.05, 0.65)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.035, 0.025, 0.008)
	_build_deck()
	_build_lower_deck_and_stairs()
	_build_compartments()
	_build_passage_walls()
	_build_passage_details()
	_build_wall_finish()
	_build_room_wall_finish()
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
	label.font = ui_font
	label.position = pos
	label.font_size = size
	label.modulate = Color(0.76, 0.88, 0.88)
	label.outline_size = 6
	label.outline_modulate = Color(0.015, 0.025, 0.03)
	add_child(label)

func _build_deck() -> void:
	# Split the main deck around a real stairwell opening on the starboard side.
	_box(self, "Main deck forward plating", Vector3(0, DECK_Y - 0.14, -22.1), Vector3(13.0, 0.28, 27.8), floor_mat, true)
	_box(self, "Main deck aft plating", Vector3(0, DECK_Y - 0.14, 18.1), Vector3(13.0, 0.28, 43.8), floor_mat, true)
	_box(self, "Main deck stairwell port plating", Vector3(-1.475, DECK_Y - 0.14, -6.0), Vector3(10.05, 0.28, 4.4), floor_mat, true)
	_box(self, "Main deck stairwell starboard plating", Vector3(5.925, DECK_Y - 0.14, -6.0), Vector3(1.15, 0.28, 4.4), floor_mat, true)
	_box(self, "Passage ceiling", Vector3(0, DECK_Y + WALL_H, 2), Vector3(PASSAGE_HALF * 2.0, 0.18, 76), wall_mat)
	for x in [-HULL_HALF, HULL_HALF]:
		_box(self, "Outer bulkhead", Vector3(x, DECK_Y + WALL_H * 0.5, 2), Vector3(0.22, WALL_H, 76), wall_mat, true)
	# The centreline passage is continuous; each room opens into it through a real gap.

func _build_lower_deck_and_stairs() -> void:
	var lower := Node3D.new()
	lower.name = "LowerDeck"
	add_child(lower)
	_box(lower, "Lower deck plating", Vector3(0, -1.55, 2), Vector3(13.0, 0.22, 76.0), floor_mat, true)
	# Lower service passage and its watertight-style bulkheads.
	_box(lower, "Lower passage port bulkhead", Vector3(-PASSAGE_HALF, -0.48, 2), Vector3(0.18, 1.9, 76.0), wall_mat, true)
	_box(lower, "Lower passage starboard forward bulkhead", Vector3(PASSAGE_HALF, -0.48, -20.35), Vector3(0.18, 1.9, 31.3), wall_mat, true)
	_box(lower, "Lower passage starboard aft bulkhead", Vector3(PASSAGE_HALF, -0.48, 18.55), Vector3(0.18, 1.9, 42.9), wall_mat, true)
	for x in [-HULL_HALF, HULL_HALF]:
		_box(lower, "Lower deck outer bulkhead", Vector3(x, -0.48, 2), Vector3(0.22, 1.9, 76.0), wall_mat, true)
	# A sloped collision ramp under individually modeled stair treads makes the
	# staircase traversable by CharacterBody3D without snagging on every riser.
	var stair := Node3D.new()
	stair.name = "Stairwell"
	stair.position = Vector3(STAIR_X, -0.095, STAIR_Z)
	var angle := atan2(2.69, 4.4)
	stair.rotation.x = angle
	lower.add_child(stair)
	_box(stair, "Stair ramp visual", Vector3.ZERO, Vector3(1.25, 0.16, 5.16), trim_mat)
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "Stair ramp collision"
	var ramp_shape := CollisionShape3D.new()
	var ramp_box := BoxShape3D.new()
	ramp_box.size = Vector3(1.25, 0.16, 5.16)
	ramp_shape.shape = ramp_box
	ramp_body.add_child(ramp_shape)
	stair.add_child(ramp_body)
	for i in range(11):
		var step_z := -8.0 + float(i) * 0.4
		var step_y := 1.16 - float(i) * 0.25
		_box(self, "Stair tread", Vector3(STAIR_X, step_y, step_z), Vector3(1.25, 0.07, 0.38), trim_mat)
	for side in [-1.0, 1.0]:
		var rail := _box(stair, "Stair handrail", Vector3(side * 0.82, 0.72, 0), Vector3(0.07, 0.07, 4.9), trim_mat)
		rail.rotation.x = 0.0
	# Lower-deck equipment, service lockers and low-level lighting.
	for z in [-28.0, -18.0, -2.0, 12.0, 26.0]:
		for side in [-1.0, 1.0]:
			_box(lower, "Lower deck service cabinet", Vector3(side * 4.7, -0.45, z), Vector3(1.0, 1.55, 1.0), dark_mat, true)
			_box(lower, "Lower deck cabinet status", Vector3(side * 4.7, -0.35, z - 0.53), Vector3(0.72, 0.45, 0.035), light_mat)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 0.35, z)
		lamp.light_color = Color(0.55, 0.72, 0.82)
		lamp.light_energy = 0.22
		lamp.omni_range = 4.5
		lower.add_child(lamp)
	_label("LOWER DECK ACCESS", Vector3(3.45, DECK_Y + 2.7, -7.6), 20)


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
		if side == 1:
			openings.append(STAIR_Z)
		openings.sort()
		var cursor := -36.0
		for center in openings:
			var segment_end := center - 0.9
			if segment_end > cursor:
				var length := segment_end - cursor
				_box(self, "Passage bulkhead", Vector3(float(side) * PASSAGE_HALF, DECK_Y + WALL_H * 0.5, cursor + length * 0.5), Vector3(0.18, WALL_H, length), wall_mat, true)
			_box(self, "Door header", Vector3(float(side) * PASSAGE_HALF, DECK_Y + WALL_H - 0.22, center), Vector3(0.24, 0.44, 1.8), trim_mat, true)
			_box(self, "Door threshold", Vector3(float(side) * PASSAGE_HALF, DECK_Y + 0.035, center), Vector3(0.28, 0.07, 1.8), trim_mat)
			_add_auto_door(side, center)
			cursor = center + 0.9
		if cursor < 40.0:
			var length := 40.0 - cursor
			_box(self, "Passage bulkhead", Vector3(float(side) * PASSAGE_HALF, DECK_Y + WALL_H * 0.5, cursor + length * 0.5), Vector3(0.18, WALL_H, length), wall_mat, true)


func _add_auto_door(side: int, z: float) -> void:
	# Heavy painted-steel hinged door, swinging into the adjoining compartment.
	var hinge := Node3D.new()
	hinge.name = "AutomaticCompartmentDoor"
	hinge.add_to_group("compartment_doors")
	hinge.position = Vector3(float(side) * PASSAGE_HALF, DECK_Y + WALL_H * 0.5, z - 0.81)
	add_child(hinge)
	var leaf := AnimatableBody3D.new()
	leaf.name = "DoorLeaf"
	leaf.position = Vector3(0, 0, 0.81)
	leaf.sync_to_physics = true
	hinge.add_child(leaf)
	_box(leaf, "Painted steel door leaf", Vector3.ZERO, Vector3(0.10, 3.18, 1.58), wall_mat)
	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = Vector3(0.11, 3.18, 1.58)
	collision.shape = collision_box
	leaf.add_child(collision)
	for y in [-1.12, 1.12]:
		_box(leaf, "Door stiffening bead", Vector3(-float(side) * 0.058, y, 0), Vector3(0.018, 0.055, 1.34), trim_mat)
	_box(leaf, "Door inspection plate", Vector3(-float(side) * 0.061, 0, 0), Vector3(0.018, 0.72, 0.48), dark_mat)
	for y in [-1.18, 0.0, 1.18]:
		var knuckle := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.055
		cylinder.bottom_radius = 0.055
		cylinder.height = 0.24
		knuckle.mesh = cylinder
		knuckle.position = Vector3(0, y, -0.73)
		knuckle.material_override = trim_mat
		hinge.add_child(knuckle)
	var handle_x := -float(side) * 0.075
	_box(leaf, "Door handle backing", Vector3(handle_x, 0, 0.48), Vector3(0.025, 0.22, 0.22), dark_mat)
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.025
	handle_mesh.bottom_radius = 0.025
	handle_mesh.height = 0.24
	handle.mesh = handle_mesh
	handle.position = Vector3(handle_x - float(side) * 0.035, 0, 0.48)
	handle.rotation.x = PI * 0.5
	handle.material_override = trim_mat
	leaf.add_child(handle)
	for z_offset in [-0.91, 0.91]:
		_box(hinge, "Door frame jamb", Vector3(0, 0, z_offset), Vector3(0.16, 3.55, 0.14), trim_mat)
	_box(hinge, "Door frame header", Vector3(0, 1.78, 0), Vector3(0.18, 0.12, 1.95), trim_mat)
	_box(hinge, "Door sill", Vector3(0, -1.76, 0), Vector3(0.22, 0.08, 1.95), trim_mat)
	var area := Area3D.new()
	area.name = "DoorInteractionArea"
	area.collision_layer = 0
	area.collision_mask = 1
	var sensor := CollisionShape3D.new()
	var sensor_shape := BoxShape3D.new()
	sensor_shape.size = Vector3(3.0, 3.4, 3.2)
	sensor.shape = sensor_shape
	area.add_child(sensor)
	hinge.add_child(area)
	area.body_entered.connect(_on_door_area_entered.bind(hinge, side))
	area.body_exited.connect(_on_door_area_exited.bind(hinge, side))

func _on_door_area_entered(body: Node3D, door: Node3D, side: int) -> void:
	if body.name == "Player":
		active_door = door
		active_door_side = side

func _on_door_area_exited(body: Node3D, door: Node3D, _side: int) -> void:
	if body.name == "Player" and active_door == door:
		active_door = null

func _process(_delta: float) -> void:
	if active_door != null and Input.is_action_just_pressed("fleet_interact"):
		var target_angle := 0.0 if absf(active_door.rotation.y) > 0.1 else float(active_door_side) * PI * 0.5
		var tween := active_door.create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(active_door, "rotation:y", target_angle, 0.65)

func _build_passage_details() -> void:
	for z in range(-34, 40, 2):
		_box(self, "Deck seam", Vector3(0, DECK_Y + 0.006, float(z)), Vector3(2.45, 0.012, 0.025), dark_mat)
	for z in range(-32, 39, 6):
		_box(self, "Ceiling light housing", Vector3(0, DECK_Y + WALL_H - 0.12, float(z)), Vector3(1.1, 0.12, 0.32), dark_mat)
		var light := OmniLight3D.new()
		light.position = Vector3(0, DECK_Y + WALL_H - 0.35, float(z))
		light.light_color = Color(0.86, 0.82, 0.72)
		light.light_energy = 0.85
		light.omni_range = 8.0
		light.shadow_enabled = true
		add_child(light)
	for side in [-1.0, 1.0]:
		_box(self, "Emergency guidance strip", Vector3(side * 1.22, DECK_Y + 0.08, 2), Vector3(0.035, 0.04, 72), light_mat)

func _build_wall_finish() -> void:
	var panel := _mat(Color(0.63, 0.62, 0.57), 0.04, 0.93)
	var seam := _mat(Color(0.25, 0.27, 0.26), 0.18, 0.8)
	var kick := _mat(Color(0.28, 0.30, 0.29), 0.42, 0.72)
	var pipe_mat := _mat(Color(0.38, 0.40, 0.37), 0.62, 0.48)
	for side in [-1.0, 1.0]:
		var wall_x: float = side * 1.245
		for z in range(-34, 39, 3):
			var near_door := false
			for door_z in [-27.0, -15.0, -3.0, 9.0, 21.0, 33.0, STAIR_Z]:
				if absf(float(z) - door_z) < 2.5:
					near_door = true
			if near_door:
				continue
			_box(self, "Bulkhead removable wall panel", Vector3(wall_x, 3.05, float(z)), Vector3(0.025, 2.85, 2.82), panel)
			_box(self, "Bulkhead panel joint", Vector3(wall_x - side * 0.018, 3.05, float(z) + 1.43), Vector3(0.018, 2.9, 0.025), seam)
		for y in [1.72, 4.35]:
			_box(self, "Bulkhead panel seam", Vector3(wall_x - side * 0.02, y, 2), Vector3(0.02, 0.025, 72), seam)
		_box(self, "Bulkhead kick plate", Vector3(wall_x - side * 0.03, 1.78, 2), Vector3(0.055, 0.62, 72), kick)
		_box(self, "Overhead cable trunk", Vector3(side * 1.12, 4.82, 2), Vector3(0.22, 0.18, 72), pipe_mat)
		for z in range(-32, 39, 8):
			_box(self, "Bulkhead stiffener", Vector3(wall_x - side * 0.035, 3.05, float(z)), Vector3(0.07, 3.1, 0.12), seam)
		for z in [-25.0, -13.0, 1.0, 17.0, 31.0]:
			_box(self, "Electrical access cover", Vector3(wall_x - side * 0.045, 3.25, z), Vector3(0.035, 0.62, 0.82), kick)
			_box(self, "Access cover latch", Vector3(wall_x - side * 0.07, 3.25, z + 0.31), Vector3(0.025, 0.12, 0.08), trim_mat)
		for z in [-19.0, 9.0, 27.0]:
			_box(self, "Ventilation grille casing", Vector3(wall_x - side * 0.045, 4.25, z), Vector3(0.04, 0.34, 1.1), seam)
			for row in range(5):
				_box(self, "Vent grille slat", Vector3(wall_x - side * 0.075, 4.12 + float(row) * 0.065, z), Vector3(0.025, 0.025, 0.96), trim_mat)
	for x in [-0.95, -0.48, 0.48, 0.95]:
		var pipe := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.045
		cylinder.bottom_radius = 0.045
		cylinder.height = 72.0
		pipe.mesh = cylinder
		pipe.position = Vector3(x, 4.92, 2)
		pipe.rotation.x = PI * 0.5
		pipe.material_override = pipe_mat
		add_child(pipe)


func _build_room_wall_finish() -> void:
	var panel_mat := _mat(Color(0.48, 0.49, 0.46), 0.10, 0.88)
	var inset_mat := _mat(Color(0.31, 0.33, 0.32), 0.24, 0.76)
	var seal_mat := _mat(Color(0.16, 0.18, 0.17), 0.30, 0.72)
	for side in [-1.0, 1.0]:
		var wall_x := side * 6.31
		for room_z in [-27.0, -15.0, -3.0, 9.0, 21.0, 33.0]:
			for panel_index in range(4):
				var pz := room_z - 3.6 + float(panel_index) * 2.4
				_box(self, "Removable bulkhead liner", Vector3(wall_x, DECK_Y + 1.75, pz), Vector3(0.045, 3.25, 2.15), panel_mat)
				_box(self, "Bulkhead liner seam", Vector3(wall_x - side * 0.028, DECK_Y + 1.75, pz + 1.12), Vector3(0.018, 3.25, 0.035), seal_mat)
			_box(self, "Bulkhead kick plate", Vector3(wall_x - side * 0.035, DECK_Y + 0.25, room_z), Vector3(0.035, 0.48, 9.0), inset_mat)
			_box(self, "Service access hatch", Vector3(wall_x - side * 0.06, DECK_Y + 2.0, room_z - 2.9), Vector3(0.04, 1.05, 0.95), inset_mat)
			for y_offset in [-0.32, 0.32]:
				_box(self, "Access hatch hinge", Vector3(wall_x - side * 0.09, DECK_Y + 2.0 + y_offset, room_z - 3.38), Vector3(0.035, 0.06, 0.12), trim_mat)
			_box(self, "Ventilation grille frame", Vector3(wall_x - side * 0.07, DECK_Y + 2.85, room_z + 2.6), Vector3(0.045, 0.48, 1.55), inset_mat)
			for slat in range(6):
				_box(self, "Ventilation grille slat", Vector3(wall_x - side * 0.105, DECK_Y + 2.64 + float(slat) * 0.08, room_z + 2.6), Vector3(0.025, 0.025, 1.38), trim_mat)
			# Overhead cable trunk and a practical bulkhead light.
			_box(self, "Room cable trunk", Vector3(side * 5.95, DECK_Y + 3.55, room_z), Vector3(0.22, 0.18, 8.8), inset_mat)
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(side * 4.1, DECK_Y + 3.15, room_z)
			lamp.light_color = Color(0.82, 0.79, 0.68)
			lamp.light_energy = 0.48
			lamp.omni_range = 5.5
			add_child(lamp)

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
		_box(self, "Communications rack", Vector3(x, DECK_Y + 1.45, -0.5), Vector3(0.9, 2.8, 1.0), dark_mat, true)
		for row in range(5):
			_box(self, "Rack module", Vector3(x, DECK_Y + 0.55 + float(row) * 0.43, -1.03), Vector3(0.72, 0.28, 0.05), trim_mat)
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
