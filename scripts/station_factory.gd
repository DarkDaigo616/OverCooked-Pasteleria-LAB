extends RefCounted
class_name StationFactory

const Materials = preload("res://materials/bakery_materials.gd")
const TINY_TREATS_BASE := "res://assets/{models,textures,sounds}/Tiny_Treats_Bakery_Interior_1.1_FREE/Assets/gltf/"
const KAYKIT_BASE := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/"
const STAND_MIXER_PATH := TINY_TREATS_BASE + "stand_mixer.gltf"
const COUNTER_SHAPE_SIZE := Vector3(1.95, 1.38, 1.88)
const MESH_SCALE := 1.75
const OVEN_MESH_SCALE := 1.2

const INGREDIENT_MESHES := {
	"cake_batter": TINY_TREATS_BASE + "mixing_bowl.gltf",
	"flour": TINY_TREATS_BASE + "flour_sack_open.gltf",
	"egg": TINY_TREATS_BASE + "egg_A.gltf",
	"sugar": TINY_TREATS_BASE + "tin_B_beige.gltf",
	"tomato": TINY_TREATS_BASE + "basket_A.gltf",
	"lettuce": TINY_TREATS_BASE + "basket_B.gltf",
	"meat": TINY_TREATS_BASE + "countertop_straight_A_short.gltf",
	"bread": TINY_TREATS_BASE + "bread.gltf",
}

const INGREDIENT_COLORS := {
	"cake_batter": Color(0.95, 0.74, 0.32),
	"flour": Color(0.94, 0.89, 0.78),
	"egg": Color(1.0, 0.86, 0.34),
	"sugar": Color(0.98, 0.95, 0.9),
	"tomato": Color(0.8, 0.2, 0.2),
	"lettuce": Color(0.2, 0.8, 0.2),
	"meat": Color(0.6, 0.3, 0.2),
	"bread": Color(0.8, 0.7, 0.4),
}

const LABELS := {
	"cake_batter": "Ingredientes",
	"flour": "Ingredientes: Harina",
	"egg": "Ingredientes: Huevo",
	"sugar": "Ingredientes: Azucar",
	"tomato": "TOMATES",
	"lettuce": "LECHUGA",
	"meat": "CARNE",
	"bread": "PAN",
	"mix": "Batidora",
	"cook": "Horno",
	"decorate_vanilla": "Decoracion: Vainilla",
	"decorate_chocolate": "Decoracion: Chocolate",
	"decorate_strawberry": "Decoracion: Fresa",
	"recipe_book": "Recetario",
	"delivery": "Entregar",
	"trash": "Basura",
}


static func build_station(data: Dictionary) -> StaticBody3D:
	var stype: String = data.get("type", "")
	match stype:
		"ingredient":
			return _build_ingredient(data)
		"mix":
			return _build_mixing(data)
		"cook":
			return _build_cooking(data)
		"decorate":
			return _build_decoration(data)
		"recipe_book":
			return _build_recipe_book(data)
		"delivery":
			return _build_delivery(data)
		"trash":
			return _build_trash(data)
		_:
			push_warning("StationFactory: tipo desconocido ", stype)
			return StaticBody3D.new()


static func _base_station(
	pos: Vector3,
	label_text: String,
	mesh_path: String,
	station_type: String,
	mesh_scale: float = MESH_SCALE,
	ingredient_type: String = ""
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.set_meta("station_type", station_type)
	if not ingredient_type.is_empty():
		body.set_meta("ingredient_type", ingredient_type)
	body.collision_layer = PhysicsLayers.STATIONS
	body.collision_mask = 0

	var shape := BoxShape3D.new()
	shape.size = COUNTER_SHAPE_SIZE
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)

	if not _add_asset_child(body, mesh_path, "StationMesh", Vector3.ONE * mesh_scale, Vector3(0, 0.08, 0)):
		_add_fallback_counter(body, station_type)

	body.set_meta("display_name", label_text)
	_add_station_dressing(body, station_type)

	StationVisuals.apply_to_station(body, label_text, station_type)
	return body


