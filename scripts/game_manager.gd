extends Node
class_name GameManager

@onready var order_manager: OrderManager = $OrderManager
@onready var hud: GameHUD = $GameHUD

var game_started: bool = false

func _ready() -> void:
	if order_manager:
		order_manager.new_order.connect(_on_new_order)
		order_manager.order_completed.connect(_on_order_completed)
		order_manager.order_failed.connect(_on_order_failed)
		order_manager.all_orders_updated.connect(_on_orders_updated)
	
	if hud:
		hud.game_ended.connect(_on_game_ended)
	
	start_game()

func start_game():
	game_started = true
	if hud and order_manager:
		hud.set_max_order_slots(order_manager.max_orders)
		hud.update_orders(order_manager.get_active_orders())
	print("=== ¡JUEGO INICIADO! ===")
	print("Instrucciones:")
	print("- Click izquierdo: mover o interactuar")
	print("- Q: Soltar objeto")
	print("¡Completa las órdenes antes de que se acabe el tiempo!")

func _on_new_order(recipe: Recipe):
	print("📋 Nueva orden recibida: ", recipe.recipe_name)
	if hud:
		hud.update_orders(order_manager.get_active_orders())

func _on_order_completed(recipe: Recipe, points: int):
	print("✅ Orden completada: ", recipe.recipe_name, " (+", points, " puntos)")
	if hud:
		hud.update_score(points)
		hud.update_orders(order_manager.get_active_orders())

func _on_order_failed(recipe: Recipe):
	print("❌ Orden fallida: ", recipe.recipe_name)
	if hud:
		hud.update_orders(order_manager.get_active_orders())

func _on_orders_updated(orders: Array):
	if hud:
		hud.update_orders(orders)

func _on_game_ended(final_score: int) -> void:
	game_started = false
	if order_manager:
		order_manager.stop_orders()
	var chef := get_tree().get_first_node_in_group("player") as ChefPlayer
	if chef:
		chef.set_movement_enabled(false)
	if hud and hud.interaction_hint:
		hud.interaction_hint.text = "Nivel terminado — usa el menu para salir"
		hud.interaction_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	print("=== JUEGO TERMINADO ===")
	print("Puntuacion final: ", final_score)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameState.go_to_menu()
