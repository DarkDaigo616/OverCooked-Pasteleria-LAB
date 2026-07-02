extends GameEvent

## El cliente cambia la decoracion de un pedido activo. Fuerza a re-planear quien
## termina que pastel (el que ya estaban preparando quiza ya no sirve).

func _init() -> void:
	id = "decoration_change"
	title = "El cliente cambio de idea"
	description = "Un pedido cambio de decoracion. Revisen la lista."
	color = Color(0.85, 0.45, 0.95)
	duration = 6.0
	weight = 1.0
	cooldown = 28.0


func can_trigger(ctx: EventContext) -> bool:
	return ctx.order_manager != null and ctx.order_manager.can_change_decoration()


func on_start(ctx: EventContext) -> void:
	if ctx.order_manager == null:
		return
	var change: Dictionary = ctx.order_manager.change_random_order_recipe()
	if not change.is_empty():
		description = "Pedido cambiado: %s → %s." % [change["old"], change["new"]]
