# Overcooked Style Game - Proyecto Godot

**Version:** 0.7.0

## Descripcion

Juego de pasteleria estilo Overcooked creado en Godot 4.x. Controlas a un chef (o dos en modo cooperativo) que debe completar ordenes de pasteles antes de que se acabe el tiempo, gestionando ingredientes, mezcla, horneado y decoracion.

## Controles

- **Click izquierdo**: Mover al chef / interactuar con estaciones
- **Shift + Click izquierdo**: Añadir accion a la cola (Niveles 4 y 5)
- **Click derecho**: Cancelar cola de acciones (Niveles 4 y 5)
- **Tecla 1**: Seleccionar P1 (Nivel 5 cooperativo)
- **Tecla 2**: Seleccionar P2 (Nivel 5 cooperativo)
- **E o Espacio**: Interactuar con estaciones
- **Q**: Soltar objeto que llevas en mano
- **Escape**: Pausar / Menu

---

## INTRODUCCION — Niveles 1 al 5

### Nivel 1 — Introduccion
Familiarizate con el flujo basico: toma masa pre-mezclada, hornea y entrega.

**Receta:** Pastel horneado (100 pts, 60s)

---

### Nivel 2 — Cadena de Receta
Prepara la receta desde cero: mezcla harina + huevo + azucar, hornea y decora.

**Receta:** Pastel de vainilla — harina + huevo + azucar → mezcla → horno → decorar (160 pts, 90s)

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
- Click derecho: cancela toda la cola (penalizacion de 2s)
- No se puede encolar la misma estacion dos veces

---

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

## EL JUEGO — Niveles 6 en adelante

### Nivel 6 — Pasteleria de barrio  _(Etapa 7)_
El primer nivel del juego real. **3 minutos**, 3 tipos de pastel, sistema de estrellas.

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
| ★★★ | Entregar 7 pedidos Y no quemar pasteles |

**Disenio del nivel:**
- Flujo izquierda → derecha: ingredientes → batidora → horno → decorar → entregar
- Dos hornos activos simultaneamente: requiere vigilar tiempos de quemado (12s tras coccion)
- Tres estaciones de decoracion (vainilla, chocolate, fresa)
- Contador de pedidos visible en HUD durante la partida
- Pantalla de resultados con estrellas animadas y boton de reintentar

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
│   ├── recipe.gd              # Definicion de recetas
│   ├── level_layouts.gd       # Layouts de los 6 niveles
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
│   ├── game_state.gd          # Estado global (autoload)
│   └── physics_layers.gd      # Capas de fisica
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

---

## Creditos

**Assets:**
- Tiny Treats Bakery Interior 1.1 FREE por Quaternius
- KayKit Restaurant Bits 1.0 FREE por Kay Lousberg

**Motor:** Godot Engine 4.x / GDScript

---

Disfruta cocinando bajo presion!
