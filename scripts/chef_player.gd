extends CharacterBody3D
class_name ChefPlayer

const CHEF_MODEL_PATH := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/fbx/Chef.fbx"
const HELD_BASE_SCALE_META := "_held_base_scale"

@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0
@export var interact_range: float = 2.8
@export var click_stop_distance: float = 0.15
@export var floor_y: float = 1.0
@export var chef_model_scale: float = 0.42
@export var chef_model_y_offset: float = 0.0
@export var model_yaw_offset_deg: float = 180.0
@export var navigation_grid_size: float = 1.0
@export var navigation_clearance: float = 0.65
@export var held_item_scale_multiplier: float = 1.85

const MAX_QUEUE_SIZE := 3
const PLAN_CHANGE_PENALTY_SECONDS := 2.0

var player_id: int = 1
var player_color: Color = Color(1.0, 0.55, 0.65)
var show_player_indicator: bool = false
var is_active_player: bool = true
var held_item: Node3D = null
var movement_enabled: bool = true
var queue_mode_enabled: bool = false
var _action_queue: Array = []
var _queue_penalty_remaining: float = 0.0
var _interactables_in_range: Array[Node3D] = []
var _level_bounds_half: float = 15.0
var _spawn_position: Vector3 = Vector3.ZERO
var _last_target: Node3D = null
var _hover_target: Node3D = null
var _pending_interaction_target: Node3D = null
var _pending_action_type: String = "deliver"
var _move_target: Vector3 = Vector3.ZERO
var _has_move_target: bool = false
var _path_points: Array[Vector3] = []
var _path_index: int = 0
var _navigation_obstacles: Array[Rect2] = []

signal action_queue_changed(queue: Array)

@onready var model = $Model
@onready var hand_position: Node3D = $Model/HandPosition
@onready var knife_hold_visual: MeshInstance3D = $Model/HandPosition/KnifeHoldVisual if has_node("Model/HandPosition/KnifeHoldVisual") else null

signal item_picked_up(item)
signal item_dropped(item)
signal interacted_with_station(station)


func _ready() -> void:
	add_to_group("player")
	add_to_group("player_%d" % player_id)
	collision_layer = PhysicsLayers.PLAYER
	collision_mask = PhysicsLayers.MASK_PLAYER

	_setup_chef_model()
	_refresh_hand_visuals()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		velocity = Vector3.ZERO
		_has_move_target = false


func _setup_chef_model() -> void:
	if not model:
		return

	for child in model.get_children():
		if child != hand_position and child.name != "HandPosition":
			child.queue_free()

	if knife_hold_visual:
		knife_hold_visual.visible = false

	if not ResourceLoader.exists(CHEF_MODEL_PATH):
		push_warning("ChefPlayer: no se encontro ", CHEF_MODEL_PATH)
		return

	var packed: PackedScene = load(CHEF_MODEL_PATH) as PackedScene
	if packed == null:
		push_warning("ChefPlayer: no se pudo cargar el modelo Chef.")
		return

	var avatar: Node3D = packed.instantiate() as Node3D
	if avatar == null:
		return

	avatar.name = "ChefAvatar"
	avatar.scale = Vector3.ONE * chef_model_scale
	avatar.position = Vector3(0, chef_model_y_offset, 0)
	avatar.rotation_degrees = Vector3.ZERO
	model.add_child(avatar)
	model.move_child(avatar, 0)

	if hand_position == null or not is_instance_valid(hand_position):
		hand_position = Node3D.new()
		hand_position.name = "HandPosition"
		model.add_child(hand_position)

	hand_position.position = Vector3(0.55, 1.08, 0.42)
	if show_player_indicator:
		_add_player_color_ring()


func configure_level_bounds(half_size: float, spawn: Vector3) -> void:
	_level_bounds_half = half_size - 1.2
	_spawn_position = spawn
	global_position = spawn
	_move_target = spawn
	_has_move_target = false
	_path_points.clear()
	_path_index = 0
	if _spawn_position.y < floor_y:
		_spawn_position.y = floor_y


