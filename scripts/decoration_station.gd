extends Station
class_name DecorationStation

@export var decoration_time: float = 3.0
@export var decoration_type: String = "vanilla"

var _progress_bar: ProgressBar3D

const DECORATION_NAMES := {
	"vanilla": "Vainilla",
	"chocolate": "Chocolate",
}


func _ready() -> void:
	super._ready()
	station_name = "Decoracion: " + _get_decoration_display_name()
	max_items = 1
	_progress_bar = $ProgressBar3D if has_node("ProgressBar3D") else null


func interact(player: ChefPlayer) -> void:
	super.interact(player)

	if is_processing:
		_show_station_message("Decoracion en proceso.", false)
		return

	var held := player.get_held_item()
	if held and current_items.is_empty():
		var validation := _validate_cake(held)
		if not validation["success"]:
			_show_station_message(validation["reason"], false)
			return

		var item := player.take_item_from_hand()
		if item and place_item(item):
			start_decorating()
		return

	if not current_items.is_empty() and not player.has_item():
		var item := take_item()
		if item:
			player.pickup_item(item)
			if _progress_bar:
				_progress_bar.show_bar(false)
		return

	if held:
		_show_station_message("La mesa de decoracion esta ocupada.", false)
	else:
		_show_station_message("Trae un pastel horneado.", false)


func start_decorating() -> void:
	is_processing = true
	is_occupied = true
	process_timer = 0.0
	if _progress_bar:
		_progress_bar.set_progress(0.0, Color(0.95, 0.48, 0.72))


func _on_processing(_delta: float) -> void:
	if _progress_bar:
		_progress_bar.set_progress(process_timer / decoration_time, Color(0.95, 0.48, 0.72))
	if process_timer >= decoration_time:
		_finish_decorating()


func _finish_decorating() -> void:
	is_processing = false
	process_timer = 0.0

	if current_items.is_empty():
		return

	var cake := current_items[0]
	var decorated_state := _get_decorated_state()
	cake.set_meta("state", decorated_state)
	cake.set_meta("decoration_type", decoration_type)
	cake.set_meta("display_name", _get_finished_display_name())
	ItemVisuals.apply_ingredient_visual(cake, "cake", decorated_state, 0.95)

	if _progress_bar:
		_progress_bar.show_complete_check(true)

	_show_station_message("%s listo." % _get_finished_display_name(), decoration_type == "vanilla")


func _validate_cake(item: Node3D) -> Dictionary:
	if item == null:
		return {"success": false, "reason": "Trae un pastel horneado."}
	if str(item.get_meta("ingredient_type", "")) != "cake":
		return {"success": false, "reason": "Solo puedes decorar pasteles horneados."}

	var state := str(item.get_meta("state", ""))
	match state:
		"baked":
			return {"success": true, "reason": ""}
		"burned":
			return {"success": false, "reason": "El pastel esta quemado."}
		"ruined_baked":
			return {"success": false, "reason": "La mezcla salio mal; prepara otro."}
		"decorated_vanilla", "decorated_chocolate":
			return {"success": false, "reason": "Ese pastel ya esta decorado."}
		_:
			return {"success": false, "reason": "Primero hornea la masa."}


func _get_decorated_state() -> String:
	return "decorated_" + decoration_type


func _get_finished_display_name() -> String:
	if decoration_type == "vanilla":
		return "Pastel de vainilla"
	return "Pastel con " + _get_decoration_display_name().to_lower()


func _get_decoration_display_name() -> String:
	return DECORATION_NAMES.get(decoration_type, decoration_type.capitalize())


func _show_station_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
