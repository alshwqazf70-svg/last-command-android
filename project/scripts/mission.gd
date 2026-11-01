extends Node3D

const ARENA_LIMIT := 15.0
const WAVE_COUNTS := [6, 8, 1]
var player_position := Vector3.ZERO
var player_health := 100.0
var kills := 0
var current_wave := 1
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var fire_cooldown := 0.0
var enemy_attack_cooldown := 0.0
const MAGAZINE_SIZE := 12
var ammo := MAGAZINE_SIZE
var reserve_ammo := 60
var reload_timer := 0.0
var hit_marker_timer := 0.0
var hit_marker_label: Label
var aim_reticle_label: Label
var hud_layer: CanvasLayer
var reload_button: Button
var joystick_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var movement_velocity := Vector2.ZERO
var aim_touch := -1
var aim_origin := Vector2.ZERO
var aim_vector := Vector2.ZERO
var hud_label: Label
var health_label: Label
var ammo_label: Label
var status_label: Label
var camera: Camera3D
var player_root: Node3D
var player_animator: AnimationPlayer
var player_animation_name := ""
var fire_button: Button
var back_button: Button
var mission_finished := false
var barracks_level := 1
var tower_level := 1
var hq_level := 1
var depot_level := 1
var mission_reward := 250
var max_player_health := 100.0

func _ready() -> void:
	_load_base_bonuses()
	_build_world()
	_build_player()
	_build_enemies()
	_build_hud()
	_update_camera()
	_update_hud()

func _load_base_bonuses() -> void:
	var config := ConfigFile.new()
	config.load("user://progress.cfg")
	hq_level = clampi(int(config.get_value("buildings", "hq", 1)), 1, 5)
	barracks_level = clampi(int(config.get_value("buildings", "barracks", 1)), 1, 5)
	depot_level = clampi(int(config.get_value("buildings", "depot", 1)), 1, 5)
	tower_level = clampi(int(config.get_value("buildings", "tower", 1)), 1, 5)
	max_player_health = 100.0 + float(hq_level - 1) * 5.0
	player_health = max_player_health
	mission_reward = 250 + (depot_level - 1) * 50

func _build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.035, 0.065, 0.10)
	sky_mat.sky_horizon_color = Color(0.34, 0.38, 0.37)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.69, 0.72)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)

	_add_box("Battlefield", Vector3(0, -0.3, 0), Vector3(36, 0.5, 36), Color(0.25, 0.29, 0.25))
	_add_box("Central road", Vector3(0, -0.02, 0), Vector3(5.0, 0.08, 34.0), Color(0.20, 0.22, 0.22))
	for i in range(7):
		var x := -14.0 + float(i) * 4.6
		_add_box("Cover_%d" % i, Vector3(x, 0.55, -5.5 if i % 2 == 0 else 6.0), Vector3(2.4, 1.1, 1.0), Color(0.36, 0.39, 0.34))
	for side in [-1.0, 1.0]:
		_add_box("Boundary_%d" % int(side), Vector3(side * 17.0, 1.0, 0), Vector3(0.5, 2.0, 34.0), Color(0.18, 0.23, 0.22))

func _build_player() -> void:
	player_root = Node3D.new()
	player_root.name = "Commander"
	add_child(player_root)
	var soldier_scene := load("res://assets/characters/soldier/character-soldier.glb") as PackedScene
	if soldier_scene != null:
		var soldier := soldier_scene.instantiate() as Node3D
		if soldier != null:
			soldier.name = "AnimatedCommander"
			soldier.scale = Vector3.ONE * 0.95
			player_root.add_child(soldier)
			player_animator = soldier.find_child("AnimationPlayer", true, false) as AnimationPlayer
	else:
		push_warning("Commander soldier GLB unavailable; using lightweight fallback.")
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.48
		capsule.height = 1.9
		body.mesh = capsule
		body.position.y = 0.95
		body.material_override = _material(Color(0.20, 0.34, 0.25))
		player_root.add_child(body)
		_add_player_detail(player_root)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 58
	add_child(camera)
	_play_commander_animation("idle")

func _play_commander_animation(preferred_name: String) -> void:
	if player_animator == null:
		return
	for animation_name in player_animator.get_animation_list():
		var candidate := String(animation_name)
		if candidate.get_file().to_lower() == preferred_name.to_lower() or candidate.to_lower() == preferred_name.to_lower():
			if player_animation_name != candidate or not player_animator.is_playing():
				player_animator.play(candidate)
				player_animation_name = candidate
			return

