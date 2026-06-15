extends Station
class_name DeliveryWindow

signal order_delivered(success: bool, points: int)

@export var delivery_time: float = 1.0

var order_manager: OrderManager = null
var _progress_bar: ProgressBar3D


func _ready() -> void:
	can_hold_item = true
	max_items = 1
	super._ready()
	station_name = "Entrega"
	_progress_bar = $ProgressBar3D if has_node("ProgressBar3D") else null
	_ensure_order_manager()


func _ensure_order_manager() -> void:
	if order_manager and is_instance_valid(order_manager):
		return
	order_manager = get_tree().get_first_node_in_group("order_manager") as OrderManager


func interact(player: ChefPlayer) -> void:
	super.interact(player)
	_ensure_order_manager()

	if is_processing:
		_show_delivery_message("Entregando pedido...", false)
		return

	var held := player.get_held_item()
	if held and current_items.is_empty():
		var validation := _validate_delivery_item(held)
		if not validation["success"]:
			_show_delivery_message(validation["reason"], false)
			return

		var item := player.take_item_from_hand()
		if item and place_item(item):
			start_delivery()
		return

	if not current_items.is_empty() and not player.has_item():
		var item := take_item()
		if item:
			player.pickup_item(item)
			if _progress_bar:
				_progress_bar.show_bar(false)
		return

	if held:
		_show_delivery_message("La ventana de entrega esta ocupada.", false)
	else:
		_show_delivery_message("Lleva un pastel terminado.", false)


func start_delivery() -> void:
	is_processing = true
	is_occupied = true
	process_timer = 0.0
	if _progress_bar:
		_progress_bar.set_progress(0.0, Color(0.34, 0.78, 0.42))


func _on_processing(_delta: float) -> void:
	if _progress_bar:
		_progress_bar.set_progress(process_timer / delivery_time, Color(0.34, 0.78, 0.42))
	if process_timer >= delivery_time:
		_finish_delivery()


func _finish_delivery() -> void:
	is_processing = false
	process_timer = 0.0

	if current_items.is_empty():
		return

	if order_manager == null:
		order_delivered.emit(false, 0)
		_show_delivery_message("Error: no hay gestor de ordenes.", false)
		if _progress_bar:
			_progress_bar.show_bar(false)
		return

	var item := current_items[0]
	var entry := _get_delivery_entry(item)
	if entry.is_empty():
		order_delivered.emit(false, 0)
		_show_delivery_message("Pedido incorrecto.", false)
		if _progress_bar:
			_progress_bar.show_bar(false)
		return

	var result := order_manager.check_delivery([entry])
	if result.success:
		order_delivered.emit(true, result.points)
		_show_delivery_message("Pastel entregado! +%d puntos" % result.points, true)
		clear_items()
		if _progress_bar:
			_progress_bar.show_complete_check(true)
	else:
		order_delivered.emit(false, 0)
		_show_delivery_message(result.get("reason", "Pedido incorrecto."), false)
		if _progress_bar:
			_progress_bar.show_bar(false)


func _validate_delivery_item(item: Node3D) -> Dictionary:
	var ingredient_type := str(item.get_meta("ingredient_type", ""))
	var state := str(item.get_meta("state", ""))

	if ingredient_type == "cake_batter" or ingredient_type == "bad_batter":
		return {"success": false, "reason": "Todavia es masa. Primero usa el horno."}
	if ingredient_type != "cake":
		return {"success": false, "reason": "Solo puedes entregar pasteles."}

	match state:
		"baked":
			return {"success": true, "reason": ""}
		"burned":
			return {"success": false, "reason": "El pastel se quemo. Prepara otro."}
		"ruined_baked":
			return {"success": false, "reason": "La mezcla salio mal. Prepara otro."}
		"decorated_vanilla", "decorated_chocolate":
			return {"success": true, "reason": ""}
		_:
			return {"success": false, "reason": "Ese pastel no esta terminado."}


func _get_delivery_entry(item: Node3D) -> Dictionary:
	if str(item.get_meta("ingredient_type", "")) != "cake":
		return {}
	var state := str(item.get_meta("state", ""))
	if state != "baked" and not state.begins_with("decorated_"):
		return {}
	return {"type": "cake", "state": state}


func _show_delivery_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
