class_name EnemyData
extends Resource
## Mẫu quái vật dùng trong trận đấu; mỗi trận dùng bản sao có HP riêng.
@export var display_name := ""
@export var portrait: Texture2D
@export var max_hp := 20
@export var attack := 6
@export var defense := 1
var hp := 0

func fresh() -> EnemyData:
	var enemy: EnemyData = duplicate()
	enemy.hp = max_hp
	return enemy
