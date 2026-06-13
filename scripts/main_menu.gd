extends Control

@onready var center_panel: PanelContainer = $CenterPanel

var level_list: VBoxContainer
var play_button: Button
var quit_button: Button

var _selected_level: int = 1
var _level_buttons: Array[Button] = []
var _click_player: AudioStreamPlayer
var _hover_player: AudioStreamPlayer


func _ready() -> void:
	_click_player = UITheme.make_sound_player(self, UITheme.CLICK_SOUND)
	_hover_player = UITheme.make_sound_player(self, UITheme.TAP_SOUND, -12.0)
	_apply_screen_style()
	_build_menu_layout()
	_build_level_buttons()
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_highlight_selection()


func _apply_screen_style() -> void:
	var bg := get_node_or_null("Background") as ColorRect
	if bg:
		bg.color = Color(0.24, 0.37, 0.61)

	var warm := get_node_or_null("WarmPanel") as ColorRect
	if warm:
		warm.color = Color(0.98, 0.78, 0.56)
		warm.anchor_left = 0.04
		warm.anchor_top = 0.08
		warm.anchor_right = 0.96
		warm.anchor_bottom = 0.9

	var inner := get_node_or_null("InnerPanel") as ColorRect
	if inner:
		inner.color = Color(0.58, 0.78, 0.74)
		inner.anchor_left = 0.06
		inner.anchor_top = 0.12
		inner.anchor_right = 0.94
		inner.anchor_bottom = 0.86

	for decor_name in ["DecorLeft", "DecorRight"]:
		var decor := get_node_or_null(decor_name) as ColorRect
		if decor:
			decor.visible = false

	center_panel.set_anchors_preset(Control.PRESET_CENTER)
	center_panel.offset_left = -520
	center_panel.offset_top = -310
	center_panel.offset_right = 520
	center_panel.offset_bottom = 310
	center_panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(0.98, 0.93, 0.82, 0.98), Color(0.25, 0.18, 0.19), 4, 8)
	)


func _build_menu_layout() -> void:
	var margin := center_panel.get_node_or_null("MarginContainer") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "MarginContainer"
		center_panel.add_child(margin)

	for child in margin.get_children():
		margin.remove_child(child)
		child.queue_free()

	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)

	layout.add_child(_build_showcase_panel())
	layout.add_child(_build_controls_panel())


func _build_showcase_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(0.9, 0.96, 0.91, 1.0), Color(0.22, 0.46, 0.44), 3, 8)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var eyebrow := Label.new()
	eyebrow.text = "PASTELERIA DE UN CLICK"
	UITheme.apply_label(eyebrow, 18, Color(0.23, 0.42, 0.45))
	vbox.add_child(eyebrow)

	var title := Label.new()
	title.text = "PASTEL RUSH"
	UITheme.apply_label(title, 64, Color(0.18, 0.13, 0.18), 2)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Apunta, cocina y entrega antes de que el pedido se enfrie."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_label(subtitle, 20, UITheme.COLOR_MUTED)
	vbox.add_child(subtitle)

	var recipe := _build_recipe_preview()
	recipe.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(recipe)

	return panel


func _build_recipe_preview() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(1.0, 0.96, 0.84, 1.0), Color(0.72, 0.54, 0.28), 3, 8)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	vbox.add_child(title_row)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(74, 74)
	badge.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(1.0, 0.72, 0.24, 1.0), Color(0.72, 0.42, 0.12), 3, 8)
	)
	var cake := Label.new()
	cake.text = "CAKE"
	cake.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cake.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.apply_label(cake, 16, Color(0.34, 0.18, 0.08))
	badge.add_child(cake)
	title_row.add_child(badge)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_box)

	var order_label := Label.new()
	order_label.text = "Pedido: Pastel basico"
	UITheme.apply_label(order_label, 24, UITheme.COLOR_INK)
	title_box.add_child(order_label)

	var reward := Label.new()
	reward.text = "100 puntos por entrega perfecta"
	UITheme.apply_label(reward, 16, UITheme.COLOR_MUTED)
	title_box.add_child(reward)

	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 8)
	vbox.add_child(steps)
	steps.add_child(_make_step_chip("1", "Ingredientes", UITheme.COLOR_GREEN))
	steps.add_child(UITheme.icon(UITheme.ICON_ARROW, Vector2(26, 26)))
	steps.add_child(_make_step_chip("2", "Hornear", UITheme.COLOR_BLUE))
	steps.add_child(UITheme.icon(UITheme.ICON_ARROW, Vector2(26, 26)))
	steps.add_child(_make_step_chip("3", "Entregar", UITheme.COLOR_YELLOW))

	return card


