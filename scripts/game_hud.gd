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
const RECIPE_BOOK_DATA := {
	1: [
		{"image": "res://assets/ui/pastel_horneado.png", "is_new": false},
	],
	2: [
		{"image": "res://assets/ui/pastel_vainilla.png", "is_new": true},
	],
	3: [
		{"image": "res://assets/ui/pastel_simple.png", "is_new": false},
		{"image": "res://assets/ui/pastel_chocolate.png", "is_new": true},
		{"image": "res://assets/ui/pastel_fresa.png", "is_new": true},
	],
	4: [
		{"image": "res://assets/ui/pastel_chocolate.png", "is_new": false},
		{"image": "res://assets/ui/pastel_fresa.png", "is_new": false},
	],
	5: [
		{"image": "res://assets/ui/pastel_simple.png", "is_new": false},
		{"image": "res://assets/ui/pastel_chocolate.png", "is_new": false},
		{"image": "res://assets/ui/pastel_fresa.png", "is_new": false},
	],
	6: [
		{"image": "res://assets/ui/pastel_vainilla.png", "is_new": false},
		{"image": "res://assets/ui/pastel_chocolate.png", "is_new": false},
		{"image": "res://assets/ui/pastel_fresa.png", "is_new": false},
	],
	7: [
		{"image": "res://assets/ui/pastel_vainilla.png", "is_new": false},
		{"image": "res://assets/ui/pastel_chocolate.png", "is_new": false},
		{"image": "res://assets/ui/pastel_fresa.png", "is_new": false},
	],
}

