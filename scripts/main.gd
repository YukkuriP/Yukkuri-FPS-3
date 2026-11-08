extends Node3D
## Fictional fleet role-play simulator. Consoles model navigation and ship services only.
const SPEED := 4.2
const SENS := 0.002
const ROLES := ["艦長","操舵員","CIC士官","機関員","通信員","乗組員"]
const KEYS: Array[Key] = [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]
var ship_root: Node3D
var ui_font: SystemFont
var player: CharacterBody3D
var camera: Camera3D
var pitch := 0.0
var role := 5
var flight_mode := false
const FLY_SPEED := 12.0
var heading := 248.0
var ship_speed := 12.0
var engine_output := 72.0
var autopilot := false
var clock := 8.0
var consoles: Array[Dictionary] = []
var active: Dictionary = {}
var hud: Label
var prompt: Label
var comms_messages := 0
var cic_training := true
var mess_status := true

func _ready() -> void:
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo UI", "Meiryo", "Noto Sans CJK JP"])
	_input_map()
	_ocean_and_sky()
	ship_root = Node3D.new()
	ship_root.name = "ShipGeometry"
	# Public Flight IIA overall length is 155.29 m; beam remains 18 m.
	ship_root.scale = Vector3(1.0, 1.0, 2.0)
	add_child(ship_root)
	_exterior()
	_interior()
	var visual_upgrade:=Node3D.new()
	visual_upgrade.set_script(load("res://scripts/visual_upgrade.gd"))
	visual_upgrade.name="VisualUpgrade"
	ship_root.add_child(visual_upgrade)
	_player()
	_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input_map() -> void:
	var actions := {"fwd":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"release":KEY_ESCAPE,"fly_toggle":KEY_F,"fly_up":KEY_SPACE,"fly_down":KEY_CTRL,"interact":KEY_E}
	for name in actions:
		var action: String = "fleet_" + str(name)
		if not InputMap.has_action(action): InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = actions[name]
		InputMap.action_add_event(action,ev)
	for i in range(6):
		var a := "fleet_role_"+str(i+1)
		if not InputMap.has_action(a): InputMap.add_action(a)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEYS[i]
		InputMap.action_add_event(a,ev)

func _material(c: Color, metal := 0.3, rough := 0.65) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=c; m.metallic=metal; m.roughness=rough
	return m

func _cube(parent: Node3D, name: String, p: Vector3, s: Vector3, c: Color, solid := false) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size=s
	var obj := MeshInstance3D.new(); obj.name=name; obj.mesh=mesh; obj.position=p
	obj.material_override=_material(c); parent.add_child(obj)
	if solid:
		var body:=StaticBody3D.new(); body.position=p; parent.add_child(body)
		var col:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=s
		col.shape=shape; body.add_child(col)
	return obj

func _ocean_and_sky() -> void:
	var sea:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(900,900)
	plane.subdivide_width=96
	plane.subdivide_depth=96
	sea.mesh=plane
	sea.position.y=-2.8
	var sea_mat:=_material(Color(0.025,0.13,0.19),0.32,0.24)
	sea_mat.clearcoat_enabled=true
	sea_mat.clearcoat=0.42
	sea_mat.clearcoat_roughness=0.28
	# Fine-scale roughness breakup gives the large ocean surface varied highlights.
	var sea_noise:=FastNoiseLite.new()
	sea_noise.seed=80421
	sea_noise.noise_type=FastNoiseLite.TYPE_SIMPLEX
	sea_noise.frequency=0.035
	sea_noise.fractal_octaves=4
	var sea_roughness:=NoiseTexture2D.new()
	sea_roughness.width=512
	sea_roughness.height=512
	sea_roughness.seamless=true
	sea_roughness.noise=sea_noise
	sea_mat.roughness_texture=sea_roughness
	sea.material_override=sea_mat
	add_child(sea)
	var we:=WorldEnvironment.new(); var env:=Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky:=Sky.new(); var sm:=ProceduralSkyMaterial.new()
	sm.sky_top_color=Color(0.12,0.25,0.42); sm.sky_horizon_color=Color(0.65,0.72,0.78)
	sm.ground_bottom_color=Color(0.025,0.06,0.09); sm.ground_horizon_color=Color(0.38,0.46,0.52)
	sky.sky_material=sm; env.sky=sky; env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0
	we.environment=env; add_child(we)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-32,-28,0); sun.light_energy=1.5; sun.light_color=Color(1.0,0.97,0.9); sun.shadow_enabled=true; add_child(sun)

