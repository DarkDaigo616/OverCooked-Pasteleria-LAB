extends RefCounted
class_name StationFactory

const BASE := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/obj/"
const COUNTER_SHAPE_SIZE := Vector3(1.95, 1.38, 1.88)
const MESH_SCALE := 1.2

const INGREDIENT_MESHES := {
	"cake_batter": BASE + "bowl.obj",
	"tomato": BASE + "crate_tomatoes.obj",
	"lettuce": BASE + "crate_lettuce.obj",
	"meat": BASE + "crate_steak.obj",
	"bread": BASE + "crate_buns.obj",
}

const INGREDIENT_COLORS := {
	"cake_batter": Color(0.95, 0.74, 0.32),
	"tomato": Color(0.8, 0.2, 0.2),
	"lettuce": Color(0.2, 0.8, 0.2),
	"meat": Color(0.6, 0.3, 0.2),
	"bread": Color(0.8, 0.7, 0.4),
}

const LABELS := {
	"cake_batter": "Ingredientes",
	"tomato": "TOMATES",
	"lettuce": "LECHUGA",
	"meat": "CARNE",
	"bread": "PAN",
	"cook": "Horno",
	"delivery": "Entregar",
}


static func build_station(data: Dictionary) -> StaticBody3D:
	var stype: String = data.get("type", "")
	match stype:
		"ingredient":
			return _build_ingredient(data)
		"cook":
			return _build_cooking(data)
		"delivery":
			return _build_delivery(data)
		_:
			push_warning("StationFactory: tipo desconocido ", stype)
			return StaticBody3D.new()


static func _base_station(
	pos: Vector3,
	label_text: String,
	mesh_path: String,
	station_type: String
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = PhysicsLayers.STATIONS
	body.collision_mask = 0

	var shape := BoxShape3D.new()
	shape.size = COUNTER_SHAPE_SIZE
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)

	if ResourceLoader.exists(mesh_path):
		var mesh: Mesh = load(mesh_path)
		if mesh:
			var mi := MeshInstance3D.new()
			mi.name = "StationMesh"
			mi.mesh = mesh
			mi.scale = Vector3.ONE * MESH_SCALE
			mi.position.y = 0.08
			body.add_child(mi)
	else:
		_add_fallback_counter(body, station_type)

	var label := Label3D.new()
	label.text = label_text
	body.add_child(label)

	StationVisuals.apply_to_station(body, label_text, station_type)
	return body


static func _add_fallback_counter(body: StaticBody3D, station_type: String) -> void:
	var base_color := Color(0.48, 0.46, 0.42)
	var top_color := Color(0.72, 0.68, 0.58)
	var accent := Color(0.86, 0.72, 0.42)
	match station_type:
		"ingredient":
			base_color = Color(0.42, 0.52, 0.38)
			top_color = Color(0.82, 0.74, 0.56)
			accent = Color(0.95, 0.73, 0.28)
		"cook":
			base_color = Color(0.34, 0.31, 0.32)
			top_color = Color(0.18, 0.18, 0.2)
			accent = Color(0.95, 0.32, 0.16)
		"delivery":
			base_color = Color(0.42, 0.39, 0.48)
			top_color = Color(0.64, 0.72, 0.68)
			accent = Color(0.35, 0.85, 0.65)

	_add_box(body, "StationMesh", Vector3(1.9, 0.9, 1.45), Vector3(0, 0.5, 0), base_color)
	_add_box(body, "StationTop", Vector3(2.05, 0.18, 1.6), Vector3(0, 1.04, 0), top_color)
	_add_box(body, "StationAccent", Vector3(2.08, 0.12, 0.12), Vector3(0, 1.18, -0.78), accent)

	match station_type:
		"ingredient":
			_add_ingredient_props(body, accent)
		"cook":
			_add_oven_props(body, accent)
		"delivery":
			_add_delivery_props(body, accent)


static func _make_mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color * emission
	return mat


