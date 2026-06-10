extends Control

@onready var center_panel: PanelContainer = $CenterPanel
@onready var level_list: VBoxContainer = $CenterPanel/MarginContainer/VBoxContainer/LevelList
@onready var play_button: Button = $CenterPanel/MarginContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $CenterPanel/MarginContainer/VBoxContainer/QuitButton

var _selected_level: int = 1
var _level_buttons: Array[Button] = []


func _ready() -> void:
	_apply_menu_style()
	_build_level_buttons()
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_highlight_selection()


func _apply_menu_style() -> void:
	center_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.98, 0.9, 0.74, 0.98), Color(0.72, 0.38, 0.16), 3, 10)
	)

	for label in find_children("*", "Label", true, false):
		var lbl := label as Label
		lbl.add_theme_color_override("font_color", Color(0.2, 0.11, 0.06))
		lbl.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.84, 0.9))
		lbl.add_theme_constant_override("outline_size", 1)

	var title := find_child("Title", true, false) as Label
	if title:
		title.text = "OverCooked"
		title.add_theme_font_size_override("font_size", 56)
		title.add_theme_color_override("font_color", Color(0.12, 0.07, 0.04))
		title.add_theme_constant_override("outline_size", 0)

	var eyebrow := find_child("Eyebrow", true, false) as Label
	if eyebrow:
		eyebrow.add_theme_font_size_override("font_size", 16)
		eyebrow.add_theme_color_override("font_color", Color(0.62, 0.29, 0.1))
		eyebrow.add_theme_constant_override("outline_size", 0)

	var subtitle := find_child("Subtitle", true, false) as Label
	if subtitle:
		subtitle.add_theme_font_size_override("font_size", 18)
		subtitle.add_theme_color_override("font_color", Color(0.38, 0.22, 0.12))
		subtitle.add_theme_constant_override("outline_size", 0)

	_style_button(play_button, Color(0.86, 0.34, 0.14), Color(1.0, 0.62, 0.26))
	_style_button(quit_button, Color(0.35, 0.24, 0.18), Color(0.52, 0.34, 0.23))


func _build_level_buttons() -> void:
	for child in level_list.get_children():
		child.queue_free()
	_level_buttons.clear()

	for i in range(1, LevelLayouts.get_level_count() + 1):
		var layout := LevelLayouts.get_layout(i)
		var btn := Button.new()
		btn.text = "Nivel %d  -  %s" % [i, layout.get("name", "Nivel")]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 19)
		_style_button(btn, Color(0.92, 0.73, 0.42), Color(0.98, 0.79, 0.45), Color(0.16, 0.09, 0.04))
		var level_id := i
		btn.pressed.connect(func(): _select_level(level_id))
		level_list.add_child(btn)
		_level_buttons.append(btn)


func _select_level(level_id: int) -> void:
	_selected_level = level_id
	_highlight_selection()


func _highlight_selection() -> void:
	for i in range(_level_buttons.size()):
		var selected := (i + 1) == _selected_level
		var btn := _level_buttons[i]
		btn.button_pressed = selected
		if selected:
			_style_button(btn, Color(0.96, 0.62, 0.22), Color(1.0, 0.73, 0.3), Color(0.12, 0.06, 0.03))
		else:
			_style_button(btn, Color(0.92, 0.73, 0.42), Color(0.98, 0.79, 0.45), Color(0.16, 0.09, 0.04))


func _style_button(
	button: Button,
	normal_color: Color,
	hover_color: Color,
	font_color: Color = Color(1.0, 0.92, 0.76)
) -> void:
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.18))
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_stylebox_override("normal", _make_panel_style(normal_color, normal_color.lightened(0.22), 2, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(hover_color, hover_color.lightened(0.22), 2, 8))
	button.add_theme_stylebox_override("pressed", _make_panel_style(normal_color.darkened(0.12), hover_color, 2, 8))
	button.add_theme_stylebox_override("focus", _make_panel_style(hover_color, Color(1.0, 0.86, 0.48), 3, 8))


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.16, 0.08, 0.03, 0.32)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _on_play_pressed() -> void:
	GameState.start_level(_selected_level)


func _on_quit_pressed() -> void:
	get_tree().quit()
