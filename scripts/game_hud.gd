extends CanvasLayer
class_name GameHUD

@onready var score_label = $MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var timer_label = $MarginContainer/VBoxContainer/TopBar/TimerLabel
@onready var level_banner: PanelContainer = $MarginContainer/VBoxContainer/LevelBanner
@onready var level_label = $MarginContainer/VBoxContainer/LevelBanner/LevelLabel
@onready var orders_panel: PanelContainer = $MarginContainer/VBoxContainer/OrdersPanel
@onready var orders_container: VBoxContainer = (
	$MarginContainer/VBoxContainer/OrdersPanel/VBoxContainer/OrdersScroll/OrdersList
)
@onready var orders_title: Label = $MarginContainer/VBoxContainer/OrdersPanel/VBoxContainer/Title
@onready var orders_scroll: ScrollContainer = (
	$MarginContainer/VBoxContainer/OrdersPanel/VBoxContainer/OrdersScroll
)
@onready var interaction_hint = $InteractionHint
@onready var game_over_panel = $GameOverPanel
@onready var final_score_label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var menu_button = $GameOverPanel/VBoxContainer/MenuButton

var score: int = 0
var game_time: float = 240.0
var game_active: bool = true

signal game_ended(final_score: int)


const HINT_DEFAULT := "Click en una estacion u objeto"
const DELIVERY_FEEDBACK_DURATION := 3.5
const RECIPE_BOOK_TEXTURES := {
	1: "res://assets/ui/recipe_book_level1.png",
	2: "res://assets/ui/recipe_book_level2.png",
}

const ORDER_NAME_FONT := 22
const ORDER_DETAIL_FONT := 16
const ORDER_TIME_FONT := 18
const ORDER_PANEL_WIDTH := 360
const ORDER_PANEL_HEIGHT := 150
const ORDER_OUTLINE_SIZE := 1

const INGREDIENT_NAMES := {
	"cake": "Pastel",
	"cake_batter": "Masa",
	"bad_batter": "Masa",
	"flour": "Harina",
	"egg": "Huevo",
	"sugar": "Azucar",
	"bread": "Pan",
	"meat": "Carne",
	"lettuce": "Lechuga",
	"tomato": "Tomate",
}
const STATE_NAMES := {
	"baked": "horneado",
	"burned": "quemado",
	"decorated_vanilla": "vainilla",
	"decorated_chocolate": "chocolate",
	"ruined_baked": "fallido",
	"raw": "crudo",
	"cooked": "cocido",
	"chopped": "cortado",
}

var _delivery_feedback_tween: Tween
var _interaction_flash_tween: Tween
var _delivery_feedback_active := false
var _hud_skin: Control
var _action_panel: PanelContainer
var _action_icon: TextureRect
var _score_pill: PanelContainer
var _timer_pill: PanelContainer
var _pause_overlay: Control
var _resume_button: Button
var _pause_menu_button: Button
var _click_player: AudioStreamPlayer
var _order_panel_style: StyleBoxFlat
var _max_order_slots: int = 4
var _game_paused := false
var _recipe_book_overlay: Control
var _recipe_book_started_level := false
var _recipe_book_paused_tree := false
var _recipe_book_texture: TextureRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_hud")
	_click_player = UITheme.make_sound_player(self, UITheme.CLICK_SOUND)
	_resolve_orders_nodes()
	_build_hud_layout()
	_setup_top_labels()
	_setup_orders_panel()
	update_score(0)
	if interaction_hint:
		_setup_hint_label()
	if game_over_panel:
		game_over_panel.visible = false
		_setup_game_over_panel()
	_build_pause_menu()
	_build_recipe_book_overlay()
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	call_deferred("_sync_orders_from_manager")
	call_deferred("_show_recipe_book_on_level_start")


