extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Could not load main scene")
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		_fail("Could not create screenshot output directory")
		return

	var capture_camera := Camera3D.new()
	capture_camera.name = "VisualCaptureCamera"
	main.add_child(capture_camera)
	capture_camera.position = Vector3(100.0, 70.0, 120.0)
	capture_camera.look_at(Vector3(0.0, 3.0, 0.0), Vector3.UP)
	capture_camera.current = true
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("ship_exterior.png")):
		_fail("Could not capture exterior view")
		return

	var player: CharacterBody3D = main.get("player")
	var player_camera: Camera3D = main.get("camera")
	if player == null or player_camera == null:
		_fail("Player camera is missing")
		return
	capture_camera.current = false
	player.position = Vector3(2.0, 2.2, -50.0)
	player.rotation.y = 0.0
	player_camera.rotation.x = 0.0
	player_camera.current = true
	for _frame in range(8):
		await process_frame
		await physics_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("bridge_compartment.png")):
		_fail("Could not capture bridge compartment")
		return

	player.position = Vector3(4.45, 2.2, -17.0)
	player.rotation.y = PI
	for _frame in range(8):
		await process_frame
		await physics_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("stairwell.png")):
		_fail("Could not capture stairwell")
		return

	print("VISUAL CAPTURE PASSED")
	print("Saved exterior, bridge compartment and stairwell screenshots")
	quit(0)

func _save_viewport(path: String) -> bool:
	var viewport_image: Image = root.get_texture().get_image()
	if viewport_image == null or viewport_image.is_empty():
		return false
	return viewport_image.save_png(path) == OK

func _fail(message: String) -> void:
	push_error("VISUAL CAPTURE FAILED: " + message)
	quit(1)
