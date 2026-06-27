extends Node3D

@onready var stations_root: Node3D = $Stations
@onready var walls_root: Node3D = $Walls
@onready var decor_root: Node3D = $Decorations
@onready var chef: ChefPlayer = $ChefPlayer
@onready var level_label: Label = null
@onready var floor_mesh: MeshInstance3D = $Floor/MeshInstance3D
@onready var floor_shape: CollisionShape3D = $Floor/CollisionShape3D
@onready var floor_root: StaticBody3D = $Floor
@onready var camera: Camera3D = $Camera3D

const BakeryPropBuilderScript = preload("res://scenes/props/bakery_prop_builder.gd")

var _navigation_obstacles: Array[Rect2] = []
var chef2: ChefPlayer = null
var _coop_mode: bool = false
var _active_player_id: int = 1
var _is_real_game: bool = false
var _orders_delivered_real: int = 0
var _cakes_burned_real: int = 0

const WALL_HEIGHT := 3.5
const PLAY_HALF := 16.5
const FLOOR_SIZE := 36.0
const WALL_INSET := 0.6
const FLOOR_TILE_SIZE := 1.2
const FLOOR_TILE_VISUAL_Y := 0.035
const DECOR_VISUAL_SCALE := 1.35
# Piso calido para la ambientacion de pasteleria de barrio.
const FLOOR_COLOR_A := Color(0.86, 0.74, 0.56)
const FLOOR_COLOR_B := Color(0.96, 0.88, 0.72)
const FLOOR_BORDER_COLOR := Color(0.42, 0.24, 0.13)

const ASSET_BASE := "res://assets/{models,textures,sounds}/Tiny_Treats_Bakery_Interior_1.1_FREE/Assets/gltf/"
const DECORATION_SPECS := [
	{"asset": "wall_sign_large.gltf", "pos": Vector3(0, 1.05, -14.7), "scale": 1.1, "rot": 0.0},
	{"asset": "wall_shelf_bakery_A.gltf", "pos": Vector3(-10.8, 0.15, -14.2), "scale": 0.95, "rot": 0.0},
	{"asset": "wall_shelf_bakery_B.gltf", "pos": Vector3(-7.0, 0.15, -14.2), "scale": 0.95, "rot": 0.0},
	{"asset": "wall_shelf_bakery_C.gltf", "pos": Vector3(6.9, 0.15, -14.2), "scale": 0.95, "rot": 0.0},
	{"asset": "countertop_straight_B_long.gltf", "pos": Vector3(-11.5, 0, -10.7), "scale": 0.95, "rot": 0.0},
	{"asset": "countertop_closet_A_large.gltf", "pos": Vector3(-7.8, 0, -10.7), "scale": 0.95, "rot": 0.0},
	{"asset": "stand_mixer.gltf", "pos": Vector3(-7.8, 1.15, -10.7), "scale": 0.82, "rot": -18.0},
	{"asset": "scale.gltf", "pos": Vector3(-10.2, 1.14, -10.65), "scale": 0.72, "rot": 16.0},
	{"asset": "flour_sack_open.gltf", "pos": Vector3(-14.0, 0, -7.8), "scale": 0.9, "rot": 22.0},
	{"asset": "flour_sack_closed.gltf", "pos": Vector3(-14.4, 0, -5.8), "scale": 0.88, "rot": -12.0},
	{"asset": "display_case_long.gltf", "pos": Vector3(11.4, 0, -8.6), "scale": 0.95, "rot": 90.0},
	{"asset": "display_case_short.gltf", "pos": Vector3(11.4, 0, -5.2), "scale": 0.95, "rot": 90.0},
	{"asset": "cash_register.gltf", "pos": Vector3(10.7, 1.12, -6.8), "scale": 0.75, "rot": -90.0},
	{"asset": "coffee_machine.gltf", "pos": Vector3(14.0, 0, -10.8), "scale": 0.86, "rot": -90.0},
	{"asset": "pastry_stand_A_decorated.gltf", "pos": Vector3(7.7, 1.08, -0.2), "scale": 0.68, "rot": -12.0},
	{"asset": "pastry_stand_B_decorated.gltf", "pos": Vector3(8.4, 1.08, 0.45), "scale": 0.68, "rot": 18.0},
	{"asset": "serving_tray.gltf", "pos": Vector3(6.8, 1.08, 0.55), "scale": 0.74, "rot": 12.0},
	{"asset": "dough_roller.gltf", "pos": Vector3(-4.4, 1.08, 7.3), "scale": 0.8, "rot": 20.0},
	{"asset": "dough_rolled_A.gltf", "pos": Vector3(-5.1, 1.08, 7.0), "scale": 0.75, "rot": -8.0},
	{"asset": "whisk.gltf", "pos": Vector3(-3.8, 1.08, 7.0), "scale": 0.76, "rot": -28.0},
	{"asset": "basket_A.gltf", "pos": Vector3(-10.1, 0, 2.1), "scale": 0.84, "rot": 18.0},
	{"asset": "basket_B.gltf", "pos": Vector3(-12.0, 0, 0.8), "scale": 0.84, "rot": -12.0},
	{"asset": "bread.gltf", "pos": Vector3(-10.1, 0.52, 2.1), "scale": 0.75, "rot": 18.0},
	{"asset": "table_round_B.gltf", "pos": Vector3(12.2, 0, 8.0), "scale": 0.9, "rot": 0.0},
	{"asset": "chair.gltf", "pos": Vector3(12.2, 0, 5.9), "scale": 0.88, "rot": 180.0},
	{"asset": "chair.gltf", "pos": Vector3(14.2, 0, 8.0), "scale": 0.88, "rot": -90.0},
	{"asset": "chair.gltf", "pos": Vector3(10.2, 0, 8.0), "scale": 0.88, "rot": 90.0},
	{"asset": "table_round_C.gltf", "pos": Vector3(12.7, 0, 12.7), "scale": 0.82, "rot": 25.0},
	{"asset": "chair.gltf", "pos": Vector3(10.9, 0, 12.7), "scale": 0.82, "rot": 90.0},
	{"asset": "chair.gltf", "pos": Vector3(14.5, 0, 12.7), "scale": 0.82, "rot": -90.0},
	{"asset": "rug.gltf", "pos": Vector3(0, 0.02, 10.8), "scale": 1.15, "rot": 0.0},
	{"asset": "curtains.gltf", "pos": Vector3(-14.2, 0, 7.4), "scale": 0.95, "rot": 90.0},
	{"asset": "pricing_card.gltf", "pos": Vector3(13.6, 1.1, -4.2), "scale": 0.75, "rot": -72.0},
]


