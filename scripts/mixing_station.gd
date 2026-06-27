extends Station
class_name MixingStation

@export var mix_time: float = 4.0

var _progress_bar: ProgressBar3D

const VALID_INGREDIENTS := ["flour", "egg"]
const ACCEPTED_INGREDIENTS := ["flour", "egg", "sugar"]


func _ready() -> void:
	super._ready()
	station_name = "Batidora"
	max_items = 2
	_progress_bar = $ProgressBar3D if has_node("ProgressBar3D") else null


func interact(player: ChefPlayer) -> void:
	super.interact(player)

	if is_processing:
		_show_station_message("Batidora ocupada.", false)
		return

	var held := player.get_held_item()
	if held:
		if _has_finished_product():
			_show_station_message("Retira primero la masa.", false)
			return
		if not can_place_item(held):
			_show_station_message("La batidora necesita ingredientes crudos.", false)
			return

		var item := player.take_item_from_hand()
		if item and place_item(item) and current_items.size() >= max_items:
			start_mixing()
		return

	if _has_finished_product():
		var product := take_item()
		if product:
			player.pickup_item(product)
			if _progress_bar:
				_progress_bar.show_bar(false)
		return

	if not current_items.is_empty():
		var item := take_item()
		if item:
			player.pickup_item(item)
		return

	_show_station_message("Trae harina y huevo.", false)


func can_place_item(item: Node3D) -> bool:
	return (
		not is_processing
		and not _has_finished_product()
		and super.can_place_item(item)
		and _can_accept_item(item)
	)


func start_mixing() -> void:
	if current_items.size() < max_items:
		return
	is_processing = true
	is_occupied = true
	process_timer = 0.0
	if _progress_bar:
		_progress_bar.set_progress(0.0, Color(0.38, 0.62, 0.92))


func _on_processing(_delta: float) -> void:
	if _progress_bar:
		_progress_bar.set_progress(process_timer / mix_time, Color(0.38, 0.62, 0.92))
	if process_timer >= mix_time:
		_finish_mixing()


func _finish_mixing() -> void:
	var valid_mix := _has_required_mix()
	for item in current_items:
		if item and is_instance_valid(item):
			item.queue_free()
	current_items.clear()

	is_processing = false
	process_timer = 0.0
	is_occupied = false

	var product := _create_batter(valid_mix)
	_place_finished_product(product)

	if _progress_bar:
		_progress_bar.show_complete_check(true)

	if valid_mix:
		_show_station_message("Masa de vainilla lista.", true)
	else:
		_show_station_message("Mezcla incorrecta.", false)


func _has_required_mix() -> bool:
	if current_items.size() != max_items:
		return false

	var counts := {"flour": 0, "egg": 0}
	for item in current_items:
		var ingredient_type := str(item.get_meta("ingredient_type", ""))
		var state := str(item.get_meta("state", ""))
		if state != "raw" or not VALID_INGREDIENTS.has(ingredient_type):
			return false
		counts[ingredient_type] += 1

	return counts["flour"] == 1 and counts["egg"] == 1


func _can_accept_item(item: Node3D) -> bool:
	if item == null or not item.get_meta("is_ingredient", false):
		return false
	var ingredient_type := str(item.get_meta("ingredient_type", ""))
	var state := str(item.get_meta("state", ""))
	return state == "raw" and ACCEPTED_INGREDIENTS.has(ingredient_type)


func _has_finished_product() -> bool:
	if current_items.size() != 1:
		return false
	var item := current_items[0]
	var ingredient_type := str(item.get_meta("ingredient_type", ""))
	return ingredient_type == "cake_batter" or ingredient_type == "bad_batter"


func _create_batter(valid_mix: bool) -> Node3D:
	var batter := Node3D.new()
	var ingredient_type := "cake_batter" if valid_mix else "bad_batter"
	batter.name = ingredient_type
	batter.set_meta("ingredient_type", ingredient_type)
	batter.set_meta("state", "raw")
	batter.set_meta("is_ingredient", true)
	batter.set_meta("display_name", "Masa de vainilla" if valid_mix else "Masa incorrecta")
	ItemVisuals.apply_ingredient_visual(batter, ingredient_type, "raw", 0.95)

	var static_body := StaticBody3D.new()
	static_body.collision_layer = PhysicsLayers.ITEMS
	static_body.collision_mask = PhysicsLayers.MASK_ITEM
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.32
	collision.shape = shape
	static_body.add_child(collision)
	batter.add_child(static_body)
	return batter


func _place_finished_product(product: Node3D) -> void:
	current_items.append(product)
	if product.get_parent():
		product.get_parent().remove_child(product)
	if item_holder:
		item_holder.add_child(product)
		product.position = Vector3(0, 0.18, 0)
		product.rotation = Vector3.ZERO
	is_occupied = true
	item_placed.emit(product)


func has_ready_output() -> bool:
	return not is_processing and _has_finished_product()


func _show_station_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
