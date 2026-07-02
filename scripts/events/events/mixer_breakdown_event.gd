extends GameEvent

## Batidora fuera de servicio: deshabilita UNA batidora (si hay varias) durante
## un rato. Fuerza a compartir la(s) batidora(s) restante(s) y coordinar el
## orden de mezclado. Solo aparece si hay al menos una batidora.

var _target: Station = null


func _init() -> void:
	id = "mixer_breakdown"
	title = "Batidora descompuesta"
	description = "Una batidora quedo fuera de servicio. Coordinen con la otra."
	color = Color(0.3, 0.55, 0.95)
	duration = 13.0
	weight = 1.0
	cooldown = 40.0


func can_trigger(ctx: EventContext) -> bool:
	return not ctx.get_mixers().is_empty()


func on_start(ctx: EventContext) -> void:
	var mixers := ctx.get_mixers()
	if mixers.is_empty():
		return
	_target = mixers[ctx.rng.randi() % mixers.size()]
	_target.set_disabled(true)


func on_end(_ctx: EventContext) -> void:
	if _target != null and is_instance_valid(_target):
		_target.set_disabled(false)
	_target = null
