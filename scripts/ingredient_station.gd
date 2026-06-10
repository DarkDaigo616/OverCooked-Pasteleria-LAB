extends Station
class_name IngredientStation

@export var ingredient_type: String = "tomato"
@export var ingredient_color: Color = Color.RED
@export var ingredient_size: Vector3 = Vector3(0.3, 0.3, 0.3)
@export var ingredient_mesh_scale: float = 0.32


func _ready():
	super._ready()
	station_name = "Ingredientes: masa" if ingredient_type == "cake_batter" else "Ingredient Station: " + ingredient_type.capitalize()
	can_hold_item = false


func interact(player: ChefPlayer):
	super.interact(player)

	if not player.has_item():
		var new_ingredient := create_ingredient()
		if new_ingredient:
			player.pickup_item(new_ingredient)


func create_ingredient() -> Node3D:
	var ingredient := Node3D.new()
	ingredient.name = ingredient_type

	ItemVisuals.apply_ingredient_visual(ingredient, ingredient_type, "raw", ingredient_mesh_scale)

	ingredient.set_meta("ingredient_type", ingredient_type)
	ingredient.set_meta("state", "raw")
	ingredient.set_meta("is_ingredient", true)
	if ingredient_type == "cake_batter":
		ingredient.set_meta("display_name", "Masa de pastel")

	var static_body := StaticBody3D.new()
	static_body.collision_layer = PhysicsLayers.ITEMS
	static_body.collision_mask = PhysicsLayers.MASK_ITEM
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = maxf(ingredient_size.x, ingredient_size.y) * 0.45
	collision.shape = shape
	static_body.add_child(collision)
	ingredient.add_child(static_body)

	return ingredient
