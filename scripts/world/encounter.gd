class_name Encounter
extends GridEntity
## Chạm ô quái vật để vào trận. Mỗi quái ngoài bản đồ chỉ đánh một lần.
@export var foes: Array[EnemyData] = []
@export var boss := false
@export var reward: RPGItem
