extends Node3D

@onready var stations_root: Node3D = $Stations
@onready var walls_root: Node3D = $Walls
@onready var decor_root: Node3D = $Decorations
@onready var chef: ChefPlayer = $ChefPlayer
@onready var level_label: Label = $GameManager/GameHUD/MarginContainer/VBoxContainer/LevelLabel
@onready var floor_mesh: MeshInstance3D = $Floor/MeshInstance3D
@onready var floor_shape: CollisionShape3D = $Floor/CollisionShape3D
@onready var floor_root: StaticBody3D = $Floor
@onready var camera: Camera3D = $Camera3D

const WALL_HEIGHT := 3.5
const PLAY_HALF := 16.5
const FLOOR_SIZE := 36.0
const WALL_INSET := 0.6
const FLOOR_TILE_SIZE := 4.0
# Azul pizarra medio — contrasta con el chef blanco (evita tonos claros/blancos)
const FLOOR_COLOR_A := Color(0.62, 0.48, 0.34)
const FLOOR_COLOR_B := Color(0.74, 0.62, 0.46)
const FLOOR_BORDER_COLOR := Color(0.36, 0.22, 0.13)

const DECO_MESHES: Array[String] = [
	"fridge_A.obj",
	"table_round_A_decorated.obj",
	"table_round_B.obj",
	"chair_A.obj",
	"chair_B.obj",
	"shelf_papertowel_decorated.obj",
	"kitchencabinet.obj",
	"pillar_A.obj",
	"pillar_B.obj",
	"extractorhood.obj",
	"menu.obj",
	"stew_pot.obj",
]


func _ready() -> void:
	var level_id := GameState.selected_level
	var layout := LevelLayouts.get_layout(level_id)
	_setup_floor()
	_setup_lighting()
	_build_stations(layout.get("stations", []))
	_build_boundary_walls()
	_build_extra_walls(layout.get("walls", []))
	_build_decorations(level_id)
	var spawn: Vector3 = layout.get("spawn", Vector3(3, 1, 2))
	spawn.y = 1.0
	_place_player(spawn)
	if chef:
		chef.configure_level_bounds(PLAY_HALF, spawn)
	if level_label:
		level_label.text = "Nivel %d: %s" % [level_id, layout.get("name", "")]
	if camera:
		camera.size = 24.0


func _setup_floor() -> void:
	if floor_shape and floor_shape.shape is BoxShape3D:
		(floor_shape.shape as BoxShape3D).size = Vector3(FLOOR_SIZE, 0.2, FLOOR_SIZE)

	if floor_mesh:
		var base := BoxMesh.new()
		base.size = Vector3(FLOOR_SIZE, 0.12, FLOOR_SIZE)
		floor_mesh.mesh = base
		floor_mesh.transform = Transform3D.IDENTITY
		floor_mesh.position.y = -0.02
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = FLOOR_COLOR_A
		base_mat.roughness = 0.92
		floor_mesh.material_override = base_mat

	_build_floor_checker()
	_build_floor_border()


func _setup_lighting() -> void:
	var env_node: WorldEnvironment = $WorldEnvironment as WorldEnvironment
	if env_node == null:
		return
	if env_node.environment:
		env_node.environment = env_node.environment.duplicate()
	else:
		env_node.environment = Environment.new()
	var env: Environment = env_node.environment
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.82, 0.68)
	env.ambient_light_energy = 1.25
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.35, 0.29)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.2

	var sun := $DirectionalLight3D
	if sun:
		sun.light_energy = 1.35
		sun.light_color = Color(1.0, 0.86, 0.66)
		sun.shadow_enabled = true

	if not has_node("FillLights"):
		var fills := Node3D.new()
		fills.name = "FillLights"
		add_child(fills)
		var positions := [
			Vector3(-12, 5, -12), Vector3(12, 5, -12),
			Vector3(-12, 5, 12), Vector3(12, 5, 12),
			Vector3(0, 7, 0),
		]
		for p in positions:
			var omni := OmniLight3D.new()
			omni.position = p
			omni.light_energy = 1.8
			omni.light_color = Color(1.0, 0.95, 0.88)
			omni.omni_range = 22.0
			omni.shadow_enabled = false
			fills.add_child(omni)


func _build_stations(station_data: Array) -> void:
	for child in stations_root.get_children():
		child.queue_free()
	await get_tree().process_frame
	for data in station_data:
		var station := StationFactory.build_station(data)
		stations_root.add_child(station)