func _ready() -> void:
	var level_id := GameState.selected_level
	var layout := LevelLayouts.get_layout(level_id)
	level_label = _find_level_label()
	_navigation_obstacles.clear()
	_setup_floor()
	_setup_lighting()
	await _build_stations(layout.get("stations", []))
	_build_boundary_walls()
	_build_extra_walls(layout.get("walls", []))
	_build_decorations(level_id)
	var spawn: Vector3 = layout.get("spawn", Vector3(3, 1, 2))
	spawn.y = 1.0
	_place_player(spawn)
	if chef:
		chef.configure_level_bounds(PLAY_HALF, spawn)
		chef.configure_navigation_obstacles(_navigation_obstacles)
		var has_queue: bool = layout.get("queue_mode", false)
		var has_coop: bool = layout.get("coop_mode", false)
		if has_queue and not has_coop:
			chef.queue_mode_enabled = true
			chef._emit_queue_update()
		if has_coop:
			_setup_coop_mode(layout)
	if layout.get("game_mode", "") == "real":
		_setup_real_game_mode(layout)
	if level_label:
		level_label.text = "Nivel %d: %s" % [level_id, layout.get("name", "")]
	if camera:
		camera.size = 22.0
		camera.position = Vector3(0, 20, 19)
		camera.rotation_degrees = Vector3(-50, 0, 0)


func _setup_floor() -> void:
	if floor_shape and floor_shape.shape is BoxShape3D:
		(floor_shape.shape as BoxShape3D).size = Vector3(FLOOR_SIZE, 0.2, FLOOR_SIZE)

	if floor_mesh:
		var base := BoxMesh.new()
		base.size = Vector3(FLOOR_SIZE, 0.12, FLOOR_SIZE)
		floor_mesh.mesh = base
		floor_mesh.transform = Transform3D.IDENTITY
		floor_mesh.position.y = -0.02
		floor_mesh.visible = true
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.78, 0.62, 0.43)
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
	env.ambient_light_color = Color(0.9, 0.78, 0.62)
	env.ambient_light_energy = 0.44
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.34, 0.28, 0.22)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.68

	var sun := $DirectionalLight3D
	if sun:
		sun.light_energy = 0.82
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
			omni.light_energy = 0.22
			omni.light_color = Color(1.0, 0.82, 0.62)
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
		_register_navigation_obstacle(station.position, Vector2(2.25, 2.15), 0.0)


