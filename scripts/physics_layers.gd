extends RefCounted
class_name PhysicsLayers

## Capas 3D (project.godot layer_names):
## 1 = world | 2 = stations | 3 = player | 4 = items

const WORLD := 1
const STATIONS := 2
const PLAYER := 4
const ITEMS := 8

const MASK_PLAYER := WORLD | STATIONS | ITEMS
const MASK_ITEM := WORLD | STATIONS
const MASK_INTERACT := STATIONS
