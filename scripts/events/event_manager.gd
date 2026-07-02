extends Node
class_name EventManager

## Planificador de eventos caoticos. Su UNICA responsabilidad es decidir cuando
## disparar un evento y llevar el ciclo de vida (activo -> tick -> fin ->
## cooldown). No sabe nada de lo que hace cada evento en concreto: eso vive en
## las subclases de GameEvent. Asi se pueden agregar eventos sin tocar este
## archivo.

var _ctx: EventContext = null
var _pool: Array[GameEvent] = []
var _active: Array = []          # [{event, remaining}]
var _cooldowns: Dictionary = {}  # id -> segundos restantes
var _time_to_next: float = 0.0
var _cfg: Dictionary = {}
var _enabled: bool = false


func setup(ctx: EventContext, pool: Array, cfg: Dictionary) -> void:
	_ctx = ctx
	_pool.assign(pool)
	_cfg = cfg
	_time_to_next = cfg.get("first_delay", 20.0)
	_enabled = bool(cfg.get("enabled", false)) and not _pool.is_empty()


## Corta el sistema (fin del nivel): revierte todos los eventos activos.
func stop() -> void:
	_enabled = false
	for entry: Dictionary in _active:
		entry["event"].on_end(_ctx)
	_active.clear()


func _process(delta: float) -> void:
	if not _enabled:
		return
	_tick_cooldowns(delta)
	_tick_active_events(delta)
	_time_to_next -= delta
	if _time_to_next <= 0.0:
		_try_trigger()
		_time_to_next = _ctx.rng.randf_range(
			_cfg.get("min_interval", 22.0),
			_cfg.get("max_interval", 34.0)
		)


func _tick_cooldowns(delta: float) -> void:
	for id: String in _cooldowns.keys():
		_cooldowns[id] = maxf(_cooldowns[id] - delta, 0.0)


func _tick_active_events(delta: float) -> void:
	for i in range(_active.size() - 1, -1, -1):
		var entry: Dictionary = _active[i]
		var ev: GameEvent = entry["event"]
		ev.on_tick(_ctx, delta)
		entry["remaining"] -= delta
		if entry["remaining"] <= 0.0 or ev.is_finished(_ctx):
			ev.on_end(_ctx)
			_cooldowns[ev.id] = ev.cooldown
			_active.remove_at(i)


func _try_trigger() -> void:
	if _active.size() >= int(_cfg.get("max_concurrent", 1)):
		return
	var eligible := _eligible_events()
	if eligible.is_empty():
		return
	var ev := _weighted_pick(eligible)
	if ev != null:
		_start_event(ev)


func _eligible_events() -> Array:
	var has_exclusive_active := false
	for entry: Dictionary in _active:
		if entry["event"].exclusive:
			has_exclusive_active = true
			break

	var out: Array = []
	for ev: GameEvent in _pool:
		if _is_active(ev):
			continue
		if _cooldowns.get(ev.id, 0.0) > 0.0:
			continue
		# Un evento exclusivo no convive con ningun otro activo, ni al reves.
		if has_exclusive_active:
			continue
		if ev.exclusive and not _active.is_empty():
			continue
		if not ev.can_trigger(_ctx):
			continue
		out.append(ev)
	return out


func _weighted_pick(list: Array) -> GameEvent:
	var total := 0.0
	for ev: GameEvent in list:
		total += maxf(ev.weight, 0.0)
	if total <= 0.0:
		return list[_ctx.rng.randi() % list.size()]
	var roll := _ctx.rng.randf() * total
	for ev: GameEvent in list:
		roll -= maxf(ev.weight, 0.0)
		if roll <= 0.0:
			return ev
	return list.back()


func _start_event(ev: GameEvent) -> void:
	ev.on_start(_ctx)
	_active.append({"event": ev, "remaining": ev.duration})
	# El evento pudo ajustar 'description' con datos dinamicos en on_start.
	_ctx.notify(ev.title, ev.description, ev.color)


func _is_active(ev: GameEvent) -> bool:
	for entry: Dictionary in _active:
		if entry["event"] == ev:
			return true
	return false
