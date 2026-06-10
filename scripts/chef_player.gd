extends CharacterBody3D
class_name ChefPlayer

const CHEF_MODEL_PATH := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/fbx/Chef.fbx"

@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0
@export var interact_range: float = 2.8
@export var click_stop_distance: float = 0.15
@export var floor_y: float = 1.0
@export var chef_model_scale: float = 0.42
@export var chef_model_y_offset: float = 0.0
@export var model_yaw_offset_deg: float = 180.0

var held_item: Node3D = null
var movement_enabled: bool = true
var _interactables_in_range: Array[Node3D] = []
var _level_bounds_half: float = 15.0
var _spawn_position: Vector3 = Vector3.ZERO
var _last_target: Node3D = null
var _move_target: Vector3 = Vector3.ZERO
var _has_move_target: bool = false

@onready var model = $Model
@onready var hand_position: Node3D = $Model/HandPosition
@onready var knife_hold_visual: MeshInstance3D = $Model/HandPosition/KnifeHoldVisual if has_node("Model/HandPosition/KnifeHoldVisual") else null

signal item_picked_up(item)
signal item_dropped(item)
signal interacted_with_station(station)


func _ready() -> void:
	add_to_group("player")
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

	hand_position.position = Vector3(0.45, 0.95, 0.35)


func configure_level_bounds(half_size: float, spawn: Vector3) -> void:
	_level_bounds_half = half_size - 1.2
	_spawn_position = spawn
	global_position = spawn
	_move_target = spawn
	_has_move_target = false
	if _spawn_position.y < floor_y:
		_spawn_position.y = floor_y


func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector3.ZERO
		return
	_refresh_nearby_interactables()
	handle_movement(delta)
	handle_rotation(delta)
	move_and_slide()
	_enforce_safe_position()


func _input(event: InputEvent) -> void:
	if not movement_enabled:
		return
	if event.is_action_pressed("interact"):
		attempt_interaction()
	if event.is_action_pressed("drop") and held_item:
		drop_item()


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_set_click_move_target(mouse_event.position)


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
	_move_target = target
	_has_move_target = true


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

	var target := _get_best_interactable()
	_update_station_highlights(target)
	_update_interaction_hud(target)


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
	else:
		hud.clear_station_target()


func _get_hud() -> GameHUD:
	return get_tree().get_first_node_in_group("game_hud") as GameHUD


func handle_movement(delta: float) -> void:
	if not movement_enabled:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		return

	var to_target := _move_target - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if _has_move_target and distance > click_stop_distance:
		var direction := to_target / distance
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		_has_move_target = false
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	if global_position.y > floor_y + 0.05:
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0


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


func get_held_item() -> Node3D:
	return held_item


func has_item() -> bool:
	return held_item != null
