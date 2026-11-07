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
	steel=_mat(Color(0.31,0.37,0.39),0.72,0.34)
	dark=_mat(Color(0.045,0.075,0.09),0.55,0.42)
	deck=_mat(Color(0.20,0.25,0.27),0.42,0.82)
	trim=_mat(Color(0.55,0.61,0.62),0.7,0.3)
	glass=_mat(Color(0.012,0.065,0.085),0.8,0.16)
	glow=_mat(Color(0.04,0.75,0.78),0.25,0.25)
	glow.emission_enabled=true; glow.emission=Color(0.02,0.35,0.42)
	rubber=_mat(Color(0.055,0.065,0.07),0.05,0.9)
	_exterior_detail()
	_interior_detail()

func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color; m.metallic=metal; m.roughness=rough
	return m

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

func _exterior_detail() -> void:
	# Hull waterline belt and bow/stern detailing
	_box(self,"Waterline stripe",Vector3(0,-2.36,2),Vector3(17.7,0.12,75),dark)
	for side in [-1.0,1.0]:
		_box(self,"Hull rubbing strake",Vector3(side*8.94,-0.9,2),Vector3(0.13,0.18,68),trim)
		for z in range(-30,36,4):
			_box(self,"Hull plate seam",Vector3(side*9.02,-0.9,float(z)),Vector3(0.025,2.0,0.045),dark,0)
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
		_box(self,"Bridge window",Vector3(x,6.5,-29.63),Vector3(0.92,0.82,0.045),glass,0)
		_box(self,"Bridge window mullion",Vector3(x+0.51,6.5,-29.68),Vector3(0.055,0.95,0.07),trim,0)
	_box(self,"Bridge visor",Vector3(0,7.05,-29.8),Vector3(11.8,0.16,0.55),steel)
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
