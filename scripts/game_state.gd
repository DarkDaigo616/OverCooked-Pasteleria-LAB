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
	selected_level = clampi(level_id, 1, LevelRegistry.get_levels().size())
	get_tree().change_scene_to_file(LEVEL_SCENE)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func get_level_stars(level_id: int) -> int:
	return level_stars.get(level_id, 0) as int


func save_level_result(level_id: int, stars: int) -> void:
	if dev_mode:
		return
	if stars > get_level_stars(level_id):
		level_stars[level_id] = stars
		save_progress()


func is_level_unlocked_real(level_id: int) -> bool:
	var entry := LevelRegistry.get_level(level_id)
	if entry.is_empty():
		return false
	var unlock_after: int = entry.get("unlock_after", 0)
	return unlock_after == 0 or get_level_stars(unlock_after) >= 1


func is_level_playable(level_id: int) -> bool:
	return dev_mode or is_level_unlocked_real(level_id)


func is_level_unlocked(level_id: int) -> bool:
	return is_level_playable(level_id)


func clear_progress() -> void:
	level_stars.clear()
	save_progress()


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
