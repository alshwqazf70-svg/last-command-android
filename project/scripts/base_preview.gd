extends Node3D

var camera: Camera3D
var camera_yaw := 0.0
var camera_pitch := -0.48
var camera_distance := 25.0
var drag_sensitivity := 0.008
var dragging := false
var camera_touch_index := -1
var selected_building := ""
var building_levels := {"hq": 1, "barracks": 1, "depot": 1, "tower": 1}
var building_names := {"hq": "مركز القيادة", "barracks": "الثكنات", "depot": "مستودع الإمدادات", "tower": "برج الدفاع"}
var progress := ConfigFile.new()
var coins := 0
var building_panel: PanelContainer
var building_title: Label
var building_info: Label
var upgrade_button: Button
var coin_label: Label

func _ready() -> void:
	_build_environment()
	_build_ground()
	_load_progress()
	_build_base()
	_build_hud()
	_register_building_pickups()
	_create_camera()
	_update_camera()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.10, 0.20, 0.32)
	sky_material.sky_horizon_color = Color(0.55, 0.63, 0.68)
	sky_material.ground_bottom_color = Color(0.12, 0.15, 0.13)
	sky_material.ground_horizon_color = Color(0.35, 0.39, 0.34)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.64, 0.70)
	env.ambient_light_energy = 0.65
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(44.0, 44.0)
	ground.mesh = mesh
	ground.position.y = -0.12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.19, 0.25, 0.20)
	material.roughness = 1.0
	ground.material_override = material
	add_child(ground)

	_add_box("Main concrete pad", Vector3(0.0, -0.035, 0.0), Vector3(25.0, 0.12, 19.0), Color(0.34, 0.37, 0.36))
	_add_box("North access road", Vector3(0.0, 0.015, -11.0), Vector3(32.0, 0.08, 2.4), Color(0.16, 0.18, 0.19))
	_add_box("West access road", Vector3(-14.0, 0.015, 0.0), Vector3(2.4, 0.08, 22.0), Color(0.16, 0.18, 0.19))

func _build_base() -> void:
	# Command headquarters: a recognizable multi-part landmark.
	_add_box("HQ foundation", Vector3(0.0, 0.65, 0.0), Vector3(5.2, 1.3, 4.2), Color(0.34, 0.39, 0.42))
	_add_box("HQ upper floor", Vector3(0.0, 1.75, 0.0), Vector3(4.0, 1.0, 3.3), Color(0.55, 0.59, 0.57))
	_add_box("HQ roof", Vector3(0.0, 2.35, 0.0), Vector3(4.5, 0.22, 3.8), Color(0.16, 0.23, 0.28))
	_add_box("HQ tower", Vector3(0.0, 3.15, -0.3), Vector3(1.0, 1.45, 1.0), Color(0.42, 0.48, 0.48))
	_add_box("HQ signal mast", Vector3(0.0, 4.25, -0.3), Vector3(0.10, 0.85, 0.10), Color(0.82, 0.72, 0.40))

	# Barracks.
	_add_box("Barracks body", Vector3(-7.0, 0.75, -4.0), Vector3(5.0, 1.5, 3.8), Color(0.34, 0.42, 0.36))
	_add_box("Barracks roof", Vector3(-7.0, 1.58, -4.0), Vector3(5.35, 0.22, 4.1), Color(0.19, 0.27, 0.23))
	_add_box("Barracks door", Vector3(-7.0, 0.48, -2.04), Vector3(1.2, 0.95, 0.08), Color(0.12, 0.17, 0.16))

	# Resource depot.
	_add_box("Depot body", Vector3(7.0, 0.68, -4.0), Vector3(4.6, 1.36, 3.8), Color(0.48, 0.43, 0.31))
	_add_box("Depot roof", Vector3(7.0, 1.42, -4.0), Vector3(4.95, 0.20, 4.1), Color(0.25, 0.25, 0.21))
	for i in range(3):
		_add_cylinder("Storage tank %d" % i, Vector3(7.0 + float(i - 1) * 1.35, 0.8, 2.9), 0.52, 1.6, Color(0.55, 0.59, 0.57))

	# Defensive towers at the corners.
	_add_tower(Vector3(-10.0, 0.0, 7.0))
	_add_tower(Vector3(10.0, 0.0, 7.0))
	_add_tower(Vector3(-10.0, 0.0, -7.0))
	_add_tower(Vector3(10.0, 0.0, -7.0))

	# Simple perimeter barriers.
	for x in [-12.0, -8.0, -4.0, 4.0, 8.0, 12.0]:
		_add_box("North barrier", Vector3(x, 0.42, -9.2), Vector3(2.6, 0.84, 0.35), Color(0.38, 0.42, 0.40))
		_add_box("South barrier", Vector3(x, 0.42, 9.2), Vector3(2.6, 0.84, 0.35), Color(0.38, 0.42, 0.40))
	_add_perimeter_gate()
	_build_troop_formation()
	_build_defense_network()
	_apply_building_visual_levels()