func _add_player_detail(parent: Node3D) -> void:
	var pack := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.65, 0.35)
	pack.mesh = box
	pack.position = Vector3(0, 1.05, 0.42)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.19, 0.15)
	pack.material_override = mat
	parent.add_child(pack)
	var gun := MeshInstance3D.new()
	var gun_mesh := BoxMesh.new()
	gun_mesh.size = Vector3(0.16, 0.16, 1.0)
	gun.mesh = gun_mesh
	gun.position = Vector3(0.42, 1.12, -0.48)
	gun.material_override = _material(Color(0.10, 0.12, 0.12))
	parent.add_child(gun)

func _build_enemies() -> void:
	_spawn_wave(current_wave)

func _spawn_wave(wave: int) -> void:
	var count := int(WAVE_COUNTS[wave - 1])
	var is_boss_wave := wave == 3
	for i in range(count):
		var enemy := Node3D.new()
		enemy.name = "Hostile_%02d_W%d" % [i + 1, wave]
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		var scale_factor := 1.65 if is_boss_wave else 1.0
		capsule.radius = 0.48 * scale_factor
		capsule.height = 1.8 * scale_factor
		body.mesh = capsule
		body.position.y = 0.9 * scale_factor
		body.material_override = _material(Color(0.72, 0.20, 0.10) if is_boss_wave else Color(0.48, 0.16, 0.13))
		enemy.add_child(body)
		var marker := MeshInstance3D.new()
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.52, 0.45, 0.35) * scale_factor
		marker.mesh = marker_mesh
		marker.position = Vector3(0, 1.0, 0.42) * scale_factor
		marker.material_override = _material(Color(0.28, 0.08, 0.05))
		enemy.add_child(marker)
		var angle := TAU * float(i) / float(count)
		var radius := 11.0 if is_boss_wave else 10.0
		enemy.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		add_child(enemy)
		enemies.append({"node": enemy, "hp": 12 if is_boss_wave else (3 if wave == 2 else 2), "attack": 0.0, "boss": is_boss_wave})

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(290, 94)
	hud_layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	hud_label = Label.new()
	hud_label.text = "LAST COMMAND  |  OPERATION: FIRST STRIKE"
	hud_label.add_theme_font_size_override("font_size", 17)
	column.add_child(hud_label)
	health_label = Label.new()
	column.add_child(health_label)
	ammo_label = Label.new()
	column.add_child(ammo_label)
	status_label = Label.new()
	status_label.text = "يسار: حركة  |  اسحب يمين: تصويب  |  FIRE: إطلاق"
	column.add_child(status_label)

	hit_marker_label = Label.new()
	hit_marker_label.text = "✕"
	hit_marker_label.visible = false
	hit_marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hit_marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hit_marker_label.add_theme_font_size_override("font_size", 42)
	hit_marker_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.18))
	hit_marker_label.anchor_left = 0.5
	hit_marker_label.anchor_top = 0.5
	hit_marker_label.anchor_right = 0.5
	hit_marker_label.anchor_bottom = 0.5
	hit_marker_label.offset_left = -24
	hit_marker_label.offset_top = -34
	hit_marker_label.offset_right = 24
	hit_marker_label.offset_bottom = 10
	hud_layer.add_child(hit_marker_label)

	aim_reticle_label = Label.new()
	aim_reticle_label.text = "+"
	aim_reticle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aim_reticle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aim_reticle_label.add_theme_font_size_override("font_size", 30)
	aim_reticle_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.82, 0.78))
	aim_reticle_label.anchor_left = 0.5
	aim_reticle_label.anchor_top = 0.5
	aim_reticle_label.anchor_right = 0.5
	aim_reticle_label.anchor_bottom = 0.5
	aim_reticle_label.offset_left = -12
	aim_reticle_label.offset_top = -18
	aim_reticle_label.offset_right = 12
	aim_reticle_label.offset_bottom = 18
	hud_layer.add_child(aim_reticle_label)

	fire_button = Button.new()
	fire_button.text = "FIRE"
	fire_button.custom_minimum_size = Vector2(112, 76)
	fire_button.anchor_left = 1.0
	fire_button.anchor_top = 1.0
	fire_button.anchor_right = 1.0
	fire_button.anchor_bottom = 1.0
	fire_button.offset_left = -142
	fire_button.offset_top = -112
	fire_button.offset_right = -22
	fire_button.offset_bottom = -24
	fire_button.add_theme_font_size_override("font_size", 23)
	fire_button.pressed.connect(_shoot)
	hud_layer.add_child(fire_button)

	reload_button = Button.new()
	reload_button.text = "RELOAD"
	reload_button.custom_minimum_size = Vector2(112, 54)
	reload_button.anchor_left = 1.0
	reload_button.anchor_top = 1.0
	reload_button.anchor_right = 1.0
	reload_button.anchor_bottom = 1.0
	reload_button.offset_left = -142
	reload_button.offset_top = -178
	reload_button.offset_right = -22
	reload_button.offset_bottom = -118
	reload_button.pressed.connect(_start_reload)
	hud_layer.add_child(reload_button)

	back_button = Button.new()
	back_button.text = "العودة للقاعدة"
	back_button.position = Vector2(20, 126)
	back_button.custom_minimum_size = Vector2(150, 48)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/base_preview.tscn"))
	hud_layer.add_child(back_button)

func _process(delta: float) -> void:
	if mission_finished:
		return
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if hit_marker_timer > 0.0:
		hit_marker_timer = maxf(0.0, hit_marker_timer - delta)
		if hit_marker_timer == 0.0 and hit_marker_label != null:
			hit_marker_label.visible = false
	if reload_timer > 0.0:
		reload_timer = maxf(0.0, reload_timer - delta)
		if reload_timer == 0.0:
			var loaded := mini(MAGAZINE_SIZE - ammo, reserve_ammo)
			ammo += loaded
			reserve_ammo -= loaded
			status_label.text = "تم تلقيم السلاح"
	enemy_attack_cooldown = maxf(0.0, enemy_attack_cooldown - delta)
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var movement := keyboard
	if joystick_vector.length() > 0.08:
		movement = joystick_vector
	var target_velocity := movement * 6.0
	var response := 10.0 if movement.length() > 0.08 else 14.0
	movement_velocity = movement_velocity.lerp(target_velocity, 1.0 - exp(-response * delta))
	player_position.x += movement_velocity.x * delta
	player_position.z += movement_velocity.y * delta
	player_position.x = clampf(player_position.x, -ARENA_LIMIT, ARENA_LIMIT)
	player_position.z = clampf(player_position.z, -ARENA_LIMIT, ARENA_LIMIT)
	player_root.position = player_position
	_play_commander_animation("sprint" if movement.length() > 0.1 else "idle")
	if movement.length() > 0.1 and (aim_touch == -1 or aim_vector.length() <= 0.12):
		var move_yaw := atan2(movement.x, movement.y)
		player_root.rotation.y = lerp_angle(player_root.rotation.y, move_yaw, 1.0 - exp(-12.0 * delta))
	_update_camera()
	_update_enemies(delta)
	_update_bullets(delta)
	if Input.is_action_pressed("ui_accept"):
		_shoot()
	_update_hud()

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var entry := enemies[i]
		var enemy: Node3D = entry["node"]
		if not is_instance_valid(enemy):
			enemies.remove_at(i)
			continue
		var direction := player_position - enemy.position
		direction.y = 0
		var distance := direction.length()
		if distance > 1.25:
			enemy.position += direction.normalized() * 1.65 * delta
			enemy.look_at(Vector3(player_position.x, enemy.position.y, player_position.z), Vector3.UP)
		else:
			var attack_timer := maxf(0.0, float(entry.get("attack", 0.0)) - delta)
			if attack_timer <= 0.0:
				player_health = maxf(0.0, player_health - maxf(3.0, 8.0 - float(tower_level - 1)))
				entry["attack"] = 0.8
			else:
				entry["attack"] = attack_timer
			enemies[i] = entry
			if player_health <= 0.0:
				_finish_mission(false)

func _shoot() -> void:
	if mission_finished or fire_cooldown > 0.0 or reload_timer > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	fire_cooldown = 0.28
	# Fire along the commander's facing direction; aiming is controlled by dragging on the right side.
	var direction := -player_root.global_transform.basis.z
	direction.y = 0.0
	direction = direction.normalized()
	if direction.length_squared() < 0.01:
		direction = Vector3(0, 0, -1)
	var bullet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	bullet.mesh = sphere
	bullet.material_override = _material(Color(1.0, 0.72, 0.22), true)
	bullet.position = player_position + Vector3.UP * 1.1 + direction * 0.8
	add_child(bullet)
	bullets.append({"node": bullet, "direction": direction, "life": 2.2})

