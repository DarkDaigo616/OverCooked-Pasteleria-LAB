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


func _ready() -> void:
	add_to_group("order_manager")
	create_recipes()
	var initial_count := 2 if GameState.selected_level >= 3 else 1
	for i in range(initial_count):
		spawn_new_order()


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

	if GameState.selected_level >= 4:
		max_orders = 2
		order_spawn_interval = 30.0
		available_recipes.append(Recipe.new(
			"Pastel de chocolate",
			[{"type": "cake", "state": "decorated_chocolate"}],
			180, 100.0
		))
		available_recipes.append(Recipe.new(
			"Pastel con fresa",
			[{"type": "cake", "state": "decorated_strawberry"}],
			180, 100.0
		))
		return

	if GameState.selected_level >= 3:
		max_orders = 3
		order_spawn_interval = 25.0

		var simple_cake := Recipe.new(
			"Pastel simple",
			[{"type": "cake", "state": "baked"}],
			80,
			60.0
		)
		var chocolate_cake := Recipe.new(
			"Pastel de chocolate",
			[{"type": "cake", "state": "decorated_chocolate"}],
			150,
			90.0
		)
		var strawberry_cake := Recipe.new(
			"Pastel con fresa",
			[{"type": "cake", "state": "decorated_strawberry"}],
			150,
			90.0
		)
		available_recipes.append(simple_cake)
		available_recipes.append(chocolate_cake)
		available_recipes.append(strawberry_cake)
		return

	if GameState.selected_level >= 2:
		var vanilla_cake := Recipe.new(
			"Pastel de vainilla",
			[{"type": "cake", "state": "decorated_vanilla"}],
			160,
			90.0
		)
		available_recipes.append(vanilla_cake)
		return

	var baked_cake := Recipe.new(
		"Pastel horneado",
		[{"type": "cake", "state": "baked"}],
		100,
		60.0
	)
	available_recipes.append(baked_cake)


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
	if GameState.selected_level < 3:
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
	if GameState.selected_level >= 3:
		order_penalty_applied.emit(75)
	all_orders_updated.emit(active_orders)


func get_active_orders() -> Array:
	return active_orders