func _resolve_orders_nodes() -> void:
	if orders_container == null and orders_panel:
		orders_container = orders_panel.find_child("OrdersList", true, false) as VBoxContainer
	if orders_scroll == null and orders_panel:
		orders_scroll = orders_panel.find_child("OrdersScroll", true, false) as ScrollContainer
	if orders_title == null and orders_panel:
		orders_title = orders_panel.find_child("Title", true, false) as Label


func _build_hud_layout() -> void:
	_hud_skin = get_node_or_null("HudSkin") as Control
	if _hud_skin == null:
		_hud_skin = Control.new()
		_hud_skin.name = "HudSkin"
		_hud_skin.set_anchors_preset(Control.PRESET_FULL_RECT)
		_hud_skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hud_skin)

	_score_pill = _make_panel("ScorePill", Vector2(285, 58), UITheme.COLOR_CARD, UITheme.COLOR_YELLOW)
	_hud_skin.add_child(_score_pill)
	_score_pill.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_score_pill.offset_left = -320
	_score_pill.offset_top = 16
	_score_pill.offset_right = -28
	_score_pill.offset_bottom = 74
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 8)
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_pill.add_child(score_row)
	score_row.add_child(UITheme.icon(UITheme.ICON_STAR, Vector2(34, 34)))
	_reparent(score_label, score_row)

	_timer_pill = _make_panel("TimerPill", Vector2(210, 62), Color(1.0, 0.96, 0.86, 0.98), Color(0.34, 0.29, 0.38))
	_hud_skin.add_child(_timer_pill)
	_timer_pill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_timer_pill.offset_left = 20
	_timer_pill.offset_top = 62
	_timer_pill.offset_right = 230
	_timer_pill.offset_bottom = 124
	var timer_row := HBoxContainer.new()
	timer_row.add_theme_constant_override("separation", 10)
	timer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_timer_pill.add_child(timer_row)
	var timer_badge := Label.new()
	timer_badge.text = "TIEMPO"
	UITheme.apply_label(timer_badge, 14, UITheme.COLOR_MUTED)
	timer_row.add_child(timer_badge)
	_reparent(timer_label, timer_row)

	if level_banner:
		_reparent(level_banner, _hud_skin)
		level_banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
		level_banner.offset_left = 20
		level_banner.offset_top = 16
		level_banner.offset_right = 390
		level_banner.offset_bottom = 54
		level_banner.custom_minimum_size = Vector2(370, 38)

	_action_panel = _make_panel("ActionPanel", Vector2(360, 72), Color(0.91, 0.97, 1.0, 0.98), UITheme.COLOR_BLUE)
	_hud_skin.add_child(_action_panel)
	_action_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_action_panel.offset_left = -240
	_action_panel.offset_top = -92
	_action_panel.offset_right = 240
	_action_panel.offset_bottom = -20
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_panel.add_child(action_row)
	_action_icon = UITheme.icon(UITheme.ICON_CHECK, Vector2(28, 28))
	action_row.add_child(_action_icon)
	_reparent(interaction_hint, action_row)


func _make_panel(name: String, min_size: Vector2, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = name
	panel.custom_minimum_size = min_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(bg, border, 3, 8))
	return panel


func _reparent(node: Node, new_parent: Node) -> void:
	if node == null or new_parent == null:
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	new_parent.add_child(node)


func _setup_orders_panel() -> void:
	_order_panel_style = UITheme.panel_style(Color(1.0, 0.96, 0.84, 0.98), Color(0.48, 0.36, 0.28), 3, 8)

	if not orders_panel:
		push_warning("GameHUD: OrdersPanel no encontrado")
		return

	orders_panel.visible = true
	orders_panel.z_index = 50
	orders_panel.add_theme_stylebox_override("panel", _order_panel_style)
	_place_orders_panel_top_right()

	if orders_title:
		_style_order_label(orders_title, 20, UITheme.COLOR_INK)

	if orders_container:
		orders_container.add_theme_constant_override("separation", 10)

	if orders_scroll:
		orders_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		orders_scroll.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH - 24, ORDER_PANEL_HEIGHT - 50)


