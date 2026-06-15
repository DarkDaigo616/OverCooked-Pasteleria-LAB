extends Station
class_name RecipeBookStation


func _ready() -> void:
	super._ready()
	station_name = "Recetario"
	can_hold_item = false


func interact(player: ChefPlayer) -> void:
	super.interact(player)
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_recipe_book(true)
