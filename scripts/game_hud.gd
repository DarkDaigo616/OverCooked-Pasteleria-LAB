extends CanvasLayer
class_name GameHUD

@onready var score_label = $MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var timer_label = $MarginContainer/VBoxContainer/TopBar/TimerLabel
@onready var level_label = $MarginContainer/VBoxContainer/LevelLabel
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


const HINT_DEFAULT := "Acercate a una estacion | E: usar | Q: soltar | Basurero: descartar platos malos"

const ORDER_NAME_FONT := 15
const ORDER_DETAIL_FONT := 15
const ORDER_TIME_FONT := 15
const ORDER_PANEL_WIDTH := 300
const ORDER_PANEL_HEIGHT := 420
const ORDER_OUTLINE_SIZE := 6

const INGREDIENT_NAMES := {
	"bread": "Pan",
	"meat": "Carne",
	"lettuce": "Lechuga",
	"tomato": "Tomate",
}
const STATE_NAMES := {
	"raw": "crudo",
	"cooked": "cocido",
	"chopped": "cortado",
}

var _flash_tween: Tween
var _order_panel_style: StyleBoxFlat
var _max_order_slots: int = 4


func _ready() -> void:
	add_to_group("game_hud")
	_resolve_orders_nodes()
	_setup_orders_panel()
	update_score(0)
	if interaction_hint:
		interaction_hint.visible = true
		interaction_hint.text = HINT_DEFAULT
		interaction_hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	if game_over_panel:
		game_over_panel.visible = false
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	call_deferred("_sync_orders_from_manager")


func _resolve_orders_nodes() -> void:
	if orders_container == null and orders_panel:
		orders_container = orders_panel.find_child("OrdersList", true, false) as VBoxContainer
	if orders_scroll == null and orders_panel:
		orders_scroll = orders_panel.find_child("OrdersScroll", true, false) as ScrollContainer
	if orders_title == null and orders_panel:
		orders_title = orders_panel.find_child("Title", true, false) as Label


func _setup_orders_panel() -> void:
	_order_panel_style = StyleBoxFlat.new()
	_order_panel_style.bg_color = Color(0.05, 0.06, 0.1, 0.92)
	_order_panel_style.border_color = Color(1, 0.9, 0.5, 0.7)
	_order_panel_style.set_border_width_all(2)
	_order_panel_style.set_corner_radius_all(8)
	_order_panel_style.content_margin_left = 8
	_order_panel_style.content_margin_right = 8
	_order_panel_style.content_margin_top = 6
	_order_panel_style.content_margin_bottom = 6

	if not orders_panel:
		push_warning("GameHUD: OrdersPanel no encontrado")
		return

	orders_panel.visible = true
	orders_panel.z_index = 50
	orders_panel.add_theme_stylebox_override("panel", _order_panel_style)
	_place_orders_panel_top_right()

	if orders_title:
		_style_order_label(orders_title, 17, Color(1, 0.98, 0.75))

	if orders_container:
		orders_container.add_theme_constant_override("separation", 8)

	if orders_scroll:
		orders_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		orders_scroll.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH - 20, ORDER_PANEL_HEIGHT - 48)


func _place_orders_panel_top_right() -> void:
	var parent_vbox := orders_panel.get_parent()
	if parent_vbox:
		parent_vbox.remove_child(orders_panel)
	add_child(orders_panel)
	move_child(orders_panel, -1)

	orders_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	orders_panel.offset_left = -ORDER_PANEL_WIDTH - 12
	orders_panel.offset_top = 68
	orders_panel.offset_right = -8
	orders_panel.offset_bottom = 68 + ORDER_PANEL_HEIGHT
	orders_panel.custom_minimum_size = Vector2(ORDER_PANEL_WIDTH, ORDER_PANEL_HEIGHT)

	var inner := orders_panel.get_node_or_null("VBoxContainer") as VBoxContainer
	if inner:
		inner.custom_minimum_size.x = ORDER_PANEL_WIDTH - 16


func _sync_orders_from_manager() -> void:
	var om := get_tree().get_first_node_in_group("order_manager") as OrderManager
	if om:
		set_max_order_slots(om.max_orders)
		update_orders(om.get_active_orders())


func _style_order_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", ORDER_OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))


func show_station_target(station_name: String) -> void:
	if not interaction_hint:
		return
	interaction_hint.text = "[ E ]  " + station_name
	interaction_hint.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35))


func clear_station_target() -> void:
	if not interaction_hint:
		return
	interaction_hint.text = HINT_DEFAULT
	interaction_hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))


func show_delivery_feedback(message: String, success: bool) -> void:
	if not interaction_hint:
		return
	interaction_hint.text = message
	if success:
		interaction_hint.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	else:
		interaction_hint.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_interval(2.5)
	_flash_tween.tween_callback(clear_station_target)


func flash_interaction() -> void:
	if not interaction_hint:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	interaction_hint.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.15)
	_flash_tween.tween_callback(func():
		if interaction_hint.text.begins_with("[ E ]"):
			interaction_hint.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35))
		else:
			interaction_hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	)


func _process(delta: float) -> void:
	if game_active:
		game_time -= delta
		if timer_label:
			timer_label.text = "Tiempo: " + format_time(game_time)
		if game_time <= 0:
			end_game()


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
			orders_title.text = "Ordenes activas (ninguna)"
		else:
			orders_title.text = "Ordenes activas (%d/%d)" % [orders.size(), _max_order_slots]

	for child in orders_container.get_children():
		child.queue_free()

	for i in range(orders.size()):
		orders_container.add_child(create_order_panel(orders[i], i + 1))

	if orders.is_empty():
		var empty := Label.new()
		empty.text = "Esperando nuevas ordenes..."
		_style_order_label(empty, ORDER_DETAIL_FONT, Color(0.75, 0.78, 0.85))
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
	card_style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
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
	_style_order_label(index_label, ORDER_NAME_FONT, Color(1, 0.92, 0.45))
	header.add_child(index_label)

	var name_label := Label.new()
	name_label.text = order["recipe"].recipe_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_order_label(name_label, ORDER_NAME_FONT, Color(1, 1, 1))
	header.add_child(name_label)

	var time_label := Label.new()
	time_label.text = format_time(order["time_remaining"])
	_style_order_label(time_label, ORDER_TIME_FONT, Color(1.0, 0.82, 0.35))
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


func end_game() -> void:
	game_active = false
	if game_over_panel:
		game_over_panel.visible = true
	if final_score_label:
		final_score_label.text = "Puntuacion final: " + str(score)
	game_ended.emit(score)


func _on_menu_pressed() -> void:
	GameState.go_to_menu()
