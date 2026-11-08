extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Could not load scenes/main.tscn")
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var ship: Node3D = main.get_node_or_null("ShipGeometry")
	if ship == null:
		_fail("ShipGeometry root is missing")
		return
	if not is_equal_approx(ship.scale.z, 2.0):
		_fail("Longitudinal scale is not set to 2.0")
		return

	var deck: Node3D = ship.get_node_or_null("CompartmentedDeckPlan")
	if deck == null:
		_fail("CompartmentedDeckPlan is missing")
		return
	var hull: MeshInstance3D = ship.get_node_or_null("VisualUpgrade/Tapered hull shell")
	if hull == null or hull.mesh == null or hull.mesh.get_surface_count() == 0:
		_fail("Tapered hull mesh was not generated")
		return

	var player: CharacterBody3D = main.get("player")
	if player == null or player.name != "Player":
		_fail("Player character was not created")
		return
	if not is_equal_approx(player.position.z, 58.0):
		_fail("Player spawn is not aligned with the aft passage")
		return

	var door_count := _count_named(deck, "AutomaticCompartmentDoor")
	if door_count != 6:
		_fail("Expected six compartment doors; found %d" % door_count)
		return
	var collision_count := _count_type(deck, StaticBody3D)
	if collision_count < 25:
		_fail("Too few static collision bodies: %d" % collision_count)
		return

	for _frame in range(30):
		await physics_frame
	if not player.is_on_floor():
		_fail("Player did not settle onto the deck floor")
		return

	print("SHIP SMOKE TEST PASSED")
	print("Flight IIA length scale: 155.29 m nominal")
	print("Compartment doors: %d" % door_count)
	print("Static collision bodies: %d" % collision_count)
	quit(0)

func _count_named(node: Node, target_name: String) -> int:
	var total := 1 if node.name == target_name else 0
	for child in node.get_children():
		total += _count_named(child, target_name)
	return total

func _count_type(node: Node, target_type: Variant) -> int:
	var total := 1 if is_instance_of(node, target_type) else 0
	for child in node.get_children():
		total += _count_type(child, target_type)
	return total

func _fail(message: String) -> void:
	push_error("SHIP SMOKE TEST FAILED: " + message)
	quit(1)