const ORDER_NAME_FONT := 22
const ORDER_DETAIL_FONT := 16
const ORDER_TIME_FONT := 18
const ORDER_PANEL_WIDTH := 380
const ORDER_PANEL_HEIGHT := 168
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
	"decorated_strawberry": "fresa",
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
var _recipe_pages: Array = []
var _recipe_page_index: int = 0
var _rb_prev_btn: Button
var _rb_next_btn: Button
var _rb_image: TextureRect
var _rb_new_badge: TextureRect
var _rb_page_indicator: Label
var _nueva_receta_overlay: Control
var _queue_panel: PanelContainer
var _queue_slots: Array = []
var _queue_panel_p2: PanelContainer
var _queue_slots_p2: Array = []
var _coop_selector: Control = null
var _p1_btn: PanelContainer = null
var _p2_btn: PanelContainer = null
var _coop_active: bool = false
var _star_thresholds: Array = []
var _no_burn_for_3_stars: bool = false
var _orders_delivered_count: int = 0
var _delivery_pts_total: int = 0
var _orders_failed_count: int = 0
var _penalty_total: int = 0
var _cakes_burned_count: int = 0
var _is_real_game: bool = false
var _star_icons: Array = []
var _threshold_labels: Array = []
var _delivery_counter_pill: PanelContainer = null
var _delivery_counter_lbl: Label = null
var _no_burn_lbl: Label = null
var _end_deliveries_lbl: Label = null
var _retry_button: Button = null


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
	_build_queue_panel()
	_build_queue_panel_p2()
	_build_coop_selector()
	_build_recipe_book_overlay()
	_build_delivery_counter()
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

	var vbox := game_over_panel.find_child("VBoxContainer", true, false) as VBoxContainer
	if vbox:
		vbox.add_theme_constant_override("separation", 12)

		# Star row: each star is a column (icon + threshold label underneath)
		var star_row := HBoxContainer.new()
		star_row.name = "StarRow"
		star_row.alignment = BoxContainer.ALIGNMENT_CENTER
		star_row.add_theme_constant_override("separation", 36)
		star_row.visible = false
		for _i in range(3):
			var col := VBoxContainer.new()
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			col.add_theme_constant_override("separation", 2)
			var star_icon := UITheme.icon(UITheme.ICON_STAR, Vector2(60, 60))
			star_icon.modulate = Color(0.35, 0.35, 0.35, 0.35)
			col.add_child(star_icon)
			_star_icons.append(star_icon)
			var thresh_lbl := Label.new()
			thresh_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			thresh_lbl.text = "?"
			UITheme.apply_label(thresh_lbl, 15, UITheme.COLOR_MUTED)
			col.add_child(thresh_lbl)
			_threshold_labels.append(thresh_lbl)
			star_row.add_child(col)
		vbox.add_child(star_row)
		vbox.move_child(star_row, 1)

		_end_deliveries_lbl = Label.new()
		_end_deliveries_lbl.name = "DeliveriesLabel"
		_end_deliveries_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_end_deliveries_lbl.visible = false
		UITheme.apply_label(_end_deliveries_lbl, 18, UITheme.COLOR_MUTED)
		vbox.add_child(_end_deliveries_lbl)
		vbox.move_child(_end_deliveries_lbl, 2)

		_no_burn_lbl = Label.new()
		_no_burn_lbl.name = "NoBurnLabel"
		_no_burn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_no_burn_lbl.visible = false
		UITheme.apply_label(_no_burn_lbl, 16, UITheme.COLOR_GREEN)
		vbox.add_child(_no_burn_lbl)
		vbox.move_child(_no_burn_lbl, 3)

	if final_score_label:
		UITheme.apply_label(final_score_label, 28, UITheme.COLOR_MUTED)

	_retry_button = Button.new()
	_retry_button.name = "RetryButton"
	_retry_button.text = "Reintentar"
	_retry_button.custom_minimum_size = Vector2(0, 58)
	_retry_button.visible = false
	UITheme.apply_button(_retry_button, UITheme.COLOR_YELLOW, Color(1.0, 0.84, 0.35), Color(0.86, 0.56, 0.1), UITheme.COLOR_INK)
	_retry_button.pressed.connect(_on_retry_pressed)
	if vbox:
		vbox.add_child(_retry_button)
		vbox.move_child(_retry_button, vbox.get_child_count() - 2)

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
	dim.color = Color(0.04, 0.03, 0.02, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_recipe_book_overlay.add_child(dim)

	# Frame sin fondo — solo contiene imagen y controles
	var frame := Control.new()
	frame.name = "BookFrame"
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -580
	frame.offset_top = -360
	frame.offset_right = 580
	frame.offset_bottom = 360
	_recipe_book_overlay.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	frame.add_child(vbox)

	# Contenedor de la imagen: ocupa todo el espacio expandible
	var img_container := Control.new()
	img_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(img_container)

	_rb_image = TextureRect.new()
	_rb_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rb_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rb_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_container.add_child(_rb_image)

	# Badge "Nueva Receta" en esquina superior derecha
	_rb_new_badge = TextureRect.new()
	_rb_new_badge.texture = load("res://assets/ui/nueva_receta.png") as Texture2D
	_rb_new_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rb_new_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rb_new_badge.anchor_left = 1.0
	_rb_new_badge.anchor_right = 1.0
	_rb_new_badge.anchor_top = 0.0
	_rb_new_badge.anchor_bottom = 0.0
	_rb_new_badge.offset_left = -190
	_rb_new_badge.offset_top = 0
	_rb_new_badge.offset_right = 0
	_rb_new_badge.offset_bottom = 120
	_rb_new_badge.visible = false
	img_container.add_child(_rb_new_badge)

	# Botón anterior — solapado sobre el lado izquierdo de la imagen
	_rb_prev_btn = Button.new()
	_rb_prev_btn.text = "◀"
	_rb_prev_btn.anchor_left = 0.0
	_rb_prev_btn.anchor_right = 0.0
	_rb_prev_btn.anchor_top = 0.5
	_rb_prev_btn.anchor_bottom = 0.5
	_rb_prev_btn.offset_left = 12
	_rb_prev_btn.offset_right = 82
	_rb_prev_btn.offset_top = -36
	_rb_prev_btn.offset_bottom = 36
	UITheme.apply_button(_rb_prev_btn, UITheme.COLOR_BLUE, Color(0.32, 0.67, 0.9), Color(0.16, 0.44, 0.66))
	_rb_prev_btn.pressed.connect(func(): _navigate_recipe_page(-1))
	img_container.add_child(_rb_prev_btn)

	# Botón siguiente — solapado sobre el lado derecho de la imagen
	_rb_next_btn = Button.new()
	_rb_next_btn.text = "▶"
	_rb_next_btn.anchor_left = 1.0
	_rb_next_btn.anchor_right = 1.0
	_rb_next_btn.anchor_top = 0.5
	_rb_next_btn.anchor_bottom = 0.5
	_rb_next_btn.offset_left = -82
	_rb_next_btn.offset_right = -12
	_rb_next_btn.offset_top = -36
	_rb_next_btn.offset_bottom = 36
	UITheme.apply_button(_rb_next_btn, UITheme.COLOR_BLUE, Color(0.32, 0.67, 0.9), Color(0.16, 0.44, 0.66))
	_rb_next_btn.pressed.connect(func(): _navigate_recipe_page(1))
	img_container.add_child(_rb_next_btn)

	# Fila inferior: indicador de página + botón Jugar
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 20)
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.custom_minimum_size = Vector2(0, 68)
	vbox.add_child(bottom_row)

	_rb_page_indicator = Label.new()
	_rb_page_indicator.custom_minimum_size = Vector2(90, 0)
	_rb_page_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rb_page_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.apply_label(_rb_page_indicator, 22, Color.WHITE, 1)
	bottom_row.add_child(_rb_page_indicator)

	var close_button := Button.new()
	close_button.text = "Jugar"
	close_button.icon = UITheme.texture(UITheme.ICON_PLAY)
	close_button.custom_minimum_size = Vector2(180, 60)
	close_button.add_theme_constant_override("icon_max_width", 26)
	UITheme.apply_button(close_button, UITheme.COLOR_GREEN, Color(0.2, 0.82, 0.5), Color(0.12, 0.55, 0.3))
	close_button.pressed.connect(_on_recipe_book_close_pressed)
	bottom_row.add_child(close_button)

	_refresh_recipe_book_content()