static func _add_fallback_counter(body: StaticBody3D, station_type: String) -> void:
	var base_color := Color(0.48, 0.46, 0.42)
	var top_color := Color(0.72, 0.68, 0.58)
	var accent := Color(0.86, 0.72, 0.42)
	match station_type:
		"ingredient":
			base_color = Materials.WOOD
			top_color = Materials.CREAM
			accent = Materials.PASTEL_YELLOW
		"mix":
			base_color = Color(0.28, 0.36, 0.52)
			top_color = Materials.CREAM_LIGHT
			accent = Color(0.36, 0.58, 0.9)
		"cook":
			base_color = Materials.CHOCOLATE
			top_color = Color(0.45, 0.22, 0.14)
			accent = Color(0.95, 0.32, 0.16)
		"decorate":
			base_color = Color(0.46, 0.28, 0.38)
			top_color = Materials.CREAM_LIGHT
			accent = Color(0.95, 0.48, 0.72)
		"recipe_book":
			base_color = Materials.WOOD
			top_color = Materials.CREAM_LIGHT
			accent = Color(0.68, 0.46, 0.28)
		"delivery":
			base_color = Color(0.48, 0.32, 0.22)
			top_color = Materials.CREAM_LIGHT
			accent = Materials.PASTEL_GREEN
		"trash":
			base_color = Color(0.38, 0.4, 0.43)
			top_color = Color(0.68, 0.7, 0.72)
			accent = Color(0.56, 0.6, 0.64)

	_add_box(body, "StationMesh", Vector3(1.9, 0.9, 1.45), Vector3(0, 0.5, 0), base_color)
	_add_box(body, "StationTop", Vector3(2.05, 0.18, 1.6), Vector3(0, 1.04, 0), top_color)
	_add_box(body, "StationAccent", Vector3(2.08, 0.12, 0.12), Vector3(0, 1.18, -0.78), accent)

	match station_type:
		"ingredient":
			_add_ingredient_props(body, accent)
		"mix":
			_add_mixer_props(body, accent)
		"cook":
			_add_oven_props(body, accent)
		"decorate":
			_add_decoration_props(body, accent)
		"recipe_book":
			_add_recipe_book_props(body, accent)
		"delivery":
			_add_delivery_props(body, accent)
		"trash":
			_add_trash_props(body, accent)


static func _add_asset_child(parent: Node3D, path: String, node_name: String, scale: Vector3, pos: Vector3) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var res := load(path)
	var node: Node3D = null
	if res is PackedScene:
		node = (res as PackedScene).instantiate() as Node3D
	elif res is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = res as Mesh
		node = mi
	if node == null:
		return false
	node.name = node_name
	node.scale = scale
	node.position = pos
	parent.add_child(node)
	return true


static func _make_mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	return Materials.make(color, 0.78, emission)


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
	var ingredient_type := str(body.get_meta("ingredient_type", ""))
	if _add_specific_ingredient_prop(body, ingredient_type):
		return
	_add_generic_ingredient_props(body, accent)


static func _add_generic_ingredient_props(body: Node3D, accent: Color) -> void:
	_add_sphere(body, "MixingBowl", 0.42, Vector3(0, 1.32, 0), Color(0.96, 0.93, 0.86), Vector3(1.0, 0.42, 1.0))
	_add_cylinder(body, "BatterSurface", 0.29, 0.08, Vector3(0, 1.42, 0), accent.lightened(0.18))
	var spoon := _add_box(body, "Spoon", Vector3(0.08, 0.08, 0.72), Vector3(0.34, 1.52, -0.02), Color(0.62, 0.48, 0.32))
	spoon.rotation_degrees = Vector3(0, 32, 18)