func _load_progress() -> void:
	progress.load("user://progress.cfg")
	coins = int(progress.get_value("progress", "coins", 500))
	if not progress.has_section_key("progress", "coins"):
		progress.set_value("progress", "coins", coins)
	for key in building_levels.keys():
		building_levels[key] = int(progress.get_value("buildings", key, 1))
	progress.save("user://progress.cfg")

func _register_building_pickups() -> void:
	_add_pickup("hq", Vector3(0.0, 1.7, 0.0), Vector3(5.8, 5.0, 5.0))
	_add_pickup("barracks", Vector3(-7.0, 1.0, -4.0), Vector3(5.8, 3.2, 4.8))
	_add_pickup("depot", Vector3(7.0, 1.0, -4.0), Vector3(5.5, 3.0, 4.8))
	_add_pickup("tower", Vector3(-10.0, 1.5, 7.0), Vector3(2.5, 4.0, 2.5))
	_add_pickup("tower", Vector3(10.0, 1.5, 7.0), Vector3(2.5, 4.0, 2.5))
	_add_pickup("tower", Vector3(-10.0, 1.5, -7.0), Vector3(2.5, 4.0, 2.5))
	_add_pickup("tower", Vector3(10.0, 1.5, -7.0), Vector3(2.5, 4.0, 2.5))

func _add_pickup(building_id: String, at: Vector3, dimensions: Vector3) -> void:
	var area := Area3D.new()
	area.position = at
	area.input_ray_pickable = true
	area.collision_layer = 1
	area.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	area.add_child(collision)
	area.input_event.connect(_on_building_input.bind(building_id))
	add_child(area)

func _on_building_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, building_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_building(building_id)
	elif event is InputEventScreenTouch and event.pressed:
		_select_building(building_id)

func _select_building(building_id: String) -> void:
	selected_building = building_id
	building_panel.visible = true
	_update_building_panel()

func _update_building_panel() -> void:
	if selected_building.is_empty():
		return
	var level := int(building_levels[selected_building])
	var cost := level * 100
	building_title.text = str(building_names[selected_building])
	building_info.text = "المستوى: %d / 5\nالرصيد: %d عملة\nتكلفة الترقية: %d" % [level, coins, cost]
	upgrade_button.disabled = level >= 5 or coins < cost
	upgrade_button.text = "تم بلوغ الحد الأقصى" if level >= 5 else "ترقية المبنى  —  %d" % cost

func _upgrade_selected_building() -> void:
	if selected_building.is_empty():
		return
	var level := int(building_levels[selected_building])
	var cost := level * 100
	if level >= 5 or coins < cost:
		return
	coins -= cost
	building_levels[selected_building] = level + 1
	progress.set_value("progress", "coins", coins)
	progress.set_value("buildings", selected_building, level + 1)
	progress.save("user://progress.cfg")
	_update_building_panel()
	_update_coin_label()
	_apply_building_visual_levels()

func _update_coin_label() -> void:
	if coin_label != null:
		coin_label.text = "العملات: %d" % coins