func configure_navigation_obstacles(obstacles: Array[Rect2]) -> void:
	_navigation_obstacles = obstacles.duplicate()


func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector3.ZERO
		return
	if _queue_penalty_remaining > 0.0:
		_queue_penalty_remaining -= delta
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		_refresh_hover_target()
		move_and_slide()
		_enforce_safe_position()
		return
	_refresh_hover_target()
	_refresh_nearby_interactables()
	_process_pending_interaction()
	handle_movement(delta)
	handle_rotation(delta)
	move_and_slide()
	_enforce_safe_position()


func _input(event: InputEvent) -> void:
	if not movement_enabled:
		return
	if event.is_action_pressed("drop") and held_item:
		drop_item()


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled:
		return
	if not is_active_player:
		return
	if queue_mode_enabled and _queue_penalty_remaining > 0.0:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if queue_mode_enabled and mouse_event.shift_pressed:
				_handle_queue_click(mouse_event.position)
			else:
				_handle_left_click(mouse_event.position)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if queue_mode_enabled:
				cancel_action_queue()


func _handle_left_click(screen_position: Vector2) -> void:
	if _hover_target and is_instance_valid(_hover_target):
		_pending_interaction_target = _hover_target
		_pending_action_type = "deliver"
		_set_navigation_target(_navigation_position_for(_pending_interaction_target))
		return

	_pending_interaction_target = null
	_set_click_move_target(screen_position)


