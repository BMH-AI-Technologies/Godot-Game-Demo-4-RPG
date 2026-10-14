class_name Equipment
extends RPGItem
## Trang bị giữ nguyên khi sử dụng, mỗi nhân vật có một vũ khí và một áo giáp.
@export_enum("weapon", "armor") var slot := "weapon"
@export var attack_bonus := 0
@export var defense_bonus := 0