func _setup_top_labels() -> void:
	for label in [score_label, timer_label, level_label]:
		if label == null:
			continue
		UITheme.apply_label(label, 24, UITheme.COLOR_INK)
	if score_label:
		score_label.custom_minimum_size = Vector2(188, 0)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_label(score_label, 20, UITheme.COLOR_INK)
	if timer_label:
		UITheme.apply_label(timer_label, 28, UITheme.COLOR_INK)
	if level_label:
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UITheme.apply_label(level_label, 18, Color.WHITE, 1)
	if level_banner:
		level_banner.add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.COLOR_BLUE, UITheme.COLOR_BLUE.darkened(0.25), 2, 8))


func _setup_hint_label() -> void:
	interaction_hint.visible = true
	interaction_hint.custom_minimum_size = Vector2(0, 30)
	interaction_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	interaction_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.apply_label(interaction_hint, 19, UITheme.COLOR_INK)
	_restore_default_hint()


func _setup_game_over_panel() -> void:
	game_over_panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(0.98, 0.94, 0.84, 0.98), Color(0.3, 0.24, 0.34), 4, 8)
	)
	var title := game_over_panel.find_child("Title", true, false) as Label
	if title:
		UITheme.apply_label(title, 42, UITheme.COLOR_INK, 1)
	if final_score_label:
		UITheme.apply_label(final_score_label, 28, UITheme.COLOR_MUTED)
	if menu_button:
		menu_button.custom_minimum_size = Vector2(0, 58)
		menu_button.icon = UITheme.texture(UITheme.ICON_PLAY)
		menu_button.add_theme_constant_override("icon_max_width", 26)
		UITheme.apply_button(menu_button, UITheme.COLOR_BLUE, Color(0.32, 0.67, 0.9), Color(0.16, 0.44, 0.66))


func _build_pause_menu() -> void:
	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_overlay.visible = false
	_pause_overlay.z_index = 200
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_pause_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.52)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210
	panel.offset_top = -150
	panel.offset_right = 210
	panel.offset_bottom = 150
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(1.0, 0.95, 0.82, 0.98), Color(0.3, 0.24, 0.34), 4, 8))
	_pause_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label(title, 42, UITheme.COLOR_INK, 1)
	vbox.add_child(title)

	_resume_button = Button.new()
	_resume_button.text = "Regresar al juego"
	_resume_button.icon = UITheme.texture(UITheme.ICON_PLAY)
	_resume_button.custom_minimum_size = Vector2(0, 58)
	_resume_button.add_theme_constant_override("icon_max_width", 26)
	UITheme.apply_button(_resume_button, UITheme.COLOR_GREEN, Color(0.2, 0.82, 0.5), Color(0.12, 0.55, 0.3))
	_resume_button.pressed.connect(_on_resume_pressed)
	vbox.add_child(_resume_button)

	_pause_menu_button = Button.new()
	_pause_menu_button.text = "Menu principal"
	_pause_menu_button.icon = UITheme.texture(UITheme.ICON_CLOSE)
	_pause_menu_button.custom_minimum_size = Vector2(0, 58)
	_pause_menu_button.add_theme_constant_override("icon_max_width", 26)
	UITheme.apply_button(_pause_menu_button, UITheme.COLOR_BLUE, Color(0.32, 0.67, 0.9), Color(0.16, 0.44, 0.66))
	_pause_menu_button.pressed.connect(_on_pause_menu_pressed)
	vbox.add_child(_pause_menu_button)