func _set_click_move_target(screen_position: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	if absf(ray_direction.y) < 0.001:
		return

	var distance_to_floor := (floor_y - ray_origin.y) / ray_direction.y
	if distance_to_floor < 0.0:
		return

	var target := ray_origin + ray_direction * distance_to_floor
	target.y = floor_y
	target.x = clampf(target.x, -_level_bounds_half, _level_bounds_half)
	target.z = clampf(target.z, -_level_bounds_half, _level_bounds_half)
	_set_navigation_target(target)


func _set_navigation_target(target: Vector3) -> void:
	_move_target = target
	_path_points.clear()
	_path_index = 0

	if _navigation_obstacles.is_empty() or not _segment_hits_obstacle(global_position, target):
		_path_points.append(target)
	else:
		_path_points = _build_grid_path(global_position, target)
		if _path_points.is_empty():
			_path_points.append(target)

	_has_move_target = true


func _refresh_hover_target() -> void:
	if not is_active_player:
		if _hover_target:
			_update_station_highlights(null)
			_hover_target = null
		return
	var target := _get_mouse_hover_target()
	_hover_target = target
	_update_station_highlights(_hover_target)
	_update_interaction_hud(_hover_target)


func _get_mouse_hover_target() -> Node3D:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end,
		PhysicsLayers.STATIONS | PhysicsLayers.ITEMS
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null

	return _find_clickable_root(result.get("collider") as Node)


func _find_clickable_root(node: Node) -> Node3D:
	var current := node
	while current:
		if current is Node3D:
			if current.is_in_group("interactable") or current.is_in_group("dropped_item"):
				return current as Node3D
			if current.has_meta("is_ingredient"):
				return current as Node3D
		current = current.get_parent()
	return null


func _enforce_safe_position() -> void:
	var p := global_position
	p.x = clampf(p.x, -_level_bounds_half, _level_bounds_half)
	p.z = clampf(p.z, -_level_bounds_half, _level_bounds_half)
	if p.y < floor_y:
		p.y = floor_y
		velocity.y = 0.0
	elif p.y > floor_y + 0.5:
		p.y = floor_y
		velocity.y = 0.0
	global_position = p


func _refresh_nearby_interactables() -> void:
	_interactables_in_range.clear()
	var gp := global_position
	for node in get_tree().get_nodes_in_group("interactable"):
		if not node is Node3D or not is_instance_valid(node):
			continue
		if gp.distance_to((node as Node3D).global_position) <= interact_range:
			_interactables_in_range.append(node)


func _update_station_highlights(target: Node3D) -> void:
	if _last_target and is_instance_valid(_last_target) and _last_target.has_method("set_highlighted"):
		_last_target.set_highlighted(false)
	_last_target = target
	if target and target.has_method("set_highlighted"):
		target.set_highlighted(true)


func _update_interaction_hud(target: Node3D) -> void:
	var hud := _get_hud()
	if not hud:
		return
	if target and target.has_method("get_display_name"):
		hud.show_station_target(target.get_display_name())
	elif target:
		hud.show_station_target(_get_item_display_name(target))
	else:
		hud.clear_station_target()


func _get_hud() -> GameHUD:
	return get_tree().get_first_node_in_group("game_hud") as GameHUD


func _get_item_display_name(item: Node3D) -> String:
	if item.has_meta("display_name"):
		return str(item.get_meta("display_name"))
	var ingredient_type := str(item.get_meta("ingredient_type", item.name))
	match ingredient_type:
		"cake_batter":
			return "Masa de vainilla"
		"bad_batter":
			return "Masa incorrecta"
		"flour":
			return "Harina"
		"egg":
			return "Huevo"
		"sugar":
			return "Azucar"
		"cake":
			var state := str(item.get_meta("state", ""))
			if state == "baked":
				return "Pastel horneado"
			if state == "burned":
				return "Pastel quemado"
			if state == "ruined_baked":
				return "Pastel fallido"
			if state == "decorated_vanilla":
				return "Pastel de vainilla"
			if state == "decorated_chocolate":
				return "Pastel con chocolate"
			return "Pastel"
		_:
			return ingredient_type.capitalize()


func handle_movement(delta: float) -> void:
	if not movement_enabled:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		return

	var current_target := _get_current_path_target()
	var to_target := current_target - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if _has_move_target and distance > click_stop_distance:
		var direction := to_target / distance
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		if _advance_path_point():
			handle_movement(delta)
			return
		else:
			_has_move_target = false
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			velocity.z = move_toward(velocity.z, 0, friction * delta)

	if global_position.y > floor_y + 0.05:
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0


func _get_current_path_target() -> Vector3:
	if _path_points.is_empty():
		return _move_target
	return _path_points[clampi(_path_index, 0, _path_points.size() - 1)]


func _advance_path_point() -> bool:
	if _path_points.is_empty():
		return false
	if _path_index < _path_points.size() - 1:
		_path_index += 1
		return true
	return false


func _segment_hits_obstacle(from: Vector3, to: Vector3) -> bool:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	for rect in _navigation_obstacles:
		var grown := rect.grow(navigation_clearance)
		if grown.has_point(a) or grown.has_point(b):
			return true
		if _segment_intersects_rect(a, b, grown):
			return true
	return false


func _segment_intersects_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var p := rect.position
	var s := rect.size
	var p1 := p
	var p2 := p + Vector2(s.x, 0)
	var p3 := p + s
	var p4 := p + Vector2(0, s.y)
	return (
		Geometry2D.segment_intersects_segment(a, b, p1, p2) != null
		or Geometry2D.segment_intersects_segment(a, b, p2, p3) != null
		or Geometry2D.segment_intersects_segment(a, b, p3, p4) != null
		or Geometry2D.segment_intersects_segment(a, b, p4, p1) != null
	)


func _build_grid_path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var start := _cell_for_point(Vector2(from.x, from.z))
	var goal := _find_nearest_free_cell(_cell_for_point(Vector2(to.x, to.z)))
	if _is_cell_blocked(start):
		start = _find_nearest_free_cell(start)

	var open: Array[Vector2i] = [start]
	var came_from := {}
	var g_score := {start: 0.0}
	var f_score := {start: _cell_distance(start, goal)}
	var closed := {}

	while not open.is_empty():
		var current := _pop_lowest_score_cell(open, f_score)
		if current == goal:
			return _cells_to_path(_reconstruct_cells(came_from, current), to)

		closed[current] = true
		for neighbor in _get_cell_neighbors(current):
			if closed.has(neighbor) or _is_cell_blocked(neighbor):
				continue
			var move_cost := _cell_distance(current, neighbor)
			var tentative_g: float = g_score.get(current, INF) + move_cost
			if tentative_g >= g_score.get(neighbor, INF):
				continue
			came_from[neighbor] = current
			g_score[neighbor] = tentative_g
			f_score[neighbor] = tentative_g + _cell_distance(neighbor, goal)
			if not open.has(neighbor):
				open.append(neighbor)

	return []


func _cell_for_point(point: Vector2) -> Vector2i:
	return Vector2i(
		roundi(point.x / navigation_grid_size),
		roundi(point.y / navigation_grid_size)
	)


func _point_for_cell(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * navigation_grid_size, cell.y * navigation_grid_size)


func _is_cell_blocked(cell: Vector2i) -> bool:
	var p := _point_for_cell(cell)
	if absf(p.x) > _level_bounds_half or absf(p.y) > _level_bounds_half:
		return true
	for rect in _navigation_obstacles:
		if rect.grow(navigation_clearance).has_point(p):
			return true
	return false


func _find_nearest_free_cell(origin: Vector2i) -> Vector2i:
	if not _is_cell_blocked(origin):
		return origin
	for radius in range(1, 8):
		for x in range(origin.x - radius, origin.x + radius + 1):
			for y in range(origin.y - radius, origin.y + radius + 1):
				if abs(x - origin.x) != radius and abs(y - origin.y) != radius:
					continue
				var cell := Vector2i(x, y)
				if not _is_cell_blocked(cell):
					return cell
	return origin


func _get_cell_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue
			var next := cell + Vector2i(x, y)
			if x != 0 and y != 0:
				if _is_cell_blocked(cell + Vector2i(x, 0)) or _is_cell_blocked(cell + Vector2i(0, y)):
					continue
			neighbors.append(next)
	return neighbors


func _pop_lowest_score_cell(open: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var best_index := 0
	var best_score: float = f_score.get(open[0], INF)
	for i in range(1, open.size()):
		var score: float = f_score.get(open[i], INF)
		if score < best_score:
			best_score = score
			best_index = i
	var cell := open[best_index]
	open.remove_at(best_index)
	return cell


func _cell_distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a).distance_to(Vector2(b))


func _reconstruct_cells(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path


func _cells_to_path(cells: Array[Vector2i], final_target: Vector3) -> Array[Vector3]:
	var path: Array[Vector3] = []
	for i in range(1, cells.size()):
		var p := _point_for_cell(cells[i])
		path.append(Vector3(p.x, floor_y, p.y))
	path.append(final_target)
	return _simplify_path(path)


func _simplify_path(path: Array[Vector3]) -> Array[Vector3]:
	if path.size() <= 2:
		return path
	var simplified: Array[Vector3] = []
	var anchor := global_position
	var i := 0
	while i < path.size():
		var furthest := i
		for j in range(path.size() - 1, i - 1, -1):
			if not _segment_hits_obstacle(anchor, path[j]):
				furthest = j
				break
		simplified.append(path[furthest])
		anchor = path[furthest]
		i = furthest + 1
	return simplified


func handle_rotation(delta: float) -> void:
	if velocity.length() > 0.5:
		# Modelos 3D miran hacia -Z; atan2(-x, -z) alinea la vista con la direccion de movimiento
		var target_rotation := atan2(-velocity.x, -velocity.z) + deg_to_rad(model_yaw_offset_deg)
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation, 10.0 * delta)


func _get_model_forward() -> Vector3:
	if model == null:
		return Vector3(0, 0, -1)
	var basis_z: Vector3 = model.global_transform.basis.z
	var forward: Vector3 = -basis_z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return Vector3(0, 0, -1)
	return forward.normalized()


func attempt_interaction() -> void:
	if not held_item:
		var dropped := _get_nearest_dropped_item()
		if dropped:
			pickup_item(dropped)
			var hud := _get_hud()
			if hud:
				hud.flash_interaction()
			return

	var target := _get_best_interactable()
	if target and target.has_method("interact"):
		target.interact(self)
		interacted_with_station.emit(target)
		var hud := _get_hud()
		if hud:
			hud.flash_interaction()


func _process_pending_interaction() -> void:
	if _pending_interaction_target == null or not is_instance_valid(_pending_interaction_target):
		_pending_interaction_target = null
		_pending_action_type = "deliver"
		if queue_mode_enabled:
			_complete_queue_action()
		return
	if global_position.distance_to(_interaction_position_for(_pending_interaction_target)) > interact_range:
		return

	var target := _pending_interaction_target

	if _pending_action_type == "wait_pickup":
		# Stay at station until it has a ready output.
		var ready: bool
		if target.has_method("has_ready_output"):
			ready = target.has_ready_output()
		else:
			ready = not bool(target.get("is_processing"))
		if not ready:
			_has_move_target = false
			velocity = Vector3.ZERO
			return
		_has_move_target = false
		velocity = Vector3.ZERO
		if target.has_method("interact"):
			target.interact(self)
			interacted_with_station.emit(target)
			_flash_hud_interaction()
		_pending_interaction_target = null
		_pending_action_type = "deliver"
		if queue_mode_enabled:
			_complete_queue_action()
		return

	# "deliver" — place item (or pick up if empty-handed and station has result)
	_has_move_target = false
	velocity = Vector3.ZERO
	if target.is_in_group("dropped_item"):
		if not held_item and pickup_item(target):
			_flash_hud_interaction()
	else:
		if target.has_method("interact"):
			target.interact(self)
			interacted_with_station.emit(target)
			_flash_hud_interaction()
	_pending_interaction_target = null
	_pending_action_type = "deliver"
	if queue_mode_enabled:
		_complete_queue_action()


func _interaction_position_for(target: Node3D) -> Vector3:
	var target_position := target.global_position
	target_position.y = floor_y
	return target_position


func _navigation_position_for(target: Node3D) -> Vector3:
	# Dropped items are on the floor — navigate to their exact position.
	if target.is_in_group("dropped_item"):
		var p := target.global_position
		p.y = floor_y
		return p
	# Stations: approach from the player's current side so the straight-line
	# path never enters the station's grown obstacle rect (±1.775 from center).
	# 2.5 units stays safely outside the grown rect at all approach angles
	# while still being within interact_range (2.8).
	const APPROACH_DIST := 2.5
	var sc := target.global_position
	var dir := Vector3(global_position.x - sc.x, 0.0, global_position.z - sc.z)
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		return Vector3(sc.x + dir.x * APPROACH_DIST, floor_y, sc.z + dir.z * APPROACH_DIST)
	return Vector3(sc.x, floor_y, sc.z)


func _flash_hud_interaction() -> void:
	var hud := _get_hud()
	if hud:
		hud.flash_interaction()


func _get_best_interactable() -> Node3D:
	var best: Node3D = null
	var best_score := INF
	var gp := global_position

	for node in _interactables_in_range:
		if not is_instance_valid(node):
			continue
		var to_station := node.global_position - gp
		to_station.y = 0.0
		var dist := to_station.length()
		if dist > interact_range:
			continue
		var score := dist
		if score < best_score:
			best_score = score
			best = node
	return best


func _get_nearest_dropped_item() -> Node3D:
	var best: Node3D = null
	var best_dist := interact_range
	var gp := global_position
	for node in get_tree().get_nodes_in_group("dropped_item"):
		if not node is Node3D or not is_instance_valid(node):
			continue
		var item := node as Node3D
		var dist := gp.distance_to(item.global_position)
		if dist <= best_dist:
			best_dist = dist
			best = item
	return best


func pickup_item(item: Node3D) -> bool:
	if held_item:
		return false

	held_item = item
	item.remove_from_group("dropped_item")
	if item.get_parent():
		item.get_parent().remove_child(item)
	hand_position.add_child(item)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	_apply_held_item_scale(item)
	_set_item_physics_enabled(item, false)

	item_picked_up.emit(item)
	_refresh_hand_visuals()
	return true


func take_item_from_hand() -> Node3D:
	if not held_item:
		return null
	var item := held_item
	hand_position.remove_child(item)
	held_item = null
	_restore_item_scale(item)
	item_dropped.emit(item)
	_refresh_hand_visuals()
	return item


func destroy_held_item() -> void:
	if not held_item:
		return
	var item := held_item
	hand_position.remove_child(item)
	held_item = null
	item.queue_free()
	_refresh_hand_visuals()


func drop_item() -> void:
	if not held_item:
		return

	var item := held_item
	hand_position.remove_child(item)
	get_parent().add_child(item)
	_restore_item_scale(item)
	var forward := _get_model_forward()
	var drop_pos := global_position + forward * 1.2
	drop_pos.y = floor_y + 0.35
	drop_pos.x = clampf(drop_pos.x, -_level_bounds_half, _level_bounds_half)
	drop_pos.z = clampf(drop_pos.z, -_level_bounds_half, _level_bounds_half)
	item.global_position = drop_pos
	item.add_to_group("dropped_item")
	held_item = null
	_set_item_physics_enabled(item, true)

	item_dropped.emit(item)
	_refresh_hand_visuals()


func _refresh_hand_visuals() -> void:
	if knife_hold_visual:
		knife_hold_visual.visible = false


func _apply_held_item_scale(item: Node3D) -> void:
	if item == null:
		return
	if not item.has_meta(HELD_BASE_SCALE_META):
		item.set_meta(HELD_BASE_SCALE_META, item.scale)
	var base_scale := item.get_meta(HELD_BASE_SCALE_META) as Vector3
	item.scale = base_scale * held_item_scale_multiplier


func _restore_item_scale(item: Node3D) -> void:
	if item == null or not item.has_meta(HELD_BASE_SCALE_META):
		return
	item.scale = item.get_meta(HELD_BASE_SCALE_META) as Vector3


func _set_item_physics_enabled(item: Node3D, enabled: bool) -> void:
	_set_item_physics_enabled_recursive(item, enabled)


func _set_item_physics_enabled_recursive(node: Node, enabled: bool) -> void:
	for child in node.get_children():
		if child is CollisionObject3D:
			var co := child as CollisionObject3D
			if enabled:
				co.collision_layer = PhysicsLayers.ITEMS
				co.collision_mask = PhysicsLayers.MASK_ITEM
			else:
				co.collision_layer = 0
				co.collision_mask = 0
		_set_item_physics_enabled_recursive(child, enabled)


func _add_player_color_ring() -> void:
	if not model:
		return
	var existing := model.find_child("PlayerColorRing", false, false)
	if existing:
		existing.queue_free()
	var ring := MeshInstance3D.new()
	ring.name = "PlayerColorRing"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.24
	mesh.bottom_radius = 0.24
	mesh.height = 0.055
	mesh.rings = 1
	mesh.radial_segments = 16
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = player_color
	mat.emission_enabled = true
	mat.emission = player_color * 0.4
	ring.material_override = mat
	ring.position = Vector3(0, 1.55, 0)
	model.add_child(ring)

	var existing_lbl := model.find_child("PlayerLabel", false, false)
	if existing_lbl:
		existing_lbl.queue_free()
	var lbl := Label3D.new()
	lbl.name = "PlayerLabel"
	lbl.text = "P%d" % player_id
	lbl.font_size = 28
	lbl.modulate = player_color
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.render_priority = 6
	lbl.position = Vector3(0, 2.1, 0)
	lbl.outline_size = 6
	lbl.outline_modulate = Color(0.05, 0.05, 0.05, 0.9)
	model.add_child(lbl)


func get_held_item() -> Node3D:
	return held_item


func has_item() -> bool:
	return held_item != null


# ── Cola de acciones ──────────────────────────────────────────────────────────

func _handle_queue_click(screen_position: Vector2) -> void:
	if _hover_target and is_instance_valid(_hover_target):
		_enqueue_action(_hover_target)
		return
	# Click en espacio vacío: movimiento libre sin encolar
	_set_click_move_target(screen_position)


func _enqueue_action(target: Node3D) -> void:
	if _action_queue.size() >= MAX_QUEUE_SIZE:
		_show_hud_message("Cola llena — max %d acciones" % MAX_QUEUE_SIZE, false)
		return

	# Check if a wait_pickup for this target already exists (active or queued).
	var has_wait := (_pending_interaction_target == target and _pending_action_type == "wait_pickup")
	for action in _action_queue:
		if action.get("target") == target and action.get("action_type") == "wait_pickup":
			has_wait = true

	# If the station is actively processing, add wait_pickup directly — no deliver needed.
	if target.get("is_processing") == true:
		if has_wait:
			_show_hud_message("Ya hay una espera en cola", false)
			return
		var base_name := _get_target_display_name(target)
		_action_queue.append({
			"target": target,
			"display_name": "Esperar: " + base_name,
			"action_type": "wait_pickup",
		})
		_emit_queue_update()
		if _pending_interaction_target == null:
			_start_next_queued_action()
		return

	# Station is not processing — count existing deliver entries for this target.
	var deliver_count := 0
	if _pending_interaction_target == target and _pending_action_type == "deliver":
		deliver_count += 1
	for action in _action_queue:
		if action.get("target") == target and action.get("action_type", "deliver") == "deliver":
			deliver_count += 1

	# A station that holds N items allows N deliver slots before one wait_pickup.
	var max_delivers: int = 1
	var raw_max: Variant = target.get("max_items")
	if raw_max is int and raw_max > 0:
		max_delivers = raw_max

	var action_type: String
	if deliver_count < max_delivers and not has_wait:
		action_type = "deliver"
	elif deliver_count > 0 and not has_wait:
		action_type = "wait_pickup"
	else:
		_show_hud_message("Ya esta en la cola", false)
		return

	var base_name := _get_target_display_name(target)
	var display_name := base_name if action_type == "deliver" else ("Esperar: " + base_name)

	_action_queue.append({
		"target": target,
		"display_name": display_name,
		"action_type": action_type,
	})
	_emit_queue_update()
	if _pending_interaction_target == null:
		_start_next_queued_action()


func cancel_action_queue() -> void:
	if _action_queue.is_empty() and _pending_interaction_target == null:
		return
	var had_active := _pending_interaction_target != null
	_action_queue.clear()
	_pending_interaction_target = null
	_pending_action_type = "deliver"
	_has_move_target = false
	if had_active:
		_queue_penalty_remaining = PLAN_CHANGE_PENALTY_SECONDS
		_show_hud_message("Plan cancelado — %ds de penalizacion" % int(PLAN_CHANGE_PENALTY_SECONDS), false)
	_emit_queue_update()


func _start_next_queued_action() -> void:
	while not _action_queue.is_empty():
		var action: Dictionary = _action_queue[0]
		var target: Node3D = action.get("target")
		if is_instance_valid(target):
			_pending_interaction_target = target
			_pending_action_type = action.get("action_type", "deliver")
			_set_navigation_target(_navigation_position_for(target))
			return
		# Objetivo invalido: saltar y continuar
		_action_queue.pop_front()
	_emit_queue_update()


func _complete_queue_action() -> void:
	if not _action_queue.is_empty():
		_action_queue.pop_front()
	_emit_queue_update()
	_start_next_queued_action()


func _emit_queue_update() -> void:
	action_queue_changed.emit(_action_queue)
	var hud := _get_hud()
	if hud and hud.has_method("update_action_queue"):
		hud.update_action_queue(_action_queue, queue_mode_enabled, player_id)


func _get_target_display_name(target: Node3D) -> String:
	if target.has_method("get_display_name"):
		return target.get_display_name()
	return _get_item_display_name(target)


func _show_hud_message(text: String, success: bool) -> void:
	var hud := _get_hud()
	if hud:
		hud.show_delivery_feedback(text, success)
