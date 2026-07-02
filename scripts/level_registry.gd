extends Node

## Fuente unica de verdad de los niveles: metadatos (nombre, categoria,
## desbloqueo), configuracion de ordenes (recetas, ritmo, puntuacion) y
## configuracion de eventos caoticos.
##
## Agregar un nivel = 1 entrada aqui + 1 funcion de layout en level_layouts.gd.
## Las recetas se referencian por id del RecipeCatalog (no se duplican).
## unlock_after: 0 = siempre desbloqueado, N = requiere >= 1 estrella en nivel N


func get_categories() -> Array[Dictionary]:
	return [
		{"id": "intro",    "label": "Intro",       "color": Color(0.26, 0.48, 0.70)},
		{"id": "tutorial", "label": "Pasteleria",  "color": Color(0.28, 0.58, 0.32)},
		{"id": "coop",     "label": "Cooperativo", "color": Color(0.54, 0.24, 0.68)},
		{"id": "desafios", "label": "Desafios",    "color": Color(0.68, 0.18, 0.18)},
	]


func get_levels() -> Array[Dictionary]:
	return [
		{
			"id": 1, "name": "Introduccion", "category": "intro", "unlock_after": 0,
			"orders": {
				"recipes": [{"id": "baked", "points": 100, "time": 60.0}],
				"max": 1, "interval": 35.0, "initial": 1, "base_prep": 15.0,
				"penalty": 0, "speed_bonus": false,
			},
		},
		{
			"id": 2, "name": "Cadena de receta", "category": "tutorial", "unlock_after": 1,
			"orders": {
				"recipes": [{"id": "vanilla", "points": 160, "time": 90.0}],
				"max": 1, "interval": 35.0, "initial": 1, "base_prep": 15.0,
				"penalty": 0, "speed_bonus": false,
			},
		},
		{
			"id": 3, "name": "Presion de tiempo", "category": "tutorial", "unlock_after": 2,
			"orders": {
				"recipes": [
					{"id": "simple", "points": 80, "time": 60.0},
					{"id": "chocolate", "points": 150, "time": 90.0},
					{"id": "strawberry", "points": 150, "time": 90.0},
				],
				"max": 3, "interval": 25.0, "initial": 2, "base_prep": 15.0,
				"penalty": 75, "speed_bonus": true,
			},
		},
		{
			"id": 4, "name": "Cola de acciones", "category": "tutorial", "unlock_after": 3,
			"orders": {
				"recipes": [
					{"id": "chocolate", "points": 180, "time": 100.0},
					{"id": "strawberry", "points": 180, "time": 100.0},
				],
				"max": 2, "interval": 30.0, "initial": 2, "base_prep": 15.0,
				"penalty": 75, "speed_bonus": true,
			},
		},
		{
			"id": 5, "name": "Cooperativo", "category": "coop", "unlock_after": 4,
			"orders": {
				"recipes": [
					{"id": "simple", "points": 80, "time": 70.0},
					{"id": "chocolate", "points": 150, "time": 100.0},
					{"id": "strawberry", "points": 150, "time": 100.0},
				],
				"max": 3, "interval": 22.0, "initial": 2, "base_prep": 15.0,
				"penalty": 75, "speed_bonus": true,
			},
		},
		{
			"id": 6, "name": "Pasteleria de barrio", "category": "desafios", "unlock_after": 5,
			"orders": {
				"recipes": [
					{"id": "vanilla", "points": 120, "time": 90.0},
					{"id": "chocolate", "points": 130, "time": 90.0},
					{"id": "strawberry", "points": 130, "time": 90.0},
				],
				"max": 3, "interval": 20.0, "initial": 2, "base_prep": 0.0,
				"penalty": 75, "speed_bonus": true,
			},
		},
		{
			"id": 7, "name": "Turno de noche", "category": "desafios", "unlock_after": 6,
			"orders": {
				"recipes": [
					{"id": "vanilla", "points": 140, "time": 80.0},
					{"id": "chocolate", "points": 150, "time": 80.0},
					{"id": "strawberry", "points": 150, "time": 80.0},
				],
				"max": 3, "interval": 16.0, "initial": 2, "base_prep": 0.0,
				"penalty": 75, "speed_bonus": true,
			},
		},
		{
			"id": 8, "name": "Servicio caotico", "category": "desafios", "unlock_after": 7,
			"orders": {
				"recipes": [
					{"id": "vanilla", "points": 140, "time": 85.0},
					{"id": "chocolate", "points": 150, "time": 85.0},
					{"id": "strawberry", "points": 150, "time": 85.0},
				],
				"max": 3, "interval": 18.0, "initial": 2, "base_prep": 0.0,
				"penalty": 75, "speed_bonus": true,
			},
			"events": {
				"enabled": true,
				"first_delay": 20.0,
				"min_interval": 22.0,
				"max_interval": 34.0,
				"max_concurrent": 2,
				"pool": [
					"oven_overheat", "cream_spill", "decoration_change",
					"mixer_breakdown", "rush_order",
				],
			},
		},
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


## Configuracion de ordenes del nivel (recetas, ritmo, penalizacion). Si el
## nivel no existe, devuelve la del nivel 1 como fallback seguro.
func get_orders_config(level_id: int) -> Dictionary:
	var entry := get_level(level_id)
	if entry.has("orders"):
		return entry["orders"]
	return get_level(1).get("orders", {})


## Lista de ids de receta usadas por el nivel (para el recetario del HUD).
func get_level_recipe_ids(level_id: int) -> Array:
	var ids: Array = []
	var cfg := get_orders_config(level_id)
	for r: Dictionary in cfg.get("recipes", []):
		var id: String = r.get("id", "")
		if not id.is_empty() and not ids.has(id):
			ids.append(id)
	return ids


## Configuracion de eventos caoticos, o diccionario vacio si el nivel no los usa.
func get_events_config(level_id: int) -> Dictionary:
	var entry := get_level(level_id)
	return entry.get("events", {})
