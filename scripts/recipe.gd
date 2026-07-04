extends Resource
class_name Recipe

@export var recipe_name: String = ""
@export var required_ingredients: Array = []
@export var points: int = 100
@export var preparation_time: float = 60.0
@export var icon_color: Color = Color.YELLOW
## Id en RecipeCatalog (para consultar requirements); "" en recetas ad-hoc.
@export var recipe_id: String = ""

const TYPE_NAMES := {
	"cake": "Pastel",
	"giant_cake": "Pastel gigante",
	"cake_batter": "Masa",
	"giant_batter": "Masa gigante",
	"bad_batter": "Masa",
	"flour": "Harina",
	"egg": "Huevo",
	"sugar": "Azucar",
}

const STATE_NAMES := {
	"baked": "horneado",
	"burned": "quemado",
	"decorated_vanilla": "vainilla",
	"decorated_chocolate": "chocolate",
	"decorated_strawberry": "fresa",
	"decorated_wedding": "boda",
	"ruined_baked": "fallido",
	"raw": "crudo",
	"cooked": "cocido",
	"chopped": "cortado",
}


func _init(p_name: String = "", p_ingredients: Array = [], p_points: int = 100, p_time: float = 60.0) -> void:
	recipe_name = p_name
	required_ingredients = p_ingredients
	points = p_points
	preparation_time = p_time


static func normalize_entry(data: Variant) -> Dictionary:
	if data is Dictionary:
		return {
			"type": str(data.get("type", "")).strip_edges().to_lower(),
			"state": str(data.get("state", "")).strip_edges().to_lower(),
		}
	return {"type": "", "state": ""}


static func normalize_list(items: Array) -> Array:
	var out: Array = []
	for item in items:
		var entry := normalize_entry(item)
		if not entry["type"].is_empty():
			out.append(entry)
	return out


static func entries_equal(a: Dictionary, b: Dictionary) -> bool:
	var na := normalize_entry(a)
	var nb := normalize_entry(b)
	return na["type"] == nb["type"] and na["state"] == nb["state"]


func matches(ingredients: Array) -> bool:
	return get_match_result(ingredients).success


func get_match_result(ingredients: Array) -> Dictionary:
	var plate_list := normalize_list(ingredients)
	var required := normalize_list(required_ingredients)

	if plate_list.is_empty():
		return {"success": false, "reason": "El plato esta vacio."}

	if plate_list.size() != required.size():
		return {
			"success": false,
			"reason": "Cantidad incorrecta: tienes %d ingrediente(s), la receta pide %d." % [
				plate_list.size(), required.size()
			],
		}

	var used: Array[bool] = []
	used.resize(plate_list.size())
	used.fill(false)

	for req in required:
		var matched := false
		for i in range(plate_list.size()):
			if used[i]:
				continue
			if entries_equal(plate_list[i], req):
				used[i] = true
				matched = true
				break
		if not matched:
			return {
				"success": false,
				"reason": "Falta o esta mal preparado: %s." % format_entry(req),
			}

	return {"success": true, "reason": ""}


static func format_entry(entry_data: Variant) -> String:
	var entry := normalize_entry(entry_data)
	var type_name: String = TYPE_NAMES.get(str(entry["type"]), str(entry["type"]).capitalize())
	var state_name: String = STATE_NAMES.get(str(entry["state"]), str(entry["state"]))
	if state_name.is_empty():
		return type_name
	return "%s (%s)" % [type_name, state_name]


func get_description() -> String:
	var desc := recipe_name + ":\n"
	for ing in required_ingredients:
		desc += "  - " + format_entry(ing) + "\n"
	return desc
