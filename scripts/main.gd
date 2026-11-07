extends Node3D

const WALK_SPEED := 4.5
const LOOK_SENSITIVITY := 0.0022
const ROLE_NAMES := ["艦長", "操舵員", "CIC士官", "機関員", "一般乗組員"]
const ROLE_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]

var player: CharacterBody3D
var camera: Camera3D
var pitch := 0.0
var role_index := 4
var status_label: Label
var hint_label: Label

func _ready() -> void:
	_setup_input()
	_build_blockout()
	_create_player()
	_create_ui()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _setup_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("interact", KEY_E)
	_add_key_action("release_mouse", KEY_ESCAPE)
	for i in range(ROLE_KEYS.size()):
		_add_key_action("role_" + str(i + 1), ROLE_KEYS[i])

func _add_key_action(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _build_blockout() -> void:
	_add_box("Deck", Vector3(0, -0.15, 0), Vector3(12, 0.3, 34), Color(0.20, 0.24, 0.27))
	_add_box("Ceiling", Vector3(0, 3.4, 0), Vector3(12, 0.25, 34), Color(0.12, 0.16, 0.19))
	_add_box("PortWall", Vector3(-6, 1.6, 0), Vector3(0.25, 3.2, 34), Color(0.25, 0.29, 0.31))
	_add_box("StarboardWall", Vector3(6, 1.6, 0), Vector3(0.25, 3.2, 34), Color(0.25, 0.29, 0.31))
	_add_box("ForwardWall", Vector3(0, 1.6, -17), Vector3(12, 3.2, 0.25), Color(0.25, 0.29, 0.31))
	_add_box("AftWall", Vector3(0, 1.6, 17), Vector3(12, 3.2, 0.25), Color(0.25, 0.29, 0.31))
	for z in [-9.0, 0.0, 9.0]:
		_add_box("BulkheadL", Vector3(-4.2, 1.55, z), Vector3(3.6, 3.1, 0.2), Color(0.31, 0.35, 0.37))
		_add_box("BulkheadR", Vector3(4.2, 1.55, z), Vector3(3.6, 3.1, 0.2), Color(0.31, 0.35, 0.37))
	_add_console(Vector3(-3.2, 0.65, -5.0), "BRIDGE CONSOLE")
	_add_console(Vector3(3.2, 0.65, 4.5), "CIC STATUS CONSOLE")
	_add_console(Vector3(-3.2, 0.65, 12.0), "ENGINE STATUS CONSOLE")
	for z in [-14.0, -7.0, 0.0, 7.0, 14.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 3.05, z)
		light.light_color = Color(0.68, 0.82, 1.0)
		light.light_energy = 0.65
		light.omni_range = 8.0
		add_child(light)

func _add_box(node_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.35
	material.roughness = 0.72
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _add_console(pos: Vector3, title: String) -> void:
	var root := Node3D.new()
	root.position = pos
	root.name = title.replace(" ", "_")
	add_child(root)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.5, 1.2, 0.8)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.13, 0.16)
	mat.metallic = 0.6
	body.material_override = mat
	root.add_child(body)
	var screen := MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(1.15, 0.55, 0.025)
	screen.mesh = screen_mesh
	screen.position = Vector3(0, 0.28, -0.415)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.55, 0.62)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.02, 0.3, 0.38)
	screen.material_override = screen_mat
	root.add_child(screen)

func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.95, 13.5)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.65, 0)
	camera.current = true
	player.add_child(camera)

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.015, 0.03, 0.045, 0.72)
	panel.position = Vector2(16, 16)
	panel.size = Vector2(470, 112)
	layer.add_child(panel)
	status_label = Label.new()
	status_label.position = Vector2(30, 26)
	status_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(status_label)
	hint_label = Label.new()
	hint_label.position = Vector2(30, 78)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.text = "WASD:移動  マウス:視点  E:操作  1～5:役職切替  Esc:カーソル"
	layer.add_child(hint_label)
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * LOOK_SENSITIVITY)
		pitch = clampf(pitch - event.relative.y * LOOK_SENSITIVITY, -1.45, 1.45)
		camera.rotation.x = pitch
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() > 0.0:
		player.velocity.x = direction.x * WALK_SPEED
		player.velocity.z = direction.z * WALK_SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, WALK_SPEED * 5.0 * delta)
	if not player.is_on_floor():
		player.velocity.y -= 20.0 * delta
	else:
		player.velocity.y = 0.0
	player.move_and_slide()
	for i in range(ROLE_NAMES.size()):
		if Input.is_action_just_pressed("role_" + str(i + 1)):
			role_index = i
			_update_status()
	if Input.is_action_just_pressed("interact"):
		status_label.text = "役職：" + ROLE_NAMES[role_index] + "\n操作端末：試作段階です"

func _update_status() -> void:
	status_label.text = "YUKKURI FLEET SIMULATOR  |  BLOCKOUT\n現在の役職：" + ROLE_NAMES[role_index]