static func _add_specific_ingredient_prop(body: Node3D, ingredient_type: String) -> bool:
	match ingredient_type:
		"flour":
			var added := _add_asset_child(body, TINY_TREATS_BASE + "flour_sack_open.gltf", "FlourSackOpen", Vector3.ONE * 1.25, Vector3(-0.18, 1.34, 0.0))
			_add_sphere(body, "LooseFlour", 0.18, Vector3(0.42, 1.36, -0.18), Materials.FLOUR, Vector3(1.45, 0.32, 1.1))
			return added
		"egg":
			var added := _add_asset_child(body, TINY_TREATS_BASE + "egg_A.gltf", "EggA", Vector3.ONE * 1.25, Vector3(-0.22, 1.36, 0.12))
			if _add_asset_child(body, TINY_TREATS_BASE + "egg_B.gltf", "EggB", Vector3.ONE * 1.18, Vector3(0.22, 1.36, -0.08)):
				added = true
			_add_cylinder(body, "EggDish", 0.42, 0.06, Vector3(0, 1.29, 0.02), Materials.CREAM_LIGHT)
			return added
		"sugar":
			var added := _add_asset_child(body, TINY_TREATS_BASE + "tin_B_beige.gltf", "SugarTin", Vector3.ONE * 1.22, Vector3(-0.12, 1.34, 0.02))
			_add_box(body, "SugarCubeA", Vector3(0.14, 0.14, 0.14), Vector3(0.4, 1.38, -0.08), Materials.CREAM_LIGHT)
			_add_box(body, "SugarCubeB", Vector3(0.14, 0.14, 0.14), Vector3(0.54, 1.42, 0.08), Materials.CREAM)
			return added
		"cake_batter":
			return _add_asset_child(body, TINY_TREATS_BASE + "mixing_bowl.gltf", "BatterBowl", Vector3.ONE * 1.1, Vector3(0, 1.32, 0.02))
		_:
			return false


static func _add_oven_props(body: Node3D, accent: Color) -> void:
	_add_box(body, "OvenDoor", Vector3(1.0, 0.48, 0.08), Vector3(0, 0.58, -0.77), Color(0.08, 0.08, 0.09))
	_add_box(body, "OvenWindow", Vector3(0.72, 0.28, 0.09), Vector3(0, 0.6, -0.82), Color(0.95, 0.55, 0.18), 0.45)
	_add_cylinder(body, "LeftKnob", 0.08, 0.06, Vector3(-0.34, 1.24, -0.78), accent, 0.25)
	_add_cylinder(body, "RightKnob", 0.08, 0.06, Vector3(0.34, 1.24, -0.78), accent, 0.25)


static func _add_mixer_props(body: Node3D, accent: Color) -> void:
	if _add_asset_child(body, STAND_MIXER_PATH, "StandMixer", Vector3.ONE * 1.1, Vector3(0, 1.16, 0.02)):
		return
	_add_cylinder(body, "MixerBowl", 0.36, 0.22, Vector3(0.0, 1.32, 0.03), Color(0.92, 0.92, 0.9))
	_add_box(body, "MixerBody", Vector3(0.38, 0.34, 0.26), Vector3(0.0, 1.68, -0.02), accent)
	_add_box(body, "MixerNeck", Vector3(0.16, 0.36, 0.16), Vector3(0.0, 1.48, -0.16), accent.darkened(0.08))
	var whisk := _add_box(body, "MixerWhisk", Vector3(0.08, 0.38, 0.08), Vector3(0.0, 1.42, 0.05), Color(0.8, 0.82, 0.84))
	whisk.rotation_degrees.z = 18.0


static func _add_decoration_props(body: Node3D, accent: Color) -> void:
	_add_cylinder(body, "IcingBowl", 0.28, 0.12, Vector3(-0.35, 1.31, -0.05), Color(1.0, 0.94, 0.8))
	_add_cylinder(body, "Icing", 0.2, 0.08, Vector3(-0.35, 1.41, -0.05), accent.lightened(0.22))
	_add_box(body, "SpatulaHandle", Vector3(0.08, 0.08, 0.6), Vector3(0.28, 1.42, 0.02), Color(0.58, 0.36, 0.2))
	_add_box(body, "SpatulaBlade", Vector3(0.24, 0.04, 0.16), Vector3(0.52, 1.46, 0.16), Color(0.82, 0.84, 0.86))


