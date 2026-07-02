# Overcooked Style Game - Proyecto Godot

**Version:** 0.9.0

## Descripcion

Juego de pasteleria estilo Overcooked creado en Godot 4.x. Controlas a un chef (o dos en modo cooperativo) que debe completar ordenes de pasteles antes de que se acabe el tiempo, gestionando ingredientes, mezcla, horneado y decoracion.

## Controles

- **Click izquierdo**: Mover al chef / interactuar con estaciones
- **Shift + Click izquierdo**: Añadir accion a la cola (Niveles 4 en adelante)
- **Click derecho**: Cancelar cola de acciones
- **Tecla 1**: Seleccionar P1 (modos cooperativos)
- **Tecla 2**: Seleccionar P2 (modos cooperativos)
- **E o Espacio**: Interactuar con estaciones
- **Q**: Soltar objeto que llevas en mano
- **Escape**: Pausar / Menu

---

## Categorias de niveles

El menu organiza los niveles en 4 categorias:

| Categoria | Niveles | Descripcion |
|-----------|---------|-------------|
| Intro | 1 | Tutorial de mecanicas basicas |
| Pasteleria | 2, 3, 4 | Recetas completas, tiempo y cola de acciones |
| Cooperativo | 5 | Dos jugadores en la misma pantalla |
| Desafios | 6, 7, 8 | Niveles reales con estrellas, tiempo limite y eventos |

Los niveles de Desafios se desbloquean en orden: hay que completar el anterior para acceder al siguiente.

---

## INTRO — Nivel 1

### Nivel 1 — Introduccion
Familiarizate con el flujo basico: toma masa pre-mezclada, hornea y entrega.

**Receta:** Pastel horneado (100 pts, 60s)

---

## PASTELERIA — Niveles 2 al 4

### Nivel 2 — Cadena de Receta
Prepara la receta desde cero: mezcla harina + huevo, hornea y decora.

**Receta:** Pastel de vainilla — harina + huevo → mezcla → horno → decorar (160 pts, 90s)

---

### Nivel 3 — Presion de Tiempo
Gestiona hasta **3 pedidos simultaneos** con temporizadores independientes.

| Pedido | Puntos | Tiempo |
|--------|--------|--------|
| Pastel simple | 80 | 60s |
| Pastel de chocolate | 150 | 90s |
| Pastel con fresa | 150 | 90s |

---

### Nivel 4 — Cola de Acciones
Planea hasta **3 acciones consecutivas** con Shift+click.

| Pedido | Puntos | Tiempo |
|--------|--------|--------|
| Pastel de chocolate | 180 | 100s |
| Pastel con fresa | 180 | 100s |

**Reglas de la cola:**
- Shift + Click en una estacion: encola la accion
- Click derecho: cancela la ultima accion encolada

---

## COOPERATIVO — Nivel 5

### Nivel 5 — Cooperativo Local
Dos jugadores en la misma pantalla. **Tecla 1** controla P1 (rosa), **Tecla 2** controla P2 (azul).

**Division natural de roles:**
- P1 (izquierda): trae ingredientes y mezcla
- P2 (derecha): controla decoracion y sirve
- Ambos pueden hornear y entregar

| Pedido | Puntos | Tiempo |
|--------|--------|--------|
| Pastel simple | 80 | 70s |
| Pastel de chocolate | 150 | 100s |
| Pastel con fresa | 150 | 100s |

---

## DESAFIOS — Niveles 6, 7 y 8

### Nivel 6 — Pasteleria de barrio
El primer nivel del juego real. **3 minutos**, 3 tipos de pastel, sistema de estrellas. Cooperativo.

**Duracion:** 3 minutos (180s)

| Pedido | Puntos | Tiempo |
|--------|--------|--------|
| Pastel de vainilla | 120 | 90s |
| Pastel de chocolate | 130 | 90s |
| Pastel con fresa | 130 | 90s |

**Sistema de estrellas:**

| Estrellas | Condicion |
|-----------|-----------|
| ★☆☆ | Entregar 3 pedidos |
| ★★☆ | Entregar 5 pedidos |
| ★★★ | Entregar 7 pedidos sin quemar pasteles |

---

### Nivel 7 — Turno de Noche  _(Etapa 8)_
Nivel de desafio disenado por restricciones. **4 minutos**, cooperativo, pedidos frecuentes.

**Restriccion:** Una sola batidora (cuello de botella) frente a 2 hornos y 3 decoradoras. El resto del equipo sobra — solo la batidora limita el ritmo de produccion.

**Objetivo:** Mantener la batidora activa en todo momento. Si la batidora para, hornos y decoradoras quedan ociosos aunque esten libres.

**Duracion:** 4 minutos (240s) | Pedidos cada 16s

