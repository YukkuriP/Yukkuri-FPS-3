extends Node3D
## Additional non-combat interior art pass: bridge, CIC, communications,
## machinery spaces and crew facilities. All displays remain in-world.

var panel_mat: StandardMaterial3D
var dark_mat: StandardMaterial3D
var alloy_mat: StandardMaterial3D
var glass_mat: StandardMaterial3D
var cyan_mat: StandardMaterial3D
var amber_mat: StandardMaterial3D
var floor_mat: StandardMaterial3D

func _ready() -> void:
	panel_mat = _mat(Color(0.105, 0.145, 0.16), 0.58, 0.48)
	dark_mat = _mat(Color(0.018, 0.032, 0.041), 0.35, 0.38)
	alloy_mat = _mat(Color(0.42, 0.49, 0.51), 0.78, 0.3)
	glass_mat = _mat(Color(0.012, 0.12, 0.16), 0.62, 0.2)
	cyan_mat = _mat(Color(0.04, 0.65, 0.72), 0.22, 0.3)
	cyan_mat.emission_enabled = true
	cyan_mat.emission = Color(0.015, 0.25, 0.32)
	amber_mat = _mat(Color(0.95, 0.48, 0.12), 0.2, 0.42)
	amber_mat.emission_enabled = true
	amber_mat.emission = Color(0.3, 0.09, 0.015)
	floor_mat = _mat(Color(0.12, 0.17, 0.19), 0.22, 0.92)
	_bridge()
	_cic()
	_communications()
	_engineering()
	_crew_spaces()
	_wayfinding()

func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	return m

func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material, bevel: float = 0.025) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var obj := MeshInstance3D.new()
	obj.name = label
	obj.mesh = mesh
	obj.position = pos
	obj.material_override = mat
	parent.add_child(obj)
	return obj

func _cylinder(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, mat: Material, sides: int = 20) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	var obj := MeshInstance3D.new()
	obj.name = label
	obj.mesh = mesh
	obj.position = pos
	obj.material_override = mat
	parent.add_child(obj)
	return obj

func _label(parent: Node3D, value: String, pos: Vector3, size: float = 0.34, color: Color = Color(0.65, 0.9, 0.92)) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.font_size = int(size * 100.0)
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color(0.015, 0.025, 0.03)
	label.no_depth_test = false
	parent.add_child(label)

func _screen_panel(parent: Node3D, pos: Vector3, width: float, height: float, title: String, accent: Material) -> void:
	_box(parent, "Display housing", pos, Vector3(width + 0.16, height + 0.16, 0.16), dark_mat)
	_box(parent, "Live display glass", pos + Vector3(0, 0, 0.09), Vector3(width, height, 0.025), glass_mat)
	_box(parent, "Display header", pos + Vector3(0, height * 0.36, 0.11), Vector3(width * 0.94, 0.035, 0.018), accent)
	_box(parent, "Display footer", pos + Vector3(0, -height * 0.39, 0.11), Vector3(width * 0.94, 0.025, 0.018), accent)
	_label(parent, title, pos + Vector3(-width * 0.44, height * 0.22, 0.13), 0.19)

func _chair(parent: Node3D, pos: Vector3, mat: Material = panel_mat) -> void:
	_cylinder(parent, "Seat pedestal", pos + Vector3(0, 0.42, 0), 0.09, 0.72, alloy_mat)
	_box(parent, "Padded seat", pos + Vector3(0, 0.82, 0), Vector3(0.72, 0.16, 0.68), mat)
	_box(parent, "Seat back", pos + Vector3(0, 1.2, 0.27), Vector3(0.72, 0.68, 0.14), mat)
	for side in [-1.0, 1.0]:
		_box(parent, "Arm rest", pos + Vector3(side * 0.42, 1.0, 0.04), Vector3(0.12, 0.12, 0.62), alloy_mat)

