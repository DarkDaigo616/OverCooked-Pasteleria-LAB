extends Station
class_name AssemblyStation

@export var max_ingredients: int = 5


func _ready():
	super._ready()
	station_name = "Assembly Table"
	max_items = max_ingredients


func interact(player: ChefPlayer):
	super.interact(player)

	var held := player.get_held_item()

	if held and held.has_meta("is_plate"):
		if current_items.is_empty():
			var plate := player.take_item_from_hand()
			if plate:
				place_item(plate)
		else:
			var plate_from_table := take_item()
			if plate_from_table:
				player.pickup_item(plate_from_table)
		return

	if held and held.has_meta("is_ingredient"):
		if not current_items.is_empty() and current_items[0].has_meta("is_plate"):
			var plate: Node3D = current_items[0]
			var ing := player.take_item_from_hand()
			if ing:
				add_ingredient_to_plate(plate, ing)
				ing.queue_free()
		return

	if not held and not current_items.is_empty():
		var item := take_item()
		if item:
			player.pickup_item(item)


func add_ingredient_to_plate(plate: Node3D, ingredient: Node3D):
	var ingredients: Array = plate.get_meta("ingredients", [])

	var ing_data = {
		"type": ingredient.get_meta("ingredient_type", "unknown"),
		"state": ingredient.get_meta("state", "raw")
	}

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
