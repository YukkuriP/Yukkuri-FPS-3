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
	capture_camera.fov = 50.0
	capture_camera.position = Vector3(70.0, 42.0, 82.0)
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
	var hangar_leaf := main.find_child("Aft hangar closure skin", true, false) as Node3D
	if hangar_leaf == null:
		_fail("Could not find the aft hangar closure skin")
		return
	capture_camera.fov = 62.0
	hangar_leaf.visible = true
	print("HANGAR_CLOSURE_GLOBAL:", hangar_leaf.global_position)
	capture_camera.position = hangar_leaf.global_position + Vector3(0.0, 0.0, 12.0)
	capture_camera.look_at(hangar_leaf.global_position, Vector3.UP)
	print("HANGAR_CAPTURE_CAMERA:", capture_camera.global_position)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("hangar_aft_closeup.png")):
		_fail("Could not capture aft hangar facade")
		return

	# Inside-facing check confirms the hangar closure panel is rendered on both sides.
	capture_camera.position = hangar_leaf.global_position + Vector3(0.0, 0.0, -12.0)
	capture_camera.look_at(hangar_leaf.global_position, Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("hangar_inside_closeup.png")):
		_fail("Could not capture the inside face of the hangar closure")
		return

	# Camera inside the forward compartment, aimed across the console and glazing.
	capture_camera.fov = 72.0
	# View from the aft side of the helm so the live monitor faces are visible.
	capture_camera.position = Vector3(0.0, 2.55, -23.5)
	capture_camera.look_at(Vector3(0.0, 2.45, -29.0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("bridge_compartment.png")):
		_fail("Could not capture bridge compartment")
		return

	# Inspect the bridge aft watertight-style access door head-on.
	var deck_plan: Node = main.find_child("CompartmentedDeckPlan", true, false)
	if deck_plan == null:
		_fail("Could not find the compartmented deck plan")
		return
	var door: Node3D = deck_plan.find_child("BridgeAftHingedDoor", true, false)
	if door == null:
		_fail("Could not find the bridge aft hinged door")
		return
	door.rotation.y = 0.0
	capture_camera.fov = 58.0
	capture_camera.position = door.global_position + Vector3(0.0, 0.2, 6.0)
	capture_camera.look_at(door.global_position + Vector3(0.0, 0.0, 0.0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("hinged_door.png")):
		_fail("Could not capture bridge aft hinged door")
		return

	# Inspect the stair geometry from a camera placed beside an actual tread.
	var stair_treads := main.get_tree().get_nodes_in_group("stair_treads")
	if stair_treads.size() < 6:
		_fail("Could not find the stair treads for visual inspection")
		return
	var stair_tread := stair_treads[5] as Node3D
	capture_camera.fov = 68.0
	# View from the port side into the actual deck opening, not down the passage.
	# Place the camera on the upper flight and look down the tread run.
	# Oblique side view keeps the stairs in frame without a vertical camera singularity.
	# Keep the camera inside the cut-out deck opening so the deck edge cannot occlude the flight.
	# The inspection camera must remain above the weather-deck plane (Y=1.25).
	# A shallow overhead oblique view exposes the complete stair flight through the cut-out.
	capture_camera.position = Vector3(4.45, 3.2, -10.0)
	capture_camera.look_at(Vector3(4.45, -0.15, -5.5), Vector3.FORWARD)
	for _frame in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("stairwell.png")):
		_fail("Could not capture stairwell")
		return

	# Diagnostic isolated view: hide unrelated ship meshes to verify the stair model itself.
	for mesh in main.find_children("*", "MeshInstance3D", true, false):
		var mesh_name := mesh.name.to_lower()
		mesh.visible = mesh_name.contains("stair") or mesh_name.contains("landing")
	capture_camera.position = Vector3(4.45, 3.2, -10.0)
	capture_camera.look_at(Vector3(4.45, -0.15, -5.5), Vector3.FORWARD)
	await process_frame
	await RenderingServer.frame_post_draw
	if not _save_viewport(output_dir.path_join("stairwell_isolated.png")):
		_fail("Could not capture isolated stairwell")
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
