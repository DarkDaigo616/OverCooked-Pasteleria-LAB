extends GameEvent

## Horno sobrecalentado: los pasteles se queman mucho antes. Fuerza la decision
## de dejar otra tarea para sacar el pastel a tiempo.

func _init() -> void:
	id = "oven_overheat"
	title = "¡Horno sobrecalentado!"
	description = "Los pasteles se queman mucho mas rapido. ¡Sacalos a tiempo!"
	color = Color(0.95, 0.35, 0.12)
	duration = 14.0
	weight = 1.0
	cooldown = 35.0


func can_trigger(ctx: EventContext) -> bool:
	return not ctx.get_ovens().is_empty()


func on_start(ctx: EventContext) -> void:
	for oven in ctx.get_ovens():
		oven.burn_time_scale = 0.35


func on_end(ctx: EventContext) -> void:
	for oven in ctx.get_ovens():
		oven.burn_time_scale = 1.0