static func _add_recipe_book_props(body: Node3D, accent: Color) -> void:
	_add_box(body, "BookLeftPage", Vector3(0.68, 0.05, 0.88), Vector3(-0.34, 1.34, 0.0), Color(1.0, 0.93, 0.76))
	_add_box(body, "BookRightPage", Vector3(0.68, 0.05, 0.88), Vector3(0.34, 1.34, 0.0), Color(1.0, 0.93, 0.76))
	_add_box(body, "BookSpine", Vector3(0.08, 0.07, 0.92), Vector3(0.0, 1.36, 0.0), accent.darkened(0.18))
	_add_box(body, "Bookmark", Vector3(0.08, 0.04, 0.54), Vector3(0.18, 1.39, 0.1), Color(0.84, 0.22, 0.18))
	_add_cylinder(body, "RecipeInkDotA", 0.04, 0.03, Vector3(-0.34, 1.39, -0.22), Color(0.35, 0.22, 0.16))
	_add_cylinder(body, "RecipeInkDotB", 0.04, 0.03, Vector3(0.34, 1.39, 0.2), Color(0.35, 0.22, 0.16))


static func _add_delivery_props(body: Node3D, accent: Color) -> void:
	_add_box(body, "CounterTray", Vector3(1.15, 0.06, 0.72), Vector3(0, 1.31, -0.02), Color(0.86, 0.86, 0.8))
	_add_box(body, "TrayGlow", Vector3(1.0, 0.04, 0.58), Vector3(0, 1.36, -0.02), accent.lightened(0.18), 0.22)
	_add_box(body, "Ticket", Vector3(0.42, 0.48, 0.04), Vector3(0.54, 1.55, -0.35), Color(1.0, 0.94, 0.72))


static func _add_trash_props(body: Node3D, accent: Color) -> void:
	if _add_asset_child(body, TINY_TREATS_BASE + "tin_B_grey.gltf", "TrashTin", Vector3.ONE * 1.65, Vector3(0, 0.78, 0.02)):
		return
	_add_cylinder(body, "TrashCan", 0.46, 0.82, Vector3(0, 0.62, 0), Color(0.42, 0.45, 0.48))
	_add_cylinder(body, "TrashRim", 0.5, 0.08, Vector3(0, 1.06, 0), accent.lightened(0.18))
	_add_box(body, "TrashSlot", Vector3(0.68, 0.08, 0.12), Vector3(0, 1.12, -0.36), Color(0.12, 0.13, 0.14))


static func _add_station_dressing(body: Node3D, station_type: String) -> void:
	match station_type:
		"ingredient":
			_add_box(body, "WarmCounterInsert", Vector3(1.5, 0.07, 1.08), Vector3(0, 1.14, 0), Materials.WOOD)
			_add_ingredient_props(body, Materials.PASTEL_YELLOW)
		"mix":
			_add_box(body, "MixerCounterInsert", Vector3(1.55, 0.08, 1.0), Vector3(0, 1.18, 0), Color(0.86, 0.9, 0.96))
			_add_mixer_props(body, Color(0.36, 0.58, 0.9))
		"cook":
			_add_box(body, "WarmOvenGlow", Vector3(0.9, 0.08, 0.06), Vector3(0, 0.82, -0.86), Color(1.0, 0.48, 0.16), 0.5)
			_add_cylinder(body, "OvenReadyPlate", 0.28, 0.05, Vector3(0.0, 1.42, 0.05), Materials.CREAM_LIGHT)
		"decorate":
			_add_box(body, "DecorationCounterInsert", Vector3(1.55, 0.08, 1.0), Vector3(0, 1.18, 0), Color(1.0, 0.9, 0.95))
			_add_decoration_props(body, Color(0.95, 0.48, 0.72))
		"recipe_book":
			_add_box(body, "RecipeBookTableTop", Vector3(1.55, 0.08, 1.0), Vector3(0, 1.18, 0), Materials.WOOD)
			_add_recipe_book_props(body, Color(0.68, 0.46, 0.28))
		"delivery":
			_add_box(body, "DeliveryCounterWood", Vector3(1.65, 0.08, 0.72), Vector3(0, 1.2, 0), Materials.WOOD)
			_add_cylinder(body, "DisplayCakeA", 0.16, 0.11, Vector3(-0.38, 1.34, -0.08), Materials.PASTEL_PINK)
			_add_cylinder(body, "DisplayCakeB", 0.16, 0.11, Vector3(0.0, 1.34, -0.08), Materials.PASTEL_YELLOW)
			_add_cylinder(body, "DisplayCakeC", 0.16, 0.11, Vector3(0.38, 1.34, -0.08), Materials.PASTEL_GREEN)