func _build_decorations(level_id: int) -> void:
	for child in decor_root.get_children():
		child.queue_free()

	var base := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/obj/"
	# Decoracion solo en esquinas lejanas (no tapa estaciones)
	var corners := [
		Vector3(-15.5, 0, -15.5), Vector3(15.5, 0, -15.5),
		Vector3(-15.5, 0, 15.5), Vector3(15.5, 0, 15.5),
	]
	for i in range(corners.size()):
		var mesh_name: String = DECO_MESHES[i % DECO_MESHES.size()]
		_spawn_deco(base + mesh_name, corners[i], 0.85)

	match level_id:
		1:
			_spawn_deco(base + "menu.obj", Vector3(-15, 0, 14), 0.9)
		2:
			_spawn_deco(base + "menu.obj", Vector3(15, 0, 14), 0.9)
		3:
			_spawn_deco(base + "extractorhood.obj", Vector3(0, 0, -15), 0.85)
		4:
			_spawn_deco(base + "pillar_A.obj", Vector3(-15, 0, 0), 1.0)
			_spawn_deco(base + "pillar_B.obj", Vector3(15, 0, 0), 1.0)
		5:
			_spawn_deco(base + "fridge_A.obj", Vector3(-15.5, 0, 8), 0.9)
			_spawn_deco(base + "fridge_A.obj", Vector3(15.5, 0, 8), 0.9)


func _spawn_deco(mesh_path: String, pos: Vector3, scale_mul: float) -> void:
	if not ResourceLoader.exists(mesh_path):
		return
	var mesh: Mesh = load(mesh_path)
	if not mesh:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = Vector3.ONE * scale_mul
	decor_root.add_child(mi)


func _build_boundary_walls() -> void:
	for child in walls_root.get_children():
		child.queue_free()
	var h := WALL_HEIGHT
	var t := 0.5
	var half := PLAY_HALF - WALL_INSET
	_add_wall(Vector3(0, h * 0.5, -half), Vector3(half * 2 + t, h, t), Color(0.62, 0.58, 0.52))
	_add_wall(Vector3(0, h * 0.5, half), Vector3(half * 2 + t, h, t), Color(0.62, 0.58, 0.52))
	_add_wall(Vector3(-half, h * 0.5, 0), Vector3(t, h, half * 2 + t), Color(0.58, 0.55, 0.5))
	_add_wall(Vector3(half, h * 0.5, 0), Vector3(t, h, half * 2 + t), Color(0.58, 0.55, 0.5))


func _build_extra_walls(walls: Array) -> void:
	for w in walls:
		_add_wall(w.get("pos", Vector3.ZERO), w.get("size", Vector3.ONE), Color(0.6, 0.55, 0.5))


func _add_wall(pos: Vector3, size: Vector3, wall_color: Color = Color(0.55, 0.52, 0.48)) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = PhysicsLayers.WORLD
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = wall_color
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	body.add_child(mi)
	walls_root.add_child(body)


func _build_floor_checker() -> void:
	if floor_root == null:
		return
	var pattern := Node3D.new()
	pattern.name = "FloorPattern"
	floor_root.add_child(pattern)

	var half := PLAY_HALF - 1.0
	var tile := FLOOR_TILE_SIZE
	var row := 0
	var z := -half
	while z < half - 0.01:
		var col := 0
		var x := -half
		while x < half - 0.01:
			var tile_mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(tile - 0.08, 0.03, tile - 0.08)
			tile_mesh.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = FLOOR_COLOR_B if (row + col) % 2 == 0 else FLOOR_COLOR_A
			mat.roughness = 0.88
			tile_mesh.material_override = mat
			tile_mesh.position = Vector3(x + tile * 0.5, 0.015, z + tile * 0.5)
			pattern.add_child(tile_mesh)
			x += tile
			col += 1
		z += tile
		row += 1


func _build_floor_border() -> void:
	if floor_root == null:
		return
	var border := Node3D.new()
	border.name = "FloorBorder"
	floor_root.add_child(border)

	var half := PLAY_HALF - 0.8
	var strip := 0.45
	var h := 0.04
	var specs := [
		{"pos": Vector3(0, h, -half), "size": Vector3(half * 2, h, strip)},
		{"pos": Vector3(0, h, half), "size": Vector3(half * 2, h, strip)},
		{"pos": Vector3(-half, h, 0), "size": Vector3(strip, h, half * 2)},
		{"pos": Vector3(half, h, 0), "size": Vector3(strip, h, half * 2)},
	]
	for spec in specs:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = spec["size"]
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = FLOOR_BORDER_COLOR
		mat.roughness = 0.85
		mi.material_override = mat
		mi.position = spec["pos"]
		border.add_child(mi)


func _place_player(spawn: Vector3) -> void:
	if chef:
		chef.position = spawn
