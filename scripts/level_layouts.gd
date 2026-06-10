extends RefCounted
class_name LevelLayouts

## type: ingredient | chop | cook | plate | plating | delivery | trash

static func get_level_count() -> int:
	return 5


static func get_layout(level_id: int) -> Dictionary:
	match clampi(level_id, 1, 5):
		1:
			return _layout_classic()
		2:
			return _layout_mirror()
		3:
			return _layout_compact()
		4:
			return _layout_cross()
		5:
			return _layout_islands()
		_:
			return _layout_classic()


static func _stations_common_ingredients(side_x: float, z_start: float, z_step: float) -> Array:
	return [
		{"type": "ingredient", "ingredient": "tomato", "pos": Vector3(side_x, 0.5, z_start)},
		{"type": "ingredient", "ingredient": "lettuce", "pos": Vector3(side_x, 0.5, z_start + z_step)},
		{"type": "ingredient", "ingredient": "meat", "pos": Vector3(side_x, 0.5, z_start + z_step * 2)},
		{"type": "ingredient", "ingredient": "bread", "pos": Vector3(side_x, 0.5, z_start + z_step * 3)},
	]


static func _plating_block(cx: float, cz: float, plate_z: float) -> Array:
	return [
		{"type": "plate", "pos": Vector3(cx - 4, 0.5, plate_z)},
		{"type": "plating", "pos": Vector3(cx, 0.5, cz)},
		{"type": "delivery", "pos": Vector3(cx + 10, 0.5, cz)},
		{"type": "trash", "pos": Vector3(cx + 6, 0.5, cz + 5)},
	]


static func _layout_classic() -> Dictionary:
	var s := _stations_common_ingredients(-11.0, -11.0, 4.5)
	s.append_array([
		{"type": "chop", "pos": Vector3(-4, 0.5, -11)},
		{"type": "chop", "pos": Vector3(-4, 0.5, -5)},
		{"type": "cook", "pos": Vector3(4, 0.5, -11)},
		{"type": "cook", "pos": Vector3(4, 0.5, -5)},
	])
	s.append_array(_plating_block(0, 2, 9))
	return {
		"name": "Cocina clasica",
		"spawn": Vector3(6.0, 1.0, 5.0),
		"stations": s,
	}


static func _layout_mirror() -> Dictionary:
	var s := _stations_common_ingredients(11.0, -11.0, 4.5)
	s.append_array([
		{"type": "chop", "pos": Vector3(4, 0.5, -11)},
		{"type": "chop", "pos": Vector3(4, 0.5, -5)},
		{"type": "cook", "pos": Vector3(-4, 0.5, -11)},
		{"type": "cook", "pos": Vector3(-4, 0.5, -5)},
	])
	s.append_array(_plating_block(0, 2, 9))
	return {
		"name": "Cocina espejo",
		"spawn": Vector3(-6.0, 1.0, 5.0),
		"stations": s,
	}


static func _layout_compact() -> Dictionary:
	var s := [
		{"type": "ingredient", "ingredient": "tomato", "pos": Vector3(-12, 0.5, -8)},
		{"type": "ingredient", "ingredient": "lettuce", "pos": Vector3(-12, 0.5, -2)},
		{"type": "ingredient", "ingredient": "meat", "pos": Vector3(-12, 0.5, 4)},
		{"type": "ingredient", "ingredient": "bread", "pos": Vector3(-12, 0.5, 10)},
		{"type": "chop", "pos": Vector3(-5, 0.5, -5)},
		{"type": "chop", "pos": Vector3(-5, 0.5, 7)},
		{"type": "cook", "pos": Vector3(5, 0.5, -5)},
		{"type": "cook", "pos": Vector3(5, 0.5, 7)},
		{"type": "plate", "pos": Vector3(10, 0.5, 10)},
		{"type": "plating", "pos": Vector3(10, 0.5, 0)},
		{"type": "delivery", "pos": Vector3(10, 0.5, -10)},
		{"type": "trash", "pos": Vector3(6, 0.5, -10)},
	]
	return {
		"name": "Cocina compacta",
		"spawn": Vector3(0.0, 1.0, 0.0),
		"stations": s,
	}


static func _layout_cross() -> Dictionary:
	var s := [
		{"type": "ingredient", "ingredient": "tomato", "pos": Vector3(0, 0.5, -13)},
		{"type": "ingredient", "ingredient": "lettuce", "pos": Vector3(-13, 0.5, 0)},
		{"type": "ingredient", "ingredient": "meat", "pos": Vector3(13, 0.5, 0)},
		{"type": "ingredient", "ingredient": "bread", "pos": Vector3(0, 0.5, 13)},
		{"type": "chop", "pos": Vector3(-6, 0.5, -6)},
		{"type": "chop", "pos": Vector3(6, 0.5, -6)},
		{"type": "cook", "pos": Vector3(-6, 0.5, 6)},
		{"type": "cook", "pos": Vector3(6, 0.5, 6)},
		{"type": "plate", "pos": Vector3(-9, 0.5, 9)},
		{"type": "plating", "pos": Vector3(0, 0.5, 0)},
		{"type": "delivery", "pos": Vector3(9, 0.5, -9)},
		{"type": "trash", "pos": Vector3(5, 0.5, -9)},
	]
	return {
		"name": "Cocina en cruz",
		"spawn": Vector3(0.0, 1.0, 3.0),
		"stations": s,
	}


static func _layout_islands() -> Dictionary:
	var s := [
		{"type": "ingredient", "ingredient": "tomato", "pos": Vector3(-12, 0.5, -9)},
		{"type": "ingredient", "ingredient": "lettuce", "pos": Vector3(-12, 0.5, -3)},
		{"type": "ingredient", "ingredient": "meat", "pos": Vector3(12, 0.5, -9)},
		{"type": "ingredient", "ingredient": "bread", "pos": Vector3(12, 0.5, -3)},
		{"type": "chop", "pos": Vector3(-6, 0.5, 4)},
		{"type": "chop", "pos": Vector3(6, 0.5, 4)},
		{"type": "cook", "pos": Vector3(-6, 0.5, 10)},
		{"type": "cook", "pos": Vector3(6, 0.5, 10)},
		{"type": "plate", "pos": Vector3(0, 0.5, -9)},
		{"type": "plating", "pos": Vector3(0, 0.5, 0)},
		{"type": "delivery", "pos": Vector3(0, 0.5, 13)},
		{"type": "trash", "pos": Vector3(4, 0.5, 13)},
	]
	return {
		"name": "Dos islas",
		"spawn": Vector3(0.0, 1.0, -4.0),
		"stations": s,
		"walls": [
			{"pos": Vector3(0, 1.25, 6.0), "size": Vector3(5.0, 2.5, 0.5)},
		],
	}