func _start_reload() -> void:
	if mission_finished or reload_timer > 0.0 or ammo >= MAGAZINE_SIZE or reserve_ammo <= 0:
		return
	reload_timer = 1.45
	status_label.text = "جاري تلقيم السلاح..."

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet_data := bullets[i]
		var bullet: Node3D = bullet_data["node"]
		bullet_data["life"] = float(bullet_data["life"]) - delta
		bullet.position += bullet_data["direction"] * 22.0 * delta
		var hit := false
		for j in range(enemies.size() - 1, -1, -1):
			var entry := enemies[j]
			var enemy: Node3D = entry["node"]
			if is_instance_valid(enemy) and bullet.position.distance_to(enemy.position + Vector3.UP * 0.8) < 0.85:
				if hit_marker_label != null:
					hit_marker_label.text = "BOSS HIT" if bool(entry.get("boss", false)) else "✕"
					hit_marker_label.visible = true
					hit_marker_timer = 0.35
				entry["hp"] = int(entry["hp"]) - (1 + barracks_level - 1)
				if int(entry["hp"]) <= 0:
					enemy.queue_free()
					enemies.remove_at(j)
					kills += 1
				else:
					enemies[j] = entry
				hit = true
				break
		if hit or float(bullet_data["life"]) <= 0.0:
			bullet.queue_free()
			bullets.remove_at(i)
		else:
			bullets[i] = bullet_data
	if enemies.is_empty() and not mission_finished:
		if current_wave < WAVE_COUNTS.size():
			current_wave += 1
			status_label.text = "WAVE %d INCOMING!" % current_wave
			_spawn_wave(current_wave)
		else:
			_finish_mission(true)

func _finish_mission(won: bool) -> void:
	mission_finished = true
	fire_button.disabled = true
	if reload_button != null:
		reload_button.disabled = true
	status_label.text = "MISSION COMPLETE!  +%d COINS" % mission_reward if won else "MISSION FAILED — حاول مرة أخرى"
	if won:
		var config := ConfigFile.new()
		config.load("user://progress.cfg")
		var coins := int(config.get_value("progress", "coins", 500)) + mission_reward
		config.set_value("progress", "coins", coins)
		config.set_value("progress", "missions_won", int(config.get_value("progress", "missions_won", 0)) + 1)
		config.save("user://progress.cfg")
	var again := Button.new()
	again.text = "العودة إلى القاعدة"
	again.position = Vector2(18, 190)
	again.custom_minimum_size = Vector2(190, 54)
	again.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/base_preview.tscn"))
	if hud_layer != null:
		hud_layer.add_child(again)

func _update_camera() -> void:
	if camera == null:
		return
	camera.position = player_position + Vector3(0, 11, 13)
	camera.look_at(player_position + Vector3(0, 0.7, 0), Vector3.UP)

func _update_hud() -> void:
	if health_label == null:
		return
	health_label.text = "WAVE %d/3   |   الصحة: %d/%d   |   الأعداء: %d   |   القتلى: %d" % [current_wave, int(player_health), int(max_player_health), enemies.size(), kills]
	if ammo_label != null:
		var boss_text := ""
		for entry in enemies:
			if bool(entry.get("boss", false)):
				boss_text = "   |   BOSS HP: %d/12" % int(entry["hp"])
				break
		ammo_label.text = "الذخيرة: %d/%d   |   الاحتياطي: %d%s" % [ammo, MAGAZINE_SIZE, reserve_ammo, boss_text]

func _is_hud_control_at(position: Vector2) -> bool:
	for control in [fire_button, reload_button, back_button]:
		if control != null and is_instance_valid(control) and control.get_global_rect().has_point(position):
			return true
	return false

func _input(event: InputEvent) -> void:
	var screen_mid := get_viewport().get_visible_rect().size.x * 0.52
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_hud_control_at(event.position):
				return
			if event.position.x < screen_mid and joystick_touch == -1:
				joystick_touch = event.index
				joystick_origin = event.position
				joystick_vector = Vector2.ZERO
			elif event.position.x >= screen_mid and aim_touch == -1:
				aim_touch = event.index
				aim_origin = event.position
				aim_vector = Vector2.ZERO
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				joystick_vector = Vector2.ZERO
			if event.index == aim_touch:
				aim_touch = -1
				aim_vector = Vector2.ZERO
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			joystick_vector = ((event.position - joystick_origin) / 58.0).limit_length(1.0)
		elif event.index == aim_touch and not _is_hud_control_at(event.position):
			aim_vector = ((event.position - aim_origin) / 90.0).limit_length(1.0)
			if aim_vector.length() > 0.12:
				player_root.rotation.y = atan2(aim_vector.x, -aim_vector.y)

func _add_box(label: String, at: Vector3, dimensions: Vector3, tint: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.name = label
	mesh_instance.material_override = _material(tint)
	add_child(mesh_instance)

func _material(tint: Color, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.78
	if glow:
		mat.emission_enabled = true
		mat.emission = tint
		mat.emission_energy_multiplier = 1.8
	return mat
