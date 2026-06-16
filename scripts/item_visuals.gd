extends RefCounted
class_name ItemVisuals

const BASE := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/"
const TINY_TREATS_BASE := "res://assets/{models,textures,sounds}/Tiny_Treats_Bakery_Interior_1.1_FREE/Assets/gltf/"

static func ingredient_mesh_path(ingredient_type: String, state: String) -> String:
	match ingredient_type:
		"cake_batter", "bad_batter", "cake", "flour", "egg", "sugar":
			return ""
		"tomato":
			if state == "chopped":
				return BASE + "food_ingredient_tomato_slices.gltf"
			return BASE + "food_ingredient_tomato.gltf"
		"lettuce":
			if state == "chopped":
				return BASE + "food_ingredient_lettuce_chopped.gltf"
			return BASE + "food_ingredient_lettuce.gltf"
		"meat":
			match state:
				"cooked":
					return BASE + "food_ingredient_burger_cooked.gltf"
				"burned":
					return BASE + "food_ingredient_burger_trash.gltf"
				_:
					return BASE + "food_ingredient_steak.gltf"
		"bread":
			return BASE + "food_ingredient_bun.gltf"
		_:
			return BASE + "food_ingredient_carrot.gltf"


static func load_ingredient_mesh(ingredient_type: String, state: String) -> Mesh:
	var path := ingredient_mesh_path(ingredient_type, state)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res = load(path)
	return res as Mesh


static func load_ingredient_scene(ingredient_type: String, state: String) -> PackedScene:
	var path := ingredient_mesh_path(ingredient_type, state)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var res = load(path)
	return res as PackedScene


static func plate_mesh_path() -> String:
	return BASE + "plate_small.gltf"


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
		_apply_cake_batter_visual(root, mesh_scale, true)
		return
	if ingredient_type == "bad_batter":
		_apply_cake_batter_visual(root, mesh_scale, false)
		return
	if ingredient_type in ["flour", "egg", "sugar"]:
		_apply_baking_ingredient_visual(root, ingredient_type, mesh_scale)
		return
	if ingredient_type == "cake":
		_apply_cake_visual(root, state, mesh_scale)
		return

	var mesh := load_ingredient_mesh(ingredient_type, state)
	if mesh:
		var mi := set_mesh_on_first_mesh_instance(root, mesh, mesh_scale)
		_tint_if_needed(mi, ingredient_type, state)
	else:
		var scene := load_ingredient_scene(ingredient_type, state)
		if scene:
			_apply_scene_visual(root, scene, mesh_scale)
		else:
			_apply_fallback_ingredient_visual(root, ingredient_type, state, mesh_scale)


static func _tint_if_needed(mi: MeshInstance3D, ingredient_type: String, state: String) -> void:
	if ingredient_type == "tomato" and state == "cooked":
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.35, 0.15)
		mi.material_override = mat


static func _apply_scene_visual(root: Node3D, scene: PackedScene, mesh_scale: float) -> void:
	var visual := _clear_generated_visual(root)
	var node := scene.instantiate() as Node3D
	if node == null:
		return
	node.scale = Vector3.ONE * mesh_scale
	visual.add_child(node)


static func _apply_tiny_treat_scene_visual(root: Node3D, asset_name: String, mesh_scale: float) -> bool:
	var path := TINY_TREATS_BASE + asset_name
	if not ResourceLoader.exists(path):
		return false
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	_apply_scene_visual(root, scene, mesh_scale)
	return true


static func _clear_generated_visual(root: Node3D) -> Node3D:
	var old := root.get_node_or_null("GeneratedVisual")
	if old:
		root.remove_child(old)
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


static func _apply_cake_batter_visual(root: Node3D, mesh_scale: float, valid_mix: bool = true) -> void:
	var visual := _clear_generated_visual(root)
	var s := mesh_scale * 1.2
	var batter_color := Color(0.95, 0.74, 0.32) if valid_mix else Color(0.56, 0.48, 0.38)

	var bowl := SphereMesh.new()
	bowl.radius = 0.38
	bowl.height = 0.24
	_add_mesh(visual, bowl, Vector3(0, 0.03, 0), Vector3(s, s * 0.45, s), Color(0.95, 0.92, 0.86))

	var batter := CylinderMesh.new()
	batter.top_radius = 0.28
	batter.bottom_radius = 0.28
	batter.height = 0.12
	_add_mesh(visual, batter, Vector3(0, 0.16, 0), Vector3(s, s, s), batter_color)

	var spoon := BoxMesh.new()
	spoon.size = Vector3(0.08, 0.08, 0.55)
	var spoon_mi := _add_mesh(visual, spoon, Vector3(0.22, 0.3, 0.0), Vector3(s, s, s), Color(0.72, 0.58, 0.42))
	spoon_mi.rotation_degrees = Vector3(0, 35, 18)


