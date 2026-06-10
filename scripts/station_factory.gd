extends RefCounted
class_name StationFactory

const BASE := "res://assets/{models,textures,sounds}/KayKit_Restaurant_Bits_1.0_FREE/Assets/obj/"
const COUNTER_SHAPE_SIZE := Vector3(1.95, 1.38, 1.88)
const MESH_SCALE := 1.2

const INGREDIENT_MESHES := {
	"tomato": BASE + "crate_tomatoes.obj",
	"lettuce": BASE + "crate_lettuce.obj",
	"meat": BASE + "crate_steak.obj",
	"bread": BASE + "crate_buns.obj",
}

const INGREDIENT_COLORS := {
	"tomato": Color(0.8, 0.2, 0.2),
	"lettuce": Color(0.2, 0.8, 0.2),
	"meat": Color(0.6, 0.3, 0.2),
	"bread": Color(0.8, 0.7, 0.4),
}

const LABELS := {
	"tomato": "TOMATES",
	"lettuce": "LECHUGA",
	"meat": "CARNE",
	"bread": "PAN",
	"chop": "CORTAR",
	"cook": "COCINAR",
	"plate": "PLATOS",
	"plating": "EMPLATADO",
	"delivery": "ENTREGAR",
	"trash": "BASURERO",
}


static func build_station(data: Dictionary) -> StaticBody3D:
	var stype: String = data.get("type", "")
	match stype:
		"ingredient":
			return _build_ingredient(data)
		"chop":
			return _build_chopping(data)
		"cook":
			return _build_cooking(data)
		"plate":
			return _build_plate(data)
		"plating", "assembly":
			return _build_plating(data)
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

	var label := Label3D.new()
	label.text = label_text
	body.add_child(label)

	StationVisuals.apply_to_station(body, label_text, station_type)
	return body


static func _add_item_holder(parent: StaticBody3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "ItemHolder"
	holder.position = Vector3(0, 0.65, 0)
	parent.add_child(holder)
	return holder


static func _add_progress_bar(parent: Node3D) -> ProgressBar3D:
	var bar := ProgressBar3D.new()
	bar.name = "ProgressBar3D"
	bar.y_offset = 1.75
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
	return body


static func _build_chopping(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["chop"],
		BASE + "cuttingboard.obj",
		"chop"
	)
	body.set_script(load("res://scripts/chopping_station.gd"))
	_add_item_holder(body)
	_add_progress_bar(body)
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


static func _build_plate(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["plate"],
		BASE + "dishrack_plates.obj",
		"plate"
	)
	body.set_script(load("res://scripts/plate_station.gd"))
	return body


static func _build_plating(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["plating"],
		BASE + "kitchentable_A_large.obj",
		"plating"
	)
	body.set_script(load("res://scripts/plating_station.gd"))
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


static func _build_trash(data: Dictionary) -> StaticBody3D:
	var body := _base_station(
		data.get("pos", Vector3.ZERO),
		LABELS["trash"],
		BASE + "food_ingredient_burger_trash.obj",
		"trash"
	)
	body.set_script(load("res://scripts/trash_station.gd"))
	return body
