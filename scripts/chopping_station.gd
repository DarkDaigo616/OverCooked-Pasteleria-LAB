extends Station
class_name ChoppingStation

@export var chop_duration: float = 2.0

var chopping_progress: float = 0.0
var is_chopping: bool = false

var _progress_bar: ProgressBar3D


func _ready() -> void:
	super._ready()
	station_name = "Chopping Board"
	max_items = 1
	_progress_bar = $ProgressBar3D if has_node("ProgressBar3D") else null


func _process(delta: float) -> void:
	super._process(delta)
	if is_chopping and not current_items.is_empty():
		var item: Node3D = current_items[0]
		if item.get_meta("state", "") != "raw":
			stop_chopping()
			return
		chopping_progress += delta / chop_duration
		if _progress_bar:
			_progress_bar.set_progress(chopping_progress, Color(0.3, 0.9, 0.4))
		if chopping_progress >= 1.0:
			complete_chopping()


func interact(player: ChefPlayer) -> void:
	super.interact(player)
	var held := player.get_held_item()

	if held and current_items.is_empty():
		if can_chop(held):
			var item := player.take_item_from_hand()
			if item:
				place_item(item)
		return

	if held:
		return

	if current_items.is_empty():
		return

	if is_chopping:
		return

	var board_item: Node3D = current_items[0]
	var state: String = board_item.get_meta("state", "raw")

	if state == "chopped":
		var item := take_item()
		if item:
			player.pickup_item(item)
		return

	var item_raw := take_item()
	if item_raw:
		player.pickup_item(item_raw)


func place_item(item: Node3D) -> bool:
	var ok := super.place_item(item)
	if ok and can_chop(item):
		start_chopping()
	return ok


func take_item() -> Node3D:
	stop_chopping()
	return super.take_item()


func can_chop(item: Node3D) -> bool:
	return item.get_meta("state", "") == "raw" and item.has_meta("is_ingredient")


func start_chopping() -> void:
	is_chopping = true
	chopping_progress = 0.0
	if _progress_bar:
		_progress_bar.show_bar(true)
		_progress_bar.set_progress(0.0, Color(0.3, 0.9, 0.4))


func stop_chopping() -> void:
	is_chopping = false
	chopping_progress = 0.0
	if _progress_bar:
		_progress_bar.show_bar(false)


func complete_chopping() -> void:
	if _progress_bar:
		_progress_bar.set_progress(1.0, Color(0.2, 1.0, 0.35))
	stop_chopping()
	if current_items.is_empty():
		return
	var item: Node3D = current_items[0]
	item.set_meta("state", "chopped")
	if item.has_meta("ingredient_type"):
		ItemVisuals.apply_ingredient_visual(item, item.get_meta("ingredient_type"), "chopped", 0.35)
