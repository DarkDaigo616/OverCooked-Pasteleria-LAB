# Overcooked Style Game - Proyecto Godot

**Version:** 0.4.0

## Descripcion

Juego de pasteleria estilo Overcooked creado en Godot 4.x. Controlas a un chef que debe completar ordenes de pasteles antes de que se acabe el tiempo, gestionando ingredientes, mezcla, horneado y decoracion.

## Controles

- **Click izquierdo**: Mover al chef / interactuar con estaciones
- **E o Espacio**: Interactuar con estaciones
- **Q**: Soltar objeto que llevas en mano
- **Escape**: Pausar / Menu

---

## Niveles

### Nivel 1 — Introduccion
Familiarizate con el flujo basico: toma masa pre-mezclada, hornea y entrega.

**Receta:** Pastel horneado (100 pts, 60s)

---

### Nivel 2 — Cadena de Receta
Prepara la receta desde cero: mezcla harina + huevo + azucar, hornea y decora.

**Receta:** Pastel de vainilla — harina + huevo + azucar → mezcla → horno → decorar (160 pts, 90s)

---

### Nivel 3 — Presion de Tiempo  _(Etapa 4)_
Gestiona hasta **3 pedidos simultaneos** con temporizadores independientes. Decide que orden atender primero: la mas rapida, la mas urgente o la de mayor puntuacion.

**Recetas disponibles:**

| Pedido | Ingredientes | Complejidad | Puntos | Tiempo |
|--------|-------------|-------------|--------|--------|
| Pastel simple | harina + huevo → hornear | Sencillo | 80 | 60s |
| Pastel de chocolate | harina + huevo → hornear → decorar (chocolate) | Medio | 150 | 90s |
| Pastel con fresa | harina + huevo → hornear → decorar (fresa) | Medio | 150 | 90s |

**Sistema de puntuacion:**
- **Bonus de velocidad** (+50%): Si entregas con mas del 50% del tiempo restante
- **Penalizacion por demora** (-75 pts): Si un pedido expira sin ser entregado
- La decision de que pedido atender primero es el reto central del nivel

**Indicadores visuales en el panel de pedidos:**
- Barra de urgencia: verde → naranja → rojo segun el tiempo restante
- Badge de complejidad: S (sencillo, verde) / CH / FR (medio, segun tipo)
- Preview del bonus de velocidad visible en cada tarjeta de pedido

---

## Cadena de preparacion (Niveles 2 y 3)

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
│   ├── chef_player.gd         # Movimiento e interaccion del chef
│   ├── game_manager.gd        # Coordinador principal
│   ├── game_hud.gd            # Interfaz: pedidos, timer, puntos
│   ├── order_manager.gd       # Pedidos, timers, bonus/penalizacion
│   ├── recipe.gd              # Definicion de recetas
│   ├── level_layouts.gd       # Layouts de los 3 niveles
│   ├── kitchen_level.gd       # Carga y construccion del nivel
│   ├── station_factory.gd     # Construccion de estaciones
│   ├── station_base.gd        # Base para todas las estaciones
│   ├── ingredient_station.gd  # Estacion de ingredientes
│   ├── mixing_station.gd      # Batidora
│   ├── cooking_station.gd     # Horno
│   ├── decoration_station.gd  # Decoracion (vainilla/chocolate/fresa)
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
| 0.4.0 | Etapa 4 | Panel de pedidos con timers, puntuacion, bonus/penalizacion, Nivel 3 con 3 recetas simultaneas y decision de prioridad |

---

## Creditos

**Assets:**
- Tiny Treats Bakery Interior 1.1 FREE por Quaternius
- KayKit Restaurant Bits 1.0 FREE por Kay Lousberg

**Motor:** Godot Engine 4.x / GDScript

---

Disfruta cocinando bajo presion!
