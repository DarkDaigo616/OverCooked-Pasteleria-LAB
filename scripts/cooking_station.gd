extends Station
class_name CookingStation

@export var cook_time: float = 5.0
@export var burn_time: float = 999.0
@export var auto_cook: bool = true

var cooking_timer: float = 0.0
var is_cooking: bool = false
var is_burned: bool = false
var _item_cooked: bool = false

var _progress_bar: ProgressBar3D


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

	if cooking_timer >= cook_time and not _item_cooked:
		_item_cooked = true
		if item.get_meta("ingredient_type", "") == "cake_batter":
			item.name = "cake"
			item.set_meta("ingredient_type", "cake")
			item.set_meta("state", "baked")
			item.set_meta("is_cake", true)
			item.set_meta("display_name", "Pastel horneado")
			ItemVisuals.apply_ingredient_visual(item, "cake", "baked", 0.75)
		else:
			item.set_meta("state", "cooked")
			if item.has_meta("ingredient_type"):
				ItemVisuals.apply_ingredient_visual(item, item.get_meta("ingredient_type"), "cooked", 0.35)

	if cooking_timer >= cook_time + burn_time and not is_burned:
		item.set_meta("state", "burned")
		is_burned = true
		is_cooking = false
		if item.has_meta("ingredient_type"):
			var burn_scale := 0.75 if item.get_meta("ingredient_type", "") == "cake" else 0.35
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
	else:
		_progress_bar.set_progress(1.0, Color(0.2, 0.95, 0.45))


func interact(player: ChefPlayer) -> void:
	super.interact(player)
	var held := player.get_held_item()

	if held and current_items.is_empty():
		if can_cook(held):
			var item := player.take_item_from_hand()
			if item:
				place_item(item)
		return

	if not current_items.is_empty() and not player.has_item():
		var item := take_item()
		if item:
			player.pickup_item(item)
			reset_cooking()


func can_cook(item: Node3D) -> bool:
	if not item.has_meta("is_ingredient"):
		return false
	var ing_type: String = item.get_meta("ingredient_type", "")
	if ing_type == "cake_batter":
		return item.get_meta("state", "") == "raw"
	if ing_type == "bread" or ing_type == "lettuce":
		return false
	if not item.has_meta("state"):
		return false
	var state: String = item.get_meta("state")
	return state == "raw" or state == "chopped"


func start_cooking() -> void:
	is_cooking = true
	cooking_timer = 0.0
	is_burned = false
	_item_cooked = false
	if _progress_bar:
		_progress_bar.show_bar(true)
		_progress_bar.set_progress(0.0, Color(1.0, 0.55, 0.15))


func reset_cooking() -> void:
	is_cooking = false
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
