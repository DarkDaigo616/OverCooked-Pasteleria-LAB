extends Area3D
class_name CreamSpill

## Charco de crema en el piso. No bloquea el paso (es un Area3D), pero ralentiza
## a quien lo pisa. Se limpia parandose encima un momento (representa trapearlo);
## al limpiarlo emite 'cleaned' y se elimina. El evento tambien puede quitarlo
## con dismiss() cuando se acaba su duracion.

signal cleaned

const SLOW_SCALE := 0.5
const CLEAN_TIME := 1.8
const RADIUS := 1.3

var _players_inside: Array = []
var _clean_progress: float = 0.0
var _disc: MeshInstance3D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitoring = true

	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = RADIUS
	cyl.height = 1.2
	shape.shape = cyl
	add_child(shape)

	_build_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _build_visual() -> void:
	_disc = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS
	mesh.height = 0.05
	_disc.mesh = mesh
	_disc.position = Vector3(0, 0.03, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.98, 0.93, 0.78, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.25
	mat.metallic = 0.1
	_disc.material_override = mat
	add_child(_disc)


func _process(delta: float) -> void:
	if _players_inside.is_empty():
		return
	_clean_progress += delta
	if _disc:
		var t := clampf(1.0 - _clean_progress / CLEAN_TIME, 0.05, 1.0)
		_disc.scale = Vector3(t, 1.0, t)
	if _clean_progress >= CLEAN_TIME:
		_restore_all()
		cleaned.emit()
		queue_free()


## Quita el charco sin contar como "limpiado" (fin del evento por tiempo).
func dismiss() -> void:
	_restore_all()
	queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body is ChefPlayer and not _players_inside.has(body):
		_players_inside.append(body)
		body.speed_scale = SLOW_SCALE


func _on_body_exited(body: Node3D) -> void:
	if body is ChefPlayer:
		_players_inside.erase(body)
		if is_instance_valid(body):
			body.speed_scale = 1.0


func _restore_all() -> void:
	for b in _players_inside:
		if is_instance_valid(b):
			b.speed_scale = 1.0
	_players_inside.clear()