| Pedido | Puntos | Tiempo |
|--------|--------|--------|
| Pastel de vainilla | 140 | 80s |
| Pastel de chocolate | 150 | 80s |
| Pastel con fresa | 150 | 80s |

**Sistema de estrellas:**

| Estrellas | Condicion |
|-----------|-----------|
| ★☆☆ | Entregar 4 pedidos |
| ★★☆ | Entregar 7 pedidos |
| ★★★ | Entregar 10 pedidos sin quemar pasteles |

---

### Nivel 8 — Servicio caotico  _(Etapa 9)_
Estrena el sistema de **eventos caoticos**. Cooperativo, **4 minutos**, con dos
batidoras, dos hornos y tres decoradoras. Cada cierto tiempo salta un imprevisto
que obliga a los jugadores a re-priorizar y coordinar.

**Duracion:** 4 minutos (240s) | Eventos cada 22-34s (primero a los 20s, hasta 2 a la vez)

| Pedido | Puntos | Tiempo |
|--------|--------|--------|
| Pastel de vainilla | 140 | 85s |
| Pastel de chocolate | 150 | 85s |
| Pastel con fresa | 150 | 85s |

**Sistema de estrellas:**

| Estrellas | Condicion |
|-----------|-----------|
| ★☆☆ | Entregar 4 pedidos |
| ★★☆ | Entregar 7 pedidos |
| ★★★ | Entregar 10 pedidos sin quemar pasteles |

---

## Eventos caoticos (Etapa 9)

