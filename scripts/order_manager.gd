extends Node
class_name OrderManager

signal order_completed(recipe: Recipe, points: int)
signal order_failed(recipe: Recipe)
signal new_order(recipe: Recipe)
signal all_orders_updated(orders: Array)
signal order_penalty_applied(penalty: int)

@export var max_orders: int = 1
@export var order_spawn_interval: float = 20.0
@export var base_prep_time: float = 0.0

var active_orders: Array = []
var available_recipes: Array = []
var spawn_timer: float = 0.0
var orders_running: bool = true

# Configuracion del nivel (recetas, ritmo, penalizacion). Se lee del
# LevelRegistry en _ready. Antes esto era una escalera gigante de
# "if selected_level >= N" con las recetas duplicadas nivel por nivel.
var _config: Dictionary = {}


func _ready() -> void:
	add_to_group("order_manager")
	_config = LevelRegistry.get_orders_config(GameState.selected_level)
	_apply_config()
	create_recipes()
	var initial_count: int = _config.get("initial", 1)
	for i in range(initial_count):
		spawn_new_order()


func _apply_config() -> void:
	max_orders = _config.get("max", max_orders)
	order_spawn_interval = _config.get("interval", order_spawn_interval)
	base_prep_time = _config.get("base_prep", base_prep_time)


func stop_orders() -> void:
	orders_running = false


func _process(delta: float) -> void:
	if not orders_running:
		return

	for i in range(active_orders.size() - 1, -1, -1):
		var order: Dictionary = active_orders[i]
		order["time_remaining"] -= delta
		if order["time_remaining"] <= 0:
			fail_order(order)

	spawn_timer += delta
	if spawn_timer >= order_spawn_interval and active_orders.size() < max_orders:
		spawn_new_order()
		spawn_timer = 0.0


func create_recipes() -> void:
	available_recipes.clear()
	for r: Dictionary in _config.get("recipes", []):
		available_recipes.append(RecipeCatalog.make_recipe(
			r.get("id", ""),
			r.get("points", 100),
			r.get("time", 60.0)
		))


func spawn_new_order() -> void:
	if not orders_running or available_recipes.is_empty():
		return

	var recipe: Recipe = available_recipes[randi() % available_recipes.size()]
	var order := {
		"recipe": recipe,
		"time_remaining": recipe.preparation_time + base_prep_time,
		"id": Time.get_ticks_msec(),
	}
	active_orders.append(order)
	new_order.emit(recipe)
	all_orders_updated.emit(active_orders)


func check_delivery(ingredients: Array) -> Dictionary:
	var normalized := Recipe.normalize_list(ingredients)

	if active_orders.is_empty():
		return {
			"success": false,
			"points": 0,
			"reason": "No hay ordenes activas.",
		}

	for order in active_orders:
		var recipe: Recipe = order["recipe"]
		var result: Dictionary = recipe.get_match_result(normalized)
		if result.success:
			var bonus := _calculate_speed_bonus(order, recipe)
			order["_awarded_points"] = recipe.points + bonus
			complete_order(order)
			return {
				"success": true,
				"points": recipe.points + bonus,
				"bonus": bonus,
				"reason": "",
				"recipe_name": recipe.recipe_name
			}

	var best_reason := "No coincide con ninguna orden activa."
	for order in active_orders:
		var recipe: Recipe = order["recipe"]
		var result: Dictionary = recipe.get_match_result(normalized)
		if not result.reason.is_empty():
			best_reason = "%s — %s" % [recipe.recipe_name, result.reason]
			break

	return {"success": false, "points": 0, "bonus": 0, "reason": best_reason}


func _calculate_speed_bonus(order: Dictionary, recipe: Recipe) -> int:
	if not _config.get("speed_bonus", false):
		return 0
	var time_remaining: float = order.get("time_remaining", 0.0)
	if recipe.preparation_time <= 0:
		return 0
	if time_remaining > recipe.preparation_time * 0.5:
		return int(recipe.points * 0.5)
	return 0


func complete_order(order: Dictionary) -> void:
	active_orders.erase(order)
	var pts: int = order.get("_awarded_points", order["recipe"].points)
	order_completed.emit(order["recipe"], pts)
	all_orders_updated.emit(active_orders)


func fail_order(order: Dictionary) -> void:
	active_orders.erase(order)
	order_failed.emit(order["recipe"])
	var penalty: int = _config.get("penalty", 0)
	if penalty > 0:
		order_penalty_applied.emit(penalty)
	all_orders_updated.emit(active_orders)


func get_active_orders() -> Array:
	return active_orders


# ---------------------------------------------------------------------------
# API para el sistema de eventos (Etapa 9). Los eventos no manipulan las
# ordenes directamente: piden estos cambios de alto nivel.
# ---------------------------------------------------------------------------

## Inyecta un pedido urgente (evento "pedido inesperado"): toma una receta al
## azar del nivel, le sube los puntos y le pone poco tiempo. Puede superar el
## limite normal de ordenes activas. Devuelve el order para seguir su estado.
func add_random_special_order(points_multiplier: float, time: float) -> Dictionary:
	if available_recipes.is_empty():
		return {}
	var base: Recipe = available_recipes[randi() % available_recipes.size()]
	var recipe := Recipe.new(
		"★ " + base.recipe_name,
		base.required_ingredients.duplicate(true),
		int(base.points * points_multiplier),
		time
	)
	var order := {
		"recipe": recipe,
		"time_remaining": time,
		"id": Time.get_ticks_msec(),
		"urgent": true,
	}
	active_orders.append(order)
	new_order.emit(recipe)
	all_orders_updated.emit(active_orders)
	return order


func is_order_active(order: Dictionary) -> bool:
	return active_orders.has(order)


## True si tiene sentido lanzar el evento de cambio de decoracion (hay al menos
## una orden decorada activa y otra decoracion posible a la que cambiar).
func can_change_decoration() -> bool:
	if _decorated_recipes().size() < 2:
		return false
	for order: Dictionary in active_orders:
		if _is_decorated_recipe(order["recipe"]):
			return true
	return false


## Cambia la decoracion pedida de una orden activa al azar (evento "el cliente
## cambia la decoracion"). Devuelve {old, new, order} o {} si no hubo cambio.
func change_random_order_recipe() -> Dictionary:
	var decorated := _decorated_recipes()
	if decorated.size() < 2:
		return {}

	var candidates: Array = []
	for order: Dictionary in active_orders:
		if _is_decorated_recipe(order["recipe"]):
			candidates.append(order)
	if candidates.is_empty():
		return {}

	var order: Dictionary = candidates[randi() % candidates.size()]
	var old_recipe: Recipe = order["recipe"]
	var options: Array = []
	for r: Recipe in decorated:
		if r.recipe_name != old_recipe.recipe_name:
			options.append(r)
	if options.is_empty():
		return {}

	var new_recipe: Recipe = options[randi() % options.size()]
	order["recipe"] = new_recipe
	order["changed"] = true
	order.erase("_awarded_points")
	all_orders_updated.emit(active_orders)
	return {"old": old_recipe.recipe_name, "new": new_recipe.recipe_name, "order": order}


func _decorated_recipes() -> Array:
	var out: Array = []
	for r: Recipe in available_recipes:
		if _is_decorated_recipe(r):
			out.append(r)
	return out


func _is_decorated_recipe(recipe: Recipe) -> bool:
	for req: Dictionary in recipe.required_ingredients:
		if str(req.get("state", "")).begins_with("decorated_"):
			return true
	return false
