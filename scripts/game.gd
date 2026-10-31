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

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
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
	panel.custom_minimum_size = Vector2(300, 82)
	layer.add_child(panel)
	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(hud_label)

	message_label = Label.new()
	message_label.position = Vector2(18, 110)
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.text = "مرحباً أيها القائد! ابدأ بتوسيع مدينتك."
	layer.add_child(message_label)

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
	hud_label.text = "LAST COMMAND  |  القائد\n💰 العملات: %d     🏠 المباني: %d     👥 السكان: %d" % [coins, buildings, population]