func _exterior() -> void:
	var hull:=_material(Color(0.17,0.22,0.25),0.72,0.38)
	var white:=_material(Color(0.56,0.57,0.54),0.18,0.78)
	var deck:=_material(Color(0.29,0.33,0.34),0.45,0.65)
	_cube(ship_root,"Hull",Vector3(0,-0.9,2),Vector3(18,3.5,78),Color.WHITE).material_override=hull
	_cube(ship_root,"Bow",Vector3(0,-0.7,-39),Vector3(13,2.7,7),Color.WHITE).material_override=hull
	_cube(ship_root,"Main deck",Vector3(0,1.0,2),Vector3(17.5,0.22,76),Color.WHITE).material_override=deck
	_cube(ship_root,"Forecastle",Vector3(0,1.2,-28),Vector3(15,0.3,22),Color.WHITE,true).material_override=deck
	# Superstructure is built as walkable shell walls, not opaque solid blocks.
	# Forward deckhouse: side/rear bulkheads, roof, and a glazed forward bridge band.
	for side in [-1.0, 1.0]:
		_cube(ship_root,"Forward deckhouse side shell",Vector3(side*5.9,4.0,-21.0),Vector3(0.2,5.8,17.0),Color.WHITE,true).material_override=white
	_cube(ship_root,"Forward deckhouse aft bulkhead",Vector3(0,4.0,-12.5),Vector3(12,5.8,0.2),Color.WHITE,true).material_override=white
	_cube(ship_root,"Forward deckhouse forward lower coaming",Vector3(0,1.48,-29.5),Vector3(12,0.42,0.2),Color.WHITE,true).material_override=white
	_cube(ship_root,"Forward deckhouse forward upper lintel",Vector3(0,6.6,-29.5),Vector3(12,0.5,0.2),Color.WHITE,true).material_override=white
	for side in [-1.0, 1.0]:
		_cube(ship_root,"Bridge window pillar",Vector3(side*5.7,4.8,-29.5),Vector3(0.6,3.2,0.2),Color.WHITE,true).material_override=white
	var bridge_glass := _cube(ship_root,"Bridge glazing",Vector3(0,4.8,-29.55),Vector3(10.8,3.2,0.12),Color.WHITE)
	var glazing_mat := StandardMaterial3D.new()
	glazing_mat.albedo_color = Color(0.16,0.19,0.18,0.24)
	glazing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glazing_mat.metallic = 0.32
	glazing_mat.roughness = 0.18
	bridge_glass.material_override = glazing_mat
	_cube(ship_root,"Forward deckhouse roof",Vector3(0,6.95,-21),Vector3(12,0.2,17),Color.WHITE,true).material_override=white
	_cube(ship_root,"Upper bridge",Vector3(0,7.8,-21),Vector3(9,2,10),Color.WHITE).material_override=white
	# Aft superstructure shell encloses communications and engineering spaces.
	for side in [-1.0, 1.0]:
		_cube(ship_root,"Aft deckhouse side shell",Vector3(side*6.4,3.6,13),Vector3(0.2,5,19),Color.WHITE,true).material_override=white
	_cube(ship_root,"Aft deckhouse forward bulkhead",Vector3(0,3.6,3.5),Vector3(13,5,0.2),Color.WHITE,true).material_override=white
	# A clear central passage connects the aft superstructure to the hangar.
	for side in [-1.0, 1.0]:
		_cube(ship_root,"Aft deckhouse aft bulkhead wing",Vector3(side*3.75,3.6,22.5),Vector3(5.5,5,0.2),Color.WHITE,true).material_override=white
	_cube(ship_root,"Aft passage lintel",Vector3(0,6.0,22.5),Vector3(2.0,0.8,0.2),Color.WHITE,true).material_override=white
	_cube(ship_root,"Aft deckhouse roof",Vector3(0,6.2,13),Vector3(13,0.2,19),Color.WHITE,true).material_override=white
	_cube(ship_root,"Funnel",Vector3(0,7.4,15),Vector3(4,4,4),Color(0.12,0.15,0.17))
	# Hangar shell: clear interior volume, side walls, roof, and aft door.
	for side in [-1.0, 1.0]:
		_cube(ship_root,"Hangar side shell",Vector3(side*6.0,4.8,28),Vector3(0.2,6,12),Color.WHITE,true).material_override=white
	for side in [-1.0, 1.0]:
		_cube(ship_root,"Hangar forward bulkhead wing",Vector3(side*3.75,4.8,22),Vector3(4.5,6,0.2),Color.WHITE,true).material_override=white
	_cube(ship_root,"Hangar passage lintel",Vector3(0,7.55,22),Vector3(3.0,0.5,0.2),Color.WHITE,true).material_override=white
	_cube(ship_root,"Hangar roof",Vector3(0,7.9,28),Vector3(12,0.2,12),Color.WHITE,true).material_override=white
	_cube(ship_root,"Hangar door",Vector3(0,4,34.1),Vector3(8.5,4.2,0.15),Color(0.1,0.15,0.18))
	_cube(ship_root,"Mast",Vector3(0,10.4,-21),Vector3(0.8,5,0.8),Color(0.3,0.34,0.35))
	_cube(ship_root,"Mast yard",Vector3(0,12,-21),Vector3(6.5,0.2,0.2),Color(0.3,0.34,0.35))
	_cube(ship_root,"Mast top",Vector3(0,13.4,-21),Vector3(0.4,2.5,0.4),Color(0.3,0.34,0.35))
	for x in [-8.35,8.35]:
		for z in range(-34,39,3): _cube(ship_root,"Rail post",Vector3(x,2,float(z)),Vector3(0.12,1.8,0.12),Color(0.65,0.69,0.68))
		_cube(ship_root,"Rail",Vector3(x,2.9,2),Vector3(0.12,0.12,72),Color(0.7,0.73,0.72))
	for z in range(-34,38,4): _cube(ship_root,"Deck seam",Vector3(0,1.12,float(z)),Vector3(16,0.015,0.04),Color(0.12,0.15,0.16))

