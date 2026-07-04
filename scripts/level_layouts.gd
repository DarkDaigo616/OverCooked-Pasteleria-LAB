extends RefCounted
class_name LevelLayouts

## Nivel 1: introduccion. Nivel 2: cadena completa. Nivel 3: presion de tiempo con multiples pedidos.


static func get_level_count() -> int:
	return 9


static func get_layout(level_id: int) -> Dictionary:
	match level_id:
		2:
			return _recipe_chain_layout()
		3:
			return _pressure_layout()
		4:
			return _action_queue_layout()
		5:
			return _coop_layout()
		6:
			return _barrio_layout()
		7:
			return _turno_noche_layout()
		8:
			return _chaos_layout()
		9:
			return _wedding_layout()
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


static func _coop_layout() -> Dictionary:
	return {
		"name": "Cooperativo",
		"spawn": Vector3(-6.0, 1.0, 7.0),
		"spawn_p2": Vector3(6.0, 1.0, 7.0),
		"coop_mode": true,
		"queue_mode": true,
		"stations": [
			# Ingredientes — izquierda (territorio P1)
			{"type": "ingredient", "ingredient": "flour", "pos": Vector3(-10.5, 0.5, -6.0), "pickup_time": 0.7, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg",   "pos": Vector3(-10.5, 0.5, -1.0), "pickup_time": 0.7, "mesh_scale": 0.78},
			# Mezcla — centro-izquierda
			{"type": "mix", "pos": Vector3(-4.0, 0.5, -6.0), "mix_time": 3.5},
			# Dos hornos — centro (evitar cuello de botella)
			{"type": "cook", "pos": Vector3(2.5, 0.5, -7.5), "cook_time": 5.0, "burn_time": 15.0},
			{"type": "cook", "pos": Vector3(2.5, 0.5, -2.5), "cook_time": 5.0, "burn_time": 15.0},
			# Decoraciones — derecha (territorio P2)
			{"type": "decorate", "decoration": "chocolate",  "pos": Vector3(9.5, 0.5, -6.0), "decoration_time": 2.8},
			{"type": "decorate", "decoration": "strawberry", "pos": Vector3(9.5, 0.5, -0.5), "decoration_time": 2.8},
			# Sur — entrega (ambos), basura, recetario
			{"type": "delivery",    "pos": Vector3(3.0,  0.5, 7.5), "delivery_time": 0.8},
			{"type": "delivery",    "pos": Vector3(-3.0, 0.5, 7.5), "delivery_time": 0.8},
			{"type": "trash",       "pos": Vector3(-8.0, 0.5, 7.5)},
			{"type": "recipe_book", "pos": Vector3(8.0,  0.5, 7.5)},
		],
	}


static func _barrio_layout() -> Dictionary:
	return {
		"name": "Pasteleria de barrio",
		"game_mode": "real",
		"duration": 180.0,
		"star_thresholds": [3, 5, 7],
		"no_burn_for_3_stars": true,
		"coop_mode": true,
		"queue_mode": true,
		"spawn": Vector3(-4.0, 1.0, 8.0),
		"spawn_p2": Vector3(4.0, 1.0, 8.0),
		"stations": [
			# Ingredientes — izquierda
			{"type": "ingredient", "ingredient": "flour", "pos": Vector3(-11.0, 0.5, -7.5), "pickup_time": 0.7, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg",   "pos": Vector3(-11.0, 0.5, -1.5), "pickup_time": 0.7, "mesh_scale": 0.78},
			# Batidora — centro-izquierda
			{"type": "mix", "pos": Vector3(-4.5, 0.5, -7.5), "mix_time": 3.0},
			# Dos hornos — burn_time 12s genera tension para la 3a estrella
			{"type": "cook", "pos": Vector3(2.5, 0.5, -7.5), "cook_time": 5.0, "burn_time": 12.0},
			{"type": "cook", "pos": Vector3(2.5, 0.5, -2.0), "cook_time": 5.0, "burn_time": 12.0},
			# Tres decoraciones — una por receta
			{"type": "decorate", "decoration": "vanilla",    "pos": Vector3(10.0, 0.5, -7.5), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "chocolate",  "pos": Vector3(10.0, 0.5, -3.0), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "strawberry", "pos": Vector3(10.0, 0.5,  1.5), "decoration_time": 2.5},
			# Sur — entrega, basura, recetario
			{"type": "delivery",    "pos": Vector3(2.0,  0.5, 7.5), "delivery_time": 0.8},
			{"type": "trash",       "pos": Vector3(-5.0, 0.5, 7.5)},
			{"type": "recipe_book", "pos": Vector3(8.0,  0.5, 7.5)},
		],
	}


static func _turno_noche_layout() -> Dictionary:
	# Restriccion: 1 sola batidora (cuello de botella), 2 hornos, 3 decoradoras
	# Objetivo: mantener la batidora siempre activa y gestionar la cadena de produccion
	# Contexto: pasteleria grande en turno de noche — el equipo sobra, solo la batidora limita
	return {
		"name": "Turno de Noche",
		"game_mode": "real",
		"duration": 240.0,
		"star_thresholds": [4, 7, 10],
		"no_burn_for_3_stars": true,
		"coop_mode": true,
		"queue_mode": true,
		"spawn": Vector3(-4.0, 1.0, 5.0),
		"spawn_p2": Vector3(4.0, 1.0, 5.0),
		"stations": [
			# Ingredientes — izquierda (los dos que necesita la batidora)
			{"type": "ingredient", "ingredient": "flour", "pos": Vector3(-11.0, 0.5, -7.0), "pickup_time": 0.6, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg",   "pos": Vector3(-11.0, 0.5, -2.0), "pickup_time": 0.6, "mesh_scale": 0.78},
			# Batidora — centro-izquierda: EL CUELLO DE BOTELLA
			{"type": "mix", "pos": Vector3(-4.0, 0.5, -7.0), "mix_time": 3.0},
			# Dos hornos — para que no sean el problema
			{"type": "cook", "pos": Vector3(2.5, 0.5, -7.5), "cook_time": 5.0, "burn_time": 11.0},
			{"type": "cook", "pos": Vector3(2.5, 0.5, -2.0), "cook_time": 5.0, "burn_time": 11.0},
			# Tres decoradoras — una por cada tipo de pastel
			{"type": "decorate", "decoration": "vanilla",    "pos": Vector3(10.0, 0.5, -7.0), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "chocolate",  "pos": Vector3(10.0, 0.5, -2.5), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "strawberry", "pos": Vector3(10.0, 0.5,  2.5), "decoration_time": 2.5},
			# Frente — dos ventanas de entrega para no perder tiempo esperando
			{"type": "delivery",    "pos": Vector3(-2.5, 0.5, 7.5), "delivery_time": 0.8},
			{"type": "delivery",    "pos": Vector3( 4.0, 0.5, 7.5), "delivery_time": 0.8},
			{"type": "trash",       "pos": Vector3(-8.0, 0.5, 7.5)},
			{"type": "recipe_book", "pos": Vector3( 9.5, 0.5, 7.5)},
		],
	}


static func _chaos_layout() -> Dictionary:
	# Etapa 9: nivel que estrena los eventos caoticos (ver LevelRegistry.events).
	# Dos batidoras a proposito: asi "batidora descompuesta" fuerza a compartir la
	# otra (una decision de coordinacion) en vez de bloquear la produccion.
	return {
		"name": "Servicio caotico",
		"game_mode": "real",
		"duration": 240.0,
		"star_thresholds": [4, 7, 10],
		"no_burn_for_3_stars": true,
		"coop_mode": true,
		"queue_mode": true,
		"spawn": Vector3(-4.0, 1.0, 6.0),
		"spawn_p2": Vector3(4.0, 1.0, 6.0),
		"stations": [
			# Ingredientes — izquierda
			{"type": "ingredient", "ingredient": "flour", "pos": Vector3(-11.0, 0.5, -7.5), "pickup_time": 0.6, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg",   "pos": Vector3(-11.0, 0.5, -2.5), "pickup_time": 0.6, "mesh_scale": 0.78},
			# Dos batidoras
			{"type": "mix", "pos": Vector3(-4.5, 0.5, -7.5), "mix_time": 3.0},
			{"type": "mix", "pos": Vector3(-4.5, 0.5, -2.5), "mix_time": 3.0},
			# Dos hornos
			{"type": "cook", "pos": Vector3(2.5, 0.5, -7.5), "cook_time": 5.0, "burn_time": 12.0},
			{"type": "cook", "pos": Vector3(2.5, 0.5, -2.5), "cook_time": 5.0, "burn_time": 12.0},
			# Tres decoradoras — una por tipo de pastel
			{"type": "decorate", "decoration": "vanilla",    "pos": Vector3(10.0, 0.5, -7.5), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "chocolate",  "pos": Vector3(10.0, 0.5, -3.0), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "strawberry", "pos": Vector3(10.0, 0.5,  1.5), "decoration_time": 2.5},
			# Frente — dos entregas, basura, recetario
			{"type": "delivery",    "pos": Vector3(-2.5, 0.5, 7.5), "delivery_time": 0.8},
			{"type": "delivery",    "pos": Vector3( 4.0, 0.5, 7.5), "delivery_time": 0.8},
			{"type": "trash",       "pos": Vector3(-8.0, 0.5, 7.5)},
			{"type": "recipe_book", "pos": Vector3( 9.5, 0.5, 7.5)},
		],
	}


static func _wedding_layout() -> Dictionary:
	# Etapa 10: cooperacion obligatoria (ver fases en LevelRegistry).
	# - Masa gigante: item pesado -> 2 chefs para cargarla (al horno y a entrega).
	# - Decoracion Boda: sync (2 chefs cerca o se pausa) + rescuable (cancelar
	#   a tiempo un acabado equivocado) + cadena larga (entra pastel de vainilla).
	return {
		"name": "Banquete de boda",
		"game_mode": "real",
		"duration": 300.0,
		"star_thresholds": [3, 5, 7],
		"no_burn_for_3_stars": true,
		"coop_mode": true,
		"queue_mode": true,
		"spawn": Vector3(-4.0, 1.0, 6.0),
		"spawn_p2": Vector3(4.0, 1.0, 6.0),
		"stations": [
			# Ingredientes — izquierda. La masa gigante es PESADA (2 chefs).
			{"type": "ingredient", "ingredient": "flour", "pos": Vector3(-11.0, 0.5, -7.5), "pickup_time": 0.6, "mesh_scale": 0.72},
			{"type": "ingredient", "ingredient": "egg",   "pos": Vector3(-11.0, 0.5, -2.5), "pickup_time": 0.6, "mesh_scale": 0.78},
			{"type": "ingredient", "ingredient": "giant_batter", "pos": Vector3(-11.0, 0.5, 2.5), "pickup_time": 0.8, "heavy": true},
			# Batidora (solo para la cadena de boda/fresa)
			{"type": "mix", "pos": Vector3(-4.5, 0.5, -7.5), "mix_time": 3.0},
			# Dos hornos
			{"type": "cook", "pos": Vector3(2.5, 0.5, -7.5), "cook_time": 5.0, "burn_time": 13.0},
			{"type": "cook", "pos": Vector3(2.5, 0.5, -2.5), "cook_time": 5.0, "burn_time": 13.0},
			# Decoradoras: vainilla (paso 1 de la boda), Boda (sync+rescate), fresa
			{"type": "decorate", "decoration": "vanilla",    "pos": Vector3(10.0, 0.5, -7.5), "decoration_time": 2.5},
			{"type": "decorate", "decoration": "wedding",    "pos": Vector3(10.0, 0.5, -2.5), "decoration_time": 4.5, "input_state": "decorated_vanilla", "sync": true, "rescuable": true},
			{"type": "decorate", "decoration": "strawberry", "pos": Vector3(10.0, 0.5,  2.5), "decoration_time": 2.5, "rescuable": true},
			# Frente — dos entregas, basura, recetario
			{"type": "delivery",    "pos": Vector3(-2.5, 0.5, 7.5), "delivery_time": 0.8},
			{"type": "delivery",    "pos": Vector3( 4.0, 0.5, 7.5), "delivery_time": 0.8},
			{"type": "trash",       "pos": Vector3(-8.0, 0.5, 7.5)},
			{"type": "recipe_book", "pos": Vector3( 9.5, 0.5, 7.5)},
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