func _refresh_recipe_book_content() -> void:
	var level_id := GameState.selected_level
	_recipe_pages = RECIPE_BOOK_DATA.get(level_id, RECIPE_BOOK_DATA[1])
	_recipe_page_index = 0
	_update_recipe_book_page()


func _update_recipe_book_page() -> void:
	if _recipe_pages.is_empty():
		return
	var page: Dictionary = _recipe_pages[_recipe_page_index]
	if _rb_image:
		_rb_image.texture = load(page["image"]) as Texture2D
	if _rb_new_badge:
		_rb_new_badge.visible = page.get("is_new", false)
	var has_multiple := _recipe_pages.size() > 1
	if _rb_page_indicator:
		_rb_page_indicator.visible = has_multiple
		_rb_page_indicator.text = "%d / %d" % [_recipe_page_index + 1, _recipe_pages.size()]
	if _rb_prev_btn:
		_rb_prev_btn.visible = has_multiple
		_rb_prev_btn.disabled = _recipe_page_index == 0
	if _rb_next_btn:
		_rb_next_btn.visible = has_multiple
		_rb_next_btn.disabled = _recipe_page_index >= _recipe_pages.size() - 1


func _navigate_recipe_page(delta: int) -> void:
	_recipe_page_index = clampi(_recipe_page_index + delta, 0, _recipe_pages.size() - 1)
	_update_recipe_book_page()
	if _click_player:
		_click_player.play()


func _show_recipe_book_on_level_start() -> void:
	if _recipe_book_started_level:
		return
	_recipe_book_started_level = true
	show_recipe_book(true)