func _build_decorations(level_id: int) -> void:
	for child in decor_root.get_children():
		child.queue_free()

	for spec in DECORATION_SPECS:
		_spawn_deco_asset(
			spec.get("asset", ""),
			spec.get("pos", Vector3.ZERO),
			spec.get("scale", 1.0),
			spec.get("rot", 0.0)
		)

	match level_id:
		1:
			_spawn_deco_asset("macaron_pink.gltf", Vector3(8.2, 1.15, 0.3), 0.7, 12.0)
			_spawn_deco_asset("cream_puff.gltf", Vector3(7.7, 1.18, -0.25), 0.68, -18.0)
		2:
			_spawn_deco_asset("wall_sign_small.gltf", Vector3(15, 0, 14), 0.9, -90.0)
		3:
			_spawn_deco_asset("wall_panelled_bakery_window_large.gltf", Vector3(0, 0, -15), 0.85, 0.0)
			_spawn_deco_asset("wall_panelled_bakery_window_large.gltf", Vector3(7, 0, -15), 0.85, 0.0)
			_spawn_deco_asset("display_case_long.gltf",  Vector3(13.2, 0, -10.5), 0.92, 90.0)
			_spawn_deco_asset("display_case_short.gltf", Vector3(13.2, 0, -6.4),  0.92, 90.0)
			_spawn_deco_asset("pricing_card.gltf",       Vector3(12.2, 1.1, -5.2), 0.72, -80.0)
			_spawn_deco_asset("pastry_stand_A_decorated.gltf", Vector3(-13.0, 1.08, 4.5), 0.70, 15.0)
			_spawn_deco_asset("pastry_stand_B_decorated.gltf", Vector3(-11.8, 1.08, 4.5), 0.70, -12.0)
			_spawn_deco_asset("serving_tray.gltf",       Vector3(-12.6, 1.08, 5.3), 0.72, 8.0)
			_spawn_deco_asset("table_round_B.gltf",      Vector3(-12.5, 0, 10.8), 0.88, 0.0)
			_spawn_deco_asset("chair.gltf",              Vector3(-12.5, 0, 8.7),  0.86, 180.0)
			_spawn_deco_asset("chair.gltf",              Vector3(-14.4, 0, 10.8), 0.86, -90.0)
			_spawn_deco_asset("table_round_C.gltf",      Vector3(13.2, 0, 11.5),  0.82, 20.0)
			_spawn_deco_asset("chair.gltf",              Vector3(11.4, 0, 11.5),  0.82, 90.0)
			_spawn_deco_asset("chair.gltf",              Vector3(15.0, 0, 11.5),  0.82, -90.0)
			_spawn_deco_asset("macaron_pink.gltf",       Vector3(13.4, 1.15, 10.5), 0.68, 8.0)
			_spawn_deco_asset("cream_puff.gltf",         Vector3(13.0, 1.18, 11.3), 0.66, -15.0)
		4:
			_spawn_deco_asset("tin_A_brown.gltf", Vector3(-15, 0, 0), 1.0, 0.0)
			_spawn_deco_asset("tin_B_beige.gltf", Vector3(15, 0, 0), 1.0, 0.0)
		5:
			_spawn_deco_asset("coffee_machine.gltf", Vector3(-15.5, 0, 8), 0.9, 90.0)
			_spawn_deco_asset("display_case_short.gltf", Vector3(15.5, 0, 8), 0.9, -90.0)

	_build_primitive_bakery_props()


func _spawn_deco_asset(asset_name: String, pos: Vector3, scale_mul: float, rotation_y_degrees: float) -> void:
	if asset_name.is_empty():
		return
	var final_scale := scale_mul * DECOR_VISUAL_SCALE
	if not _spawn_deco(ASSET_BASE + asset_name, pos, final_scale, rotation_y_degrees):
		return

	var collider_size := _get_deco_collider_size(asset_name) * final_scale
	if collider_size.x > 0.0 and collider_size.y > 0.0:
		_add_deco_collision(asset_name, pos, collider_size, rotation_y_degrees)
		_register_navigation_obstacle(pos, collider_size, rotation_y_degrees)


func _spawn_deco(asset_path: String, pos: Vector3, scale_mul: float, rotation_y_degrees: float) -> bool:
	if not ResourceLoader.exists(asset_path):
		return false
	var res := load(asset_path)
	var node: Node3D = null
	if res is PackedScene:
		node = (res as PackedScene).instantiate() as Node3D
	elif res is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = res as Mesh
		node = mi
	if node == null:
		return false
	node.position = pos
	node.scale = Vector3.ONE * scale_mul
	node.rotation_degrees.y = rotation_y_degrees
	decor_root.add_child(node)
	return true


