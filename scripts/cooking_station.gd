extends Station
class_name CookingStation

signal item_burned

@export var cook_time: float = 5.0
@export var burn_time: float = 999.0
@export var auto_cook: bool = true
@export_range(0.0, 1.0, 0.05) var progress_loss_on_remove: float = 0.2

var cooking_timer: float = 0.0
var is_cooking: bool = false
var is_burned: bool = false
var _item_cooked: bool = false

var _progress_bar: ProgressBar3D

const COOKING_PROGRESS_META := "cooking_progress"


func _ready() -> void:
	super._ready()
	station_name = "Horno"
	max_items = 1
	_progress_bar = $ProgressBar3D if has_node("ProgressBar3D") else null


func _process(delta: float) -> void:
	super._process(delta)

	if not is_cooking or current_items.is_empty():
		return

	cooking_timer += delta
	var item: Node3D = current_items[0]
	item.set_meta(COOKING_PROGRESS_META, cooking_timer)

	if cooking_timer >= cook_time and not _item_cooked:
		_item_cooked = true
		is_processing = false  # baking done — queued player can now pick up
		if item.get_meta("ingredient_type", "") == "cake_batter":
			item.name = "cake"
			item.set_meta("ingredient_type", "cake")
			item.set_meta("state", "baked")
			item.set_meta("is_cake", true)
			item.set_meta("display_name", "Pastel horneado")
			item.set_meta(COOKING_PROGRESS_META, cook_time)
			ItemVisuals.apply_ingredient_visual(item, "cake", "baked", 0.95)
		elif item.get_meta("ingredient_type", "") == "bad_batter":
			item.name = "cake"
			item.set_meta("ingredient_type", "cake")
			item.set_meta("state", "ruined_baked")
			item.set_meta("is_cake", true)
			item.set_meta("display_name", "Pastel fallido")
			item.set_meta(COOKING_PROGRESS_META, cook_time)
			ItemVisuals.apply_ingredient_visual(item, "cake", "ruined_baked", 0.95)
		else:
			item.set_meta("state", "cooked")
			item.set_meta(COOKING_PROGRESS_META, cook_time)
			if item.has_meta("ingredient_type"):
				ItemVisuals.apply_ingredient_visual(item, item.get_meta("ingredient_type"), "cooked", 0.35)

	if cooking_timer >= cook_time + burn_time and not is_burned:
		item.set_meta("state", "burned")
		item.set_meta(COOKING_PROGRESS_META, cook_time + burn_time)
		is_burned = true
		is_cooking = false
		is_processing = false
		item_burned.emit()
		if item.has_meta("ingredient_type"):
			var burn_scale := 0.95 if item.get_meta("ingredient_type", "") == "cake" else 0.45
			ItemVisuals.apply_ingredient_visual(item, item.get_meta("ingredient_type"), "burned", burn_scale)
		if _progress_bar:
			_progress_bar.show_bar(false)
		return

	_update_cook_bar()


func _update_cook_bar() -> void:
	if not _progress_bar:
		return
	_progress_bar.show_bar(true)
	if cooking_timer < cook_time:
		var ratio := cooking_timer / cook_time
		_progress_bar.set_progress(ratio, Color(1.0, 0.62, 0.18))
	elif burn_time < 900.0 and not is_burned:
		var burn_ratio := (cooking_timer - cook_time) / maxf(burn_time, 0.1)
		_progress_bar.set_progress(burn_ratio, Color(0.9, 0.12, 0.08))
	else:
		_progress_bar.show_complete_check(true)


func interact(player: ChefPlayer) -> void:
	super.interact(player)
	var held := player.get_held_item()

	if held:
		if current_items.is_empty():
			if can_cook(held):
				var item := player.take_item_from_hand()
				if item:
					place_item(item)
			else:
				_show_station_message("El horno necesita masa mezclada.", false)
		else:
			_show_station_message("El horno esta ocupado.", false)
		return

	if not current_items.is_empty() and not player.has_item():
		var item := take_item()
		if item:
			_store_interrupted_progress(item)
			player.pickup_item(item)
			reset_cooking()


func can_cook(item: Node3D) -> bool:
	if not item.has_meta("is_ingredient"):
		return false
	var ing_type: String = item.get_meta("ingredient_type", "")
	if ing_type == "cake_batter" or ing_type == "bad_batter":
		return item.get_meta("state", "") == "raw"
	if ing_type == "bread" or ing_type == "lettuce":
		return false
	if not item.has_meta("state"):
		return false
	var state: String = item.get_meta("state")
	return state == "raw" or state == "chopped"


func start_cooking() -> void:
	is_cooking = true
	var item := current_items[0] if not current_items.is_empty() else null
	cooking_timer = _get_saved_progress(item)
	is_burned = item != null and item.get_meta("state", "") == "burned"
	_item_cooked = cooking_timer >= cook_time or (item != null and item.get_meta("state", "") in ["baked", "cooked"])
	is_processing = not _item_cooked and not is_burned
	if _progress_bar:
		_update_cook_bar()


func reset_cooking() -> void:
	is_cooking = false
	is_processing = false
	cooking_timer = 0.0
	is_burned = false
	_item_cooked = false
	if _progress_bar:
		_progress_bar.show_bar(false)


func place_item(item: Node3D) -> bool:
	var result := super.place_item(item)
	if result and auto_cook:
		start_cooking()
	return result


func _get_saved_progress(item: Node3D) -> float:
	if item == null:
		return 0.0
	return clampf(float(item.get_meta(COOKING_PROGRESS_META, 0.0)), 0.0, cook_time + burn_time)


func _store_interrupted_progress(item: Node3D) -> void:
	if item == null:
		return
	if cooking_timer >= cook_time:
		item.set_meta(COOKING_PROGRESS_META, cooking_timer)
		return
	var saved_progress := cooking_timer * (1.0 - progress_loss_on_remove)
	item.set_meta(COOKING_PROGRESS_META, saved_progress)


func _show_station_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
