# 🍳 Overcooked Style Game - Proyecto Godot

## 📋 Descripción
Este es un juego estilo Overcooked creado en Godot 4.x donde controlas a un chef que debe completar órdenes de comida antes de que se acabe el tiempo.

## 🎮 Controles
- **WASD o Flechas**: Mover al chef
- **E o Espacio**: Interactuar con estaciones
- **Shift**: Correr
- **Q**: Soltar objeto que llevas en mano

## 🎯 Cómo Jugar

### Objetivo
Completa el máximo número de órdenes posibles en 3 minutos para obtener la mayor puntuación.

### Mecánicas Básicas

1. **Recoger Ingredientes**
   - Ve a las estaciones de ingredientes (Tomate, Lechuga, Carne, Pan)
   - Presiona E para tomar un ingrediente

2. **Procesar Ingredientes**
   - **Cortar**: Coloca ingredientes crudos en la tabla de cortar, mantén E presionado
   - **Cocinar**: Coloca ingredientes en la estufa y espera (¡cuidado que no se quemen!)

3. **Ensamblar Platos**
   - Toma un plato de la estación de platos
   - Llévalo a la mesa de ensamblaje
   - Agrega los ingredientes según la orden

4. **Entregar**
   - Lleva el plato completo a la ventana de entrega
   - Si coincide con una orden activa, ¡ganas puntos!

### Recetas Disponibles

**Hamburguesa Simple** (150 puntos)
- Pan (crudo)
- Carne (cocida)
- Lechuga (cruda)

**Ensalada Fresca** (100 puntos)
- Lechuga (cortada)
- Tomate (cortado)

**Tomate Asado** (80 puntos)
- Tomate (cocido)

**Hamburguesa Deluxe** (250 puntos)
- Pan (crudo)
- Carne (cocida)
- Lechuga (cortada)
- Tomate (cortado)

## 🛠️ Instalación

### Requisitos
- Godot Engine 4.2 o superior

### Pasos

1. **Descarga e instala Godot**
   - Ve a https://godotengine.org/download
   - Descarga Godot 4.2 o superior
   - Instala o extrae el ejecutable

2. **Abre el Proyecto**
   - Abre Godot
   - Click en "Importar"
   - Navega a la carpeta del proyecto
   - Selecciona el archivo `project.godot`
   - Click en "Importar y Editar"

3. **Ejecuta el Juego**
   - Presiona F5 o click en el botón "Play" ▶️
   - ¡Disfruta!

## 📁 Estructura del Proyecto

```
OvercookedGame/
├── project.godot          # Configuración del proyecto
├── scripts/               # Todos los scripts GDScript
│   ├── chef_player.gd
│   ├── station_base.gd
│   ├── ingredient_station.gd
│   ├── chopping_station.gd
│   ├── cooking_station.gd
│   ├── plate_station.gd
│   ├── assembly_station.gd
│   ├── delivery_window.gd
│   ├── recipe.gd
│   ├── order_manager.gd
│   ├── game_manager.gd
│   └── game_hud.gd
├── scenes/                # Escenas del juego
│   ├── player/
│   │   └── chef_player.tscn
│   ├── stations/
│   │   └── ingredient_station.tscn
│   └── levels/
│       └── kitchen_level.tscn
└── assets/                # Carpeta para tus assets 3D
    ├── models/
    ├── textures/
    └── sounds/
```

## 🎨 Personalización

### Agregar Assets 3D

1. **Modelos del Restaurante (KayKit)**
   - Descarga: https://kaylousberg.itch.io/restaurant-bits
   - Extrae los archivos .gltf o .fbx
   - Cópialos a `assets/models/`
   - En Godot, arrastra los modelos a las estaciones correspondientes

2. **Modelo del Chef**
   - Descarga: https://brickle-pickle.itch.io/chef-3d-character
   - Extrae Chef.fbx
   - Cópialo a `assets/models/`
   - En la escena chef_player.tscn, reemplaza el MeshInstance3D con el modelo del chef

### Modificar Parámetros

Puedes ajustar los siguientes valores en el editor:

**En OrderManager:**
- `max_orders`: Máximo de órdenes simultáneas
- `order_spawn_interval`: Cada cuántos segundos aparece una nueva orden
- `base_prep_time`: Tiempo para completar cada orden

**En GameHUD:**
- `game_time`: Duración total del juego (en segundos)

**En ChefPlayer:**
- `speed`: Velocidad de movimiento normal
- `sprint_speed`: Velocidad al correr

**En CookingStation:**
- `cook_time`: Tiempo para cocinar
- `burn_time`: Tiempo extra antes de quemarse

**En ChoppingStation:**
- `chop_duration`: Tiempo para cortar

## 🐛 Solución de Problemas

### El juego no inicia
- Asegúrate de tener Godot 4.2 o superior
- Verifica que importaste el proyecto correctamente

### Los ingredientes no se ven
- Esto es normal en la versión básica
- Los ingredientes se muestran como esferas de colores
- Puedes reemplazarlos con los modelos 3D descargados

### Las interacciones no funcionan
- Asegúrate de estar cerca de la estación
- Presiona E o Espacio para interactuar
- Verifica que la estación tenga el grupo "interactable"

### El tiempo no aparece
- Revisa que la escena kitchen_level.tscn esté configurada como escena principal
- Ve a Proyecto > Configuración del Proyecto > Application > Run > Main Scene

## 💡 Tips y Trucos

1. **Organización es clave**: Planifica qué ingredientes necesitas antes de empezar
2. **Usa el sprint**: Shift te permite moverte más rápido entre estaciones
3. **Atención a los temporizadores**: No dejes comida cocinando sin supervisión
4. **Prioriza órdenes**: Completa primero las que están por vencer
5. **Prepara con anticipación**: Puedes cortar ingredientes antes de que llegue la orden

## 🚀 Mejoras Futuras Sugeridas

- [ ] Agregar sonidos y música
- [ ] Implementar animaciones del chef
- [ ] Añadir más recetas
- [ ] Sistema de niveles con dificultad creciente
- [ ] Modo multijugador local
- [ ] Power-ups y bonificaciones
- [ ] Más tipos de estaciones (lavado, horno, parrilla)
- [ ] Sistema de estrellas según puntuación

## 📝 Créditos

**Assets Utilizados:**
- KayKit Restaurant Bits por Kay Lousberg
- Chef Character por Brickle Pickle

**Creado con:**
- Godot Engine 4.x
- GDScript

## 📄 Licencia

Este proyecto es educativo y de código abierto. 
Los assets de terceros mantienen sus licencias originales (CC0 para KayKit).

---

## 🎓 Notas para Desarrollo

Este proyecto fue creado como base educativa. Algunas características están simplificadas:

- **Modelos Placeholder**: Se usan formas geométricas básicas en lugar de modelos 3D complejos
- **Sin Audio**: No hay sonidos ni música implementados
- **UI Básica**: La interfaz es funcional pero minimalista
- **Sin Persistencia**: No se guardan puntuaciones ni progreso

**Para mejorar el proyecto:**
1. Reemplaza los modelos placeholder con los assets descargados
2. Agrega música de fondo y efectos de sonido
3. Mejora la UI con sprites personalizados
4. Implementa un sistema de guardado

---

¡Diviértete cocinando! 👨‍🍳🍔🥗