func _interior() -> void:
	var plan := Node3D.new()
	plan.name = "CompartmentedDeckPlan"
	plan.set_script(load("res://scripts/deck_plan.gd"))
	ship_root.add_child(plan)
	_add_console(Vector3(-4.0, 1.85, -24.8), "BRIDGE", "航海・艦内状況")
	_add_console(Vector3(4.0, 1.85, -24.8), "BRIDGE", "艦長用状況盤")
	_add_console(Vector3(-5.0, 1.85, -15.0), "CIC", "乗員訓練・艦内状況")
	_add_console(Vector3(-2.8, 1.85, -15.0), "CIC", "訓練状況")
	_add_console(Vector3(4.1, 1.85, -3.0), "COMMS", "通信管理")
	_add_console(Vector3(4.1, 1.85, 21.0), "ENGINE", "機関・電力")
	_add_console(Vector3(-4.1, 1.85, 9.0), "MESS", "食堂案内")

func _add_console(pos: Vector3, kind: String, title: String) -> void:
	var root:=Node3D.new(); root.position=pos; ship_root.add_child(root)
	_cube(root,"Console cabinet",Vector3(0,0,0),Vector3(1.8,1.15,0.85),Color(0.08,0.12,0.15),true)
	_cube(root,"Bezel",Vector3(0,1.05,-0.18),Vector3(1.65,0.88,0.12),Color(0.02,0.04,0.05))
	var vp:=SubViewport.new(); vp.size=Vector2i(640,360); vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(vp)
	var ui:=Control.new(); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); vp.add_child(ui)
	var bg:=ColorRect.new(); bg.color=Color(0.004,0.014,0.021); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(bg)
	var header_bar:=ColorRect.new(); header_bar.position=Vector2(0,0); header_bar.size=Vector2(640,48); header_bar.color=Color(0.015,0.105,0.13); ui.add_child(header_bar)
	var header:=Label.new(); header.text=title.to_upper(); header.position=Vector2(22,7); header.size=Vector2(590,34); header.add_theme_font_size_override("font_size",20); header.add_theme_color_override("font_color",Color(0.78,0.96,0.91)); header.add_theme_font_override("font",ui_font); ui.add_child(header)
	var divider:=ColorRect.new(); divider.position=Vector2(18,49); divider.size=Vector2(604,3); divider.color=Color(0.18,0.62,0.58); ui.add_child(divider)
	var label:=Label.new(); label.position=Vector2(22,58); label.size=Vector2(600,292); label.add_theme_font_size_override("font_size",22); label.add_theme_color_override("font_color",Color(0.58,0.98,0.88)); label.add_theme_font_override("font",ui_font); ui.add_child(label)
	var surface:=MeshInstance3D.new(); surface.name="ConsoleDisplaySurface"; var pm:=PlaneMesh.new(); pm.size=Vector2(1.52,0.79); surface.mesh=pm; surface.position=Vector3(0,1.05,-0.12); surface.rotation.x=PI/2
	var mat:=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_texture=vp.get_texture(); mat.emission_enabled=true; mat.emission_texture=vp.get_texture(); mat.emission_energy_multiplier=1.25; surface.material_override=mat; root.add_child(surface)
	var hit_body:=StaticBody3D.new()
	hit_body.name="ScreenHitArea"
	hit_body.position=Vector3(0,1.05,-0.12)
	hit_body.rotation.x=0.0
	var hit_shape:=CollisionShape3D.new()
	var hit_box:=BoxShape3D.new()
	hit_box.size=Vector3(1.52,0.79,0.12)
	hit_shape.shape=hit_box
	hit_body.add_child(hit_shape)
	hit_body.set_meta("console_index",consoles.size())
	root.add_child(hit_body)
	consoles.append({"node":root,"kind":kind,"title":title,"label":label})

