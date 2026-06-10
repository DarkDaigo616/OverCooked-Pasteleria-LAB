extends Node3D
class_name ProgressBar3D

@export var bar_width: float = 1.25
@export var bar_depth: float = 0.1
@export var bar_height: float = 0.14
@export var y_offset: float = 1.35

var value: float = 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		_update_fill()

var fill_color: Color = Color(0.25, 0.85, 0.35):
	set(c):
		fill_color = c
		_apply_fill_color()

var _bg: MeshInstance3D
var _fill: MeshInstance3D


func _ready() -> void:
	position.y = y_offset
	_build_meshes()
	visible = false
	_update_fill()


func _build_meshes() -> void:
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(bar_width, bar_height, bar_depth)
	_bg = MeshInstance3D.new()
	_bg.mesh = bg_box
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.15, 0.18, 0.9)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bg.material_override = bg_mat
	add_child(_bg)

	var fill_box := BoxMesh.new()
	fill_box.size = Vector3(bar_width, bar_height, bar_depth * 0.9)
	_fill = MeshInstance3D.new()
	_fill.mesh = fill_box
	_fill.position = Vector3(-bar_width * 0.5, 0, bar_depth * 0.05)
	_apply_fill_color()
	add_child(_fill)
	_update_fill()


func _apply_fill_color() -> void:
	if not _fill:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fill_color
	mat.emission_enabled = true
	mat.emission = fill_color * 0.35
	_fill.material_override = mat


func _update_fill() -> void:
	if not _fill:
		return
	var w := maxf(value * bar_width, 0.02)
	_fill.scale = Vector3(value, 1.0, 1.0)
	_fill.position.x = -bar_width * 0.5 + w * 0.5


func show_bar(show: bool) -> void:
	visible = show
	if not show:
		value = 0.0


func set_progress(ratio: float, color_override: Variant = null) -> void:
	if color_override is Color:
		fill_color = color_override
	value = ratio
