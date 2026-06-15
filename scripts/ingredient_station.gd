extends Station
class_name IngredientStation

@export var ingredient_type: String = "tomato"
@export var ingredient_color: Color = Color.RED
@export var ingredient_size: Vector3 = Vector3(0.3, 0.3, 0.3)
@export var ingredient_mesh_scale: float = 0.32
@export var pickup_time: float = 1.0

var _pending_player: ChefPlayer = null
var _progress_bar: ProgressBar3D

const INGREDIENT_DISPLAY_NAMES := {
	"cake_batter": "Masa de pastel",
	"flour": "Harina",
	"egg": "Huevo",
	"sugar": "Azucar",
	"tomato": "Tomate",
	"lettuce": "Lechuga",
	"meat": "Carne",
	"bread": "Pan",
}

func _ready():
	can_hold_item = false
	super._ready()
	station_name = "Ingredientes: " + _get_ingredient_display_name()
	_progress_bar = $ProgressBar3D if has_node("ProgressBar3D") else null


func interact(player: ChefPlayer):
	super.interact(player)

	if player.has_item():
		_show_station_message("Manos ocupadas.", false)
		return

	if is_processing:
		_show_station_message("Tomando ingrediente...", false)
		return

	if pickup_time <= 0.0:
		var new_ingredient := create_ingredient()
		if new_ingredient:
			player.pickup_item(new_ingredient)
		return

	_pending_player = player
	is_processing = true
	process_timer = 0.0
	if _progress_bar:
		_progress_bar.set_progress(0.0, Color(0.4, 0.78, 0.35))


func _on_processing(_delta: float) -> void:
	if pickup_time <= 0.0:
		_finish_pickup()
		return

	if _progress_bar:
		_progress_bar.set_progress(process_timer / pickup_time, Color(0.4, 0.78, 0.35))

	if process_timer >= pickup_time:
		_finish_pickup()


func _finish_pickup() -> void:
	is_processing = false
	process_timer = 0.0

	if _progress_bar:
		_progress_bar.show_complete_check(true)
		var tween := create_tween()
		tween.tween_interval(0.35)
		tween.tween_callback(func():
			if _progress_bar:
				_progress_bar.show_bar(false)
		)

	if _pending_player == null or not is_instance_valid(_pending_player):
		_pending_player = null
		return

	if _pending_player.has_item():
		_show_station_message("No puedes cargar otro ingrediente.", false)
		_pending_player = null
		return

	var new_ingredient := create_ingredient()
	if new_ingredient:
		_pending_player.pickup_item(new_ingredient)
		_show_station_message("%s listo." % _get_ingredient_display_name(), true)
	_pending_player = null


func create_ingredient() -> Node3D:
	var ingredient := Node3D.new()
	ingredient.name = ingredient_type

	ItemVisuals.apply_ingredient_visual(ingredient, ingredient_type, "raw", ingredient_mesh_scale)

	ingredient.set_meta("ingredient_type", ingredient_type)
	ingredient.set_meta("state", "raw")
	ingredient.set_meta("is_ingredient", true)
	ingredient.set_meta("display_name", _get_ingredient_display_name())

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


func _get_ingredient_display_name() -> String:
	return INGREDIENT_DISPLAY_NAMES.get(ingredient_type, ingredient_type.capitalize())


func _show_station_message(text: String, success: bool) -> void:
	var hud := get_tree().get_first_node_in_group("game_hud") as GameHUD
	if hud:
		hud.show_delivery_feedback(text, success)
