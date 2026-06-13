extends RefCounted
class_name StationVisuals

const TYPE_COLORS := {
	"ingredient": Color(0.95, 0.73, 0.28),
	"chop": Color(0.35, 0.65, 1.0),
	"cook": Color(0.95, 0.32, 0.16),
	"plate": Color(0.9, 0.95, 1.0),
	"plating": Color(1.0, 0.88, 0.2),
	"delivery": Color(0.35, 0.85, 0.65),
	"trash": Color(0.55, 0.58, 0.62),
	"default": Color(0.7, 0.75, 0.8),
}


static func apply_to_station(body: StaticBody3D, label_text: String, station_type: String) -> void:
	var accent: Color = TYPE_COLORS.get(station_type, TYPE_COLORS["default"])
	_add_platform(body, accent)
	_add_highlight_ring(body, accent)
	_add_station_light(body, accent)
	_configure_label(body, label_text)


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


static func _configure_label(body: StaticBody3D, text: String) -> void:
	for child in body.get_children():
		if child is Label3D:
			var label := child as Label3D
			label.name = "StationLabel"
			label.text = text
			label.position = Vector3(0, 1.35, 1.55)
			label.font_size = 76
			label.pixel_size = 0.008
			label.outline_size = 12
			label.outline_modulate = Color(1.0, 0.95, 0.78, 1)
			label.modulate = Color(0.2, 0.12, 0.07, 1)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			return
