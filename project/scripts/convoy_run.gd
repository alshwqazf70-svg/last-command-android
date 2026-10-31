extends Node3D
## Last Command - Tactical Convoy Run mode.
## Lightweight procedural lane-runner designed for Android touch controls.

const SAVE_PATH := "user://progress.cfg"
const MAX_VISIBLE_SOLDIERS := 80
const LANE_LIMIT := 4.2
const RUN_SPEED := 17.0
const SEGMENT_GAP := 34.0
const MAX_SEGMENTS := 7
const FINISH_DISTANCE := 850.0
const BOOST_COOLDOWN := 10.0

var player_x := 0.0
var target_x := 0.0
var run_distance := 0.0
var crowd_count := 1
var health := 100
var coins := 0
var game_over := false
var boost_timer := 0.0
var victory := false
var spawn_cursor := -24.0
var drag_active := false
var drag_index := -1
var drag_last_x := 0.0
var segments: Array[Node3D] = []
var soldiers: Array[MeshInstance3D] = []
var player_root: Node3D
var camera: Camera3D
var hud: CanvasLayer
var count_label: Label
var status_label: Label
var result_panel: PanelContainer
var result_label: Label
var fire_button: Button
var restart_button: Button
var rng := RandomNumberGenerator.new()
var run_time := 0.0
var best_distance := 0.0
var feedback_cooldown := 0.0

func _ready() -> void:
	rng.randomize()
	_load_coins()
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	for i in range(MAX_SEGMENTS):
		_spawn_segment(spawn_cursor)
		spawn_cursor -= SEGMENT_GAP
	_update_hud()

func _process(delta: float) -> void:
	if game_over:
		return
	run_time += delta
	feedback_cooldown = maxf(0.0, feedback_cooldown - delta)
	run_distance += RUN_SPEED * delta
	boost_timer = maxf(0.0, boost_timer - delta)
	if run_distance >= FINISH_DISTANCE:
		_finish_run(true)
		_update_hud()
		return
	player_root.position.z = -run_distance
	player_x = move_toward(player_x, target_x, 9.0 * delta)
	player_x = clampf(player_x, -LANE_LIMIT, LANE_LIMIT)
	player_root.position.x = player_x
	_update_crowd()
	_update_camera()
	_check_segments()
	_update_hud()

func _build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.035, 0.09, 0.16)
	sky_mat.sky_horizon_color = Color(0.55, 0.59, 0.55)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.67, 0.68)
	env.ambient_light_energy = 0.7
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_energy = 1.1
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(13, 260)
	ground.mesh = plane
	ground.position = Vector3(0, -0.16, -105)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.20, 0.25, 0.22)
	ground.material_override = ground_mat
	add_child(ground)
	for x in [-6.0, 6.0]:
		_add_box(self, Vector3(x, 0.15, -105), Vector3(0.25, 0.3, 260), Color(0.65, 0.58, 0.34))
	for x in [-2.1, 2.1]:
		_add_box(self, Vector3(x, 0.01, -105), Vector3(0.045, 0.025, 260), Color(0.75, 0.73, 0.60))

func _build_player() -> void:
	player_root = Node3D.new()
	player_root.name = "Convoy"
	add_child(player_root)
	var leader := _make_soldier(Color(0.22, 0.34, 0.27), 1.0)
	player_root.add_child(leader)
	for i in range(MAX_VISIBLE_SOLDIERS - 1):
		var soldier := _make_soldier(Color(0.30, 0.39, 0.30), 0.72)
		player_root.add_child(soldier)
		soldiers.append(soldier)

func _make_soldier(tint: Color, scale_value: float) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.22 * scale_value
	mesh.height = 0.85 * scale_value
	body.mesh = mesh
	body.position.y = 0.48 * scale_value
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	body.material_override = mat
	return body

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 62
	add_child(camera)

func _update_camera() -> void:
	if camera == null:
		return
	camera.position = player_root.position + Vector3(0, 7.8, 10.5)
	camera.look_at(player_root.position + Vector3(0, 1.0, -9.0), Vector3.UP)

func _update_crowd() -> void:
	var visible_count := mini(crowd_count, MAX_VISIBLE_SOLDIERS)
	var columns := maxi(1, int(ceil(sqrt(float(visible_count)))))
	for i in range(soldiers.size()):
		var soldier := soldiers[i]
		var active := i < visible_count - 1
		soldier.visible = active
		if active:
			var row := int(i / columns)
			var col := i % columns
			soldier.position = Vector3((float(col) - float(columns - 1) * 0.5) * 0.58, absf(sin(run_time * 7.0 + float(i) * 0.35)) * 0.055, float(row + 1) * 0.72)