func _get_deco_collider_size(asset_name: String) -> Vector2:
	if asset_name.contains("whisk") or asset_name.contains("dough_roller"):
		return Vector2.ZERO
	if asset_name.contains("macaron") or asset_name.contains("cream_puff") or asset_name.contains("bread"):
		return Vector2.ZERO
	if asset_name.contains("plate") or asset_name.contains("bowl") or asset_name.contains("serving_tray"):
		return Vector2.ZERO
	if asset_name.contains("wall_") or asset_name.contains("curtains") or asset_name.contains("pricing_card"):
		return Vector2.ZERO
	if asset_name.contains("countertop"):
		return Vector2(2.15, 1.35)
	if asset_name.contains("display_case_long"):
		return Vector2(3.0, 1.35)
	if asset_name.contains("display_case_short"):
		return Vector2(1.65, 1.25)
	if asset_name.contains("coffee_machine"):
		return Vector2(1.2, 1.0)
	if asset_name.contains("cash_register") or asset_name.contains("stand_mixer") or asset_name.contains("scale"):
		return Vector2.ZERO
	if asset_name.contains("shelf"):
		return Vector2(1.85, 0.95)
	if asset_name.contains("table_round"):
		return Vector2(2.15, 2.15)
	if asset_name.contains("chair"):
		return Vector2(0.9, 0.9)
	if asset_name.contains("basket") or asset_name.contains("flour_sack") or asset_name.contains("tin_"):
		return Vector2(1.05, 1.05)
	if asset_name.contains("rug"):
		return Vector2.ZERO
	return Vector2.ZERO


