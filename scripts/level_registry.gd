extends Node


func get_categories() -> Array[Dictionary]:
	return [
		{"id": "intro",    "label": "Intro",       "color": Color(0.26, 0.48, 0.70)},
		{"id": "tutorial", "label": "Pasteleria",  "color": Color(0.28, 0.58, 0.32)},
		{"id": "coop",     "label": "Cooperativo", "color": Color(0.54, 0.24, 0.68)},
		{"id": "desafios", "label": "Desafios",    "color": Color(0.68, 0.18, 0.18)},
	]


# Agregar un nivel = una entrada aqui + una funcion en level_layouts.gd
# unlock_after: 0 = siempre desbloqueado, N = requiere >= 1 estrella en nivel N
func get_levels() -> Array[Dictionary]:
	return [
		{"id": 1, "name": "Introduccion",        "category": "intro",    "unlock_after": 0},
		{"id": 2, "name": "Cadena de receta",    "category": "tutorial", "unlock_after": 1},
		{"id": 3, "name": "Presion de tiempo",   "category": "tutorial", "unlock_after": 2},
		{"id": 4, "name": "Cola de acciones",    "category": "tutorial", "unlock_after": 3},
		{"id": 5, "name": "Cooperativo",         "category": "coop",     "unlock_after": 4},
		{"id": 6, "name": "Pasteleria de barrio","category": "desafios", "unlock_after": 5},
		{"id": 7, "name": "Turno de noche",      "category": "desafios", "unlock_after": 6},
	]


func get_level(level_id: int) -> Dictionary:
	for lvl: Dictionary in get_levels():
		if lvl["id"] == level_id:
			return lvl
	return {}


func get_levels_in_category(cat_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lvl: Dictionary in get_levels():
		if lvl["category"] == cat_id:
			result.append(lvl)
	return result