func _add_perimeter_gate() -> void:
	_add_box("Gate left pillar", Vector3(-2.1, 1.15, 9.2), Vector3(0.65, 2.3, 0.7), Color(0.48, 0.52, 0.48))
	_add_box("Gate right pillar", Vector3(2.1, 1.15, 9.2), Vector3(0.65, 2.3, 0.7), Color(0.48, 0.52, 0.48))
	_add_box("Armored gate", Vector3(0.0, 0.72, 9.2), Vector3(3.6, 1.35, 0.28), Color(0.20, 0.29, 0.30))
	_add_box("Gate warning light", Vector3(0.0, 2.45, 9.2), Vector3(1.2, 0.12, 0.16), Color(0.92, 0.56, 0.18))

func _build_troop_formation() -> void:
	# A visible parade formation makes the barracks feel staffed, not decorative.
	for row in range(3):
		for column in range(4):
			var soldier := Node3D.new()
			soldier.name = "Base_Soldier_%02d" % (row * 4 + column + 1)
			soldier.position = Vector3(-5.0 + float(column) * 1.15, 0.0, 5.0 + float(row) * 1.25)
			add_child(soldier)
			var uniform := _make_material(Color(0.20, 0.31, 0.24))
			var body := MeshInstance3D.new()
			var torso := CapsuleMesh.new()
			torso.radius = 0.24
			torso.height = 0.95
			body.mesh = torso
			body.position.y = 0.78
			body.material_override = uniform
			soldier.add_child(body)
			var head := MeshInstance3D.new()
			var helmet := SphereMesh.new()
			helmet.radius = 0.22
			helmet.height = 0.34
			head.mesh = helmet
			head.position.y = 1.42
			head.material_override = _make_material(Color(0.43, 0.48, 0.30))
			soldier.add_child(head)
			var pack := MeshInstance3D.new()
			var pack_mesh := BoxMesh.new()
			pack_mesh.size = Vector3(0.34, 0.48, 0.22)
			pack.mesh = pack_mesh
			pack.position = Vector3(0.0, 0.82, 0.25)
			pack.material_override = _make_material(Color(0.12, 0.18, 0.14))
			soldier.add_child(pack)
			var rifle := MeshInstance3D.new()
			var rifle_mesh := BoxMesh.new()
			rifle_mesh.size = Vector3(0.10, 0.10, 0.82)
			rifle.mesh = rifle_mesh
			rifle.position = Vector3(0.28, 0.92, -0.28)
			rifle.material_override = _make_material(Color(0.08, 0.10, 0.09))
			soldier.add_child(rifle)

func _build_defense_network() -> void:
	var positions := [Vector3(-10.0, 0.0, 7.0), Vector3(10.0, 0.0, 7.0), Vector3(-10.0, 0.0, -7.0), Vector3(10.0, 0.0, -7.0)]
	for i in range(positions.size()):
		var p: Vector3 = positions[i]
		_add_box("Turret mount %d" % i, p + Vector3(0.0, 2.58, 0.0), Vector3(1.0, 0.22, 1.0), Color(0.18, 0.24, 0.24))
		_add_box("Turret barrel %d" % i, p + Vector3(0.0, 2.82, -0.55), Vector3(0.18, 0.18, 1.15), Color(0.10, 0.14, 0.15))
		_add_box("Turret sensor %d" % i, p + Vector3(0.0, 3.15, 0.0), Vector3(0.38, 0.22, 0.38), Color(0.78, 0.35, 0.20))
	_add_cylinder("Central radar mast", Vector3(0.0, 3.35, -6.7), 0.10, 3.0, Color(0.28, 0.34, 0.34))
	var radar := MeshInstance3D.new()
	var radar_mesh := SphereMesh.new()
	radar_mesh.radius = 0.72
	radar_mesh.height = 0.18
	radar.mesh = radar_mesh
	radar.position = Vector3(0.0, 4.9, -6.7)
	radar.material_override = _make_material(Color(0.30, 0.72, 0.66))
	add_child(radar)
	for x in [-6.0, 6.0]:
		_add_box("Floodlight pole", Vector3(x, 2.5, 8.0), Vector3(0.12, 5.0, 0.12), Color(0.26, 0.31, 0.30))
		_add_box("Floodlight head", Vector3(x, 5.0, 8.0), Vector3(0.7, 0.24, 0.42), Color(0.84, 0.78, 0.56))

