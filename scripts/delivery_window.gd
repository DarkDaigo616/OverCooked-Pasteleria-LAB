extends Station
class_name DeliveryWindow

signal order_delivered(success: bool, points: int)

var order_manager: OrderManager = null


func _ready() -> void:
	super._ready()
	station_name = "Ventanilla de entrega"
	can_hold_item = false
	_ensure_order_manager()


func _ensure_order_manager() -> void:
	if order_manager and is_instance_valid(order_manager):
		return
	order_manager = get_tree().get_first_node_in_group("order_manager") as OrderManager


func interact(player: ChefPlayer) -> void:
	super.interact(player)
	_ensure_order_manager()

	var held := player.get_held_item()
	if held == null:
		_show_delivery_message("Lleva un plato con la comida terminada.", false)
		return

	if not _is_plate(held):
		_show_delivery_message("Solo puedes entregar un plato.", false)
		return

	var ingredients: Array = _get_plate_ingredients(held)
	if ingredients.is_empty():
		_show_delivery_message("El plato esta vacio. Usa la mesa de emplatado.", false)
		return

	if order_manager == null:
		_show_delivery_message("Error: no hay gestor de ordenes.", false)
		return

	var result: Dictionary = order_manager.check_delivery(ingredients)
	if result.success:
		player.destroy_held_item()
		order_delivered.emit(true, result.points)
		_show_delivery_message("¡Orden entregada! +%d puntos" % result.points, true)
	else:
		order_delivered.emit(false, 0)
		var reason: String = result.get("reason", "Pedido incorrecto.")
		_show_delivery_message(
			"%s Usa el BASURERO para desechar el plato." % reason,
			false
		)


func _is_plate(node: Node3D) -> bool:
	return node.has_meta("is_plate") and node.get_meta("is_plate") == true


func _get_plate_ingredients(plate: Node3D) -> Array:
	if not plate.has_meta("ingredients"):
		return []
	var raw: Variant = plate.get_meta("ingredients")
	if raw is Array:
		return Recipe.normalize_list(raw)
	return []


func _show_delivery_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