func _spawn_segment(z_pos: float) -> void:
	var segment := Node3D.new()
	segment.position.z = z_pos
	segment.set_meta("resolved", false)
	add_child(segment)
	segments.append(segment)
	var gate_lane := rng.randi_range(-1, 1)
	var roll := rng.randf()
	var gate_value := 10 if roll < 0.55 else (2 if roll < 0.85 else 25)
	var gate_text := "+%d" % gate_value if gate_value == 10 or gate_value == 25 else "x2"
	var gate_color := Color(0.12, 0.48, 0.88) if gate_value == 10 else (Color(0.12, 0.66, 0.35) if gate_value == 2 else Color(0.72, 0.42, 0.08))
	_add_gate(segment, Vector3(float(gate_lane) * 2.8, 1.35, 0), gate_text, gate_color, gate_value)
	var obstacle_lanes: Array[int] = []
	for lane in [-1, 0, 1]:
		if lane != gate_lane:
			obstacle_lanes.append(lane)
	obstacle_lanes.shuffle()
	for lane in obstacle_lanes:
		_add_obstacle(segment, Vector3(float(lane) * 2.8, 1.0, -1.2))

func _add_gate(parent: Node3D, at: Vector3, text_value: String, tint: Color, value: int) -> void:
	var gate := Node3D.new()
	gate.position = at
	gate.set_meta("kind", "gate")
	gate.set_meta("value", value)
	gate.set_meta("lane", int(round(at.x / 2.8)))
	parent.add_child(gate)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = tint
	glow.emission_enabled = true
	glow.emission = tint
	glow.emission_energy_multiplier = 0.65
	_add_box(gate, Vector3(-0.8, 0, 0), Vector3(0.16, 2.7, 0.22), tint).material_override = glow
	_add_box(gate, Vector3(0.8, 0, 0), Vector3(0.16, 2.7, 0.22), tint).material_override = glow
	_add_box(gate, Vector3(0, 1.25, 0), Vector3(1.75, 0.18, 0.22), tint).material_override = glow
	var label := Label3D.new()
	label.text = text_value
	label.position = Vector3(0, 0.35, -0.16)
	label.font_size = 64
	label.modulate = Color.WHITE
	gate.add_child(label)

func _add_obstacle(parent: Node3D, at: Vector3) -> void:
	var obstacle := Node3D.new()
	obstacle.position = at
	obstacle.set_meta("kind", "obstacle")
	obstacle.set_meta("lane", int(round(at.x / 2.8)))
	parent.add_child(obstacle)
	var variant := rng.randi_range(0, 2)
	if variant == 0:
		_add_box(obstacle, Vector3.ZERO, Vector3(1.35, 1.9, 0.8), Color(0.62, 0.16, 0.12))
		_add_box(obstacle, Vector3(0, 1.0, 0), Vector3(1.55, 0.16, 0.9), Color(0.95, 0.55, 0.12))
	elif variant == 1:
		_add_box(obstacle, Vector3(0, 0.55, 0), Vector3(1.5, 1.1, 1.0), Color(0.38, 0.31, 0.22))
		_add_box(obstacle, Vector3(0, 1.15, 0), Vector3(1.55, 0.12, 1.05), Color(0.82, 0.68, 0.38))
	else:
		_add_box(obstacle, Vector3(0, 0.45, 0), Vector3(1.65, 0.9, 0.55), Color(0.28, 0.32, 0.34))
		_add_box(obstacle, Vector3(0, 0.95, 0), Vector3(1.8, 0.12, 0.62), Color(0.92, 0.68, 0.16))

