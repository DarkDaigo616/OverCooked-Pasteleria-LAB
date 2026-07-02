extends GameEvent

## Pedido urgente inesperado: aparece un pedido VIP con bonus de puntos y poco
## tiempo, por encima del limite normal de ordenes. Fuerza a decidir si dejan lo
## que estaban haciendo para priorizarlo. Termina cuando se entrega o expira.

var _order: Dictionary = {}


func _init() -> void:
	id = "rush_order"
	title = "¡Pedido urgente!"
	description = "Un pedido VIP con bonus y poco tiempo. ¡Prioricenlo!"
	color = Color(0.95, 0.3, 0.3)
	duration = 45.0  # tope de seguridad; normalmente termina antes por is_finished
	weight = 0.9
	cooldown = 40.0


func can_trigger(ctx: EventContext) -> bool:
	return ctx.order_manager != null


func on_start(ctx: EventContext) -> void:
	if ctx.order_manager == null:
		return
	_order = ctx.order_manager.add_random_special_order(1.6, 35.0)


func is_finished(ctx: EventContext) -> bool:
	if _order.is_empty() or ctx.order_manager == null:
		return true
	return not ctx.order_manager.is_order_active(_order)


func on_end(_ctx: EventContext) -> void:
	_order = {}