func _make_step_chip(number: String, label_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(color, color.darkened(0.2), 2, 8, false))

	var label := Label.new()
	label.text = "%s. %s" % [number, label_text]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label(label, 16, Color.WHITE, 1)
	panel.add_child(label)
	return panel


func _build_controls_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 0)
	panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(0.94, 0.94, 0.98, 1.0), Color(0.42, 0.46, 0.58), 3, 8)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var heading := Label.new()
	heading.text = "Seleccion de nivel"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label(heading, 28, UITheme.COLOR_INK)
	vbox.add_child(heading)

	level_list = VBoxContainer.new()
	level_list.add_theme_constant_override("separation", 8)
	level_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(level_list)

	play_button = Button.new()
	play_button.text = "Jugar"
	play_button.icon = UITheme.texture(UITheme.ICON_PLAY)
	play_button.custom_minimum_size = Vector2(0, 64)
	play_button.expand_icon = true
	play_button.add_theme_constant_override("icon_max_width", 30)
	UITheme.apply_button(play_button, UITheme.COLOR_GREEN, Color(0.2, 0.82, 0.5), Color(0.12, 0.55, 0.3))
	_connect_button_sounds(play_button)
	vbox.add_child(play_button)

	quit_button = Button.new()
	quit_button.text = "Salir"
	quit_button.icon = UITheme.texture(UITheme.ICON_CLOSE)
	quit_button.custom_minimum_size = Vector2(0, 52)
	quit_button.add_theme_constant_override("icon_max_width", 24)
	UITheme.apply_button(quit_button, Color(0.48, 0.5, 0.6), Color(0.6, 0.62, 0.72), Color(0.32, 0.34, 0.42))
	_connect_button_sounds(quit_button)
	vbox.add_child(quit_button)

	return panel


func _build_level_buttons() -> void:
	for child in level_list.get_children():
		child.queue_free()
	_level_buttons.clear()

	for i in range(1, LevelLayouts.get_level_count() + 1):
		var layout := LevelLayouts.get_layout(i)
		var btn := Button.new()
		btn.text = "Nivel %d  -  %s" % [i, layout.get("name", "Nivel")]
		btn.icon = UITheme.texture(UITheme.ICON_STAR)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 58)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_constant_override("icon_max_width", 26)
		UITheme.apply_button(btn, Color(0.96, 0.76, 0.28), Color(1.0, 0.84, 0.35), Color(0.84, 0.58, 0.18), UITheme.COLOR_INK)
		_connect_button_sounds(btn)
		var level_id := i
		btn.pressed.connect(func(): _select_level(level_id))
		btn.gui_input.connect(func(event: InputEvent): _on_level_button_gui_input(event, level_id))
		level_list.add_child(btn)
		_level_buttons.append(btn)


func _connect_button_sounds(button: Button) -> void:
	button.mouse_entered.connect(func(): _play_sound(_hover_player))
	button.pressed.connect(func(): _play_sound(_click_player))


func _play_sound(player: AudioStreamPlayer) -> void:
	if player:
		player.stop()
		player.play()


func _select_level(level_id: int) -> void:
	_selected_level = level_id
	_highlight_selection()


func _on_level_button_gui_input(event: InputEvent, level_id: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.double_click:
			_selected_level = level_id
			_play_sound(_click_player)
			GameState.start_level(_selected_level)


func _highlight_selection() -> void:
	for i in range(_level_buttons.size()):
		var selected := (i + 1) == _selected_level
		var btn := _level_buttons[i]
		btn.button_pressed = selected
		if selected:
			UITheme.apply_button(btn, UITheme.COLOR_YELLOW, Color(1.0, 0.82, 0.28), Color(0.86, 0.56, 0.1), UITheme.COLOR_INK)
		else:
			UITheme.apply_button(btn, Color(0.88, 0.9, 0.98), Color(0.96, 0.96, 1.0), Color(0.72, 0.74, 0.85), UITheme.COLOR_INK)


func _on_play_pressed() -> void:
	GameState.start_level(_selected_level)


func _on_quit_pressed() -> void:
	get_tree().quit()