func _apply_building_visual_levels() -> void:
	# Upgrade ranks are represented in-world by visible level markers and added structures.
	var anchors := {
		"hq": Vector3(0.0, 5.15, 0.0),
		"barracks": Vector3(-7.0, 2.65, -4.0),
		"depot": Vector3(7.0, 2.55, -4.0),
		"tower": Vector3(10.0, 4.0, 7.0)
	}
	for key in building_levels.keys():
		var old := get_node_or_null("UpgradeVisual_" + str(key))
		if old != null:
			old.queue_free()
		var root := Node3D.new()
		root.name = "UpgradeVisual_" + str(key)
		add_child(root)
		var level := clampi(int(building_levels[key]), 1, 5)
		var badge := Label3D.new()
		badge.name = "LevelBadge"
		badge.text = "LV.%d" % level
		badge.font_size = 48
		badge.pixel_size = 0.008
		badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		badge.position = anchors[key]
		badge.modulate = Color(0.95, 0.78, 0.30)
		root.add_child(badge)
		for tier in range(1, level):
			var marker := MeshInstance3D.new()
			var marker_mesh := BoxMesh.new()
			marker_mesh.size = Vector3(0.55 + float(tier) * 0.12, 0.16, 0.55 + float(tier) * 0.12)
			marker.mesh = marker_mesh
			marker.position = anchors[key] + Vector3(0.0, -0.55 - float(tier) * 0.22, 0.0)
			marker.material_override = _make_material(Color(0.78, 0.58, 0.22))
			root.add_child(marker)
		if key == "hq" and level >= 3:
			_add_box("HQ upgrade antenna", Vector3(1.5, 4.4 + float(level - 2) * 0.35, 0.0), Vector3(0.12, 1.5, 0.12), Color(0.76, 0.68, 0.38))
		elif key == "barracks" and level >= 3:
			_add_box("Barracks command awning", Vector3(-7.0, 2.0, -1.6), Vector3(3.0, 0.14, 0.8), Color(0.25, 0.39, 0.30))
		elif key == "depot" and level >= 3:
			_add_cylinder("Depot extra silo", Vector3(9.2, 1.0, 2.9), 0.62, 2.0 + float(level - 3) * 0.35, Color(0.60, 0.64, 0.59))
		elif key == "tower" and level >= 3:
			_add_box("Advanced defense sensor", Vector3(10.0, 4.0 + float(level - 2) * 0.25, 7.0), Vector3(0.75, 0.28, 0.75), Color(0.24, 0.72, 0.68))

func _make_material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.72
	return material

func _add_tower(at: Vector3) -> void:
	_add_box("Watch tower base", at + Vector3(0.0, 0.75, 0.0), Vector3(1.4, 1.5, 1.4), Color(0.32, 0.38, 0.38))
	_add_box("Watch tower cabin", at + Vector3(0.0, 1.75, 0.0), Vector3(1.8, 0.65, 1.8), Color(0.48, 0.54, 0.52))
	_add_box("Watch tower roof", at + Vector3(0.0, 2.15, 0.0), Vector3(2.0, 0.18, 2.0), Color(0.16, 0.22, 0.25))