func _build_recipe_book_overlay() -> void:
	_recipe_book_overlay = Control.new()
	_recipe_book_overlay.name = "RecipeBookOverlay"
	_recipe_book_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_recipe_book_overlay.visible = false
	_recipe_book_overlay.z_index = 180
	_recipe_book_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_recipe_book_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_recipe_book_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.06, 0.04, 0.56)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_recipe_book_overlay.add_child(dim)

	var frame := Control.new()
	frame.name = "BookFrame"
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -610
	frame.offset_top = -350
	frame.offset_right = 610
	frame.offset_bottom = 350
	_recipe_book_overlay.add_child(frame)

	_recipe_book_texture = TextureRect.new()
	_recipe_book_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_recipe_book_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_recipe_book_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_recipe_book_texture)

	var close_button := Button.new()
	close_button.text = ""
	close_button.icon = UITheme.texture(UITheme.ICON_PLAY)
	close_button.custom_minimum_size = Vector2(74, 62)
	close_button.expand_icon = true
	close_button.add_theme_constant_override("icon_max_width", 34)
	close_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_button.offset_left = -37
	close_button.offset_top = -84
	close_button.offset_right = 37
	close_button.offset_bottom = -22
	UITheme.apply_button(close_button, UITheme.COLOR_GREEN, Color(0.2, 0.82, 0.5), Color(0.12, 0.55, 0.3))
	close_button.pressed.connect(_on_recipe_book_close_pressed)
	frame.add_child(close_button)
	_refresh_recipe_book_content()


func _refresh_recipe_book_content() -> void:
	var level_id := GameState.selected_level
	if _recipe_book_texture:
		var texture_path: String = RECIPE_BOOK_TEXTURES.get(level_id, RECIPE_BOOK_TEXTURES[1])
		_recipe_book_texture.texture = load(texture_path) as Texture2D


func _show_recipe_book_on_level_start() -> void:
	if _recipe_book_started_level:
		return
	_recipe_book_started_level = true
	show_recipe_book(true)


func show_recipe_book(pause_level: bool = true) -> void:
	if _recipe_book_overlay == null:
		return
	_refresh_recipe_book_content()
	_recipe_book_overlay.visible = true
	if pause_level and not get_tree().paused:
		_recipe_book_paused_tree = true
		get_tree().paused = true
	if _click_player:
		_click_player.play()


func hide_recipe_book() -> void:
	if _recipe_book_overlay == null:
		return
	_recipe_book_overlay.visible = false
	if _recipe_book_paused_tree:
		get_tree().paused = false
		_recipe_book_paused_tree = false


func _on_recipe_book_close_pressed() -> void:
	if _click_player:
		_click_player.play()
	hide_recipe_book()


func _restore_default_hint() -> void:
	if not interaction_hint:
		return
	interaction_hint.text = HINT_DEFAULT
	interaction_hint.add_theme_color_override("font_color", UITheme.COLOR_INK)
	if _action_icon:
		_action_icon.texture = UITheme.texture(UITheme.ICON_CHECK)
	if _action_panel:
		_action_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(0.91, 0.97, 1.0, 0.98), UITheme.COLOR_BLUE, 3, 8))


func _place_orders_panel_top_right() -> void:
	var parent_vbox := orders_panel.get_parent()
	if parent_vbox:
		parent_vbox.remove_child(orders_panel)
	if _hud_skin:
		_hud_skin.add_child(orders_panel)
	else:
		add_child(orders_panel)

	orders_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	orders_panel.offset_left = -ORDER_PANEL_WIDTH - 28
	orders_panel.offset_top = 86
	orders_panel.offset_right = -28
	orders_panel.offset_bottom = 86 + ORDER_PANEL_HEIGHT
	orders_panel.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH, ORDER_PANEL_HEIGHT)

	var inner := orders_panel.get_node_or_null("VBoxContainer") as VBoxContainer
	if inner:
		inner.custom_minimum_size.x = ORDER_PANEL_WIDTH - 20


func _sync_orders_from_manager() -> void:
	var om := get_tree().get_first_node_in_group("order_manager") as OrderManager
	if om:
		set_max_order_slots(om.max_orders)
		update_orders(om.get_active_orders())


