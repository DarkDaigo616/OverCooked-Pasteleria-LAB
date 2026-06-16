extends RefCounted
class_name BakeryPropBuilder

const Materials = preload("res://materials/bakery_materials.gd")


static func add_flour_sack(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "FlourSack"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	_add_box(root, "Sack", Vector3(0.72, 0.72, 0.42), Vector3(0, 0.36, 0), Materials.FLOUR)
	_add_box(root, "Label", Vector3(0.42, 0.06, 0.22), Vector3(0, 0.5, -0.23), Materials.PASTEL_BLUE)
	return root


static func add_bread_basket(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "BreadBasket"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	_add_box(root, "Basket", Vector3(1.0, 0.18, 0.62), Vector3(0, 0.12, 0), Materials.WOOD)
	for i in range(3):
		var bread := _add_cylinder(root, "Bread%d" % i, 0.16, 0.46, Vector3(-0.28 + i * 0.28, 0.34, 0), Color(0.87, 0.58, 0.24))
		bread.rotation_degrees = Vector3(90, 0, 10 - i * 10)
	return root


static func add_cupcake_stand(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "CupcakeStand"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	_add_cylinder(root, "Stand", 0.48, 0.08, Vector3(0, 0.22, 0), Materials.CREAM_LIGHT)
	_add_cylinder(root, "Stem", 0.08, 0.28, Vector3(0, 0.4, 0), Materials.WOOD)
	_add_cylinder(root, "Top", 0.36, 0.07, Vector3(0, 0.58, 0), Materials.CREAM_LIGHT)
	var colors := [Materials.PASTEL_PINK, Materials.PASTEL_BLUE, Materials.PASTEL_YELLOW]
	for i in range(3):
		var cupcake := _add_cylinder(root, "Cupcake%d" % i, 0.11, 0.14, Vector3(-0.22 + i * 0.22, 0.72, 0), Color(0.58, 0.34, 0.18))
		_add_sphere(root, "Frosting%d" % i, 0.11, Vector3(cupcake.position.x, 0.83, 0), colors[i], Vector3(1, 0.65, 1))
	return root


static func add_tray(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "PastryTray"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	_add_box(root, "Tray", Vector3(1.05, 0.06, 0.56), Vector3(0, 0.16, 0), Color(0.78, 0.74, 0.65))
	_add_cylinder(root, "MacaronA", 0.13, 0.08, Vector3(-0.25, 0.25, 0), Materials.PASTEL_PINK)
	_add_cylinder(root, "MacaronB", 0.13, 0.08, Vector3(0.05, 0.25, 0), Materials.PASTEL_GREEN)
	_add_cylinder(root, "MacaronC", 0.13, 0.08, Vector3(0.35, 0.25, 0), Materials.PASTEL_YELLOW)
	return root


static func add_potted_plant(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "PottedPlant"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	_add_cylinder(root, "Pot", 0.24, 0.32, Vector3(0, 0.2, 0), Color(0.62, 0.32, 0.18))
	_add_sphere(root, "LeafA", 0.2, Vector3(-0.12, 0.48, 0), Materials.LEAF, Vector3(0.8, 1.25, 0.65))
	_add_sphere(root, "LeafB", 0.2, Vector3(0.14, 0.52, 0.04), Materials.LEAF.lightened(0.12), Vector3(0.8, 1.3, 0.65))
	return root


static func add_blackboard(parent: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "BakeryBlackboard"
	root.position = pos
	root.rotation_degrees.y = rot_y
	parent.add_child(root)
	_add_box(root, "Frame", Vector3(1.42, 1.0, 0.08), Vector3(0, 0.82, 0), Materials.WOOD_DARK)
	_add_box(root, "Board", Vector3(1.16, 0.74, 0.1), Vector3(0, 0.82, -0.02), Materials.BLACKBOARD)
	_add_box(root, "ChalkLineA", Vector3(0.72, 0.035, 0.11), Vector3(0, 0.92, -0.09), Color(0.92, 0.88, 0.76))
	_add_box(root, "ChalkLineB", Vector3(0.52, 0.03, 0.11), Vector3(-0.1, 0.74, -0.09), Color(0.92, 0.88, 0.76))
	return root


static func _add_box(parent: Node3D, name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = Materials.make(color)
	parent.add_child(mi)
	return mi


static func _add_cylinder(parent: Node3D, name: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = Materials.make(color)
	parent.add_child(mi)
	return mi


static func _add_sphere(parent: Node3D, name: String, radius: float, pos: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.6
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scale
	mi.material_override = Materials.make(color)
	parent.add_child(mi)
	return mi
