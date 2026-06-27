extends Node

var selected_level: int = 1
var level_stars: Dictionary = {}
var dev_mode: bool = false

const LEVEL_SCENE := "res://scenes/levels/kitchen_level.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const SAVE_PATH := "user://progress.cfg"


func _ready() -> void:
	load_progress()


func start_level(level_id: int) -> void:
	get_tree().paused = false
	selected_level = clampi(level_id, 1, LevelLayouts.get_level_count())
	get_tree().change_scene_to_file(LEVEL_SCENE)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func get_level_stars(level_id: int) -> int:
	return level_stars.get(level_id, 0) as int


func save_level_result(level_id: int, stars: int) -> void:
	if stars > get_level_stars(level_id):
		level_stars[level_id] = stars
		save_progress()


func is_level_unlocked(level_id: int) -> bool:
	if dev_mode or level_id <= 1:
		return true
	return get_level_stars(level_id - 1) >= 1


func save_progress() -> void:
	var cfg := ConfigFile.new()
	for level_id: Variant in level_stars:
		cfg.set_value("stars", str(level_id), level_stars[level_id])
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	if not cfg.has_section("stars"):
		return
	for key: String in cfg.get_section_keys("stars"):
		level_stars[int(key)] = cfg.get_value("stars", key, 0) as int
