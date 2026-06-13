extends RefCounted
class_name BakeryMaterials

const CREAM := Color(0.95, 0.86, 0.68)
const CREAM_LIGHT := Color(1.0, 0.94, 0.79)
const BEIGE := Color(0.78, 0.63, 0.43)
const WOOD := Color(0.56, 0.34, 0.18)
const WOOD_DARK := Color(0.31, 0.18, 0.11)
const CHOCOLATE := Color(0.25, 0.13, 0.08)
const PASTEL_PINK := Color(1.0, 0.58, 0.66)
const PASTEL_BLUE := Color(0.42, 0.72, 0.86)
const PASTEL_GREEN := Color(0.48, 0.78, 0.58)
const PASTEL_YELLOW := Color(1.0, 0.78, 0.28)
const FLOUR := Color(0.94, 0.89, 0.78)
const LEAF := Color(0.28, 0.58, 0.32)
const BLACKBOARD := Color(0.08, 0.18, 0.15)


static func make(color: Color, roughness: float = 0.78, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color * emission
	return mat


static func wood() -> StandardMaterial3D:
	return make(WOOD, 0.82)


static func dark_wood() -> StandardMaterial3D:
	return make(WOOD_DARK, 0.86)


static func cream() -> StandardMaterial3D:
	return make(CREAM, 0.88)


static func flour() -> StandardMaterial3D:
	return make(FLOUR, 0.92)
