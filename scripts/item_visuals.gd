extends RefCounted
class_name ItemVisuals

const BASE := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/obj/"

static func ingredient_mesh_path(ingredient_type: String, state: String) -> String:
	match ingredient_type:
		"cake_batter", "cake":
			return ""
		"tomato":
			if state == "chopped":
				return BASE + "food_ingredient_tomato_slices.obj"
			return BASE + "food_ingredient_tomato.obj"
		"lettuce":
			if state == "chopped":
				return BASE + "food_ingredient_lettuce_chopped.obj"
			return BASE + "food_ingredient_lettuce.obj"
		"meat":
			match state:
				"cooked":
					return BASE + "food_ingredient_burger_cooked.obj"
				"burned":
					return BASE + "food_ingredient_burger_trash.obj"
				_:
					return BASE + "food_ingredient_steak.obj"
		"bread":
			return BASE + "food_ingredient_bun.obj"
		_:
			return BASE + "food_ingredient_carrot.obj"


static func load_ingredient_mesh(ingredient_type: String, state: String) -> Mesh:
	var path := ingredient_mesh_path(ingredient_type, state)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res = load(path)
	return res as Mesh


static func plate_mesh_path() -> String:
	return BASE + "plate_small.obj"


static func set_mesh_on_first_mesh_instance(root: Node3D, mesh: Mesh, scale_mul: float = 1.0) -> MeshInstance3D:
	var mi := _find_mesh_instance(root)
	if not mi:
		mi = MeshInstance3D.new()
		root.add_child(mi)
	mi.mesh = mesh
	mi.scale = Vector3.ONE * scale_mul
	return mi


static func _find_mesh_instance(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var found := _find_mesh_instance(c)
		if found:
			return found
	return null


static func apply_ingredient_visual(root: Node3D, ingredient_type: String, state: String, mesh_scale: float = 1.0) -> void:
	if ingredient_type == "cake_batter":
		_apply_cake_batter_visual(root, mesh_scale)
		return
	if ingredient_type == "cake":
		_apply_cake_visual(root, state, mesh_scale)
		return

	var mesh := load_ingredient_mesh(ingredient_type, state)
	if mesh:
		var mi := set_mesh_on_first_mesh_instance(root, mesh, mesh_scale)
		_tint_if_needed(mi, ingredient_type, state)
	else:
		_apply_fallback_ingredient_visual(root, ingredient_type, state, mesh_scale)


static func _tint_if_needed(mi: MeshInstance3D, ingredient_type: String, state: String) -> void:
	if ingredient_type == "tomato" and state == "cooked":
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.35, 0.15)
		mi.material_override = mat


static func _clear_generated_visual(root: Node3D) -> Node3D:
	var old := root.get_node_or_null("GeneratedVisual")
	if old:
		old.queue_free()
	var visual := Node3D.new()
	visual.name = "GeneratedVisual"
	root.add_child(visual)
	return visual


static func _make_mat(color: Color, roughness: float = 0.75) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat


static func _add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, scale: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scale
	mi.material_override = _make_mat(color)
	parent.add_child(mi)
	return mi


static func _apply_cake_batter_visual(root: Node3D, mesh_scale: float) -> void:
	var visual := _clear_generated_visual(root)
	var s := mesh_scale * 1.2

	var bowl := SphereMesh.new()
	bowl.radius = 0.38
	bowl.height = 0.24
	_add_mesh(visual, bowl, Vector3(0, 0.03, 0), Vector3(s, s * 0.45, s), Color(0.95, 0.92, 0.86))

	var batter := CylinderMesh.new()
	batter.top_radius = 0.28
	batter.bottom_radius = 0.28
	batter.height = 0.12
	_add_mesh(visual, batter, Vector3(0, 0.16, 0), Vector3(s, s, s), Color(0.95, 0.74, 0.32))

	var spoon := BoxMesh.new()
	spoon.size = Vector3(0.08, 0.08, 0.55)
	var spoon_mi := _add_mesh(visual, spoon, Vector3(0.22, 0.3, 0.0), Vector3(s, s, s), Color(0.72, 0.58, 0.42))
	spoon_mi.rotation_degrees = Vector3(0, 35, 18)


static func _apply_cake_visual(root: Node3D, state: String, mesh_scale: float) -> void:
	var visual := _clear_generated_visual(root)
	var s := mesh_scale * 1.25
	var burned := state == "burned"

	var base := CylinderMesh.new()
	base.top_radius = 0.36
	base.bottom_radius = 0.38
	base.height = 0.24
	_add_mesh(
		visual,
		base,
		Vector3(0, 0.12, 0),
		Vector3(s, s, s),
		Color(0.16, 0.12, 0.1) if burned else Color(0.72, 0.42, 0.2)
	)

	var frosting := CylinderMesh.new()
	frosting.top_radius = 0.34
	frosting.bottom_radius = 0.34
	frosting.height = 0.08
	_add_mesh(
		visual,
		frosting,
		Vector3(0, 0.29, 0),
		Vector3(s, s, s),
		Color(0.08, 0.07, 0.06) if burned else Color(1.0, 0.92, 0.72)
	)

	var cherry := SphereMesh.new()
	cherry.radius = 0.08
	cherry.height = 0.12
	_add_mesh(
		visual,
		cherry,
		Vector3(0, 0.38, 0),
		Vector3(s, s, s),
		Color(0.28, 0.05, 0.04) if burned else Color(0.9, 0.05, 0.08)
	)


static func _apply_fallback_ingredient_visual(root: Node3D, ingredient_type: String, state: String, mesh_scale: float) -> void:
	var visual := _clear_generated_visual(root)
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.42
	var color := Color(0.9, 0.75, 0.35)
	match ingredient_type:
		"tomato":
			color = Color(0.85, 0.12, 0.08)
		"lettuce":
			color = Color(0.25, 0.8, 0.25)
		"meat":
			color = Color(0.55, 0.22, 0.16)
		"bread":
			color = Color(0.82, 0.62, 0.28)
	if state == "burned":
		color = Color(0.08, 0.07, 0.06)
	_add_mesh(visual, sphere, Vector3(0, 0.18, 0), Vector3.ONE * mesh_scale, color)
