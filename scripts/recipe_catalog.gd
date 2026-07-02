extends RefCounted
class_name RecipeCatalog

## Fuente unica de verdad de las recetas del juego.
## Cada receta se define UNA sola vez aqui (nombre, ingredientes requeridos,
## imagen del recetario). Los niveles solo referencian el id y ajustan
## puntos/tiempo. Antes esto estaba duplicado en order_manager.gd (una vez por
## nivel) y en game_hud.gd (RECIPE_BOOK_DATA), lo que obligaba a editar varios
## archivos por cada cambio. Ahora se agrega/edita en un solo lugar.

const BOOK_BASE := "res://assets/ui/"

const RECIPES := {
	"baked": {
		"name": "Pastel horneado",
		"required": [{"type": "cake", "state": "baked"}],
		"book_image": "pastel_horneado.png",
	},
	"simple": {
		"name": "Pastel simple",
		"required": [{"type": "cake", "state": "baked"}],
		"book_image": "pastel_simple.png",
	},
	"vanilla": {
		"name": "Pastel de vainilla",
		"required": [{"type": "cake", "state": "decorated_vanilla"}],
		"book_image": "pastel_vainilla.png",
	},
	"chocolate": {
		"name": "Pastel de chocolate",
		"required": [{"type": "cake", "state": "decorated_chocolate"}],
		"book_image": "pastel_chocolate.png",
	},
	"strawberry": {
		"name": "Pastel con fresa",
		"required": [{"type": "cake", "state": "decorated_strawberry"}],
		"book_image": "pastel_fresa.png",
	},
}


static func has_recipe(id: String) -> bool:
	return RECIPES.has(id)


static func get_name(id: String) -> String:
	var entry: Dictionary = RECIPES.get(id, {})
	return entry.get("name", id.capitalize())


static func book_image_path(id: String) -> String:
	var entry: Dictionary = RECIPES.get(id, {})
	var img: String = entry.get("book_image", "")
	if img.is_empty():
		return ""
	return BOOK_BASE + img


## Construye una instancia de Recipe a partir del id del catalogo, con los
## puntos y el tiempo que fije el nivel.
static func make_recipe(id: String, points: int, time: float) -> Recipe:
	var entry: Dictionary = RECIPES.get(id, {})
	if entry.is_empty():
		push_warning("RecipeCatalog: receta desconocida '%s'" % id)
		return Recipe.new(id.capitalize(), [], points, time)
	return Recipe.new(
		entry["name"],
		_duplicate_required(entry["required"]),
		points,
		time
	)


static func _duplicate_required(required: Array) -> Array:
	var out: Array = []
	for req: Dictionary in required:
		out.append(req.duplicate())
	return out