func _player() -> void:
	player=CharacterBody3D.new(); player.name="Player"; player.position=Vector3(0,2.2,58); add_child(player)
	var col:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.radius=0.34; cap.height=1.8; col.shape=cap; player.add_child(col)
	camera=Camera3D.new(); camera.position=Vector3(0,0.65,0); camera.current=true; camera.fov=78; player.add_child(camera)

func _hud() -> void:
	var layer:=CanvasLayer.new(); layer.add_to_group("runtime_hud"); add_child(layer)
	var panel:=ColorRect.new(); panel.color=Color(0.01,0.025,0.04,0.8); panel.position=Vector2(14,14); panel.size=Vector2(490,112); layer.add_child(panel)
	hud=Label.new(); hud.position=Vector2(28,22); hud.add_theme_font_size_override("font_size",17); hud.add_theme_font_override("font",ui_font); layer.add_child(hud)
	prompt=Label.new(); prompt.position=Vector2(28,82); prompt.add_theme_font_size_override("font_size",14); prompt.add_theme_font_override("font",ui_font); layer.add_child(prompt)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE: _click_console()
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x*SENS); pitch=clampf(pitch-event.relative.y*SENS,-1.42,1.42); camera.rotation.x=pitch
	if event.is_action_pressed("fleet_release"):
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("fleet_fly_toggle"):
		flight_mode = not flight_mode
		player.velocity = Vector3.ZERO
		_update_hud()


func _physics_process(delta: float) -> void:
	clock=fposmod(clock+delta*0.002,24.0)
	var v:=Vector2(Input.get_action_strength("fleet_right")-Input.get_action_strength("fleet_left"),Input.get_action_strength("fleet_back")-Input.get_action_strength("fleet_fwd"))
	if flight_mode:
		var fly_direction := camera.global_basis * Vector3(v.x, 0.0, v.y)
		fly_direction += Vector3.UP * (Input.get_action_strength("fleet_fly_up") - Input.get_action_strength("fleet_fly_down"))
		if fly_direction.length_squared() > 1.0:
			fly_direction = fly_direction.normalized()
		player.global_position += fly_direction * FLY_SPEED * delta
		player.velocity = Vector3.ZERO
	else:
		var dir:=(player.transform.basis*Vector3(v.x,0,v.y)).normalized()
		player.velocity.x=dir.x*SPEED
		player.velocity.z=dir.z*SPEED
		if not player.is_on_floor():
			player.velocity.y-=20*delta
		else:
			player.velocity.y=0
		player.move_and_slide()
	for i in range(6):
		if Input.is_action_just_pressed("fleet_role_"+str(i+1)): role=i
	_update_screens()
	_update_hud()

