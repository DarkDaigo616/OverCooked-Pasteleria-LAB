extends Station
class_name PlateStation

@export var plate_color: Color = Color.WHITE
@export var plate_mesh_scale: float = 0.45


func _ready():
	super._ready()
	station_name = "Plate Station"
	can_hold_item = false


func interact(player: ChefPlayer):
	super.interact(player)

	if not player.has_item():
		var new_plate := create_plate()
		if new_plate:
			player.pickup_item(new_plate)


func create_plate() -> Node3D:
	var plate := Node3D.new()
	plate.name = "Plate"

	var mesh := load(ItemVisuals.plate_mesh_path()) as Mesh
	if mesh:
		var mi := ItemVisuals.set_mesh_on_first_mesh_instance(plate, mesh, plate_mesh_scale)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = plate_color
		mi.material_override = mat
	else:
		var mesh_instance := MeshInstance3D.new()
		var cylinder_mesh := CylinderMesh.new()
		cylinder_mesh.top_radius = 0.4
		cylinder_mesh.bottom_radius = 0.4
		cylinder_mesh.height = 0.05
		mesh_instance.mesh = cylinder_mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = plate_color
		mesh_instance.material_override = material
		plate.add_child(mesh_instance)

	plate.set_meta("is_plate", true)
	plate.set_meta("ingredients", [])

	var static_body := StaticBody3D.new()
	static_body.collision_layer = PhysicsLayers.ITEMS
	static_body.collision_mask = PhysicsLayers.MASK_ITEM
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 0.08
	collision.shape = shape
	static_body.add_child(collision)
	plate.add_child(static_body)

	return plate