func _style_order_label(label: Label, font_size: int, color: Color) -> void:
	UITheme.apply_label(label, font_size, color, ORDER_OUTLINE_SIZE)


func show_station_target(station_name: String) -> void:
	if not interaction_hint:
		return
	if _delivery_feedback_active:
		return
	interaction_hint.text = "Click para usar: " + station_name
	interaction_hint.add_theme_color_override("font_color", UITheme.COLOR_INK)
	if _action_panel:
		_action_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(0.91, 0.97, 1.0, 0.98), UITheme.COLOR_BLUE, 3, 8))


func clear_station_target() -> void:
	if not interaction_hint:
		return
	if _delivery_feedback_active:
		return
	_restore_default_hint()


func show_delivery_feedback(message: String, success: bool) -> void:
	if not interaction_hint:
		return
	_delivery_feedback_active = true
	interaction_hint.text = message
	if success:
		if _action_icon:
			_action_icon.texture = UITheme.texture(UITheme.ICON_CHECK)
		interaction_hint.add_theme_color_override("font_color", Color(0.05, 0.38, 0.18))
		if _action_panel:
			_action_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(0.83, 1.0, 0.88, 0.98), UITheme.COLOR_GREEN, 3, 8))
	else:
		if _action_icon:
			_action_icon.texture = UITheme.texture(UITheme.ICON_CLOSE)
		interaction_hint.add_theme_color_override("font_color", Color(0.62, 0.08, 0.08))
		if _action_panel:
			_action_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(1.0, 0.88, 0.84, 0.98), UITheme.COLOR_RED, 3, 8))
	if _delivery_feedback_tween and _delivery_feedback_tween.is_valid():
		_delivery_feedback_tween.kill()
	_delivery_feedback_tween = create_tween()
	_delivery_feedback_tween.tween_interval(DELIVERY_FEEDBACK_DURATION)
	_delivery_feedback_tween.tween_callback(func():
		_delivery_feedback_active = false
		clear_station_target()
	)


func flash_interaction() -> void:
	if not interaction_hint:
		return
	if _delivery_feedback_active:
		return
	if _interaction_flash_tween and _interaction_flash_tween.is_valid():
		_interaction_flash_tween.kill()
	interaction_hint.add_theme_color_override("font_color", UITheme.COLOR_GREEN)
	_interaction_flash_tween = create_tween()
	_interaction_flash_tween.tween_interval(0.15)
	_interaction_flash_tween.tween_callback(func():
		if interaction_hint.text.begins_with("Click"):
			interaction_hint.add_theme_color_override("font_color", UITheme.COLOR_INK)
		else:
			interaction_hint.add_theme_color_override("font_color", UITheme.COLOR_MUTED)
	)


func _process(delta: float) -> void:
	if game_active and not _game_paused:
		game_time -= delta
		if timer_label:
			timer_label.text = format_time(game_time)
		if game_time <= 0:
			end_game()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if _recipe_book_overlay and _recipe_book_overlay.visible:
				hide_recipe_book()
				get_viewport().set_input_as_handled()
				return
			if game_over_panel and game_over_panel.visible:
				return
			_set_paused(not _game_paused)
			get_viewport().set_input_as_handled()


func format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%02d:%02d" % [mins, secs]


func update_score(points: int) -> void:
	score += points
	if score_label:
		score_label.text = "Puntos: " + str(score)


func set_max_order_slots(slots: int) -> void:
	_max_order_slots = maxi(slots, 1)


func update_orders(orders: Array) -> void:
	_resolve_orders_nodes()
	if not orders_container:
		push_warning("GameHUD: OrdersList no encontrado — no se pueden mostrar ordenes")
		return

	if orders_panel:
		orders_panel.visible = true

	if orders_title:
		if orders.is_empty():
			orders_title.text = "Pedido"
		else:
			orders_title.text = "Pedido activo"

	for child in orders_container.get_children():
		child.queue_free()

	for i in range(orders.size()):
		orders_container.add_child(create_order_card(orders[i], i + 1))

	if orders.is_empty():
		var empty := Label.new()
		empty.text = "Esperando nuevo pedido..."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_order_label(empty, ORDER_DETAIL_FONT, UITheme.COLOR_MUTED)
		orders_container.add_child(empty)

	if orders_scroll:
		orders_scroll.set_deferred("scroll_vertical", 0)