static func _add_item_holder(parent: StaticBody3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "ItemHolder"
	holder.position = Vector3(0, 0.65, 0)
	parent.add_child(holder)
	return holder


static func _add_progress_bar(parent: Node3D) -> ProgressBar3D:
	var bar := ProgressBar3D.new()
	bar.name = "ProgressBar3D"
	bar.y_offset = 3.05
	bar.z_offset = 1.65
	bar.bar_width = 2.35
	bar.bar_height = 0.24
	bar.bar_depth = 0.18
	parent.add_child(bar)
	return bar


static func _build_ingredient(data: Dictionary) -> StaticBody3D:
	var ing: String = data.get("ingredient", "tomato")
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS.get(ing, ing.to_upper()),
		TINY_TREATS_BASE + "countertop_straight_A_short.gltf",
		"ingredient",
		1.2,
		ing
	)
	var script := load("res://scripts/ingredient_station.gd") as Script
	body.set_script(script)
	body.ingredient_type = ing
	body.ingredient_color = INGREDIENT_COLORS.get(ing, Color.WHITE)
	body.pickup_time = data.get("pickup_time", 1.0)
	if ing == "cake_batter":
		body.ingredient_mesh_scale = 0.75
	elif data.has("mesh_scale"):
		body.ingredient_mesh_scale = data.get("mesh_scale", 0.32)
	_add_progress_bar(body)
	return body


static func _build_mixing(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["mix"],
		TINY_TREATS_BASE + "countertop_straight_B_short.gltf",
		"mix",
		1.2
	)
	body.set_script(load("res://scripts/mixing_station.gd"))
	body.mix_time = data.get("mix_time", 4.0)
	_add_item_holder(body)
	_add_progress_bar(body)
	return body


static func _build_cooking(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["cook"],
		KAYKIT_BASE + "oven.gltf",
		"cook",
		OVEN_MESH_SCALE
	)
	body.set_script(load("res://scripts/cooking_station.gd"))
	body.cook_time = data.get("cook_time", 5.0)
	body.burn_time = data.get("burn_time", 999.0)
	_add_item_holder(body)
	_add_progress_bar(body)
	return body


static func _build_decoration(data: Dictionary) -> StaticBody3D:
	var decoration_type: String = data.get("decoration", "vanilla")
	var label_key := "decorate_" + decoration_type
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS.get(label_key, "Decoracion"),
		TINY_TREATS_BASE + "countertop_straight_B_short.gltf",
		"decorate"
	)
	body.set_script(load("res://scripts/decoration_station.gd"))
	body.decoration_type = decoration_type
	body.decoration_time = data.get("decoration_time", 3.0)
	_add_item_holder(body)
	_add_progress_bar(body)
	return body


static func _build_recipe_book(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["recipe_book"],
		TINY_TREATS_BASE + "countertop_straight_A_short.gltf",
		"recipe_book"
	)
	body.set_script(load("res://scripts/recipe_book_station.gd"))
	return body


static func _build_trash(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["trash"],
		TINY_TREATS_BASE + "tin_B_grey.gltf",
		"trash",
		1.65
	)
	body.set_script(load("res://scripts/trash_station.gd"))
	return body


static func _build_delivery(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["delivery"],
		TINY_TREATS_BASE + "display_case_long.gltf",
		"delivery"
	)
	body.set_script(load("res://scripts/delivery_window.gd"))
	body.delivery_time = data.get("delivery_time", 1.0)
	_add_item_holder(body)
	_add_progress_bar(body)
	return body
