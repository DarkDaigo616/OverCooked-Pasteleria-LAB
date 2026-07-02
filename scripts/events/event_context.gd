extends RefCounted
class_name EventContext

## Fachada al mundo del juego para los eventos. En vez de que cada evento busque
## nodos por rutas fragiles, pide todo aqui: ordenes, estaciones, jugadores, HUD
## y un RNG compartido. Esto mantiene los eventos desacoplados de la escena.

var level: Node = null                 ## raiz del nivel (para instanciar hazards)
var order_manager: OrderManager = null
var hud: Node = null                   ## GameHUD
var stations_root: Node = null
var rng: RandomNumberGenerator = null


func _init(
	p_level: Node,
	p_order_manager: OrderManager,
	p_hud: Node,
	p_stations_root: Node,
	p_rng: RandomNumberGenerator = null
) -> void:
	level = p_level
	order_manager = p_order_manager
	hud = p_hud
	stations_root = p_stations_root
	if p_rng != null:
		rng = p_rng
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()


## Estaciones del nivel, opcionalmente filtradas por tipo ("cook", "mix",
## "decorate", "delivery", "ingredient", "trash", "recipe_book").
func get_stations(type_filter: String = "") -> Array:
	var out: Array = []
	if stations_root == null:
		return out
	for s in stations_root.get_children():
		if not is_instance_valid(s):
			continue
		if type_filter.is_empty() or str(s.get_meta("station_type", "")) == type_filter:
			out.append(s)
	return out


func get_ovens() -> Array:
	return get_stations("cook")


func get_mixers() -> Array:
	return get_stations("mix")


func get_players() -> Array:
	if level == null or level.get_tree() == null:
		return []
	return level.get_tree().get_nodes_in_group("player")


## Muestra el banner de anuncio del evento en el HUD.
func notify(banner_title: String, banner_description: String, banner_color: Color) -> void:
	if hud and hud.has_method("show_event_banner"):
		hud.call("show_event_banner", banner_title, banner_description, banner_color)
