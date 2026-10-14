class_name GridEntity
extends Node2D
## Tâm mỗi ô cách nhau 32 pixel. Ô (0,0) có tâm tại (16,16).
const TILE := 32
@export var display_name := ""
@export var icon: Texture2D
func _ready() -> void:
	if icon:
		$Sprite2D.texture = icon
func get_cell() -> Vector2i:
	return Vector2i((position - Vector2(16, 16)) / TILE)
func move_to(cell: Vector2i) -> void:
	position = Vector2(cell * TILE) + Vector2(16, 16)
