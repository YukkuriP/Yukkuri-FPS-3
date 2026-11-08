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

	for hud_layer in main.get_tree().get_nodes_in_group("runtime_hud"):
		hud_layer.visible = false
	await process_frame

	var capture_camera := Camera3D.new()
	capture_camera.name = "VisualCaptureCamera"
	main.add_child(capture_camera)
	capture_camera.fov = 55.0
	capture_camera.position = Vector3(82.0, 48.0, 98.0)
	capture_camera.look_at(Vector3(0.0, 2.0, 2.0), Vector3.UP)
	capture_camera.current = true
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("ship_exterior.png")):
		_fail("Could not capture exterior view")
		return

	# Close inspection of the bridge, mast, funnels and hangar silhouette.
	capture_camera.fov = 58.0
	capture_camera.position = Vector3(32.0, 17.0, 24.0)
	capture_camera.look_at(Vector3(0.0, 5.0, -18.0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("superstructure_closeup.png")):
		_fail("Could not capture superstructure close-up")
		return

	# Aft deckhouse, twin exhaust trunks and hangar facade inspection.
	capture_camera.position = Vector3(30.0, 16.0, 70.0)
	capture_camera.look_at(Vector3(0.0, 5.0, 34.0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("aft_superstructure_closeup.png")):
		_fail("Could not capture aft superstructure close-up")
		return

	# Aim directly at the actual aft hangar door mesh.
	var hangar_leaf := main.find_child("Hangar outer door leaf", true, false) as Node3D
	if hangar_leaf == null:
		_fail("Could not find the aft hangar door leaf")
		return
	capture_camera.fov = 62.0
	hangar_leaf.visible = true
	print("HANGAR_LEAF_GLOBAL:", hangar_leaf.global_position)
	capture_camera.position = hangar_leaf.global_position + Vector3(0.0, 0.0, 12.0)
	capture_camera.look_at(hangar_leaf.global_position, Vector3.UP)
	print("HANGAR_CAPTURE_CAMERA:", capture_camera.global_position)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("hangar_aft_closeup.png")):
		_fail("Could not capture aft hangar facade")
		return

	# Camera inside the forward compartment, aimed across the console and glazing.
	capture_camera.fov = 82.0
	capture_camera.position = Vector3(5.2, 3.8, -49.0)
	capture_camera.look_at(Vector3(3.9, 2.4, -54.5), Vector3.UP)
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
	var door: Node3D = doors[0]
	for candidate in doors:
		if candidate.global_position.x > 0.0 and absf(candidate.global_position.z + 7.62) < absf(door.global_position.z + 7.62):
			door = candidate
	door.rotation.y = PI * 0.5
	var door_center_z := door.global_position.z + 1.62
	capture_camera.fov = 72.0
	capture_camera.position = Vector3(5.8, 3.2, door_center_z + 2.2)
	capture_camera.look_at(Vector3(door.global_position.x + 1.62, 3.0, door_center_z), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("hinged_door.png")):
		_fail("Could not capture hinged door")
		return

	# Inspect the stair geometry from a camera placed beside an actual tread.
	var stair_treads := main.get_tree().get_nodes_in_group("stair_treads")
	if stair_treads.size() < 6:
		_fail("Could not find the stair treads for visual inspection")
		return
	var stair_tread := stair_treads[5] as Node3D
	capture_camera.fov = 68.0
	capture_camera.position = stair_tread.global_position + Vector3(-2.0, 1.3, 2.5)
	capture_camera.look_at(stair_tread.global_position, Vector3.UP)
	for _frame in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("stairwell.png")):
		_fail("Could not capture stairwell")
		return

	print("VISUAL CAPTURE PASSED")
	print("Saved exterior, superstructure, hangar, bridge, door and stairwell screenshots")
	quit(0)

func _save_viewport(path: String) -> bool:
	var viewport_image: Image = root.get_texture().get_image()
	if viewport_image == null or viewport_image.is_empty():
		return false
	return viewport_image.save_png(path) == OK

func _fail(message: String) -> void:
	push_error("VISUAL CAPTURE FAILED: " + message)
	quit(1)
