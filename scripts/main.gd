extends Node3D
## Fictional fleet role-play simulator. Consoles model navigation and ship services only.
const SPEED := 4.2
const SENS := 0.002
const ROLES := ["艦長","操舵員","CIC士官","機関員","通信員","乗組員"]
const KEYS: Array[Key] = [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]
var player: CharacterBody3D
var camera: Camera3D
var pitch := 0.0
var role := 5
var heading := 248.0
var ship_speed := 12.0
var engine_output := 72.0
var autopilot := false
var clock := 8.0
var consoles: Array[Dictionary] = []
var active: Dictionary = {}
var monitor_open := false
var hud: Label
var prompt: Label
var monitor_layer: CanvasLayer
var monitor_title: Label
var monitor_text: Label

func _ready() -> void:
	_input_map()
	_ocean_and_sky()
	_exterior()
	_interior()
	_player()
	_hud()
	_monitor()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input_map() -> void:
	var actions := {"fwd":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"use":KEY_E,"release":KEY_ESCAPE,"close":KEY_Q}
	for name in actions:
		var action := "fleet_"+name
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
	var sea:=MeshInstance3D.new(); var plane:=PlaneMesh.new(); plane.size=Vector2(900,900)
	sea.mesh=plane; sea.position.y=-2.8; sea.material_override=_material(Color(0.012,0.09,0.15),0.5,0.25); add_child(sea)
	var we:=WorldEnvironment.new(); var env:=Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky:=Sky.new(); var sm:=ProceduralSkyMaterial.new()
	sm.sky_top_color=Color(0.12,0.25,0.42); sm.sky_horizon_color=Color(0.65,0.72,0.78)
	sm.ground_bottom_color=Color(0.025,0.06,0.09); sm.ground_horizon_color=Color(0.38,0.46,0.52)
	sky.sky_material=sm; env.sky=sky; env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	we.environment=env; add_child(we)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-32,-28,0); sun.light_energy=1.2; add_child(sun)

func _exterior() -> void:
	var hull:=_material(Color(0.17,0.22,0.25),0.72,0.38)
	var white:=_material(Color(0.68,0.72,0.72),0.25,0.6)
	var deck:=_material(Color(0.29,0.33,0.34),0.45,0.65)
	_cube(self,"Hull",Vector3(0,-0.9,2),Vector3(18,3.5,78),Color.WHITE,true).material_override=hull
	_cube(self,"Bow",Vector3(0,-0.7,-39),Vector3(13,2.7,7),Color.WHITE).material_override=hull
	_cube(self,"Main deck",Vector3(0,1.0,2),Vector3(17.5,0.22,76),Color.WHITE,true).material_override=deck
	_cube(self,"Forecastle",Vector3(0,1.2,-28),Vector3(15,0.3,22),Color.WHITE).material_override=deck
	_cube(self,"Forward deckhouse",Vector3(0,4,-21),Vector3(12,5.8,17),Color.WHITE).material_override=white
	_cube(self,"Bridge glazing",Vector3(0,6.5,-29.55),Vector3(10.8,1.2,0.12),Color(0.025,0.14,0.2))
	_cube(self,"Upper bridge",Vector3(0,7.8,-21),Vector3(9,2,10),Color.WHITE).material_override=white
	_cube(self,"Aft deckhouse",Vector3(0,3.6,13),Vector3(13,5,19),Color.WHITE).material_override=white
	_cube(self,"Funnel",Vector3(0,7.4,15),Vector3(4,4,4),Color(0.12,0.15,0.17))
	_cube(self,"Hangar",Vector3(0,4.8,28),Vector3(12,6,12),Color.WHITE).material_override=white
	_cube(self,"Hangar door",Vector3(0,4,34.1),Vector3(8.5,4.2,0.15),Color(0.1,0.15,0.18))
	_cube(self,"Mast",Vector3(0,10.4,-21),Vector3(0.8,5,0.8),Color(0.3,0.34,0.35))
	_cube(self,"Mast yard",Vector3(0,12,-21),Vector3(6.5,0.2,0.2),Color(0.3,0.34,0.35))
	_cube(self,"Mast top",Vector3(0,13.4,-21),Vector3(0.4,2.5,0.4),Color(0.3,0.34,0.35))
	for x in [-8.35,8.35]:
		for z in range(-34,39,3): _cube(self,"Rail post",Vector3(x,2,float(z)),Vector3(0.12,1.8,0.12),Color(0.65,0.69,0.68))
		_cube(self,"Rail",Vector3(x,2.9,2),Vector3(0.12,0.12,72),Color(0.7,0.73,0.72))
	for z in range(-34,38,4): _cube(self,"Deck seam",Vector3(0,1.12,float(z)),Vector3(16,0.015,0.04),Color(0.12,0.15,0.16))

