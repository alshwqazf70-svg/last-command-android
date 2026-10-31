extends Node3D

const MOVE_SPEED := 7.0
const BUILD_COST := 25
const WORLD_LIMIT := 42.0

var player: CharacterBody3D
var camera: Camera3D
var coins := 120
var population := 0
var buildings := 0
var held := {"forward": false, "back": false, "left": false, "right": false}
var hud_label: Label
var message_label: Label
var building_root: Node3D
var army_count := 0
var enemies: Array[Node3D] = []
var soldiers: Array[MeshInstance3D] = []
var combat_timer := 0.0
var has_barracks := false
var city_health := 100
var wave_number := 0
var archer_count := 0
var soldier_kinds: Array[String] = []
var towers: Array[Node3D] = []
var has_walls := false
var wood := 100
var iron := 60
var food := 100
var sawmills := 0
var iron_mines := 0
var farms := 0
var production_timer := 0.0
var barracks_level := 1
var autosave_timer := 0.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
	_load_game()
	_spawn_enemy(Vector3(9, 0, 8))
	_spawn_enemy(Vector3(-13, 0, 16))
	_update_hud()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var direction := Vector3.ZERO
	if held.forward or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.z -= 1.0
	if held.back or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.z += 1.0
	if held.left or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if held.right or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	direction = direction.normalized()
	var movement := Vector3(direction.x, 0, direction.z)
	player.velocity.x = movement.x * MOVE_SPEED
	player.velocity.z = movement.z * MOVE_SPEED
	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	else:
		player.velocity.y = -0.2
	player.move_and_slide()
	player.global_position.x = clampf(player.global_position.x, -WORLD_LIMIT, WORLD_LIMIT)
	player.global_position.z = clampf(player.global_position.z, -WORLD_LIMIT, WORLD_LIMIT)
	if movement.length() > 0.05:
		player.rotation.y = atan2(-movement.x, -movement.z)
	camera.global_position = camera.global_position.lerp(player.global_position + Vector3(0, 8, 11), minf(delta * 5.0, 1.0))
	camera.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	_update_soldiers()
	_update_enemies(delta)
	combat_timer -= delta
	if combat_timer <= 0.0:
		combat_timer = 1.0
		_soldiers_attack()
		_towers_attack()
	autosave_timer += delta
	if autosave_timer >= 30.0:
		autosave_timer = 0.0
		_save_game()
	production_timer += delta
	if production_timer >= 10.0:
		production_timer -= 10.0
		wood += sawmills * 8
		iron += iron_mines * 5
		food += farms * 10
		if sawmills + iron_mines + farms > 0:
			_update_hud()
			_save_game()

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.48, 0.70, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.8
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = false
	add_child(sun)

	var ground_body := StaticBody3D.new()
	ground_body.position = Vector3(0, -0.3, 0)
	add_child(ground_body)
	var ground_mesh := _make_box(Vector3(100, 0.5, 100), Vector3.ZERO, Color(0.25, 0.43, 0.25))
	ground_body.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(100, 0.5, 100)
	ground_collision.shape = ground_shape
	ground_body.add_child(ground_collision)
	building_root = Node3D.new()
	building_root.name = "City"
	add_child(building_root)

	# A simple road grid and starter district.
	for i in range(-3, 4):
		_add_box(building_root, Vector3(3.2, 0.06, 92), Vector3(i * 12.0, -0.015, 0), Color(0.16, 0.18, 0.20))
		_add_box(building_root, Vector3(92, 0.06, 3.2), Vector3(0, -0.01, i * 12.0), Color(0.16, 0.18, 0.20))
	for x in range(-2, 3):
		for z in range(-2, 3):
			if abs(x) + abs(z) > 1:
				_create_building(Vector3(x * 12.0 + 5.0, 0, z * 12.0 + 5.0), false)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Commander"
	player.position = Vector3(0, 1.2, 0)
	add_child(player)

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var visual := MeshInstance3D.new()
	visual.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.38, 0.82)
	visual.material_override = material
	visual.position.y = 0.9
	player.add_child(visual)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	player.add_child(collision)

	camera = Camera3D.new()
	camera.position = Vector3(0, 8, 11)
	camera.fov = 62
	add_child(camera)
	camera.current = true
	camera.look_at(player.global_position, Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(440, 122)
	layer.add_child(panel)
	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(hud_label)

	message_label = Label.new()
	message_label.position = Vector2(18, 110)
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.text = "مرحباً أيها القائد! ابدأ بتوسيع مدينتك."
	layer.add_child(message_label)

	var save_button := Button.new()
	save_button.text = "💾 حفظ"
	save_button.position = Vector2(-205, 16)
	save_button.anchor_left = 1.0
	save_button.anchor_right = 1.0
	save_button.custom_minimum_size = Vector2(90, 44)
	save_button.pressed.connect(_on_save_pressed)
	layer.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "📂 تحميل"
	load_button.position = Vector2(-305, 16)
	load_button.anchor_left = 1.0
	load_button.anchor_right = 1.0
	load_button.custom_minimum_size = Vector2(90, 44)
	load_button.pressed.connect(_on_load_pressed)
	layer.add_child(load_button)

	var build_button := Button.new()
	build_button.text = "🏠 بناء منزل (25)"
	build_button.position = Vector2(-210, -82)
	build_button.anchor_left = 1.0
	build_button.anchor_right = 1.0
	build_button.anchor_top = 1.0
	build_button.anchor_bottom = 1.0
	build_button.custom_minimum_size = Vector2(190, 58)
	build_button.pressed.connect(_on_build_pressed)
	layer.add_child(build_button)

	var recruit_button := Button.new()
	recruit_button.text = "🛡️ تجنيد جندي (40)"
	recruit_button.position = Vector2(-400, -82)
	recruit_button.anchor_left = 1.0
	recruit_button.anchor_right = 1.0
	recruit_button.anchor_top = 1.0
	recruit_button.anchor_bottom = 1.0
	recruit_button.custom_minimum_size = Vector2(180, 58)
	recruit_button.pressed.connect(_on_recruit_pressed)
	layer.add_child(recruit_button)

	var barracks_button := Button.new()
	barracks_button.text = "🏰 بناء ثكنة (100)"
	barracks_button.position = Vector2(-590, -82)
	barracks_button.anchor_left = 1.0
	barracks_button.anchor_right = 1.0
	barracks_button.anchor_top = 1.0
	barracks_button.anchor_bottom = 1.0
	barracks_button.custom_minimum_size = Vector2(180, 58)
	barracks_button.pressed.connect(_on_barracks_pressed)
	layer.add_child(barracks_button)

	var wave_button := Button.new()
	wave_button.text = "🚨 موجة أعداء"
	wave_button.position = Vector2(-400, -150)
	wave_button.anchor_left = 1.0
	wave_button.anchor_right = 1.0
	wave_button.anchor_top = 1.0
	wave_button.anchor_bottom = 1.0
	wave_button.custom_minimum_size = Vector2(180, 54)
	wave_button.pressed.connect(_on_wave_pressed)
	layer.add_child(wave_button)

	var archer_button := Button.new()
	archer_button.text = "🏹 رامي (60)"
	archer_button.position = Vector2(-590, -150)
	archer_button.anchor_left = 1.0
	archer_button.anchor_right = 1.0
	archer_button.anchor_top = 1.0
	archer_button.anchor_bottom = 1.0
	archer_button.custom_minimum_size = Vector2(180, 54)
	archer_button.pressed.connect(_on_archer_pressed)
	layer.add_child(archer_button)

	var tower_button := Button.new()
	tower_button.text = "🗼 برج (120)"
	tower_button.position = Vector2(-800, -82)
	tower_button.anchor_left = 1.0
	tower_button.anchor_right = 1.0
	tower_button.anchor_top = 1.0
	tower_button.anchor_bottom = 1.0
	tower_button.custom_minimum_size = Vector2(180, 58)
	tower_button.pressed.connect(_on_tower_pressed)
	layer.add_child(tower_button)

	var wall_button := Button.new()
	wall_button.text = "🧱 سور (150)"
	wall_button.position = Vector2(-800, -150)
	wall_button.anchor_left = 1.0
	wall_button.anchor_right = 1.0
	wall_button.anchor_top = 1.0
	wall_button.anchor_bottom = 1.0
	wall_button.custom_minimum_size = Vector2(180, 54)
	wall_button.pressed.connect(_on_walls_pressed)
	layer.add_child(wall_button)

	var sawmill_button := Button.new()
	sawmill_button.text = "🪵 منشرة (60 + 20 خشب)"
	sawmill_button.position = Vector2(-800, -220)
	sawmill_button.anchor_left = 1.0
	sawmill_button.anchor_right = 1.0
	sawmill_button.anchor_top = 1.0
	sawmill_button.anchor_bottom = 1.0
	sawmill_button.custom_minimum_size = Vector2(190, 54)
	sawmill_button.pressed.connect(_on_sawmill_pressed)
	layer.add_child(sawmill_button)

	var mine_button := Button.new()
	mine_button.text = "⛏️ منجم (80 + 20 خشب)"
	mine_button.position = Vector2(-600, -220)
	mine_button.anchor_left = 1.0
	mine_button.anchor_right = 1.0
	mine_button.anchor_top = 1.0
	mine_button.anchor_bottom = 1.0
	mine_button.custom_minimum_size = Vector2(190, 54)
	mine_button.pressed.connect(_on_iron_mine_pressed)
	layer.add_child(mine_button)

	var farm_button := Button.new()
	farm_button.text = "🌾 مزرعة (50 + 15 خشب)"
	farm_button.position = Vector2(-400, -220)
	farm_button.anchor_left = 1.0
	farm_button.anchor_right = 1.0
	farm_button.anchor_top = 1.0
	farm_button.anchor_bottom = 1.0
	farm_button.custom_minimum_size = Vector2(190, 54)
	farm_button.pressed.connect(_on_farm_pressed)
	layer.add_child(farm_button)

	var upgrade_button := Button.new()
	upgrade_button.text = "⬆️ ترقية الثكنة"
	upgrade_button.position = Vector2(-200, -220)
	upgrade_button.anchor_left = 1.0
	upgrade_button.anchor_right = 1.0
	upgrade_button.anchor_top = 1.0
	upgrade_button.anchor_bottom = 1.0
	upgrade_button.custom_minimum_size = Vector2(190, 54)
	upgrade_button.pressed.connect(_on_barracks_upgrade_pressed)
	layer.add_child(upgrade_button)

	var attack_button := Button.new()
	attack_button.text = "⚔️ هجوم"
	attack_button.position = Vector2(-210, -150)
	attack_button.anchor_left = 1.0
	attack_button.anchor_right = 1.0
	attack_button.anchor_top = 1.0
	attack_button.anchor_bottom = 1.0
	attack_button.custom_minimum_size = Vector2(190, 54)
	attack_button.pressed.connect(_on_attack_pressed)
	layer.add_child(attack_button)

	_add_move_button(layer, "▲", "forward", Vector2(95, -190))
	_add_move_button(layer, "▼", "back", Vector2(95, -70))
	_add_move_button(layer, "◀", "left", Vector2(25, -130))
	_add_move_button(layer, "▶", "right", Vector2(165, -130))

func _add_move_button(layer: CanvasLayer, caption: String, action: String, offset: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.position = offset
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.custom_minimum_size = Vector2(62, 58)
	button.button_down.connect(_set_held.bind(action, true))
	button.button_up.connect(_set_held.bind(action, false))
	layer.add_child(button)

func _set_held(action: String, value: bool) -> void:
	held[action] = value

func _on_build_pressed() -> void:
	if coins < BUILD_COST:
		message_label.text = "لا توجد عملات كافية. اجمع الموارد أولاً."
		return
	coins -= BUILD_COST
	buildings += 1
	population += 4
	var angle := float(buildings) * 2.399
	var distance := 8.0 + float(buildings % 5) * 2.2
	var location := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	_create_building(location, true)
	message_label.text = "تم بناء منزل جديد! ازداد عدد السكان."
	_update_hud()
	_save_game()

func _create_building(at: Vector3, is_new: bool) -> void:
	var height := randf_range(3.5, 7.5) if is_new else randf_range(4.0, 10.0)
	var width := randf_range(3.0, 4.5)
	var colors := [Color(0.78, 0.67, 0.52), Color(0.62, 0.70, 0.76), Color(0.78, 0.78, 0.69), Color(0.68, 0.57, 0.48)]
	var body := _make_box(Vector3(width, height, width), at + Vector3(0, height / 2.0, 0), colors[randi() % colors.size()])
	building_root.add_child(body)
	var roof := _make_box(Vector3(width + 0.2, 0.25, width + 0.2), at + Vector3(0, height + 0.12, 0), Color(0.25, 0.30, 0.36))
	building_root.add_child(roof)

func _make_box(size: Vector3, at: Vector3, tint: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.82
	mesh_instance.material_override = material
	return mesh_instance

func _add_box(parent: Node3D, size: Vector3, at: Vector3, tint: Color) -> void:
	parent.add_child(_make_box(size, at, tint))

func _update_hud() -> void:
	hud_label.text = "LAST COMMAND | القائد\n💰 %d  🪵 %d  ⛓️ %d  🌾 %d\n🏠 %d  👥 %d  🛡️ %d/%d (🏹 %d)\n❤️ %d  🌊 %d  🏰 Lv.%d  🧱 %s  🗼 %d\nالإنتاج كل 10 ثوانٍ: خشب +%d | حديد +%d | غذاء +%d" % [coins, wood, iron, food, buildings, population, army_count, _army_limit(), archer_count, city_health, wave_number, barracks_level if has_barracks else 0, "نعم" if has_walls else "لا", towers.size(), sawmills * 8, iron_mines * 5, farms * 10]

func _on_barracks_pressed() -> void:
	if has_barracks:
		message_label.text = "الثكنة جاهزة بالفعل. الحد الأقصى للجيش ارتفع إلى 20."
		return
	if coins < 100:
		message_label.text = "تحتاج إلى 100 عملة لبناء الثكنة."
		return
	coins -= 100
	has_barracks = true
	var barracks := _make_box(Vector3(6.0, 2.8, 5.0), Vector3(18, 1.4, -18), Color(0.42, 0.38, 0.30))
	building_root.add_child(barracks)
	var roof := _make_box(Vector3(6.3, 0.35, 5.3), Vector3(18, 2.95, -18), Color(0.24, 0.27, 0.30))
	building_root.add_child(roof)
	message_label.text = "تم إنشاء الثكنة! أصبح بإمكانك تجنيد 20 جندياً."
	_update_hud()
	_save_game()

func _on_wave_pressed() -> void:
	wave_number += 1
	var count := mini(2 + wave_number, 8)
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		var spawn_at := player.global_position + Vector3(cos(angle) * 18.0, 0, sin(angle) * 18.0)
		spawn_at.x = clampf(spawn_at.x, -WORLD_LIMIT + 2.0, WORLD_LIMIT - 2.0)
		spawn_at.z = clampf(spawn_at.z, -WORLD_LIMIT + 2.0, WORLD_LIMIT - 2.0)
		_spawn_enemy(spawn_at)
	message_label.text = "بدأت الموجة %d! عدد المغيرين: %d" % [wave_number, count]
	_update_hud()
	_save_game()

func _on_archer_pressed() -> void:
	if not has_barracks:
		message_label.text = "ابنِ الثكنة أولاً لتجنيد الرماة."
		return
	if coins < 60 or food < 3:
		message_label.text = "تحتاج إلى 60 عملة و3 غذاء لتجنيد رامٍ."
		return
	if army_count >= _army_limit():
		message_label.text = "وصلت إلى الحد الأقصى للجيش."
		return
	coins -= 60
	food -= 3
	army_count += 1
	archer_count += 1
	_add_soldier_visual("archer")
	message_label.text = "تم تجنيد رامٍ! مدى هجومه أكبر من المشاة."
	_update_hud()
	_save_game()

func _add_soldier_visual(kind: String) -> void:
	var soldier_mesh := CapsuleMesh.new()
	soldier_mesh.radius = 0.28 if kind == "infantry" else 0.24
	soldier_mesh.height = 1.25 if kind == "infantry" else 1.1
	var soldier := MeshInstance3D.new()
	soldier.mesh = soldier_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.72, 0.38) if kind == "infantry" else Color(0.82, 0.68, 0.20)
	soldier.material_override = material
	add_child(soldier)
	soldiers.append(soldier)
	soldier_kinds.append(kind)

func _on_recruit_pressed() -> void:
	const RECRUIT_COST := 40
	if not has_barracks:
		message_label.text = "ابنِ الثكنة أولاً لتجنيد الجنود."
		return
	if coins < RECRUIT_COST or food < 2:
		message_label.text = "تحتاج إلى 40 عملة و2 غذاء لتجنيد جندي."
		return
	if army_count >= _army_limit():
		message_label.text = "وصلت إلى الحد الأقصى للجيش."
		return
	coins -= RECRUIT_COST
	food -= 2
	army_count += 1
	_add_soldier_visual("infantry")
	message_label.text = "تم تجنيد جندي جديد. جنودك يحمون القائد تلقائياً."
	_update_hud()
	_save_game()

func _on_tower_pressed() -> void:
	if coins < 120:
		message_label.text = "تحتاج إلى 120 عملة لبناء برج دفاعي."
		return
	if towers.size() >= 4:
		message_label.text = "يمكنك بناء أربعة أبراج في هذه المرحلة."
		return
	coins -= 120
	var slot := towers.size()
	var positions := [Vector3(-24, 0, -24), Vector3(24, 0, -24), Vector3(-24, 0, 24), Vector3(24, 0, 24)]
	var base := _make_box(Vector3(3.0, 4.0, 3.0), positions[slot] + Vector3(0, 2.0, 0), Color(0.48, 0.49, 0.52))
	building_root.add_child(base)
	var top := _make_box(Vector3(3.6, 0.6, 3.6), positions[slot] + Vector3(0, 4.3, 0), Color(0.25, 0.30, 0.36))
	building_root.add_child(top)
	towers.append(base)
	message_label.text = "تم بناء برج دفاعي! يهاجم الأعداء القريبين تلقائياً."
	_update_hud()
	_save_game()

func _on_walls_pressed() -> void:
	if has_walls:
		message_label.text = "أسوار المدينة مبنية بالفعل."
		return
	if coins < 150:
		message_label.text = "تحتاج إلى 150 عملة لبناء الأسوار."
		return
	coins -= 150
	has_walls = true
	_add_box(building_root, Vector3(48, 2.2, 1.0), Vector3(0, 1.1, -25), Color(0.42, 0.44, 0.46))
	_add_box(building_root, Vector3(48, 2.2, 1.0), Vector3(0, 1.1, 25), Color(0.42, 0.44, 0.46))
	_add_box(building_root, Vector3(1.0, 2.2, 48), Vector3(-25, 1.1, 0), Color(0.42, 0.44, 0.46))
	_add_box(building_root, Vector3(1.0, 2.2, 48), Vector3(25, 1.1, 0), Color(0.42, 0.44, 0.46))
	message_label.text = "اكتمل سور المدينة التجريبي حول المنطقة المركزية."
	_update_hud()
	_save_game()

func _on_save_pressed() -> void:
	_save_game()
	message_label.text = "تم حفظ تقدم المدينة على هذا الجهاز."

func _on_load_pressed() -> void:
	get_tree().reload_current_scene()

func _save_game() -> void:
	var data := ConfigFile.new()
	data.set_value("city", "coins", coins)
	data.set_value("city", "wood", wood)
	data.set_value("city", "iron", iron)
	data.set_value("city", "food", food)
	data.set_value("city", "population", population)
	data.set_value("city", "buildings", buildings)
	data.set_value("city", "sawmills", sawmills)
	data.set_value("city", "iron_mines", iron_mines)
	data.set_value("city", "farms", farms)
	data.set_value("city", "has_barracks", has_barracks)
	data.set_value("city", "barracks_level", barracks_level)
	data.set_value("city", "city_health", city_health)
	data.set_value("city", "wave_number", wave_number)
	data.set_value("city", "has_walls", has_walls)
	data.set_value("city", "army_count", army_count)
	data.set_value("city", "archer_count", archer_count)
	data.set_value("city", "soldier_kinds", soldier_kinds)
	data.set_value("city", "tower_count", towers.size())
	if is_instance_valid(player):
		data.set_value("city", "player_position", player.global_position)
	var error := data.save("user://last_command_save.cfg")
	if error != OK:
		push_warning("Could not save city progress. Error: %s" % error)

func _load_game() -> void:
	var data := ConfigFile.new()
	if data.load("user://last_command_save.cfg") != OK:
		return
	coins = maxi(0, int(data.get_value("city", "coins", coins)))
	wood = maxi(0, int(data.get_value("city", "wood", wood)))
	iron = maxi(0, int(data.get_value("city", "iron", iron)))
	food = maxi(0, int(data.get_value("city", "food", food)))
	population = maxi(0, int(data.get_value("city", "population", population)))
	buildings = clampi(int(data.get_value("city", "buildings", buildings)), 0, 500)
	sawmills = clampi(int(data.get_value("city", "sawmills", sawmills)), 0, 20)
	iron_mines = clampi(int(data.get_value("city", "iron_mines", iron_mines)), 0, 20)
	farms = clampi(int(data.get_value("city", "farms", farms)), 0, 20)
	has_barracks = bool(data.get_value("city", "has_barracks", has_barracks))
	barracks_level = clampi(int(data.get_value("city", "barracks_level", barracks_level)), 1, 2)
	city_health = clampi(int(data.get_value("city", "city_health", city_health)), 0, 100)
	wave_number = maxi(0, int(data.get_value("city", "wave_number", wave_number)))
	has_walls = bool(data.get_value("city", "has_walls", has_walls))
	var saved_kinds: Array = data.get_value("city", "soldier_kinds", [])
	soldier_kinds.clear()
	soldiers.clear()
	army_count = 0
	archer_count = 0
	for kind_value in saved_kinds:
		var kind := str(kind_value)
		if kind == "infantry" or kind == "archer":
			_add_soldier_visual(kind)
			army_count += 1
			if kind == "archer":
				archer_count += 1
	if is_instance_valid(player):
		var saved_position: Variant = data.get_value("city", "player_position", player.global_position)
		if saved_position is Vector3:
			player.global_position = saved_position
	_restore_saved_city_visuals(int(data.get_value("city", "tower_count", 0)))

func _restore_saved_city_visuals(tower_count: int) -> void:
	for i in range(buildings):
		var angle := float(i + 1) * 2.399
		var distance := 8.0 + float((i + 1) % 5) * 2.2
		_create_building(Vector3(cos(angle) * distance, 0, sin(angle) * distance), false)
	for i in range(sawmills):
		var at := Vector3(-18 + float(i) * 5.0, 0, -8)
		_add_box(building_root, Vector3(4.5, 2.8, 3.5), at + Vector3(0, 1.4, 0), Color(0.48, 0.31, 0.18))
		_add_box(building_root, Vector3(4.8, 0.25, 3.8), at + Vector3(0, 2.9, 0), Color(0.28, 0.20, 0.14))
	for i in range(iron_mines):
		var at := Vector3(18 - float(i) * 5.0, 0, 12)
		_add_box(building_root, Vector3(4.5, 3.2, 4.0), at + Vector3(0, 1.6, 0), Color(0.38, 0.42, 0.46))
		_add_box(building_root, Vector3(2.2, 1.0, 2.2), at + Vector3(0, 3.7, 0), Color(0.25, 0.28, 0.31))
	for i in range(farms):
		var at := Vector3(-18 + float(i) * 5.0, 0, 20)
		_add_box(building_root, Vector3(5.0, 0.35, 5.0), at + Vector3(0, 0.18, 0), Color(0.42, 0.31, 0.16))
		for row in range(4):
			_add_box(building_root, Vector3(0.18, 0.8, 4.2), at + Vector3(-1.8 + float(row) * 1.2, 0.65, 0), Color(0.28, 0.52, 0.20))
	if has_barracks:
		_add_box(building_root, Vector3(6.0, 2.8, 5.0), Vector3(18, 1.4, -18), Color(0.42, 0.38, 0.30))
		_add_box(building_root, Vector3(6.3, 0.35, 5.3), Vector3(18, 2.95, -18), Color(0.24, 0.27, 0.30))
	var positions := [Vector3(-24, 0, -24), Vector3(24, 0, -24), Vector3(-24, 0, 24), Vector3(24, 0, 24)]
	for i in range(clampi(tower_count, 0, 4)):
		var base := _make_box(Vector3(3.0, 4.0, 3.0), positions[i] + Vector3(0, 2.0, 0), Color(0.48, 0.49, 0.52))
		building_root.add_child(base)
		_add_box(building_root, Vector3(3.6, 0.6, 3.6), positions[i] + Vector3(0, 4.3, 0), Color(0.25, 0.30, 0.36))
		towers.append(base)
	if has_walls:
		_add_box(building_root, Vector3(48, 2.2, 1.0), Vector3(0, 1.1, -25), Color(0.42, 0.44, 0.46))
		_add_box(building_root, Vector3(48, 2.2, 1.0), Vector3(0, 1.1, 25), Color(0.42, 0.44, 0.46))
		_add_box(building_root, Vector3(1.0, 2.2, 48), Vector3(-25, 1.1, 0), Color(0.42, 0.44, 0.46))
		_add_box(building_root, Vector3(1.0, 2.2, 48), Vector3(25, 1.1, 0), Color(0.42, 0.44, 0.46))

func _army_limit() -> int:
	return 30 if barracks_level >= 2 else (20 if has_barracks else 8)

func _on_sawmill_pressed() -> void:
	if coins < 60 or wood < 20:
		message_label.text = "تحتاج إلى 60 عملة و20 خشب لبناء المنشرة."
		return
	coins -= 60
	wood -= 20
	sawmills += 1
	var at := Vector3(-18 + float(sawmills - 1) * 5.0, 0, -8)
	_add_box(building_root, Vector3(4.5, 2.8, 3.5), at + Vector3(0, 1.4, 0), Color(0.48, 0.31, 0.18))
	_add_box(building_root, Vector3(4.8, 0.25, 3.8), at + Vector3(0, 2.9, 0), Color(0.28, 0.20, 0.14))
	message_label.text = "بُنيت المنشرة! تنتج 8 خشب كل 10 ثوانٍ."
	_update_hud()
	_save_game()

func _on_iron_mine_pressed() -> void:
	if coins < 80 or wood < 20:
		message_label.text = "تحتاج إلى 80 عملة و20 خشب لبناء منجم الحديد."
		return
	coins -= 80
	wood -= 20
	iron_mines += 1
	var at := Vector3(18 - float(iron_mines - 1) * 5.0, 0, 12)
	_add_box(building_root, Vector3(4.5, 3.2, 4.0), at + Vector3(0, 1.6, 0), Color(0.38, 0.42, 0.46))
	_add_box(building_root, Vector3(2.2, 1.0, 2.2), at + Vector3(0, 3.7, 0), Color(0.25, 0.28, 0.31))
	message_label.text = "بُني منجم الحديد! ينتج 5 حديد كل 10 ثوانٍ."
	_update_hud()
	_save_game()

func _on_farm_pressed() -> void:
	if coins < 50 or wood < 15:
		message_label.text = "تحتاج إلى 50 عملة و15 خشب لبناء المزرعة."
		return
	coins -= 50
	wood -= 15
	farms += 1
	var at := Vector3(-18 + float(farms - 1) * 5.0, 0, 20)
	_add_box(building_root, Vector3(5.0, 0.35, 5.0), at + Vector3(0, 0.18, 0), Color(0.42, 0.31, 0.16))
	for i in range(4):
		_add_box(building_root, Vector3(0.18, 0.8, 4.2), at + Vector3(-1.8 + float(i) * 1.2, 0.65, 0), Color(0.28, 0.52, 0.20))
	message_label.text = "بُنيت المزرعة! تنتج 10 غذاء كل 10 ثوانٍ."
	_update_hud()
	_save_game()

func _on_barracks_upgrade_pressed() -> void:
	if not has_barracks:
		message_label.text = "ابنِ الثكنة أولاً قبل ترقيتها."
		return
	if barracks_level >= 2:
		message_label.text = "الثكنة وصلت إلى أعلى مستوى متاح حالياً."
		return
	if coins < 100 or wood < 40 or iron < 25:
		message_label.text = "ترقية الثكنة تحتاج 100 عملة و40 خشب و25 حديد."
		return
	coins -= 100
	wood -= 40
	iron -= 25
	barracks_level = 2
	message_label.text = "تمت ترقية الثكنة إلى المستوى 2! سقف الجيش أصبح 30."
	_update_hud()
	_save_game()

func _spawn_enemy(at: Vector3) -> void:
	var enemy := Node3D.new()
	enemy.name = "Raider"
	enemy.position = at
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 1.7
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.78, 0.16, 0.13)
	visual.material_override = material
	visual.position.y = 0.85
	enemy.add_child(visual)
	var marker := _make_box(Vector3(1.0, 0.12, 0.16), Vector3(0, 1.9, 0), Color(0.95, 0.12, 0.10))
	enemy.add_child(marker)
	enemy.set_meta("health", 60)
	enemy.set_meta("attack_timer", 1.0)
	add_child(enemy)
	enemies.append(enemy)

func _on_attack_pressed() -> void:
	var target := _nearest_enemy(4.2)
	if target == null:
		message_label.text = "اقترب من العدو حتى يصبح ضمن مدى الهجوم."
		return
	var defeated := _damage_enemy(target, 30)
	if not defeated:
		message_label.text = "ضربة ناجحة! استمر في الدفاع عن مدينتك."
	_update_hud()

func _nearest_enemy(max_distance: float) -> Node3D:
	var nearest: Node3D = null
	var best_distance := max_distance
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance := player.global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = enemy
	return nearest

func _damage_enemy(enemy: Node3D, amount: int) -> bool:
	var health := int(enemy.get_meta("health", 0)) - amount
	if health <= 0:
		enemies.erase(enemy)
		enemy.queue_free()
		coins += 15
		message_label.text = "تم القضاء على المغير! حصلت على 15 عملة."
		_save_game()
		return true
	enemy.set_meta("health", health)
	return false

func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			continue
		var offset: Vector3 = player.global_position - enemy.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		if distance > 1.7:
			enemy.global_position += offset.normalized() * 1.65 * delta
			enemy.look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z), Vector3.UP)
		else:
			var attack_timer := float(enemy.get_meta("attack_timer", 0.0)) - delta
			if attack_timer <= 0.0 and city_health > 0:
				city_health = maxi(city_health - 5, 0)
				_save_game()
				enemy.set_meta("attack_timer", 1.2)
				message_label.text = "المغيرون يهاجمونك! صحة القائد: %d" % city_health
				_update_hud()
			else:
				enemy.set_meta("attack_timer", attack_timer)

func _update_soldiers() -> void:
	for i in range(soldiers.size()):
		if not is_instance_valid(soldiers[i]):
			continue
		var angle := float(i) * TAU / maxf(float(soldiers.size()), 1.0)
		var offset := Vector3(cos(angle) * 2.0, -0.1, sin(angle) * 2.0)
		soldiers[i].global_position = player.global_position + offset

func _soldiers_attack() -> void:
	if soldiers.is_empty():
		return
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			continue
		var total_damage := 0
		var in_range := false
		for kind in soldier_kinds:
			var distance := player.global_position.distance_to(enemy.global_position)
			if kind == "archer" and distance <= 14.0:
				total_damage += 9
				in_range = true
			elif kind == "infantry" and distance <= 9.0:
				total_damage += 5
				in_range = true
		if in_range and total_damage > 0:
			_damage_enemy(enemy, total_damage)
			_update_hud()
			break

func _towers_attack() -> void:
	for tower in towers:
		if not is_instance_valid(tower):
			continue
		for enemy in enemies.duplicate():
			if not is_instance_valid(enemy):
				enemies.erase(enemy)
				continue
			if tower.global_position.distance_to(enemy.global_position) <= 16.0:
				_damage_enemy(enemy, 18)
				_update_hud()
				break