func _build_queue_panel() -> void:
	_queue_panel = PanelContainer.new()
	_queue_panel.name = "QueuePanel"
	_queue_panel.visible = false
	_queue_panel.z_index = 70
	_queue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_queue_panel.offset_left = -310
	_queue_panel.offset_top = -256
	_queue_panel.offset_right = 310
	_queue_panel.offset_bottom = -108
	_queue_panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(0.10, 0.08, 0.06, 0.92), Color(0.72, 0.54, 0.28), 3, 8)
	)
	_hud_skin.add_child(_queue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_queue_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.name = "Title"
	title.text = "Cola de Acciones"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label(title, 12, UITheme.COLOR_YELLOW, 1)
	header.add_child(title)

	var hint := Label.new()
	hint.text = "Click derecho = cancelar"
	UITheme.apply_label(hint, 10, UITheme.COLOR_MUTED)
	header.add_child(hint)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 6)
	vbox.add_child(slots_row)

	_queue_slots.clear()
	for i in range(MAX_QUEUE_SIZE if true else 3):
		var slot := _make_queue_slot(i + 1)
		slots_row.add_child(slot)
		_queue_slots.append(slot)


const MAX_QUEUE_SIZE := 3


func _make_queue_slot(slot_number: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(184, 46)
	panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(0.20, 0.16, 0.12, 0.95), Color(0.44, 0.34, 0.22), 2, 6, false)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	var num := Label.new()
	num.text = str(slot_number)
	num.custom_minimum_size = Vector2(14, 0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label(num, 11, UITheme.COLOR_MUTED)
	num.name = "Num"
	hbox.add_child(num)

	var lbl := Label.new()
	lbl.text = "—"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_label(lbl, 11, UITheme.COLOR_MUTED)
	lbl.name = "ActionLabel"
	hbox.add_child(lbl)

	return panel


func update_action_queue(queue: Array, queue_active: bool, player_id: int = 1) -> void:
	if player_id == 2:
		_update_queue_display(_queue_panel_p2, _queue_slots_p2, queue, queue_active, Color(0.28, 0.60, 1.0))
	else:
		_update_queue_display(_queue_panel, _queue_slots, queue, queue_active, Color(1.0, 0.42, 0.58))


func _update_queue_display(panel: PanelContainer, slots: Array, queue: Array, active: bool, accent: Color) -> void:
	if panel == null:
		return
	panel.visible = active
	if not active:
		return
	for i in range(slots.size()):
		var slot := slots[i] as PanelContainer
		if slot == null:
			continue
		var lbl := slot.find_child("ActionLabel", true, false) as Label
		if lbl == null:
			continue
		if i < queue.size():
			var action: Dictionary = queue[i]
			lbl.text = action.get("display_name", "?")
			if i == 0:
				UITheme.apply_label(lbl, 11, accent.lightened(0.3))
				slot.add_theme_stylebox_override(
					"panel",
					UITheme.panel_style(accent.darkened(0.6), accent, 2, 6, false)
				)
			else:
				UITheme.apply_label(lbl, 11, UITheme.COLOR_CREAM)
				slot.add_theme_stylebox_override(
					"panel",
					UITheme.panel_style(Color(0.20, 0.16, 0.12, 0.95), Color(0.44, 0.34, 0.22), 2, 6, false)
				)
		else:
			lbl.text = "—"
			UITheme.apply_label(lbl, 11, UITheme.COLOR_MUTED)
			slot.add_theme_stylebox_override(
				"panel",
				UITheme.panel_style(Color(0.20, 0.16, 0.12, 0.95), Color(0.44, 0.34, 0.22), 2, 6, false)
			)


func _build_queue_panel_p2() -> void:
	_queue_panel_p2 = PanelContainer.new()
	_queue_panel_p2.name = "QueuePanelP2"
	_queue_panel_p2.visible = false
	_queue_panel_p2.z_index = 70
	_queue_panel_p2.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_queue_panel_p2.offset_left = 20
	_queue_panel_p2.offset_top = -256
	_queue_panel_p2.offset_right = 630
	_queue_panel_p2.offset_bottom = -108
	_queue_panel_p2.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(0.06, 0.10, 0.20, 0.92), Color(0.28, 0.55, 0.90), 3, 8)
	)
	_hud_skin.add_child(_queue_panel_p2)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_queue_panel_p2.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Cola P2"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_label(title, 12, Color(0.55, 0.82, 1.0), 1)
	header.add_child(title)

	var hint := Label.new()
	hint.text = "Tecla 2 para seleccionar"
	UITheme.apply_label(hint, 10, UITheme.COLOR_MUTED)
	header.add_child(hint)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 6)
	vbox.add_child(slots_row)

	_queue_slots_p2.clear()
	for i in range(MAX_QUEUE_SIZE):
		var slot := _make_queue_slot(i + 1)
		slots_row.add_child(slot)
		_queue_slots_p2.append(slot)