func _interior() -> void:
	var floor:=_material(Color(0.22,0.26,0.27),0.4,0.75)
	var wall:=_material(Color(0.58,0.63,0.63),0.2,0.8)
	_cube(self,"Interior floor",Vector3(0,1.25,5),Vector3(13.5,0.22,76),Color.WHITE,true).material_override=floor
	_cube(self,"Interior ceiling",Vector3(0,5.25,5),Vector3(13.5,0.18,76),Color.WHITE).material_override=wall
	for x in [-6.85,6.85]: _cube(self,"Side bulkhead",Vector3(x,3.2,5),Vector3(0.22,4,76),Color.WHITE,true).material_override=wall
	for z in [-31,-18,-3,15,27,43]:
		for x in [-4,4]: _cube(self,"Bulkhead",Vector3(x,3.2,float(z)),Vector3(5.7,4,0.25),Color.WHITE,true).material_override=wall
	_add_console(Vector3(-3.8,1.85,-24),"BRIDGE","航海・艦内状況")
	_add_console(Vector3(3.8,1.85,-24),"BRIDGE","艦長用状況盤")
	_add_console(Vector3(-4.2,1.85,-10),"CIC","統合状況")
	_add_console(Vector3(0,1.85,-10),"CIC","センサー情報")
	_add_console(Vector3(4.2,1.85,-10),"CIC","航行情報")
	_add_console(Vector3(-5.4,1.85,5),"COMMS","通信管理")
	_add_console(Vector3(0,1.85,20),"ENGINE","機関・電力")
	_add_console(Vector3(4.2,1.85,20),"ENGINE","環境制御")
	_add_console(Vector3(5.2,1.85,5),"MESS","食堂案内")
	for x in [-4.5,4.5]:
		for z in [32,36,40]:
			_cube(self,"Bunk",Vector3(x,1.85,float(z)),Vector3(2.1,0.65,1),Color(0.28,0.33,0.36))
	for z in range(-29,44,6):
		var light:=OmniLight3D.new(); light.position=Vector3(0,4.9,float(z)); light.light_color=Color(0.72,0.84,1); light.light_energy=0.5; light.omni_range=8; add_child(light)

func _add_console(pos: Vector3, kind: String, title: String) -> void:
	var root:=Node3D.new(); root.position=pos; add_child(root)
	_cube(root,"Console cabinet",Vector3(0,0,0),Vector3(1.8,1.15,0.85),Color(0.08,0.12,0.15))
	_cube(root,"Bezel",Vector3(0,0.72,-0.18),Vector3(1.65,0.88,0.12),Color(0.02,0.04,0.05))
	var vp:=SubViewport.new(); vp.size=Vector2i(640,360); vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(vp)
	var ui:=Control.new(); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); vp.add_child(ui)
	var bg:=ColorRect.new(); bg.color=Color(0.01,0.04,0.055); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(bg)
	var label:=Label.new(); label.position=Vector2(22,20); label.size=Vector2(600,310); label.add_theme_font_size_override("font_size",24); label.add_theme_color_override("font_color",Color(0.4,0.9,0.86)); ui.add_child(label)
	var surface:=MeshInstance3D.new(); var pm:=PlaneMesh.new(); pm.size=Vector2(1.52,0.79); surface.mesh=pm; surface.position=Vector3(0,0.73,-0.255)
	var mat:=StandardMaterial3D.new(); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_texture=vp.get_texture(); mat.emission_enabled=true; mat.emission_texture=vp.get_texture(); mat.emission_energy_multiplier=0.65; surface.material_override=mat; root.add_child(surface)
	consoles.append({"node":root,"kind":kind,"title":title,"label":label})

func _player() -> void:
	player=CharacterBody3D.new(); player.position=Vector3(0,2.2,37); add_child(player)
	var col:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.radius=0.34; cap.height=1.8; col.shape=cap; player.add_child(col)
	camera=Camera3D.new(); camera.position=Vector3(0,0.65,0); camera.current=true; camera.fov=78; player.add_child(camera)

func _hud() -> void:
	var layer:=CanvasLayer.new(); add_child(layer)
	var panel:=ColorRect.new(); panel.color=Color(0.01,0.025,0.04,0.8); panel.position=Vector2(14,14); panel.size=Vector2(490,112); layer.add_child(panel)
	hud=Label.new(); hud.position=Vector2(28,22); hud.add_theme_font_size_override("font_size",17); layer.add_child(hud)
	prompt=Label.new(); prompt.position=Vector2(28,82); prompt.add_theme_font_size_override("font_size",14); layer.add_child(prompt)

func _monitor() -> void:
	monitor_layer=CanvasLayer.new(); monitor_layer.visible=false; add_child(monitor_layer)
	var shade:=ColorRect.new(); shade.color=Color(0.005,0.015,0.025,0.94); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); monitor_layer.add_child(shade)
	var panel:=PanelContainer.new(); panel.set_anchors_preset(Control.PRESET_CENTER); panel.position=Vector2(-390,-250); panel.size=Vector2(780,500); monitor_layer.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",14); panel.add_child(box)
	monitor_title=Label.new(); monitor_title.add_theme_font_size_override("font_size",26); box.add_child(monitor_title)
	monitor_text=Label.new(); monitor_text.custom_minimum_size=Vector2(700,300); monitor_text.add_theme_font_size_override("font_size",19); box.add_child(monitor_text)
	var row:=HBoxContainer.new(); box.add_child(row)
	_button(row,"情報更新",_refresh)
	_button(row,"自動操船 切替",_autopilot)
	_button(row,"針路 −5°",_left)
	_button(row,"針路 ＋5°",_right)
	_button(row,"閉じる",_close)