func _add_deco_collision(asset_name: String, pos: Vector3, footprint: Vector2, rotation_y_degrees: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision_%s" % asset_name.get_basename()
	body.position = Vector3(pos.x, 0.75, pos.z)
	body.rotation_degrees.y = rotation_y_degrees
	body.collision_layer = PhysicsLayers.WORLD
	body.collision_mask = 0

	var shape := BoxShape3D.new()
	shape.size = Vector3(footprint.x, 1.5, footprint.y)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	decor_root.add_child(body)


func _register_navigation_obstacle(pos: Vector3, footprint: Vector2, rotation_y_degrees: float) -> void:
	var final_size := footprint
	var y_rot := fposmod(absf(rotation_y_degrees), 180.0)
	if y_rot > 45.0 and y_rot < 135.0:
		final_size = Vector2(footprint.y, footprint.x)
	var rect := Rect2(
		Vector2(pos.x - final_size.x * 0.5, pos.z - final_size.y * 0.5),
		final_size
	)
	_navigation_obstacles.append(rect)


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

	var half := PLAY_HALF - WALL_INSET - 0.9
	var tile := FLOOR_TILE_SIZE
	var row := 0
	var z := -half
	while z < half - 0.01:
		var col := 0
		var x := -half
		while x < half - 0.01:
			var tile_pos := Vector3(x + tile * 0.5, FLOOR_TILE_VISUAL_Y, z + tile * 0.5)
			_add_fallback_floor_tile(pattern, tile_pos, row, col)
			x += tile
			col += 1
		z += tile
		row += 1


func _add_fallback_floor_tile(parent: Node3D, pos: Vector3, row: int, col: int) -> void:
	var tile_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(FLOOR_TILE_SIZE - 0.035, 0.03, FLOOR_TILE_SIZE - 0.035)
	tile_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FLOOR_COLOR_B if (row + col) % 2 == 0 else FLOOR_COLOR_A
	mat.roughness = 0.88
	tile_mesh.material_override = mat
	tile_mesh.position = pos
	parent.add_child(tile_mesh)


func _build_primitive_bakery_props() -> void:
	BakeryPropBuilderScript.add_flour_sack(decor_root, Vector3(-14.1, 0.0, -3.4), -12.0)
	BakeryPropBuilderScript.add_flour_sack(decor_root, Vector3(-13.35, 0.0, -2.95), 16.0)
	BakeryPropBuilderScript.add_bread_basket(decor_root, Vector3(-9.0, 0.0, 3.4), 24.0)
	BakeryPropBuilderScript.add_cupcake_stand(decor_root, Vector3(6.2, 0.0, 1.7), -18.0)
	BakeryPropBuilderScript.add_tray(decor_root, Vector3(8.7, 0.0, 2.0), 12.0)
	BakeryPropBuilderScript.add_potted_plant(decor_root, Vector3(-13.9, 0.0, 12.5), 0.0)
	BakeryPropBuilderScript.add_potted_plant(decor_root, Vector3(14.2, 0.0, -13.1), 0.0)
	BakeryPropBuilderScript.add_blackboard(decor_root, Vector3(-3.0, 0.0, -14.45), 0.0)


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


func _setup_coop_mode(layout: Dictionary) -> void:
	_coop_mode = true

	# Configurar P1 (ya existe en escena)
	chef.player_id = 1
	chef.player_color = Color(1.0, 0.42, 0.58)
	chef.show_player_indicator = true
	chef.queue_mode_enabled = true
	chef.is_active_player = true
	chef._add_player_color_ring()
	chef._emit_queue_update()

	# Instanciar P2
	var chef_scene := load("res://scenes/player/chef_player.tscn") as PackedScene
	if chef_scene == null:
		push_error("CoopMode: no se pudo cargar chef_player.tscn")
		return
	chef2 = chef_scene.instantiate() as ChefPlayer
	if chef2 == null:
		return

	chef2.player_id = 2
	chef2.player_color = Color(0.28, 0.60, 1.0)
	chef2.show_player_indicator = true
	chef2.queue_mode_enabled = true
	chef2.is_active_player = false
	add_child(chef2)

	var spawn_p2: Vector3 = layout.get("spawn_p2", Vector3(6, 1, 7))
	spawn_p2.y = 1.0
	chef2.position = spawn_p2
	chef2.configure_level_bounds(PLAY_HALF, spawn_p2)
	chef2.configure_navigation_obstacles(_navigation_obstacles)
	chef2._emit_queue_update()

	# Notificar HUD
	var hud := _get_hud()
	if hud and hud.has_method("setup_coop_mode"):
		hud.setup_coop_mode(true)

	_set_active_player(1)


func _set_active_player(id: int) -> void:
	_active_player_id = id
	if chef:
		chef.is_active_player = (id == 1)
	if chef2:
		chef2.is_active_player = (id == 2)
	var hud := _get_hud()
	if hud and hud.has_method("update_coop_selection"):
		hud.update_coop_selection(id)


func _unhandled_input(event: InputEvent) -> void:
	if not _coop_mode:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_set_active_player(1)
				get_viewport().set_input_as_handled()
			KEY_2:
				_set_active_player(2)
				get_viewport().set_input_as_handled()


func _get_hud() -> Node:
	return get_node_or_null("GameManager/GameHUD")


func _place_player(spawn: Vector3) -> void:
	if chef:
		chef.position = spawn


func _find_level_label() -> Label:
	var hud := get_node_or_null("GameManager/GameHUD")
	if hud == null:
		return null
	return hud.find_child("LevelLabel", true, false) as Label


func _setup_real_game_mode(layout: Dictionary) -> void:
	_is_real_game = true
	var hud := _get_hud() as GameHUD
	if hud == null:
		return
	var thresholds: Array = layout.get("star_thresholds", [3, 5, 7])
	var no_burn: bool = layout.get("no_burn_for_3_stars", false)
	var duration: float = layout.get("duration", 180.0)
	hud.set_game_objectives(thresholds, no_burn)
	hud.set_game_duration(duration)
	var order_mgr := get_tree().get_first_node_in_group("order_manager") as OrderManager
	if order_mgr:
		order_mgr.order_completed.connect(_on_real_game_delivery)
		order_mgr.order_failed.connect(_on_real_game_failure)
		order_mgr.order_penalty_applied.connect(_on_real_game_penalty)
	for station in stations_root.get_children():
		if station is CookingStation:
			station.item_burned.connect(_on_cake_burned)


func _on_real_game_delivery(_recipe: Recipe, pts: int) -> void:
	_orders_delivered_real += 1
	var hud := _get_hud() as GameHUD
	if hud:
		hud.register_delivery(pts)


func _on_real_game_failure(_recipe: Recipe) -> void:
	var hud := _get_hud() as GameHUD
	if hud:
		hud.register_order_failure()


func _on_real_game_penalty(amount: int) -> void:
	var hud := _get_hud() as GameHUD
	if hud:
		hud.register_penalty(amount)


func _on_cake_burned() -> void:
	_cakes_burned_real += 1
	var hud := _get_hud() as GameHUD
	if hud:
		hud.register_burn()