func _click_console() -> void:
	var origin:=camera.project_ray_origin(get_viewport().get_mouse_position())
	var direction:=camera.project_ray_normal(get_viewport().get_mouse_position())
	var query:=PhysicsRayQueryParameters3D.create(origin,origin+direction*5.0)
	query.collide_with_areas=false
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return
	var collider: Object=hit.collider
	if not collider is StaticBody3D: return
	if collider.has_meta("control"):
		var control:String=str(collider.get_meta("control"))
		if control=="helm":
			var helm_side:= -1.0 if hit.position.x<collider.global_position.x else 1.0
			heading=fposmod(heading+helm_side*5.0,360.0)
			_update_screens()
			return
	if not collider.has_meta("console_index"): return
	var index:int=int(collider.get_meta("console_index"))
	if index<0 or index>=consoles.size(): return
	var c:Dictionary=consoles[index]
	var local_hit:Vector3=c.node.to_local(hit.position)
	var side:= -1 if local_hit.x<0.0 else 1
	match c.kind:
		"BRIDGE":
			if absf(local_hit.x)<0.18:
				ship_speed=clampf(ship_speed+float(side),0.0,30.0)
			else:
				heading=fposmod(heading+float(side)*5.0,360.0)
		"ENGINE":
			engine_output=clampf(engine_output+float(side)*5.0,0.0,100.0)
		"CIC":
			cic_training=not cic_training
		"COMMS":
			comms_messages+=1
		_:
			mess_status=not mess_status
	_update_screens()

func _update_screens() -> void:
	for c in consoles:
		var l:Label=c.label
		match c.kind:
			"BRIDGE": l.text="NAVIGATION / LIVE\nSPEED  %.1f kt\nHEADING  %03.0f°\nAUTOPILOT  %s\nSTATUS  NORMAL\nCLICK: COURSE -/+5  |  CENTER: SPEED -/+" % [ship_speed,heading,"ON" if autopilot else "OFF"]
			"CIC": l.text="INTEGRATED STATUS / LIVE\nNAV DATA  NORMAL\nSENSOR NETWORK  ONLINE\nTRAINING MODE  %s\nLINK  CONNECTED\nCLICK DISPLAY TO TOGGLE" % ("ACTIVE" if cic_training else "PAUSED")
			"ENGINE": l.text="ENGINE / LIVE MONITOR\nOUTPUT  %.0f %%\nPOWER  NORMAL\nCOOLING  NORMAL\nAUXILIARY  ONLINE\nCLICK LEFT/RIGHT: OUTPUT -/+5%%" % engine_output
			"COMMS": l.text="COMMUNICATIONS / LIVE\nINTERNAL LINK  UP\nEXTERNAL LINK  STANDBY\nINBOX  %d\nLOG  NORMAL\nCLICK DISPLAY: ACKNOWLEDGE" % comms_messages
			_: l.text="CREW SERVICES / LIVE\nMESS HALL  %s\nNOTICE  NONE\nSHIP TIME  %02d:%02d\nCLICK DISPLAY: CHANGE STATUS" % ["OPEN" if mess_status else "CLOSED",int(clock),int(fposmod(clock*60,60))]

func _update_hud() -> void:
	hud.text="YUKKURI FLEET SIMULATOR  |  "+("FLIGHT MODE" if flight_mode else ROLES[role])+"\n速力 %.1f kt   針路 %03.0f°   艦内時刻 %02d:%02d" % [ship_speed,heading,int(clock),int(fposmod(clock*60,60))]
	prompt.text=("飛行モード ON: WASD移動 / Space上昇 / Ctrl下降 / F解除" if flight_mode else "WASD 移動 / マウス 視点 / E ドア開閉 / F 飛行モード / Esc カーソル切替")
