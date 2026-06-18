extends RefCounted
class_name LevelLayouts

## Nivel 1: introduccion. Nivel 2: cadena completa. Nivel 3: presion de tiempo con multiples pedidos.


static func get_level_count() -> int:
	return 4


static func get_layout(level_id: int) -> Dictionary:
	match level_id:
		2:
			return _recipe_chain_layout()
		3:
			return _pressure_layout()
		4:
			return _action_queue_layout()
		_:
			return _intro_layout()


static func _intro_layout() -> Dictionary:
	return {
		"name": "Introduccion",
		"spawn": Vector3(0.0, 1.0, 5.0),
		"stations": [
			{"type": "ingredient", "ingredient": "cake_batter", "pos": Vector3(-8, 0.5, 0), "pickup_time": 0.5},
			{"type": "cook", "pos": Vector3(0, 0.5, -5), "cook_time": 4.0, "burn_time": 999.0},
			{"type": "delivery", "pos": Vector3(8, 0.5, 0), "delivery_time": 0.5},
		],
	}


static func _recipe_chain_layout() -> Dictionary:
	return {
		"name": "Cadena de receta",
		"spawn": Vector3(0.0, 1.0, 8.0),
		"stations": [
			{"type": "ingredient", "ingredient": "flour", "pos": Vector3(-10.5, 0.5, -5.4), "pickup_time": 1.0, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg", "pos": Vector3(-10.5, 0.5, -1.2), "pickup_time": 1.0, "mesh_scale": 0.78},
			{"type": "ingredient", "ingredient": "sugar", "pos": Vector3(-10.5, 0.5, 3.0), "pickup_time": 1.0, "mesh_scale": 0.68},
			{"type": "mix", "pos": Vector3(-3.5, 0.5, -5.4), "mix_time": 4.0},
			{"type": "cook", "pos": Vector3(3.5, 0.5, -5.4), "cook_time": 6.0, "burn_time": 5.0},
			{"type": "decorate", "decoration": "vanilla", "pos": Vector3(10.3, 0.5, -3.0), "decoration_time": 3.0},
			{"type": "decorate", "decoration": "chocolate", "pos": Vector3(10.3, 0.5, 1.6), "decoration_time": 3.0},
			{"type": "recipe_book", "pos": Vector3(-3.5, 0.5, 7.6)},
			{"type": "trash", "pos": Vector3(-7.0, 0.5, 7.6)},
			{"type": "delivery", "pos": Vector3(1.0, 0.5, 7.6), "delivery_time": 1.0},
		],
	}


static func _action_queue_layout() -> Dictionary:
	return {
		"name": "Cola de Acciones",
		"spawn": Vector3(0.0, 1.0, 8.0),
		"queue_mode": true,
		"stations": [
			# Ingredientes — izquierda
			{"type": "ingredient", "ingredient": "flour", "pos": Vector3(-10.0, 0.5, -7.0), "pickup_time": 0.8, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg",   "pos": Vector3(-10.0, 0.5, -1.5), "pickup_time": 0.8, "mesh_scale": 0.78},
			# Batidora — centro-izquierda
			{"type": "mix", "pos": Vector3(-3.5, 0.5, -7.0), "mix_time": 3.5},
			# Dos hornos — centro (crear decision: cual usar)
			{"type": "cook", "pos": Vector3(3.0, 0.5, -7.0), "cook_time": 5.0, "burn_time": 14.0},
			{"type": "cook", "pos": Vector3(3.0, 0.5, -1.5), "cook_time": 5.0, "burn_time": 14.0},
			# Decoraciones — derecha
			{"type": "decorate", "decoration": "chocolate",  "pos": Vector3(10.0, 0.5, -5.0), "decoration_time": 3.0},
			{"type": "decorate", "decoration": "strawberry", "pos": Vector3(10.0, 0.5,  1.0), "decoration_time": 3.0},
			# Sur — entrega, basura, recetario
			{"type": "delivery",    "pos": Vector3(1.0,  0.5, 7.5), "delivery_time": 0.8},
			{"type": "trash",       "pos": Vector3(-5.0, 0.5, 7.5)},
			{"type": "recipe_book", "pos": Vector3(7.0,  0.5, 7.5)},
		],
	}


static func _pressure_layout() -> Dictionary:
	return {
		"name": "Presion de Tiempo",
		"spawn": Vector3(0.0, 1.0, 6.5),
		"stations": [
			# Ingredientes: izquierda
			{"type": "ingredient", "ingredient": "flour",  "pos": Vector3(-10.5, 0.5, -7.5), "pickup_time": 0.8, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg",    "pos": Vector3(-10.5, 0.5, -2.5), "pickup_time": 0.8, "mesh_scale": 0.78},
			# Mezcla y horno: centro-norte
			{"type": "mix",  "pos": Vector3(-4.0, 0.5, -7.5), "mix_time": 3.5},
			{"type": "cook", "pos": Vector3(2.5,  0.5, -7.5), "cook_time": 5.0, "burn_time": 9.0},
			# Decoraciones: derecha
			{"type": "decorate", "decoration": "chocolate",  "pos": Vector3(10.0, 0.5, -5.0), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "strawberry", "pos": Vector3(10.0, 0.5,  1.0), "decoration_time": 2.5},
			# Sur: entrega, basura y recetario
			{"type": "delivery",    "pos": Vector3(0.5,  0.5, 7.5), "delivery_time": 0.8},
			{"type": "trash",       "pos": Vector3(-5.5, 0.5, 7.5)},
			{"type": "recipe_book", "pos": Vector3(6.0,  0.5, 7.5)},
		],
	}
