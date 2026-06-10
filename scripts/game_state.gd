extends Node

## Nivel seleccionado en el menú (1-5).
var selected_level: int = 1

const LEVEL_SCENES: Array[String] = [
	"res://scenes/levels/kitchen_level.tscn",
	"res://scenes/levels/kitchen_level.tscn",
	"res://scenes/levels/kitchen_level.tscn",
	"res://scenes/levels/kitchen_level.tscn",
	"res://scenes/levels/kitchen_level.tscn",
]

const MENU_SCENE := "res://scenes/main_menu.tscn"


func start_level(level_id: int) -> void:
	selected_level = clampi(level_id, 1, 5)
	get_tree().change_scene_to_file(LEVEL_SCENES[0])


func go_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
