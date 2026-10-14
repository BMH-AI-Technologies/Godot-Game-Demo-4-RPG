class_name RPGMap
extends Node2D
@export var map_id := ""
@export var display_name := ""
@export var width := 24
@export var height := 16
@onready var ground: TileMapLayer = $Ground
@onready var entities: Node2D = $Entities

func is_blocked(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	var data := ground.get_cell_tile_data(cell)
	return data == null or bool(data.get_custom_data("blocked"))

func entity_at(cell: Vector2i) -> GridEntity:
	for entity in entities.get_children():
		if entity.visible and entity.get_cell() == cell:
			return entity
	return null

func object_id(entity: GridEntity) -> String:
	return map_id + "/" + str(entity.name)

func exit_at(cell: Vector2i) -> MapPortal:
	# Cả mép đường là lối ra, không chỉ riêng ô có biển chỉ dẫn.
	if is_blocked(cell):
		return null
	for entity in entities.get_children():
		if not entity is MapPortal:
			continue
		var sign_cell: Vector2i = entity.get_cell()
		if cell == sign_cell:
			return entity
		if sign_cell.x == 0 and cell.x == 0:
			return entity
		if sign_cell.x == width - 1 and cell.x == width - 1:
			return entity
		if sign_cell.y == 0 and cell.y == 0:
			return entity
		if sign_cell.y == height - 1 and cell.y == height - 1:
			return entity
	return null
