extends GameEvent

## Derrame de crema: aparece un charco en el piso que ralentiza a quien lo pisa.
## Fuerza la decision "¿quien deja su tarea para ir a limpiar?". Termina cuando
## alguien lo limpia (parandose encima) o al agotarse la duracion.

const CreamSpillScene := preload("res://scripts/events/cream_spill.gd")

var _spill: CreamSpill = null
var _cleaned: bool = false


func _init() -> void:
	id = "cream_spill"
	title = "¡Derrame de crema!"
	description = "Hay crema en el piso. Alguien tiene que ir a limpiarla (parate encima)."
	color = Color(0.95, 0.85, 0.5)
	duration = 16.0
	weight = 1.0
	cooldown = 30.0


func can_trigger(ctx: EventContext) -> bool:
	return ctx.level != null


func on_start(ctx: EventContext) -> void:
	_cleaned = false
	_spill = CreamSpillScene.new() as CreamSpill
	ctx.level.add_child(_spill)
	_spill.global_position = _pick_spot(ctx)
	_spill.cleaned.connect(func() -> void: _cleaned = true)


func is_finished(_ctx: EventContext) -> bool:
	return _cleaned


func on_end(_ctx: EventContext) -> void:
	if _spill != null and is_instance_valid(_spill):
		_spill.dismiss()
	_spill = null


## Coloca el charco frente a una estacion al azar, desplazado hacia el centro
## (sobre una ruta que los jugadores suelen recorrer).
func _pick_spot(ctx: EventContext) -> Vector3:
	var stations := ctx.get_stations()
	if stations.is_empty():
		return Vector3(0, 0.06, 0)
	var s: Node3D = stations[ctx.rng.randi() % stations.size()]
	var p: Vector3 = s.global_position
	var flat := Vector2(p.x, p.z)
	var dir := Vector3(0, 0, 1)
	if flat.length() > 0.1:
		var n := flat.normalized()
		dir = Vector3(-n.x, 0, -n.y)  # hacia el centro
	return Vector3(p.x + dir.x * 2.6, 0.06, p.z + dir.z * 2.6)
