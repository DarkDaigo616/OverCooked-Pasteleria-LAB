extends Station
class_name PlatingStation

@export var max_ingredients: int = 6

var _progress_bar: ProgressBar3D


func _ready() -> void:
	super._ready()
	station_name = "Emplatado"
	max_items = 1
	can_hold_item = true
	_progress_bar = _get_progress_bar()
	_update_plating_bar()


func _get_progress_bar() -> ProgressBar3D:
	if has_node("ProgressBar3D"):
		return $ProgressBar3D as ProgressBar3D
	return null


func _process(_delta: float) -> void:
	super._process(_delta)
	_update_plating_bar()


func _update_plating_bar() -> void:
	if not _progress_bar:
		return
	if current_items.is_empty():
		_progress_bar.show_bar(false)
		return
	var plate: Node3D = current_items[0]
	if not plate.has_meta("is_plate"):
		_progress_bar.show_bar(false)
		return
	var ings: Array = plate.get_meta("ingredients", [])
	var ratio := float(ings.size()) / float(max_ingredients)
	_progress_bar.show_bar(true)
	_progress_bar.set_progress(ratio, Color(0.95, 0.75, 0.2))


func interact(player: ChefPlayer) -> void:
	super.interact(player)
	var held := player.get_held_item()

	# 1) Colocar plato vacío en la mesa
	if held and held.has_meta("is_plate"):
		if current_items.is_empty():
			var plate := player.take_item_from_hand()
			if plate:
				place_item(plate)
				_update_plating_bar()
		else:
			var taken := take_item()
			if taken:
				player.pickup_item(taken)
		return

	# 2) Añadir ingrediente al plato en la mesa
	if held and held.has_meta("is_ingredient"):
		if not current_items.is_empty() and current_items[0].has_meta("is_plate"):
			var plate: Node3D = current_items[0]
			var ings: Array = plate.get_meta("ingredients", [])
			if ings.size() >= max_ingredients:
				return
			var ing := player.take_item_from_hand()
			if ing:
				add_ingredient_to_plate(plate, ing)
				ing.queue_free()
				_update_plating_bar()
		return

	# 3) Recoger plato terminado
	if not held and not current_items.is_empty():
		var item := take_item()
		if item:
			player.pickup_item(item)


func add_ingredient_to_plate(plate: Node3D, ingredient: Node3D) -> void:
	var ingredients: Array = plate.get_meta("ingredients", [])

	var ing_data := Recipe.normalize_entry({
		"type": ingredient.get_meta("ingredient_type", "unknown"),
		"state": ingredient.get_meta("state", "raw"),
	})
	ingredients.append(ing_data)
	plate.set_meta("ingredients", ingredients)

	var visual := Node3D.new()
	ItemVisuals.apply_ingredient_visual(
		visual,
		str(ing_data["type"]),
		str(ing_data["state"]),
		0.22
	)
	plate.add_child(visual)
	visual.position = Vector3(0, 0.03 + 0.04 * ingredients.size(), 0)