func _add_box(label: String, at: Vector3, dimensions: Vector3, tint: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.82
	instance.material_override = material
	instance.name = label.replace(" ", "_")
	add_child(instance)

func _add_cylinder(label: String, at: Vector3, radius: float, height: float, tint: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.28
	material.roughness = 0.55
	instance.material_override = material
	instance.name = label.replace(" ", "_")
	add_child(instance)

func _create_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 48.0
	add_child(camera)

func _update_camera() -> void:
	if camera == null:
		return
	var offset := Vector3(
		sin(camera_yaw) * cos(camera_pitch),
		-sin(camera_pitch),
		cos(camera_yaw) * cos(camera_pitch)
	) * camera_distance
	camera.position = Vector3(0.0, 1.2, 0.0) + offset
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "LAST COMMAND  |  MILITARY BASE PROTOTYPE"
	title.position = Vector2(28.0, 22.0)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.91, 0.94, 0.91))
	layer.add_child(title)

	var hint := Label.new()
	hint.text = "DRAG TO ROTATE CAMERA  •  FIRST 3D BLOCKOUT"
	hint.position = Vector2(30.0, 58.0)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.80))

	layer.add_child(hint)

	var mission_button := Button.new()
	mission_button.text = "START COMBAT MISSION  ▶"
	mission_button.position = Vector2(28.0, 104.0)
	mission_button.custom_minimum_size = Vector2(270.0, 58.0)
	mission_button.add_theme_font_size_override("font_size", 18)
	mission_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/mission.tscn"))
	layer.add_child(mission_button)

	var convoy_button := Button.new()
	convoy_button.text = "CONVOY ASSAULT  ▶"
	convoy_button.position = Vector2(28.0, 250.0)
	convoy_button.custom_minimum_size = Vector2(270.0, 54.0)
	convoy_button.add_theme_font_size_override("font_size", 17)
	convoy_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/convoy_run.tscn"))
	layer.add_child(convoy_button)

	var base_status := Label.new()
	base_status.text = "COMMAND CENTER  •  BARRACKS  •  SUPPLY DEPOT  •  DEFENSE TOWERS"
	base_status.position = Vector2(28.0, 174.0)
	base_status.add_theme_font_size_override("font_size", 14)
	base_status.add_theme_color_override("font_color", Color(0.84, 0.87, 0.81))
	layer.add_child(base_status)

	coin_label = Label.new()
	coin_label.text = "العملات: %d" % coins
	coin_label.position = Vector2(28.0, 205.0)
	coin_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(coin_label)

	building_panel = PanelContainer.new()
	building_panel.anchor_left = 1.0
	building_panel.anchor_right = 1.0
	building_panel.offset_left = -310.0
	building_panel.offset_top = 22.0
	building_panel.offset_right = -18.0
	building_panel.offset_bottom = 218.0
	building_panel.visible = false
	layer.add_child(building_panel)
	var panel_column := VBoxContainer.new()
	building_panel.add_child(panel_column)
	building_title = Label.new()
	building_title.add_theme_font_size_override("font_size", 20)
	panel_column.add_child(building_title)
	building_info = Label.new()
	panel_column.add_child(building_info)
	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(0.0, 48.0)
	upgrade_button.pressed.connect(_upgrade_selected_building)
	panel_column.add_child(upgrade_button)
	var close_button := Button.new()
	close_button.text = "إغلاق"
	close_button.pressed.connect(func(): building_panel.visible = false)
	panel_column.add_child(close_button)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if camera_touch_index == -1 and not _is_hud_position(event.position):
				camera_touch_index = event.index
				dragging = true
		else:
			if event.index == camera_touch_index:
				camera_touch_index = -1
				dragging = false
	elif event is InputEventScreenDrag and dragging and event.index == camera_touch_index:
		camera_yaw -= event.relative.x * drag_sensitivity
		camera_pitch = clamp(camera_pitch - event.relative.y * drag_sensitivity, -0.95, -0.18)
		_update_camera()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed and not _is_hud_position(event.position)
	elif event is InputEventMouseMotion and dragging:
		camera_yaw -= event.relative.x * drag_sensitivity
		camera_pitch = clamp(camera_pitch - event.relative.y * drag_sensitivity, -0.95, -0.18)
		_update_camera()

func _is_hud_position(position: Vector2) -> bool:
	if building_panel != null and building_panel.visible and building_panel.get_global_rect().has_point(position):
		return true
	return position.y < 320.0 and position.x < 340.0
