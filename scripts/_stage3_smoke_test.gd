extends SceneTree


func _initialize() -> void:
	var layouts_script := load("res://scripts/level_layouts.gd")
	var factory_script := load("res://scripts/station_factory.gd")
	var layout: Dictionary = layouts_script.get_layout(2)
	for station_data: Dictionary in layout.get("stations", []):
		var station: StaticBody3D = factory_script.build_station(station_data)
		if station == null:
			push_error("No se pudo construir estacion: %s" % [station_data])
			quit(1)
			return
		root.add_child(station)
	quit()
