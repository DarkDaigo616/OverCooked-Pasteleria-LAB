# 🚀 GUÍA DE INICIO RÁPIDO

## ⚡ Comenzar en 3 Pasos

### 1️⃣ Instala Godot
- Descarga Godot 4.2: https://godotengine.org/download
- No necesitas instalar, solo ejecuta el .exe (Windows) o equivalente

### 2️⃣ Abre el Proyecto
1. Ejecuta Godot
2. Click en **"Importar"**
3. Busca la carpeta `OvercookedGame`
4. Selecciona `project.godot`
5. Click **"Importar y Editar"**

### 3️⃣ ¡Juega!
- Presiona **F5** o click en el botón **Play ▶️** (arriba a la derecha)

---

## 🎮 Controles Básicos

| Tecla | Acción |
|-------|--------|
| **Click izquierdo** | Mover al punto clickeado |
| **E** o **Espacio** | Interactuar |
| **Q** | Soltar objeto |

---

## 📖 Tutorial Rápido de Juego

### Paso 1: Toma un Plato
- Ve a la estación "PLATOS" (centro-derecha)
- Presiona **E** para tomar un plato vacío

### Paso 2: Recolecta Ingredientes
- Ve a las estaciones de ingredientes (izquierda):
  - TOMATES (rojo)
  - LECHUGA (verde)
  - CARNE (café)
  - PAN (amarillo)
- Presiona **E** para tomar ingredientes

### Paso 3: Procesa Ingredientes
- **Para Cortar**: 
  - Lleva ingrediente a "CORTAR"
  - Presiona **E** para colocar
  - Mantén **E** presionado para cortar
  - Presiona **E** para recoger
  
- **Para Cocinar**:
  - Lleva ingrediente a "COCINAR"
  - Presiona **E** para colocar
  - Espera (automático)
  - Presiona **E** para recoger (¡antes de que se queme!)

### Paso 4: Ensambla el Plato
- Ve a "ENSAMBLAR" con tu plato
- Presiona **E** para colocar el plato
- Trae ingredientes y presiona **E** para agregarlos
- Toma el plato completo con **E**

### Paso 5: Entrega
- Ve a "ENTREGAR" (derecha)
- Presiona **E** para entregar
- Si coincide con una orden, ¡ganas puntos!

---

## 🎯 Ejemplo: Ensalada Fresca (100 puntos)

```
1. Toma PLATO
2. Toma LECHUGA → llévala a CORTAR → córtala
3. Toma TOMATE → llévalo a CORTAR → córtalo
4. Lleva PLATO a ENSAMBLAR
5. Agrega LECHUGA cortada al plato
6. Agrega TOMATE cortado al plato
7. Toma el plato y llévalo a ENTREGAR
8. ¡+100 puntos!
```

---

## ⚠️ Importante

- Tienes **3 MINUTOS** para completar el máximo de órdenes
- Las órdenes aparecen en el panel superior izquierdo
- Cada orden tiene un temporizador - ¡no las dejes expirar!
- La comida se QUEMA si la dejas cocinando mucho tiempo
- Solo puedes llevar 1 objeto a la vez

---

## 🏆 Recetas Completas

### Ensalada Fresca (100 pts)
- Lechuga (cortada)
- Tomate (cortado)

### Tomate Asado (80 pts)
- Tomate (cocido)

### Hamburguesa Simple (150 pts)
- Pan (crudo)
- Carne (cocida)
- Lechuga (cruda)

### Hamburguesa Deluxe (250 pts)
- Pan (crudo)
- Carne (cocida)
- Lechuga (cortada)
- Tomate (cortado)

---

## 💡 Tips Pro

1. **Lee las órdenes primero** - Planifica antes de empezar
2. **Cocina con anticipación** - Puedes preparar carne mientras cortas otras cosas
3. **Cuidado con los tiempos** - No dejes carne cocinando sin supervisión
4. **Haz clicks precisos** - Ahorra tiempo entre estaciones
5. **Prioriza órdenes urgentes** - Las que tienen poco tiempo primero

---

## 🎨 Personalización (Opcional)

### Agregar Modelos 3D Reales

1. Descarga los assets:
   - **Restaurante**: https://kaylousberg.itch.io/restaurant-bits
   - **Chef**: https://brickle-pickle.itch.io/chef-3d-character

2. Colócalos en `assets/models/`

3. En Godot:
   - Abre las escenas de estaciones
   - Reemplaza los cubos con los modelos descargados
   - Ajusta tamaños y posiciones

### Modificar Dificultad

En el editor de Godot:
1. Abre `kitchen_level.tscn`
2. Selecciona `GameManager/OrderManager`
3. En el Inspector (derecha), modifica:
   - **Max Orders**: Cuántas órdenes simultáneas (default: 3)
   - **Order Spawn Interval**: Cada cuántos segundos nueva orden (default: 25)
   - **Base Prep Time**: Segundos para completar (default: 90)

4. Selecciona `GameManager/GameHUD`
5. Modifica:
   - **Game Time**: Duración total en segundos (default: 180 = 3 min)

---

## 🆘 Ayuda

**¿No puedes interactuar con nada?**
- Acércate más a la estación
- Asegúrate de presionar E (no mantener, solo presionar una vez)

**¿Los ingredientes no aparecen?**
- Es normal, en esta versión básica son esferas de colores
- Puedes agregar modelos 3D después

**¿El juego va muy lento?**
- Baja la calidad gráfica en Godot
- Cierra otras aplicaciones

**¿Quieres reiniciar?**
- Presiona F5 cuando termine el tiempo

---

¡Ahora estás listo para cocinar! 👨‍🍳

**¿Preguntas?** Revisa el README.md completo para más detalles.
