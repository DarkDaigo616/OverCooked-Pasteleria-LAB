extends RefCounted
class_name EventLibrary

## Registro de todos los eventos disponibles. Es el UNICO sitio que hay que
## tocar para dar de alta un evento nuevo: se agrega una linea aqui y ya se
## puede referenciar por id desde la config de cualquier nivel (LevelRegistry).

const _EVENTS := {
	"oven_overheat": preload("res://scripts/events/events/oven_overheat_event.gd"),
	"cream_spill": preload("res://scripts/events/events/cream_spill_event.gd"),
	"decoration_change": preload("res://scripts/events/events/decoration_change_event.gd"),
	"mixer_breakdown": preload("res://scripts/events/events/mixer_breakdown_event.gd"),
	"rush_order": preload("res://scripts/events/events/rush_order_event.gd"),
}


## Crea instancias frescas de los eventos indicados por id.
static func create_pool(ids: Array) -> Array:
	var pool: Array = []
	for id: String in ids:
		var scr: GDScript = _EVENTS.get(id, null)
		if scr != null:
			pool.append(scr.new())
		else:
			push_warning("EventLibrary: evento desconocido '%s'" % id)
	return pool


static func available_ids() -> Array:
	return _EVENTS.keys()