func _add_box(parent: Node3D, at: Vector3, dimensions: Vector3, tint: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.85
	node.material_override = mat
	parent.add_child(node)
	return node

func _check_segments() -> void:
	for segment in segments.duplicate():
		if not is_instance_valid(segment):
			segments.erase(segment)
			continue
		var distance_to_segment := absf(segment.position.z - player_root.position.z)
		if distance_to_segment < 1.0 and not bool(segment.get_meta("resolved", false)):
			_resolve_segment(segment)
		if segment.position.z > player_root.position.z + 18.0:
			segments.erase(segment)
			segment.queue_free()
			_spawn_segment(spawn_cursor)
			spawn_cursor -= SEGMENT_GAP
		if segments.size() > MAX_SEGMENTS + 2:
			var oldest := segments.pop_front()
			if is_instance_valid(oldest):
				oldest.queue_free()

func _resolve_segment(segment: Node3D) -> void:
	segment.set_meta("resolved", true)
	for item in segment.get_children():
		if not item is Node3D or not item.has_meta("kind"):
			continue
		var lane := int(item.get_meta("lane"))
		if absf(player_x - float(lane) * 2.8) > 1.35:
			continue
		if str(item.get_meta("kind")) == "gate":
			var value := int(item.get_meta("value"))
			var before := crowd_count
			crowd_count = mini(999, crowd_count + value) if value == 10 or value == 25 else mini(999, crowd_count * value)
			_show_feedback("+%d جندي" % (crowd_count - before) if value != 2 else "تضاعفت الفرقة!", Color(0.35, 1.0, 0.55))
		else:
			var lost := mini(15, maxi(0, crowd_count - 1))
			crowd_count = maxi(1, crowd_count - 15)
			health -= 25 if lost == 0 else 0
			_show_feedback("اصطدام! -%d" % lost, Color(1.0, 0.35, 0.2))
			if health <= 0:
				_finish_run(false)
	_update_crowd()

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var top := PanelContainer.new()
	top.position = Vector2(18, 18)
	top.custom_minimum_size = Vector2(330, 86)
	hud.add_child(top)
	var column := VBoxContainer.new()
	top.add_child(column)
	var title := Label.new()
	title.text = "LAST COMMAND  •  CONVOY ASSAULT"
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)
	count_label = Label.new()
	column.add_child(count_label)
	status_label = Label.new()
	column.add_child(status_label)
	fire_button = Button.new()
	fire_button.text = "BOOST"
	fire_button.position = Vector2(0, 0)
	fire_button.anchor_left = 1
	fire_button.anchor_right = 1
	fire_button.anchor_top = 1
	fire_button.anchor_bottom = 1
	fire_button.offset_left = -170
	fire_button.offset_top = -100
	fire_button.offset_right = -20
	fire_button.offset_bottom = -25
	fire_button.pressed.connect(_activate_boost)
	hud.add_child(fire_button)
	var back := Button.new()
	back.text = "العودة للقاعدة"
	back.position = Vector2(18, 118)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/base_preview.tscn"))
	hud.add_child(back)
	result_panel = PanelContainer.new()
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -190
	result_panel.offset_top = -95
	result_panel.offset_right = 190
	result_panel.offset_bottom = 95
	result_panel.visible = false
	hud.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_panel.add_child(result_box)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_box.add_child(result_label)
	restart_button = Button.new()
	restart_button.text = "إعادة المهمة"
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	result_box.add_child(restart_button)
	var base_button := Button.new()
	base_button.text = "العودة إلى القاعدة"
	base_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/base_preview.tscn"))
	result_box.add_child(base_button)

func _update_hud() -> void:
	if count_label == null:
		return
	count_label.text = "قوة الفرقة: %d  |  المسافة: %d / %d م" % [crowd_count, int(run_distance), int(FINISH_DISTANCE)]
	status_label.text = "الصحة: %d  |  العملات: %d  |  أفضل مسافة: %d م  |  التعزيز: %s" % [health, coins, int(best_distance), ("جاهز" if boost_timer <= 0.0 else "%d ث" % int(ceil(boost_timer)))]

func _activate_boost() -> void:
	if game_over or boost_timer > 0.0:
		return
	boost_timer = BOOST_COOLDOWN
	crowd_count = mini(999, crowd_count + 5)
	_update_crowd()
	_update_hud()

func _finish_run(won: bool) -> void:
	if game_over:
		return
	game_over = true
	victory = won
	best_distance = maxf(best_distance, run_distance)
	var reward := (250 + int(crowd_count * 2)) if won else int(run_distance / 8.0)
	coins += reward
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("convoy", "best_distance", maxf(float(cfg.get_value("convoy", "best_distance", 0.0)), run_distance))
	cfg.save(SAVE_PATH)
	result_label.text = ("اكتملت المهمة!" if won else "انتهت المهمة") + "\nالمكافأة: %d عملة" % reward
	result_panel.visible = true
	fire_button.disabled = true
	_update_hud()

func _load_coins() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	coins = int(cfg.get_value("progress", "coins", 500))
	best_distance = float(cfg.get_value("convoy", "best_distance", 0.0))

func _show_feedback(message: String, tint: Color) -> void:
	if feedback_cooldown > 0.0 or player_root == null:
		return
	feedback_cooldown = 0.28
	var popup := Label3D.new()
	popup.text = message
	popup.font_size = 48
	popup.modulate = tint
	popup.position = player_root.position + Vector3(0, 2.4, -1.0)
	popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "position:y", popup.position.y + 1.1, 0.55)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.55)
	tween.tween_callback(popup.queue_free)

func _input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventScreenTouch:
		if event.pressed and drag_index == -1 and event.position.x < get_viewport().get_visible_rect().size.x * 0.72:
			drag_index = event.index
			drag_active = true
			drag_last_x = event.position.x
		elif not event.pressed and event.index == drag_index:
			drag_active = false
			drag_index = -1
	elif event is InputEventScreenDrag and drag_active and event.index == drag_index:
		target_x = clampf(target_x + event.relative.x * 0.018, -LANE_LIMIT, LANE_LIMIT)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag_active = event.pressed
		drag_last_x = event.position.x
	elif event is InputEventMouseMotion and drag_active:
		target_x = clampf(target_x + event.relative.x * 0.018, -LANE_LIMIT, LANE_LIMIT)