static func _add_box(parent: Node3D, name: String, size: Vector3, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = _make_mat(color, emission)
	parent.add_child(mi)
	return mi


static func _add_cylinder(parent: Node3D, name: String, radius: float, height: float, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mi.mesh = cyl
	mi.position = pos
	mi.material_override = _make_mat(color, emission)
	parent.add_child(mi)
	return mi


static func _add_sphere(parent: Node3D, name: String, radius: float, pos: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.6
	mi.mesh = sphere
	mi.position = pos
	mi.scale = scale
	mi.material_override = _make_mat(color)
	parent.add_child(mi)
	return mi


static func _add_ingredient_props(body: Node3D, accent: Color) -> void:
	_add_sphere(body, "MixingBowl", 0.42, Vector3(0, 1.32, 0), Color(0.96, 0.93, 0.86), Vector3(1.0, 0.42, 1.0))
	_add_cylinder(body, "BatterSurface", 0.29, 0.08, Vector3(0, 1.42, 0), accent.lightened(0.18))
	var spoon := _add_box(body, "Spoon", Vector3(0.08, 0.08, 0.72), Vector3(0.34, 1.52, -0.02), Color(0.62, 0.48, 0.32))
	spoon.rotation_degrees = Vector3(0, 32, 18)


static func _add_oven_props(body: Node3D, accent: Color) -> void:
	_add_box(body, "OvenDoor", Vector3(1.0, 0.48, 0.08), Vector3(0, 0.58, -0.77), Color(0.08, 0.08, 0.09))
	_add_box(body, "OvenWindow", Vector3(0.72, 0.28, 0.09), Vector3(0, 0.6, -0.82), Color(0.95, 0.55, 0.18), 0.45)
	_add_cylinder(body, "LeftKnob", 0.08, 0.06, Vector3(-0.34, 1.24, -0.78), accent, 0.25)
	_add_cylinder(body, "RightKnob", 0.08, 0.06, Vector3(0.34, 1.24, -0.78), accent, 0.25)


static func _add_delivery_props(body: Node3D, accent: Color) -> void:
	_add_box(body, "CounterTray", Vector3(1.15, 0.06, 0.72), Vector3(0, 1.31, -0.02), Color(0.86, 0.86, 0.8))
	_add_box(body, "TrayGlow", Vector3(1.0, 0.04, 0.58), Vector3(0, 1.36, -0.02), accent.lightened(0.18), 0.22)
	_add_box(body, "Ticket", Vector3(0.42, 0.48, 0.04), Vector3(0.54, 1.55, -0.35), Color(1.0, 0.94, 0.72))


static func _add_item_holder(parent: StaticBody3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "ItemHolder"
	holder.position = Vector3(0, 0.65, 0)
	parent.add_child(holder)
	return holder


static func _add_progress_bar(parent: Node3D) -> ProgressBar3D:
	var bar := ProgressBar3D.new()
	bar.name = "ProgressBar3D"
	bar.y_offset = 1.45
	parent.add_child(bar)
	return bar


static func _build_ingredient(data: Dictionary) -> StaticBody3D:
	var ing: String = data.get("ingredient", "tomato")
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS.get(ing, ing.to_upper()),
		INGREDIENT_MESHES.get(ing, INGREDIENT_MESHES["tomato"]),
		"ingredient"
	)
	var script := load("res://scripts/ingredient_station.gd") as Script
	body.set_script(script)
	body.ingredient_type = ing
	body.ingredient_color = INGREDIENT_COLORS.get(ing, Color.WHITE)
	if ing == "cake_batter":
		body.ingredient_mesh_scale = 0.75
	return body


static func _build_cooking(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["cook"],
		BASE + "stove_multi.obj",
		"cook"
	)
	body.set_script(load("res://scripts/cooking_station.gd"))
	_add_item_holder(body)
	_add_progress_bar(body)
	return body


static func _build_delivery(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["delivery"],
		BASE + "wall_orderwindow.obj",
		"delivery"
	)
	body.set_script(load("res://scripts/delivery_window.gd"))
	return body
