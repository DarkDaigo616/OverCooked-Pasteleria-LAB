extends RefCounted
class_name LevelLayouts

## Nivel 1 conserva la introduccion. Nivel 2 abre la cadena completa de receta.


static func get_level_count() -> int:
	return 2


static func get_layout(level_id: int) -> Dictionary:
	match level_id:
		2:
			return _recipe_chain_layout()
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