func _bridge() -> void:
	# Forward bridge glazing, instrument brow and a tactile helm station.
	for i in range(9):
		var x := -4.8 + float(i) * 1.2
		_box(self, "Bridge inner glazing", Vector3(x, 6.45, -29.38), Vector3(1.05, 0.88, 0.07), glass_mat)
		_box(self, "Bridge window frame", Vector3(x + 0.55, 6.45, -29.43), Vector3(0.055, 1.02, 0.09), alloy_mat)
	_box(self, "Bridge instrument brow", Vector3(0, 5.75, -28.55), Vector3(10.8, 0.22, 1.0), panel_mat)
	for x in [-4.2, -2.8, 2.8, 4.2]:
		_box(self, "Bridge switch panel", Vector3(x, 5.9, -28.05), Vector3(1.0, 0.08, 0.48), dark_mat)
		for i in range(4):
			_cylinder(self, "Illuminated bridge control", Vector3(x - 0.32 + float(i) * 0.21, 6.0, -28.05), 0.045, 0.035, cyan_mat, 12)
	# A clearly visible helm wheel prop, not a real-world control procedure.
	var wheel := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.57
	wheel.mesh = torus
	wheel.position = Vector3(0, 2.55, -26.5)
	wheel.rotation.x = PI / 2.0
	wheel.material_override = alloy_mat
	add_child(wheel)
	var helm_body := StaticBody3D.new()
	helm_body.name = "HelmInteraction"
	helm_body.position = Vector3(0, 2.55, -26.5)
	helm_body.set_meta("control", "helm")
	var helm_collision := CollisionShape3D.new()
	var helm_shape := BoxShape3D.new()
	helm_shape.size = Vector3(1.2, 1.2, 0.24)
	helm_collision.shape = helm_shape
	helm_body.add_child(helm_collision)
	add_child(helm_body)
	_cylinder(self, "Helm wheel hub", Vector3(0, 2.55, -26.5), 0.12, 0.2, alloy_mat)
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var spoke := _box(self, "Helm wheel spoke", Vector3(sin(a) * 0.27, 2.55 + cos(a) * 0.27, -26.5), Vector3(0.055, 0.055, 0.12), alloy_mat)
		spoke.rotation.z = -a
	_chair(self, Vector3(-2.8, 1.35, -26.0))
	_chair(self, Vector3(2.8, 1.35, -26.0))
	_screen_panel(self, Vector3(-4.8, 4.75, -28.4), 1.5, 0.85, "NAV / LIVE", cyan_mat)
	_screen_panel(self, Vector3(4.8, 4.75, -28.4), 1.5, 0.85, "SHIP STATUS", amber_mat)

func _cic() -> void:
	# CIC is visually distinct: darker surfaces, large common picture wall,
	# map table and seated workstations.
	_box(self, "CIC rear display wall", Vector3(0, 4.0, -17.65), Vector3(11.8, 2.15, 0.28), dark_mat)
	for i in range(5):
		var x := -4.6 + float(i) * 2.3
		_screen_panel(self, Vector3(x, 4.1, -17.45), 2.05, 1.55, "TRACK / STATUS", cyan_mat if i % 2 == 0 else amber_mat)
	_box(self, "CIC map table base", Vector3(0, 2.0, -10.0), Vector3(3.8, 1.25, 2.3), panel_mat)
	_box(self, "CIC map table surface", Vector3(0, 2.66, -10.0), Vector3(4.0, 0.12, 2.5), dark_mat)
	_box(self, "CIC map glass", Vector3(0, 2.735, -10.0), Vector3(3.7, 0.025, 2.2), glass_mat)
	for i in range(9):
		var x := -1.45 + float(i % 3) * 1.45
		var z := -10.75 + float(i / 3) * 0.75
		_box(self, "Map grid line", Vector3(x, 2.76, z), Vector3(0.018, 0.012, 2.0), cyan_mat)
	for i in range(4):
		_chair(self, Vector3(-4.5 + float(i) * 3.0, 1.35, -8.3))
	_screen_panel(self, Vector3(-5.8, 4.05, -8.8), 1.1, 0.95, "NETWORK", cyan_mat)
	_screen_panel(self, Vector3(5.8, 4.05, -8.8), 1.1, 0.95, "SYSTEMS", amber_mat)

