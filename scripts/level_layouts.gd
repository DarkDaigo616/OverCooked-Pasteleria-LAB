extends RefCounted
class_name LevelLayouts

## Primera version: tres estaciones para pasteles.


static func get_level_count() -> int:
	return 1


static func get_layout(_level_id: int) -> Dictionary:
	return {
		"name": "Pasteleria basica",
		"spawn": Vector3(0.0, 1.0, 5.0),
		"stations": [
			{"type": "ingredient", "ingredient": "cake_batter", "pos": Vector3(-8, 0.5, 0)},
			{"type": "cook", "pos": Vector3(0, 0.5, -5)},
			{"type": "delivery", "pos": Vector3(8, 0.5, 0)},
		],
	}
