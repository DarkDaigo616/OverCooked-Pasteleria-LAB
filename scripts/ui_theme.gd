extends RefCounted
class_name UITheme

const ROOT := "res://assets/{models,textures,sounds}/UI Pack/"
const FONT_PATH := ROOT + "Font/Kenney Future.ttf"
const FONT_NARROW_PATH := ROOT + "Font/Kenney Future Narrow.ttf"
const CLICK_SOUND := ROOT + "Sounds/click-a.ogg"
const TAP_SOUND := ROOT + "Sounds/tap-a.ogg"

const ICON_STAR := "PNG/Yellow/Double/star.png"
const ICON_PLAY := "PNG/Extra/Double/icon_play_light.png"
const ICON_CLOSE := "PNG/Red/Double/icon_cross.png"
const ICON_CHECK := "PNG/Green/Double/icon_checkmark.png"
const ICON_ARROW := "PNG/Blue/Double/arrow_basic_e_small.png"

const COLOR_INK := Color(0.22, 0.13, 0.08)
const COLOR_MUTED := Color(0.48, 0.39, 0.36)
const COLOR_CREAM := Color(1.0, 0.92, 0.75)
const COLOR_CARD := Color(0.98, 0.9, 0.72, 0.98)
const COLOR_BLUE := Color(0.36, 0.63, 0.72)
const COLOR_GREEN := Color(0.34, 0.68, 0.44)
const COLOR_YELLOW := Color(1.0, 0.72, 0.24)
const COLOR_RED := Color(0.82, 0.24, 0.18)

static var _font_cache: Font
static var _narrow_font_cache: Font


static func font() -> Font:
	if _font_cache == null:
		_font_cache = load(FONT_PATH) as Font
	return _font_cache


static func narrow_font() -> Font:
	if _narrow_font_cache == null:
		_narrow_font_cache = load(FONT_NARROW_PATH) as Font
	return _narrow_font_cache


static func texture(relative_path: String) -> Texture2D:
	return load(ROOT + relative_path) as Texture2D


static func sound(path: String) -> AudioStream:
	return load(path) as AudioStream


static func make_sound_player(parent: Node, path: String, volume_db: float = -8.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = sound(path)
	player.volume_db = volume_db
	parent.add_child(player)
	return player


static func panel_style(
	bg: Color = COLOR_CARD,
	border: Color = Color(0.55, 0.34, 0.18),
	border_width: int = 3,
	radius: int = 8,
	shadow: bool = true
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	if shadow:
		style.shadow_color = Color(0.07, 0.08, 0.11, 0.28)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 5)
	return style


static func apply_label(label: Label, font_size: int, color: Color = COLOR_INK, outline: int = 0) -> void:
	label.add_theme_font_override("font", font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("line_spacing", max(2, roundi(float(font_size) * 0.18)))
	if outline > 0:
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.72))
	else:
		label.add_theme_constant_override("outline_size", 0)


static func apply_button(
	button: Button,
	normal: Color = COLOR_BLUE,
	hover: Color = Color(0.31, 0.66, 0.9),
	pressed: Color = Color(0.14, 0.42, 0.64),
	font_color: Color = Color.WHITE
) -> void:
	button.add_theme_font_override("font", font())
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 0.32))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", panel_style(normal, normal.darkened(0.22), 2, 8))
	button.add_theme_stylebox_override("hover", panel_style(hover, hover.lightened(0.18), 2, 8))
	button.add_theme_stylebox_override("pressed", panel_style(pressed, pressed.darkened(0.16), 2, 8))
	button.add_theme_stylebox_override("focus", panel_style(hover, COLOR_YELLOW, 3, 8))


static func icon(path: String, size: Vector2 = Vector2(34, 34)) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture(path)
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect
