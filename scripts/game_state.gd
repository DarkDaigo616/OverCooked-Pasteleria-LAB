extends Node

var selected_level: int = 1

const LEVEL_SCENE := "res://scenes/levels/kitchen_level.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"


func start_level(level_id: int) -> void:
	get_tree().paused = false
	selected_level = clampi(level_id, 1, LevelLayouts.get_level_count())
	get_tree().change_scene_to_file(LEVEL_SCENE)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
