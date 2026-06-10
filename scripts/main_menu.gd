extends Control

@onready var level_list: VBoxContainer = $CenterPanel/MarginContainer/VBoxContainer/LevelList
@onready var play_button: Button = $CenterPanel/MarginContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $CenterPanel/MarginContainer/VBoxContainer/QuitButton

var _selected_level: int = 1
var _level_buttons: Array[Button] = []


func _ready() -> void:
	_build_level_buttons()
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_highlight_selection()


func _build_level_buttons() -> void:
	for i in range(1, LevelLayouts.get_level_count() + 1):
		var layout := LevelLayouts.get_layout(i)
		var btn := Button.new()
		btn.text = "%d — %s" % [i, layout.get("name", "Nivel")]
		btn.toggle_mode = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var level_id := i
		btn.pressed.connect(func(): _select_level(level_id))
		level_list.add_child(btn)
		_level_buttons.append(btn)


func _select_level(level_id: int) -> void:
	_selected_level = level_id
	_highlight_selection()


func _highlight_selection() -> void:
	for i in range(_level_buttons.size()):
		_level_buttons[i].button_pressed = (i + 1) == _selected_level


func _on_play_pressed() -> void:
	GameState.start_level(_selected_level)


func _on_quit_pressed() -> void:
	get_tree().quit()