func _format_ingredient_line(ing: Variant) -> String:
	var n: Dictionary = Recipe.normalize_entry(ing)
	var type_name: String = INGREDIENT_NAMES.get(str(n["type"]), str(n["type"]).capitalize())
	var state_name: String = STATE_NAMES.get(str(n["state"]), str(n["state"]))
	return "%s (%s)" % [type_name, state_name]


func create_order_panel(order: Dictionary, order_number: int = 1) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = ORDER_PANEL_WIDTH - 24
	var card_style := _order_panel_style.duplicate() if _order_panel_style else StyleBoxFlat.new()
	card_style.bg_color = Color(0.18, 0.13, 0.1, 0.94)
	panel.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var index_label := Label.new()
	index_label.text = "#%d" % order_number
	_style_order_label(index_label, ORDER_NAME_FONT, Color(1, 0.78, 0.28))
	header.add_child(index_label)

	var name_label := Label.new()
	name_label.text = order["recipe"].recipe_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_order_label(name_label, ORDER_NAME_FONT, Color(1.0, 0.96, 0.86))
	header.add_child(name_label)

	var time_label := Label.new()
	time_label.text = format_time(order["time_remaining"])
	_style_order_label(time_label, ORDER_TIME_FONT, Color(1.0, 0.72, 0.32))
	header.add_child(time_label)

	var ing_parts: PackedStringArray = []
	for ing in order["recipe"].required_ingredients:
		ing_parts.append(_format_ingredient_line(ing))

	if not ing_parts.is_empty():
		var ing_label := Label.new()
		ing_label.text = "Necesitas:\n• " + "\n• ".join(ing_parts)
		ing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ing_label.custom_minimum_size.x = ORDER_PANEL_WIDTH - 40
		_style_order_label(ing_label, ORDER_DETAIL_FONT, Color(0.92, 0.96, 1))
		vbox.add_child(ing_label)

	var timer_updater := Timer.new()
	timer_updater.wait_time = 0.2
	timer_updater.timeout.connect(func():
		if is_instance_valid(time_label):
			time_label.text = format_time(order["time_remaining"])
			if order["time_remaining"] < 10.0:
				_style_order_label(time_label, ORDER_TIME_FONT, Color(1.0, 0.4, 0.35))
			else:
				_style_order_label(time_label, ORDER_TIME_FONT, Color(1.0, 0.82, 0.35))
	)
	timer_updater.autostart = true
	panel.add_child(timer_updater)
	return panel