func _communications() -> void:
	# Communications racks are equipment furniture, not menu panels.
	for x in [-5.6, -3.9, 3.9, 5.6]:
		_box(self, "Communications equipment rack", Vector3(x, 3.15, 5.0), Vector3(1.25, 3.25, 0.9), dark_mat)
		_box(self, "Rack face", Vector3(x, 3.15, 4.52), Vector3(1.08, 3.0, 0.045), panel_mat)
		for row in range(5):
			var y := 2.05 + float(row) * 0.48
			_box(self, "Rack module", Vector3(x, y, 4.47), Vector3(0.9, 0.32, 0.06), alloy_mat)
			for col in range(3):
				_cylinder(self, "Rack indicator", Vector3(x - 0.28 + float(col) * 0.28, y, 4.42), 0.035, 0.025, cyan_mat if (row + col) % 2 == 0 else amber_mat, 10)
	_screen_panel(self, Vector3(0, 4.0, 4.4), 2.6, 1.25, "COMMS / LIVE", cyan_mat)
	_box(self, "Comms work desk", Vector3(0, 1.95, 6.8), Vector3(3.4, 0.16, 1.1), panel_mat)
	for x in [-1.15, 1.15]:
		_chair(self, Vector3(x, 1.35, 7.6))

func _engineering() -> void:
	# Machinery-space visual language: pipe runs, service manifolds and gauges.
	for x in [-5.8, -4.9, 4.9, 5.8]:
		_cylinder(self, "Main service pipe", Vector3(x, 3.45, 20.0), 0.16, 8.5, alloy_mat, 16)
		for z in [16.5, 20.0, 23.5]:
			_cylinder(self, "Pipe coupling", Vector3(x, 3.45, z), 0.22, 0.18, panel_mat, 16)
	for x in [-3.5, 0.0, 3.5]:
		_box(self, "Machinery cabinet", Vector3(x, 2.75, 23.0), Vector3(2.0, 2.5, 1.1), panel_mat)
		_box(self, "Machinery cabinet face", Vector3(x, 2.8, 22.42), Vector3(1.72, 2.1, 0.05), dark_mat)
		_screen_panel(self, Vector3(x, 3.25, 22.37), 1.35, 0.72, "PLANT / LIVE", cyan_mat)
		for i in range(4):
			_box(self, "Machinery vent slot", Vector3(x - 0.5 + float(i) * 0.33, 2.25, 22.35), Vector3(0.18, 0.035, 0.035), alloy_mat)
	for x in [-4.8, 4.8]:
		_cylinder(self, "Pressure gauge housing", Vector3(x, 4.2, 17.0), 0.34, 0.16, dark_mat)
		_cylinder(self, "Pressure gauge face", Vector3(x, 4.2, 16.89), 0.27, 0.035, glass_mat)
		_box(self, "Gauge needle", Vector3(x, 4.2, 16.86), Vector3(0.025, 0.32, 0.025), amber_mat)

func _crew_spaces() -> void:
	# Locker fronts, reading lights and a compact mess/dining corner.
	for side in [-1.0, 1.0]:
		for z in [32.0, 35.0, 38.0, 41.0]:
			_box(self, "Locker ventilation", Vector3(side * 6.35, 4.0, z), Vector3(0.04, 0.22, 0.72), alloy_mat)
			_box(self, "Locker name plate", Vector3(side * 6.34, 2.85, z), Vector3(0.045, 0.16, 0.55), cyan_mat)
	for x in [-2.6, 2.6]:
		_box(self, "Mess table", Vector3(x, 2.05, 5.0), Vector3(1.8, 0.14, 2.3), panel_mat)
		for side in [-1.0, 1.0]:
			_chair(self, Vector3(x + side * 0.95, 1.35, 5.0))
	_box(self, "Mess service counter", Vector3(0, 2.3, 10.5), Vector3(4.0, 0.95, 0.8), panel_mat)
	_box(self, "Counter top", Vector3(0, 2.82, 10.5), Vector3(4.15, 0.12, 0.9), alloy_mat)
	_label(self, "CREW MESS", Vector3(-1.0, 3.05, 10.0), 0.28)

func _wayfinding() -> void:
	var signs := [
		["BRIDGE", -24.0],
		["CIC", -10.0],
		["COMMUNICATIONS", 5.0],
		["ENGINEERING", 20.0],
		["CREW QUARTERS", 35.0]
	]
	for item in signs:
		var title: String = item[0]
		var z: float = item[1]
		_box(self, "Compartment sign backing", Vector3(0, 4.45, z - 0.35), Vector3(2.8, 0.55, 0.09), dark_mat)
		_label(self, title, Vector3(-1.1, 4.35, z - 0.40), 0.25)
		_box(self, "Compartment sign lamp", Vector3(1.2, 4.45, z - 0.42), Vector3(0.12, 0.12, 0.035), cyan_mat)
