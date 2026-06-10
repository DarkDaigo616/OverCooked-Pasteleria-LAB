extends Station
class_name DeliveryWindow

signal order_delivered(success: bool, points: int)

var order_manager: OrderManager = null


func _ready() -> void:
	super._ready()
	station_name = "Entrega"
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
		_show_delivery_message("Lleva un pastel horneado.", false)
		return

	if held.get_meta("ingredient_type", "") == "cake_batter":
		_show_delivery_message("Todavia es masa. Primero usa el HORNO.", false)
		return

	if held.get_meta("ingredient_type", "") == "cake" and held.get_meta("state", "") == "burned":
		_show_delivery_message("El pastel se quemo. Prepara otro.", false)
		return

	if not _is_baked_cake(held):
		_show_delivery_message("Solo puedes entregar un pastel horneado.", false)
		return

	if order_manager == null:
		_show_delivery_message("Error: no hay gestor de ordenes.", false)
		return

	var result := order_manager.check_delivery([
		{"type": "cake", "state": "baked"}
	])
	if result.success:
		player.destroy_held_item()
		order_delivered.emit(true, result.points)
		_show_delivery_message("Pastel entregado! +%d puntos" % result.points, true)
	else:
		order_delivered.emit(false, 0)
		_show_delivery_message(result.get("reason", "Pedido incorrecto."), false)


func _is_baked_cake(node: Node3D) -> bool:
	return node.get_meta("ingredient_type", "") == "cake" and node.get_meta("state", "") == "baked"


func _show_delivery_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