func create_order_card(order: Dictionary, _order_number: int = 1) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = ORDER_PANEL_WIDTH - 24
	panel.custom_minimum_size.y = 96
	panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(1.0, 0.98, 0.9, 1.0), Color(0.74, 0.58, 0.32), 2, 8, false)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.custom_minimum_size = Vector2(0, 42)
	vbox.add_child(header)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(40, 40)
	icon_panel.add_theme_stylebox_override("panel", UITheme.panel_style(Color(1.0, 0.75, 0.25), Color(0.72, 0.45, 0.12), 2, 8, false))
	var icon_label := Label.new()
	icon_label.text = "PA"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_order_label(icon_label, 18, Color(0.34, 0.18, 0.08))
	icon_panel.add_child(icon_label)
	header.add_child(icon_panel)

	var name_label := Label.new()
	name_label.text = order["recipe"].recipe_name
	name_label.custom_minimum_size = Vector2(0, 42)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_order_label(name_label, 18, UITheme.COLOR_INK)
	header.add_child(name_label)

	var time_label := Label.new()
	time_label.text = format_time(order["time_remaining"])
	time_label.custom_minimum_size = Vector2(62, 42)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_order_label(time_label, ORDER_TIME_FONT, UITheme.COLOR_RED)
	header.add_child(time_label)

	var ing_parts: PackedStringArray = []
	for ing in order["recipe"].required_ingredients:
		ing_parts.append(_format_ingredient_line(ing))

	if not ing_parts.is_empty():
		var ing_label := Label.new()
		ing_label.text = "Necesitas: " + ", ".join(ing_parts)
		ing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ing_label.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH - 52, 34)
		ing_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_order_label(ing_label, 14, UITheme.COLOR_MUTED)
		vbox.add_child(ing_label)

	var timer_updater := Timer.new()
	timer_updater.wait_time = 0.2
	timer_updater.timeout.connect(func():
		if is_instance_valid(time_label):
			time_label.text = format_time(order["time_remaining"])
			if order["time_remaining"] < 10.0:
				_style_order_label(time_label, ORDER_TIME_FONT, UITheme.COLOR_RED)
			else:
				_style_order_label(time_label, ORDER_TIME_FONT, UITheme.COLOR_INK)
	)
	timer_updater.autostart = true
	panel.add_child(timer_updater)
	return panel


func _make_order_step(text: String, color: Color) -> Control:
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", UITheme.panel_style(color, color.darkened(0.18), 2, 8, false))
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_order_label(label, 14, Color.WHITE)
	chip.add_child(label)
	return chip


func _populate_order_steps(container: HBoxContainer, recipe: Recipe) -> void:
	var step_specs := _get_order_step_specs(recipe)
	for i in range(step_specs.size()):
		var spec: Dictionary = step_specs[i]
		container.add_child(_make_order_step(spec["label"], spec["color"]))
		if i < step_specs.size() - 1:
			container.add_child(_make_order_arrow())


func _get_order_step_specs(recipe: Recipe) -> Array:
	var needs_decoration := false
	for ing in recipe.required_ingredients:
		var entry := Recipe.normalize_entry(ing)
		if str(entry["state"]).begins_with("decorated_"):
			needs_decoration = true
			break

	if needs_decoration:
		return [
			{"label": "Ing.", "color": UITheme.COLOR_GREEN},
			{"label": "Batir", "color": UITheme.COLOR_BLUE},
			{"label": "Horno", "color": UITheme.COLOR_RED},
			{"label": "Decorar", "color": Color(0.95, 0.48, 0.72)},
			{"label": "Entrega", "color": UITheme.COLOR_YELLOW},
		]

	return [
		{"label": "Ing.", "color": UITheme.COLOR_GREEN},
		{"label": "Horno", "color": UITheme.COLOR_BLUE},
		{"label": "Entrega", "color": UITheme.COLOR_YELLOW},
	]


func _make_order_arrow() -> TextureRect:
	return UITheme.icon(UITheme.ICON_ARROW, Vector2(20, 20))


func end_game() -> void:
	if _game_paused:
		_set_paused(false)
	game_active = false
	if game_over_panel:
		game_over_panel.visible = true
	if final_score_label:
		final_score_label.text = "Puntuacion final: " + str(score)
	game_ended.emit(score)


func _set_paused(paused: bool) -> void:
	_game_paused = paused
	get_tree().paused = paused
	if _pause_overlay:
		_pause_overlay.visible = paused
	if paused and _click_player:
		_click_player.play()


func _on_resume_pressed() -> void:
	if _click_player:
		_click_player.play()
	_set_paused(false)


func _on_pause_menu_pressed() -> void:
	if _click_player:
		_click_player.play()
	get_tree().paused = false
	_game_paused = false
	GameState.go_to_menu()


func _on_menu_pressed() -> void:
	if _click_player:
		_click_player.play()
	get_tree().paused = false
	GameState.go_to_menu()
