extends RefCounted
class_name GameEvent

## Clase base de todos los eventos caoticos (Etapa 9).
##
## Cada evento vive en su propia clase y conoce: cuando puede aparecer
## (can_trigger), cuanto dura (duration), como inicia (on_start), que hace
## mientras esta activo (on_tick / is_finished), como termina (on_end) y sus
## reglas de balance (weight, cooldown, priority, exclusive).
##
## El EventManager NO contiene logica especifica de ningun evento: solo decide
## cuando disparar. Agregar un evento nuevo = crear una subclase y registrarla
## en EventLibrary. No hay que tocar el EventManager.

var id: String = "event"                       ## identificador unico
var title: String = "Evento"                   ## titulo mostrado en el banner
var description: String = ""                    ## descripcion mostrada en el banner
var color: Color = Color(0.95, 0.6, 0.2)        ## color de acento del banner
var duration: float = 12.0                      ## segundos que dura activo
var weight: float = 1.0                         ## probabilidad relativa de salir
var cooldown: float = 30.0                      ## segundos antes de poder repetirse
var priority: int = 0                           ## para ordenar/combinar (mayor = mas importante)
var exclusive: bool = false                     ## si true, no se combina con otros eventos


## Condiciones necesarias para que el evento pueda aparecer ahora mismo.
func can_trigger(_ctx: EventContext) -> bool:
	return true


## Se llama una vez al activarse. Aqui se aplica el efecto y, si hace falta,
## se ajusta 'description' con datos dinamicos antes de mostrar el banner.
func on_start(_ctx: EventContext) -> void:
	pass


## Se llama cada frame mientras el evento esta activo.
func on_tick(_ctx: EventContext, _delta: float) -> void:
	pass


## Permite que el evento termine antes de agotar su duracion (p. ej. el pedido
## urgente ya se entrego, o el charco ya se limpio).
func is_finished(_ctx: EventContext) -> bool:
	return false


## Se llama al terminar (por tiempo, por is_finished o al cortar el nivel).
## Debe revertir cualquier efecto aplicado en on_start.
func on_end(_ctx: EventContext) -> void:
	pass
