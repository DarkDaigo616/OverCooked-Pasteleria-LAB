extends RefCounted
class_name ItemVisuals

const BASE := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/obj/"

static func ingredient_mesh_path(ingredient_type: String, state: String) -> String:
	match ingredient_type:
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
	var mesh := load_ingredient_mesh(ingredient_type, state)
	if mesh:
		var mi := set_mesh_on_first_mesh_instance(root, mesh, mesh_scale)
		_tint_if_needed(mi, ingredient_type, state)
	else:
		push_warning("ItemVisuals: could not load mesh for ", ingredient_type, " ", state)


static func _tint_if_needed(mi: MeshInstance3D, ingredient_type: String, state: String) -> void:
	if ingredient_type == "tomato" and state == "cooked":
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.35, 0.15)
		mi.material_override = mat
