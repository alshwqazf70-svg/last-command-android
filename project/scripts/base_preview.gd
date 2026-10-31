extends Node3D

var camera: Camera3D
var camera_yaw := 0.0
var camera_pitch := -0.48
var camera_distance := 25.0
var drag_sensitivity := 0.008
var dragging := false

func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_base()
	_build_hud()
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

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		dragging = event.pressed
	elif event is InputEventScreenDrag and dragging:
		camera_yaw -= event.relative.x * drag_sensitivity
		camera_pitch = clamp(camera_pitch - event.relative.y * drag_sensitivity, -0.95, -0.18)
		_update_camera()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		camera_yaw -= event.relative.x * drag_sensitivity
		camera_pitch = clamp(camera_pitch - event.relative.y * drag_sensitivity, -0.95, -0.18)
		_update_camera()