static func _apply_baking_ingredient_visual(root: Node3D, ingredient_type: String, mesh_scale: float) -> void:
	match ingredient_type:
		"flour":
			if _apply_tiny_treat_scene_visual(root, "flour_sack_open.gltf", mesh_scale * 1.08):
				return
		"egg":
			if _apply_tiny_treat_scene_visual(root, "egg_A.gltf", mesh_scale * 1.1):
				return
		"sugar":
			if _apply_tiny_treat_scene_visual(root, "tin_B_beige.gltf", mesh_scale * 1.05):
				return

	var visual := _clear_generated_visual(root)
	var s := mesh_scale

	match ingredient_type:
		"flour":
			var sack := BoxMesh.new()
			sack.size = Vector3(0.42, 0.36, 0.3)
			_add_mesh(visual, sack, Vector3(0, 0.18, 0), Vector3(s, s, s), Color(0.78, 0.58, 0.36))
			var flour := SphereMesh.new()
			flour.radius = 0.22
			flour.height = 0.16
			_add_mesh(visual, flour, Vector3(0.02, 0.43, 0), Vector3(s * 1.2, s * 0.45, s), Color(0.96, 0.92, 0.82))
		"egg":
			var shell := SphereMesh.new()
			shell.radius = 0.22
			shell.height = 0.34
			_add_mesh(visual, shell, Vector3(0, 0.22, 0), Vector3(s * 0.88, s * 1.1, s * 0.88), Color(1.0, 0.96, 0.82))
			var yolk := SphereMesh.new()
			yolk.radius = 0.08
			yolk.height = 0.1
			_add_mesh(visual, yolk, Vector3(0.06, 0.28, 0.12), Vector3(s, s, s), Color(1.0, 0.72, 0.12))
		"sugar":
			var cube := BoxMesh.new()
			cube.size = Vector3(0.16, 0.16, 0.16)
			_add_mesh(visual, cube, Vector3(-0.11, 0.15, 0.02), Vector3(s, s, s), Color(1.0, 0.96, 0.9))
			_add_mesh(visual, cube, Vector3(0.06, 0.18, -0.08), Vector3(s, s, s), Color(0.94, 0.9, 0.86))
			_add_mesh(visual, cube, Vector3(0.13, 0.33, 0.08), Vector3(s, s, s), Color(1.0, 0.98, 0.94))


static func _apply_cake_visual(root: Node3D, state: String, mesh_scale: float) -> void:
	var visual := _clear_generated_visual(root)
	var s := mesh_scale * 1.25
	var burned := state == "burned"
	var ruined := state == "ruined_baked"
	var decorated_vanilla := state == "decorated_vanilla"
	var decorated_chocolate := state == "decorated_chocolate"
	var decorated_strawberry := state == "decorated_strawberry"

	var base := CylinderMesh.new()
	base.top_radius = 0.36
	base.bottom_radius = 0.38
	base.height = 0.24
	var base_color := Color(0.72, 0.42, 0.2)
	if burned:
		base_color = Color(0.16, 0.12, 0.1)
	elif ruined:
		base_color = Color(0.36, 0.28, 0.22)
	_add_mesh(
		visual,
		base,
		Vector3(0, 0.12, 0),
		Vector3(s, s, s),
		base_color
	)

	var frosting := CylinderMesh.new()
	frosting.top_radius = 0.34
	frosting.bottom_radius = 0.34
	frosting.height = 0.08
	var frosting_color := Color(1.0, 0.92, 0.72)
	if burned:
		frosting_color = Color(0.08, 0.07, 0.06)
	elif ruined:
		frosting_color = Color(0.42, 0.38, 0.32)
	elif decorated_chocolate:
		frosting_color = Color(0.22, 0.1, 0.05)
	elif decorated_vanilla:
		frosting_color = Color(1.0, 0.97, 0.84)
	elif decorated_strawberry:
		frosting_color = Color(0.95, 0.32, 0.42)
	_add_mesh(
		visual,
		frosting,
		Vector3(0, 0.29, 0),
		Vector3(s, s, s),
		frosting_color
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

	if decorated_vanilla or decorated_chocolate or decorated_strawberry:
		var sprinkle := BoxMesh.new()
		sprinkle.size = Vector3(0.12, 0.035, 0.035)
		var sprinkle_colors: Array[Color]
		if decorated_strawberry:
			sprinkle_colors = [
				Color(0.92, 0.08, 0.14),
				Color(0.82, 0.04, 0.1),
				Color(1.0, 0.22, 0.32),
			]
		else:
			sprinkle_colors = [
				Color(0.95, 0.36, 0.46),
				Color(0.35, 0.62, 0.92),
				Color(0.36, 0.78, 0.42),
			]
		var positions := [
			Vector3(-0.16, 0.36, 0.08),
			Vector3(0.14, 0.36, 0.04),
			Vector3(0.0, 0.36, -0.14),
		]
		for i in range(positions.size()):
			var piece := _add_mesh(visual, sprinkle, positions[i], Vector3(s, s, s), sprinkle_colors[i])
			piece.rotation_degrees.y = 35.0 * float(i + 1)


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