func _build_coop_selector() -> void:
	_coop_selector = Control.new()
	_coop_selector.name = "CoopSelector"
	_coop_selector.visible = false
	_coop_selector.z_index = 72
	_coop_selector.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_coop_selector.offset_left = 20
	_coop_selector.offset_top = -96
	_coop_selector.offset_right = 230
	_coop_selector.offset_bottom = -12
	_hud_skin.add_child(_coop_selector)

	var hbox := HBoxContainer.new()
	hbox.name = "PlayerBtns"
	hbox.add_theme_constant_override("separation", 10)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_coop_selector.add_child(hbox)

	_p1_btn = _make_player_selector_btn(1, Color(1.0, 0.42, 0.58))
	_p2_btn = _make_player_selector_btn(2, Color(0.28, 0.60, 1.0))
	hbox.add_child(_p1_btn)
	hbox.add_child(_p2_btn)


func _make_player_selector_btn(pid: int, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "PlayerBtn%d" % pid
	panel.custom_minimum_size = Vector2(96, 80)
	panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(color.darkened(0.55), color, 3, 10)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = "P%d" % pid
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label(name_lbl, 22, color.lightened(0.5), 1)
	vbox.add_child(name_lbl)

	var key_lbl := Label.new()
	key_lbl.text = "Tecla %d" % pid
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_label(key_lbl, 10, UITheme.COLOR_MUTED)
	vbox.add_child(key_lbl)

	return panel


func setup_coop_mode(active: bool) -> void:
	_coop_active = active
	if _coop_selector:
		_coop_selector.visible = active
	if _queue_panel_p2:
		_queue_panel_p2.visible = active
	# Reposicionar cola de P1 a la izquierda para hacer espacio a P2
	if _queue_panel and active:
		_queue_panel.offset_left = -630
		_queue_panel.offset_right = -20
		var title_lbl := _queue_panel.find_child("Title", true, false) as Label
		if title_lbl:
			title_lbl.text = "Cola P1"


func update_coop_selection(active_id: int) -> void:
	var p1_active := (active_id == 1)
	if _p1_btn:
		var alpha := 1.0 if p1_active else 0.38
		_p1_btn.modulate = Color(1, 1, 1, alpha)
	if _p2_btn:
		var alpha := 1.0 if not p1_active else 0.38
		_p2_btn.modulate = Color(1, 1, 1, alpha)


func _build_nueva_receta_popup() -> void:
	_nueva_receta_overlay = Control.new()
	_nueva_receta_overlay.name = "NuevaRecetaOverlay"
	_nueva_receta_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_nueva_receta_overlay.visible = false
	_nueva_receta_overlay.z_index = 190
	_nueva_receta_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_nueva_receta_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_nueva_receta_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nueva_receta_overlay.add_child(dim)

	var frame := Control.new()
	frame.name = "NuevaRecetaFrame"
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -300
	frame.offset_top = -200
	frame.offset_right = 300
	frame.offset_bottom = 200
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nueva_receta_overlay.add_child(frame)

	var img := TextureRect.new()
	img.texture = load("res://assets/ui/nueva_receta.png") as Texture2D
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(img)

	var hint := Label.new()
	hint.text = "Click para ver el recetario"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -180
	hint.offset_right = 180
	hint.offset_top = -30
	hint.offset_bottom = 10
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_label(hint, 16, Color(0.85, 0.85, 0.85))
	_nueva_receta_overlay.add_child(hint)

	_nueva_receta_overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			if _click_player:
				_click_player.play()
			hide_nueva_receta()
			show_recipe_book(false)
	)


func show_nueva_receta() -> void:
	if _nueva_receta_overlay == null:
		return
	_nueva_receta_overlay.visible = true
	if not get_tree().paused:
		_recipe_book_paused_tree = true
		get_tree().paused = true