func _button(parent: HBoxContainer, caption: String, action: Callable) -> void:
	var b:=Button.new(); b.text=caption; b.custom_minimum_size=Vector2(125,48); b.pressed.connect(action); parent.add_child(b)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not monitor_open: Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not monitor_open:
		player.rotate_y(-event.relative.x*SENS); pitch=clampf(pitch-event.relative.y*SENS,-1.42,1.42); camera.rotation.x=pitch
	if event.is_action_pressed("fleet_release"): Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("fleet_close") and monitor_open: _close()

func _physics_process(delta: float) -> void:
	clock=fposmod(clock+delta*0.002,24.0)
	if not monitor_open:
		var v:=Vector2(Input.get_action_strength("fleet_right")-Input.get_action_strength("fleet_left"),Input.get_action_strength("fleet_back")-Input.get_action_strength("fleet_fwd"))
		var dir:=(player.transform.basis*Vector3(v.x,0,v.y)).normalized()
		player.velocity.x=dir.x*SPEED; player.velocity.z=dir.z*SPEED
		if not player.is_on_floor(): player.velocity.y-=20*delta
		else: player.velocity.y=0
		player.move_and_slide()
		for i in range(6):
			if Input.is_action_just_pressed("fleet_role_"+str(i+1)): role=i
		if Input.is_action_just_pressed("fleet_use"): _interact()
	_update_screens()
	_update_hud()

func _nearest() -> Dictionary:
	var result: Dictionary={}; var best:=3.0
	for c in consoles:
		var d:float=player.global_position.distance_to(c.node.global_position)
		if d<best: best=d; result=c
	return result

func _interact() -> void:
	var c:=_nearest()
	if c.is_empty(): return
	active=c; monitor_open=true; monitor_layer.visible=true; monitor_title.text=str(c.title)+" / "+str(c.kind)
	_refresh(); Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _refresh() -> void:
	if active.is_empty(): return
	var text := ""
	match active.kind:
		"BRIDGE": text="航海管理\n速力 %.1f kt\n針路 %03.0f°\n自動操船 %s\n海況 訓練用データ" % [ship_speed,heading,"ON" if autopilot else "OFF"]
		"CIC": text="艦内状況統合\n航海データ 正常\nセンサー系統 オンライン\n訓練シナリオ 接続中"
		"ENGINE": text="機関・電力管理\n主機出力 %.0f%%\n発電系統 正常\n冷却系統 正常" % engine_output
		"COMMS": text="通信管理\n艦内回線 接続\n外部通信 待機\n受信メッセージ 0"
		_: text="乗組員サービス\n食堂 営業中\n艦内案内 利用可能"
	monitor_text.text=text+"\n\n担当ロール："+ROLES[role]+"\n情報はシミュレーション内の架空データです。"

func _autopilot() -> void:
	autopilot=not autopilot; _refresh()
func _left() -> void:
	heading=fposmod(heading-5,360); _refresh()
func _right() -> void:
	heading=fposmod(heading+5,360); _refresh()
func _close() -> void:
	monitor_open=false; monitor_layer.visible=false; active={}; Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _update_screens() -> void:
	for c in consoles:
		var l:Label=c.label
		match c.kind:
			"BRIDGE": l.text="NAVIGATION\nSPEED  %.1f kt\nHEADING  %03.0f°\nAUTOPILOT  %s\nSHIP STATUS  NORMAL" % [ship_speed,heading,"ON" if autopilot else "OFF"]
			"CIC": l.text="INTEGRATED STATUS\nNAV DATA  NORMAL\nSENSOR NETWORK  ONLINE\nTRAINING MODE  ACTIVE\nLINK  CONNECTED"
			"ENGINE": l.text="ENGINE CONTROL\nOUTPUT  %.0f %%\nPOWER  NORMAL\nCOOLING  NORMAL\nAUXILIARY  ONLINE" % engine_output
			"COMMS": l.text="COMMUNICATIONS\nINTERNAL LINK  UP\nEXTERNAL LINK  STANDBY\nINBOX  0\nLOG  NORMAL"
			_: l.text="CREW SERVICES\nMESS HALL  OPEN\nNOTICE  NONE\nSHIP TIME  %02d:%02d" % [int(clock),int(fposmod(clock*60,60))]

func _update_hud() -> void:
	hud.text="YUKKURI FLEET SIMULATOR  |  "+ROLES[role]+"\n速力 %.1f kt   針路 %03.0f°   艦内時刻 %02d:%02d" % [ship_speed,heading,int(clock),int(fposmod(clock*60,60))]
	var c:=_nearest()
	prompt.text="E：%s を操作" % c.title if not c.is_empty() else "WASD 移動 / マウス 視点 / 1～6 役職 / Q 端末を閉じる"