La filosofia: el caos debe nacer de **decisiones y coordinacion**, no de castigos
al azar. Cada evento crea un conflicto de prioridades ("yo saco el pastel", "ve
limpiando el piso", "yo termino este pedido").

| Evento | Que hace | Decision que fuerza |
|--------|----------|---------------------|
| Horno sobrecalentado | Los pasteles se queman mucho antes | ¿Dejo mi tarea para sacar el pastel? |
| Derrame de crema | Aparece un charco que ralentiza; se limpia parandose encima | ¿Quien va a limpiar y quien sigue cocinando? |
| El cliente cambio de idea | Un pedido activo cambia de decoracion | ¿Re-planeamos quien termina que pastel? |
| Batidora descompuesta | Una batidora queda fuera de servicio un rato | ¿Como compartimos la otra batidora? |
| Pedido urgente | Aparece un pedido VIP con bonus y poco tiempo | ¿Lo priorizamos o seguimos con lo actual? |

Los eventos tienen **duracion, peso (probabilidad), cooldown y prioridad**, se
anuncian en un banner y pueden combinarse. Estan disponibles solo en los niveles
que los activan (opt-in por nivel).

---

## Cadena de preparacion

```
[Harina] ─┐
[Huevo]  ─┼→ [Batidora] → [Horno] → [Decorar?] → [Entrega]
```

---

## Instalacion

### Requisitos
- Godot Engine 4.2 o superior

### Pasos

1. Descarga e instala Godot desde https://godotengine.org/download
2. Abre Godot → Importar → selecciona `project.godot`
3. Presiona F5 para ejecutar

---

## Estructura del Proyecto

```
OvercookedGame/
├── project.godot
├── scripts/
│   ├── chef_player.gd         # Movimiento e interaccion del chef (P1/P2)
│   ├── game_manager.gd        # Coordinador principal
│   ├── game_hud.gd            # Interfaz: pedidos, timer, puntos, colas, estrellas
│   ├── order_manager.gd       # Pedidos, timers, bonus/penalizacion
│   ├── recipe.gd              # Definicion de recetas (matching de ingredientes)
│   ├── recipe_catalog.gd      # Fuente unica de recetas: nombre, ingredientes, imagen (static)
│   ├── level_layouts.gd       # Layouts fisicos de los 8 niveles (estaciones, spawns)
│   ├── level_registry.gd      # Fuente unica de niveles: metadatos, ordenes, eventos (autoload)
│   ├── kitchen_level.gd       # Carga y construccion del nivel, modo real, modo coop
│   ├── station_factory.gd     # Construccion de estaciones
│   ├── station_base.gd        # Base para todas las estaciones
│   ├── ingredient_station.gd  # Estacion de ingredientes
│   ├── mixing_station.gd      # Batidora
│   ├── cooking_station.gd     # Horno (emite item_burned al quemarse)
│   ├── decoration_station.gd  # Decoracion
│   ├── delivery_window.gd     # Ventana de entrega
│   ├── trash_station.gd       # Basura
│   ├── recipe_book_station.gd # Recetario
│   ├── item_visuals.gd        # Visuales de ingredientes y pasteles
│   ├── station_visuals.gd     # Visuales de estaciones
│   ├── ui_theme.gd            # Tema visual de la UI
│   ├── game_state.gd          # Estado global: progreso, dev mode (autoload)
│   ├── physics_layers.gd      # Capas de fisica
│   └── events/                # Sistema de eventos caoticos (Etapa 9)
│       ├── game_event.gd      # Clase base de un evento (duracion, peso, cooldown...)
│       ├── event_context.gd   # Fachada al mundo (ordenes, estaciones, jugadores, HUD)
│       ├── event_manager.gd   # Planificador: SOLO decide cuando disparar
│       ├── event_library.gd   # Registro de eventos disponibles (id -> clase)
│       ├── cream_spill.gd     # Nodo del charco de crema
│       └── events/            # Un archivo por evento concreto
│           ├── oven_overheat_event.gd
│           ├── cream_spill_event.gd
│           ├── decoration_change_event.gd
│           ├── mixer_breakdown_event.gd
│           └── rush_order_event.gd
├── scenes/
│   ├── main_menu.tscn
│   ├── levels/kitchen_level.tscn
│   └── player/chef_player.tscn
└── assets/
	├── ui/                    # Texturas de recetario
	└── {models,textures,sounds}/
		├── Tiny_Treats_Bakery_Interior_1.1_FREE/
		└── KayKit_Restaurant_Bits_1.0_FREE/
```

---

## Modo desarrollador (Dev Mode)

El boton **Dev: OFF** en el menu activa el modo desarrollador:

- Permite jugar cualquier nivel sin haber completado los anteriores
- Muestra los niveles desbloqueados por dev con etiqueta `[DEV]` en purpura
- **No guarda estrellas ni progreso** mientras dev mode esta activo
- El boton **Borrar prog.** (rojo, solo visible en dev mode) resetea todo el progreso guardado
- Al desactivar dev mode, el menu vuelve al estado real del jugador

---

## Como agregar contenido (arquitectura 0.9.0)

La base quedo preparada para crecer sin reescribir sistemas:

- **Nueva receta:** 1 entrada en `recipe_catalog.gd` (nombre, ingredientes,
  imagen). El recetario del HUD y el matching la toman de ahi automaticamente.
- **Nuevo nivel:** 1 entrada en `level_registry.gd` (metadatos + ordenes +
  eventos) y 1 funcion de layout en `level_layouts.gd`. El menu, el desbloqueo,
  las recetas y el recetario se actualizan solos.
- **Nuevo evento:** 1 clase que hereda de `GameEvent` (con `on_start` / `on_end`
  / `can_trigger`...) y 1 linea en `event_library.gd`. El `EventManager` no se
  toca nunca: solo decide cuando disparar. Luego se agrega el id al `pool` del
  nivel que lo quiera usar.

Principios: fuente unica de verdad por dato, bajo acoplamiento (los eventos
hablan con `EventContext`, no con rutas de nodos) y efectos reversibles
(`burn_time_scale`, `set_disabled`, `speed_scale`).

---

## Historial de Etapas

| Version | Etapa | Descripcion |
|---------|-------|-------------|
| 0.1.0 | Etapa 1 | Movimiento del chef, estaciones basicas, click-to-move |
| 0.2.0 | Etapa 2 | Assets 3D (Tiny Treats + KayKit), floor procedural, decoraciones |
| 0.3.0 | Etapa 3 | Cadena de receta completa (mezcla → horno → decoracion), UI mejorada |
| 0.4.0 | Etapa 4 | Panel de pedidos con timers, puntuacion, bonus/penalizacion, Nivel 3 con 3 recetas simultaneas |
| 0.5.0 | Etapa 5 | Cola de acciones (Nivel 4): Shift+click encola, espera automatica, click derecho cancela |
| 0.6.0 | Etapa 6 | Cooperativo local (Nivel 5): P1/P2 con teclas 1-2, colas independientes, menu de pausa con ESC |
| 0.7.0 | Etapa 7 | Primer nivel real (Nivel 6 "Pasteleria de barrio"): sistema de estrellas, contador de pedidos, 3 min, reintentar |
| 0.8.0 | Etapa 8 | Nivel 7 "Turno de Noche" (diseno por restricciones); menu por categorias (Intro/Pasteleria/Coop/Desafios); desbloqueo secuencial; dev mode separado del progreso real |
| 0.9.0 | Etapa 9 | Sistema de eventos caoticos modular (horno, derrame, cambio de decoracion, batidora, pedido urgente) y Nivel 8 "Servicio caotico". Refactor de base: catalogo unico de recetas, definicion de nivel consolidada en LevelRegistry (ordenes/eventos), ganchos de runtime en estaciones |

---

## Creditos

**Assets:**
- Tiny Treats Bakery Interior 1.1 FREE por Quaternius
- KayKit Restaurant Bits 1.0 FREE por Kay Lousberg

**Motor:** Godot Engine 4.x / GDScript

---

Disfruta cocinando bajo presion!
