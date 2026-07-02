extends StaticBody3D
class_name Station

signal interaction_started(player)
signal interaction_completed(player, result)
signal item_placed(item)
signal item_removed(item)

@export var station_name: String = "Station"
@export var interaction_time: float = 0.0
@export var can_hold_item: bool = true
@export var max_items: int = 1

var is_occupied: bool = false
var current_items: Array[Node3D] = []
var is_processing: bool = false
var process_timer: float = 0.0
# Fuera de servicio temporal (eventos: bateria descompuesta, etc.). Generico:
# cualquier estacion puede deshabilitarse; las que lo comprueban llaman a
# _check_available() al inicio de su interact().
var disabled: bool = false

var _highlight_ring: MeshInstance3D
var _station_pad: MeshInstance3D
var _flash_tween: Tween
var _disabled_overlay: MeshInstance3D

@onready var item_holder = $ItemHolder if has_node("ItemHolder") else null


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("station")
	collision_layer = PhysicsLayers.STATIONS
	collision_mask = 0

	if has_node("HighlightRing"):
		_highlight_ring = $HighlightRing as MeshInstance3D
	if has_node("StationPad"):
		_station_pad = $StationPad as MeshInstance3D

	if not item_holder and can_hold_item:
		item_holder = Node3D.new()
		item_holder.name = "ItemHolder"
		item_holder.position = Vector3(0, 0.65, 0)
		add_child(item_holder)


func _process(delta: float) -> void:
	if is_processing:
		process_timer += delta
		_on_processing(delta)


func _on_processing(_delta: float) -> void:
	pass


func interact(player: ChefPlayer) -> void:
	interaction_started.emit(player)
	_play_interact_feedback()


func set_highlighted(active: bool) -> void:
	if _highlight_ring:
		_highlight_ring.visible = active


## Deshabilita/rehabilita la estacion (usado por los eventos). Muestra un
## indicador rojo flotante mientras esta fuera de servicio.
func set_disabled(value: bool) -> void:
	disabled = value
	_update_disabled_visual()


func is_available() -> bool:
	return not disabled


## Las estaciones interactivas llaman esto al inicio de interact(): si estan
## fuera de servicio, avisan al jugador y devuelven false.
func _check_available() -> bool:
	if not disabled:
		return true
	var hud := get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("show_delivery_feedback"):
		hud.show_delivery_feedback("%s fuera de servicio." % get_display_name(), false)
	return false


func _update_disabled_visual() -> void:
	if disabled:
		if _disabled_overlay == null:
			_disabled_overlay = MeshInstance3D.new()
			_disabled_overlay.name = "DisabledOverlay"
			var box := BoxMesh.new()
			box.size = Vector3(2.1, 0.14, 1.7)
			_disabled_overlay.mesh = box
			_disabled_overlay.position = Vector3(0, 1.55, 0)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.15, 0.12, 0.55)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(0.85, 0.12, 0.08)
			mat.emission_energy_multiplier = 0.5
			_disabled_overlay.material_override = mat
			add_child(_disabled_overlay)
		_disabled_overlay.visible = true
	elif _disabled_overlay:
		_disabled_overlay.visible = false


func has_ready_output() -> bool:
	return not is_processing and not current_items.is_empty()


func get_display_name() -> String:
	if has_meta("display_name"):
		return str(get_meta("display_name"))
	if has_node("StationLabel"):
		return ($StationLabel as Label3D).text
	return station_name


func _play_interact_feedback() -> void:
	if _station_pad:
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		_station_pad.scale = Vector3.ONE
		_flash_tween = create_tween()
		_flash_tween.tween_property(_station_pad, "scale", Vector3(1.12, 1.3, 1.12), 0.08)
		_flash_tween.tween_property(_station_pad, "scale", Vector3.ONE, 0.12)


func can_place_item(item: Node3D) -> bool:
	return can_hold_item and current_items.size() < max_items


func place_item(item: Node3D) -> bool:
	if not can_place_item(item):
		return false

	current_items.append(item)

	if item.get_parent():
		item.get_parent().remove_child(item)

	if item_holder:
		item_holder.add_child(item)
		item.position = Vector3(0, 0.2 * current_items.size(), 0)
		item.rotation = Vector3.ZERO

	is_occupied = current_items.size() >= max_items
	item_placed.emit(item)
	return true


func take_item() -> Node3D:
	if current_items.is_empty():
		return null

	var item = current_items.pop_back()

	if item_holder and item.get_parent() == item_holder:
		item_holder.remove_child(item)

	is_occupied = current_items.size() >= max_items
	item_removed.emit(item)
	return item


func get_items() -> Array[Node3D]:
	return current_items


func clear_items() -> void:
	for item in current_items:
		if item and is_instance_valid(item):
			item.queue_free()
	current_items.clear()
	is_occupied = false


func is_station_occupied() -> bool:
	return is_occupied
