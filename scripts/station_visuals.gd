extends RefCounted
class_name StationVisuals

const TYPE_COLORS := {
	"ingredient": Color(0.93, 0.64, 0.25),
	"mix": Color(0.36, 0.58, 0.9),
	"chop": Color(0.48, 0.68, 0.82),
	"cook": Color(0.82, 0.28, 0.16),
	"decorate": Color(0.95, 0.48, 0.72),
	"recipe_book": Color(0.58, 0.42, 0.28),
	"plate": Color(0.9, 0.84, 0.74),
	"plating": Color(0.98, 0.78, 0.35),
	"delivery": Color(0.42, 0.72, 0.52),
	"trash": Color(0.55, 0.58, 0.62),
	"default": Color(0.7, 0.75, 0.8),
}

static func apply_to_station(body: StaticBody3D, label_text: String, station_type: String) -> void:
	var accent: Color = TYPE_COLORS.get(station_type, TYPE_COLORS["default"])
	_add_platform(body, accent)
	_add_highlight_ring(body, accent)
	_add_station_light(body, accent)


static func _add_platform(body: StaticBody3D, accent: Color) -> void:
	var pad := MeshInstance3D.new()
	pad.name = "StationPad"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.55
	cyl.bottom_radius = 1.55
	cyl.height = 0.08
	pad.mesh = cyl
	pad.position = Vector3(0, 0.04, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent.darkened(0.28)
	mat.emission_enabled = true
	mat.emission = accent * 0.08
	mat.roughness = 0.68
	pad.material_override = mat
	body.add_child(pad)
	body.move_child(pad, 0)


static func _add_highlight_ring(body: StaticBody3D, accent: Color) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "HighlightRing"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.72
	cyl.bottom_radius = 1.72
	cyl.height = 0.035
	ring.mesh = cyl
	ring.position = Vector3(0, 0.12, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent
	mat.emission_enabled = true
	mat.emission = accent * 0.45
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.48
	ring.material_override = mat
	ring.visible = false
	body.add_child(ring)


static func _add_station_light(body: StaticBody3D, accent: Color) -> void:
	var light := OmniLight3D.new()
	light.name = "StationLight"
	light.position = Vector3(0, 2.4, 0)
	light.light_color = accent.lerp(Color.WHITE, 0.5)
	light.light_energy = 0.35
	light.omni_range = 3.4
	light.shadow_enabled = false
	body.add_child(light)
