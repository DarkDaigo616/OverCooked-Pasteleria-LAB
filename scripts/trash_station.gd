extends Station
class_name TrashStation

## Descarta platos con pedidos incorrectos para liberar las manos del jugador.


func _ready() -> void:
	super._ready()
	station_name = "Basurero"
	can_hold_item = false


func interact(player: ChefPlayer) -> void:
	super.interact(player)

	var held := player.get_held_item()
	if held == null:
		_show_message("Trae un plato con pedido incorrecto para desecharlo.", false)
		return

	if _is_plate(held):
		var ingredients: Array = _get_plate_ingredients(held)
		if ingredients.is_empty():
			player.destroy_held_item()
			_show_message("Plato vacio desechado.", true)
		else:
			player.destroy_held_item()
			_show_message("Pedido incorrecto desechado.", true)
		return

	player.destroy_held_item()
	_show_message("Objeto desechado.", true)


func _is_plate(node: Node3D) -> bool:
	return node.has_meta("is_plate") and node.get_meta("is_plate") == true


func _get_plate_ingredients(plate: Node3D) -> Array:
	if not plate.has_meta("ingredients"):
		return []
	var raw: Variant = plate.get_meta("ingredients")
	if raw is Array:
		return Recipe.normalize_list(raw)
	return []


func _show_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
