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

	var hud_layer := main.get_node_or_null("CanvasLayer")
	if hud_layer != null:
		hud_layer.visible = false

	var capture_camera := Camera3D.new()
	capture_camera.name = "VisualCaptureCamera"
	main.add_child(capture_camera)
	capture_camera.fov = 55.0
	capture_camera.position = Vector3(65.0, 35.0, 70.0)
	capture_camera.look_at(Vector3(0.0, 3.0, 0.0), Vector3.UP)
	capture_camera.current = true
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("ship_exterior.png")):
		_fail("Could not capture exterior view")
		return

	# Camera inside the forward compartment, aimed across the console and glazing.
	capture_camera.position = Vector3(4.0, 3.0, -52.0)
	capture_camera.look_at(Vector3(4.0, 3.8, -61.0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("bridge_compartment.png")):
		_fail("Could not capture bridge compartment")
		return

	# Inspect a door leaf swung open into the adjoining room.
	var deck: Node3D = main.get_node_or_null("ShipGeometry/CompartmentedDeckPlan")
	if deck == null:
		_fail("Compartmented deck is missing")
		return
	var doors := deck.get_tree().get_nodes_in_group("compartment_doors")
	if doors.size() != 7:
		_fail("Expected seven hinged doors for visual capture")
		return
	var door: Node3D = doors[1]
	door.rotation.y = PI * 0.5
	capture_camera.position = Vector3(4.8, 3.0, -54.0)
	capture_camera.look_at(Vector3(2.7, 3.0, -54.0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("hinged_door.png")):
		_fail("Could not capture hinged door")
		return

	# Overhead oblique view of the stairwell opening and the lower-deck stair.
	capture_camera.position = Vector3(5.8, 4.65, -11.0)
	capture_camera.look_at(Vector3(4.45, -0.1, -12.0), Vector3.UP)
	for _frame in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("stairwell.png")):
		_fail("Could not capture stairwell")
		return

	print("VISUAL CAPTURE PASSED")
	print("Saved exterior, bridge compartment, hinged door and stairwell screenshots")
	quit(0)

func _save_viewport(path: String) -> bool:
	var viewport_image: Image = root.get_texture().get_image()
	if viewport_image == null or viewport_image.is_empty():
		return false
	return viewport_image.save_png(path) == OK

func _fail(message: String) -> void:
	push_error("VISUAL CAPTURE FAILED: " + message)
	quit(1)
