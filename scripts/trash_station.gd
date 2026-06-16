extends Station
class_name TrashStation


func _ready() -> void:
	can_hold_item = false
	super._ready()
	station_name = "Basura"


func interact(player: ChefPlayer) -> void:
	super.interact(player)

	if not player.has_item():
		_show_station_message("Trae algo para tirar.", false)
		return

	player.destroy_held_item()
	_show_station_message("Tirado a la basura.", true)


func _show_station_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