func hide_nueva_receta() -> void:
	if _nueva_receta_overlay == null:
		return
	_nueva_receta_overlay.visible = false


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
	if not orders_panel:
		return
	var parent_vbox := orders_panel.get_parent()
	if parent_vbox:
		parent_vbox.remove_child(orders_panel)
	if _hud_skin:
		_hud_skin.add_child(orders_panel)
	else:
		add_child(orders_panel)

	var panel_h: int = (
		390 if _max_order_slots >= 3
		else 230 if _max_order_slots == 2
		else ORDER_PANEL_HEIGHT
	)
	orders_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	orders_panel.offset_left = -ORDER_PANEL_WIDTH - 28
	orders_panel.offset_top = 86
	orders_panel.offset_right = -28
	orders_panel.offset_bottom = 86 + panel_h
	orders_panel.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH, panel_h)

	if orders_scroll:
		orders_scroll.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH - 24, panel_h - 50)

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
			if _nueva_receta_overlay and _nueva_receta_overlay.visible:
				hide_nueva_receta()
				show_recipe_book(false)
				get_viewport().set_input_as_handled()
				return
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
	_place_orders_panel_top_right()


func update_orders(orders: Array) -> void:
	_resolve_orders_nodes()
	if not orders_container:
		push_warning("GameHUD: OrdersList no encontrado — no se pueden mostrar ordenes")
		return

	if orders_panel:
		orders_panel.visible = true

	if orders_title:
		if orders.is_empty():
			orders_title.text = "Pedidos"
		elif orders.size() == 1:
			orders_title.text = "Pedido activo"
		else:
			orders_title.text = "Pedidos activos (%d)" % orders.size()

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
	var recipe: Recipe = order["recipe"]
	var is_complex := false
	var icon_text := "PA"
	var icon_color := Color(0.46, 0.78, 0.46)
	for ing in recipe.required_ingredients:
		var entry := Recipe.normalize_entry(ing)
		match str(entry["state"]):
			"decorated_chocolate":
				is_complex = true
				icon_text = "CH"
				icon_color = Color(0.42, 0.24, 0.10)
			"decorated_strawberry":
				is_complex = true
				icon_text = "FR"
				icon_color = Color(0.88, 0.18, 0.30)
			"decorated_vanilla":
				is_complex = true
				icon_text = "VA"
				icon_color = Color(0.92, 0.82, 0.42)

	var border_col := Color(0.46, 0.72, 0.42) if not is_complex else Color(0.72, 0.50, 0.22)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH - 24, 0)
	panel.add_theme_stylebox_override(
		"panel",
		UITheme.panel_style(Color(1.0, 0.98, 0.91, 1.0), border_col, 2, 8, false)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# ── Fila superior: icono + nombre/puntos + timer ──
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(42, 42)
	icon_panel.add_theme_stylebox_override("panel", UITheme.panel_style(icon_color, icon_color.darkened(0.22), 2, 6, false))
	var icon_label := Label.new()
	icon_label.text = icon_text
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_order_label(icon_label, 16, Color.WHITE)
	icon_panel.add_child(icon_label)
	header.add_child(icon_panel)

	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 2)
	header.add_child(name_col)

	var name_label := Label.new()
	name_label.text = recipe.recipe_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_order_label(name_label, 17, UITheme.COLOR_INK)
	name_col.add_child(name_label)

	var pts_row := HBoxContainer.new()
	pts_row.add_theme_constant_override("separation", 6)
	name_col.add_child(pts_row)
	var pts_label := Label.new()
	pts_label.text = "%d pts" % recipe.points
	_style_order_label(pts_label, 13, UITheme.COLOR_MUTED)
	pts_row.add_child(pts_label)
	if GameState.selected_level >= 3:
		var bonus_label := Label.new()
		bonus_label.text = "+%d rapido" % int(recipe.points * 0.5)
		_style_order_label(bonus_label, 13, Color(0.12, 0.68, 0.36))
		pts_row.add_child(bonus_label)

	var time_label := Label.new()
	time_label.text = format_time(order["time_remaining"])
	time_label.custom_minimum_size = Vector2(62, 42)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_order_label(time_label, ORDER_TIME_FONT, UITheme.COLOR_INK)
	header.add_child(time_label)

	# ── Ingredientes ──
	var ing_parts: PackedStringArray = []
	for ing in recipe.required_ingredients:
		ing_parts.append(_format_ingredient_line(ing))
	if not ing_parts.is_empty():
		var ing_label := Label.new()
		ing_label.text = "Necesitas: " + ", ".join(ing_parts)
		ing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_order_label(ing_label, 13, UITheme.COLOR_MUTED)
		vbox.add_child(ing_label)

	# ── Barra de urgencia ──
	var bar_track := Control.new()
	bar_track.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH - 42, 7)
	bar_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bar_track)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.80, 0.76, 0.70, 0.55)
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_track.add_child(bar_bg)

	var bar_fill := ColorRect.new()
	bar_fill.color = Color(0.22, 0.76, 0.38)
	bar_fill.anchor_left = 0.0
	bar_fill.anchor_right = 1.0
	bar_fill.anchor_top = 0.0
	bar_fill.anchor_bottom = 1.0
	bar_fill.offset_left = 0
	bar_fill.offset_right = 0
	bar_fill.offset_top = 0
	bar_fill.offset_bottom = 0
	bar_track.add_child(bar_fill)

	# ── Actualizador periódico ──
	var timer_updater := Timer.new()
	timer_updater.wait_time = 0.15
	timer_updater.timeout.connect(func():
		if not is_instance_valid(time_label):
			return
		var remaining: float = order["time_remaining"]
		var prep: float = maxf(recipe.preparation_time, 1.0)
		var pct: float = clampf(remaining / prep, 0.0, 1.0)
		time_label.text = format_time(remaining)
		if remaining < 10.0:
			_style_order_label(time_label, ORDER_TIME_FONT, UITheme.COLOR_RED)
		elif pct < 0.35:
			_style_order_label(time_label, ORDER_TIME_FONT, Color(0.92, 0.58, 0.14))
		else:
			_style_order_label(time_label, ORDER_TIME_FONT, UITheme.COLOR_INK)
		if is_instance_valid(bar_fill):
			bar_fill.anchor_right = pct
			if pct < 0.2:
				bar_fill.color = Color(0.92, 0.16, 0.16)
			elif pct < 0.45:
				bar_fill.color = Color(0.92, 0.62, 0.14)
			else:
				bar_fill.color = Color(0.22, 0.76, 0.38)
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
	if _is_real_game:
		_show_star_results()
		if final_score_label:
			final_score_label.visible = false
	else:
		GameState.save_level_result(GameState.selected_level, 1)
		if final_score_label:
			final_score_label.text = "Puntuacion final: " + str(score)
	game_ended.emit(score)


func set_game_objectives(thresholds: Array, no_burn: bool) -> void:
	_is_real_game = true
	_star_thresholds = thresholds
	_no_burn_for_3_stars = no_burn
	if _delivery_counter_pill:
		_delivery_counter_pill.visible = true
	_update_delivery_counter_display()


func set_game_duration(duration: float) -> void:
	game_time = duration
	if timer_label:
		timer_label.text = format_time(game_time)


func register_delivery(pts: int = 0) -> void:
	_orders_delivered_count += 1
	_delivery_pts_total += pts
	_update_delivery_counter_display()


func register_order_failure() -> void:
	_orders_failed_count += 1


func register_penalty(amount: int) -> void:
	_penalty_total += amount


func register_burn() -> void:
	_cakes_burned_count += 1


func _update_delivery_counter_display() -> void:
	if _delivery_counter_lbl == null:
		return
	var target: int = _star_thresholds[2] if _star_thresholds.size() >= 3 else 7
	_delivery_counter_lbl.text = "%d / %d" % [_orders_delivered_count, target]


func _compute_stars() -> int:
	if _star_thresholds.is_empty():
		return 0
	var stars := 0
	if _orders_delivered_count >= _star_thresholds[0]:
		stars = 1
	if _star_thresholds.size() >= 2 and _orders_delivered_count >= _star_thresholds[1]:
		stars = 2
	if _star_thresholds.size() >= 3 and _orders_delivered_count >= _star_thresholds[2]:
		stars = 3
	if stars == 3 and _no_burn_for_3_stars and _cakes_burned_count > 0:
		stars = 2
	return stars


func _show_star_results() -> void:
	var stars := _compute_stars()
	GameState.save_level_result(GameState.selected_level, stars)

	# Star icons + threshold numbers below each
	var star_row := game_over_panel.find_child("StarRow", true, false) as HBoxContainer
	if star_row:
		star_row.visible = true
		for i in range(_star_icons.size()):
			var icon := _star_icons[i] as CanvasItem
			if icon:
				icon.modulate = Color(1.0, 0.82, 0.0) if i < stars else Color(0.35, 0.35, 0.35, 0.35)
	# Fill threshold labels per star
	var thresholds: Array = _star_thresholds if not _star_thresholds.is_empty() else [3, 5, 7]
	for i in range(_threshold_labels.size()):
		var lbl := _threshold_labels[i] as Label
		if lbl == null:
			continue
		var t: int = thresholds[i] if i < thresholds.size() else 0
		if i == 2 and _no_burn_for_3_stars:
			lbl.text = "%d ped. +\nsin quemar" % t
		else:
			lbl.text = "%d ped." % t

	# Receipt-style breakdown
	if _end_deliveries_lbl:
		_end_deliveries_lbl.visible = true
		var total_pts := _delivery_pts_total - _penalty_total
		var lines: PackedStringArray = []
		lines.append("Pedidos entregados  ×%d     %d pts" % [_orders_delivered_count, _delivery_pts_total])
		if _orders_failed_count > 0:
			lines.append("Pedidos perdidos    ×%d    -%d pts" % [_orders_failed_count, _penalty_total])
		lines.append("─────────────────────────────")
		lines.append("TOTAL:               %d pts" % total_pts)
		_end_deliveries_lbl.text = "\n".join(lines)
		# Make TOTAL line bigger by updating font size on the label
		UITheme.apply_label(_end_deliveries_lbl, 17, UITheme.COLOR_INK)

	if _no_burn_lbl and _no_burn_for_3_stars:
		_no_burn_lbl.visible = true
		if _cakes_burned_count == 0:
			_no_burn_lbl.text = "Sin pasteles quemados  ✓"
			UITheme.apply_label(_no_burn_lbl, 16, UITheme.COLOR_GREEN)
		else:
			_no_burn_lbl.text = "Pasteles quemados: %d  ✗" % _cakes_burned_count
			UITheme.apply_label(_no_burn_lbl, 16, Color(0.8, 0.25, 0.18))

	if _retry_button:
		_retry_button.visible = true


func _on_retry_pressed() -> void:
	GameState.start_level(GameState.selected_level)


func _build_delivery_counter() -> void:
	if _hud_skin == null:
		return
	_delivery_counter_pill = _make_panel(
		"DeliveryPill", Vector2(160, 48),
		Color(0.88, 0.97, 0.88, 0.98), UITheme.COLOR_GREEN
	)
	_delivery_counter_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_delivery_counter_pill.visible = false
	_hud_skin.add_child(_delivery_counter_pill)
	_delivery_counter_pill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_delivery_counter_pill.offset_left = 20
	_delivery_counter_pill.offset_top = 134
	_delivery_counter_pill.offset_right = 210
	_delivery_counter_pill.offset_bottom = 182
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_delivery_counter_pill.add_child(row)
	row.add_child(UITheme.icon(UITheme.ICON_CHECK, Vector2(20, 20)))
	_delivery_counter_lbl = Label.new()
	_delivery_counter_lbl.text = "0 / 7"
	UITheme.apply_label(_delivery_counter_lbl, 20, UITheme.COLOR_INK, 1)
	row.add_child(_delivery_counter_lbl)


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
