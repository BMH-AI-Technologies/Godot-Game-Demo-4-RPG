class_name Consumable
extends RPGItem
## Vật phẩm dùng một lần. Chỉ tiêu hao khi hồi máu thành công.
@export var healing := 24
func use(target: PartyMember) -> bool:
	if target.hp <= 0 or target.hp >= target.max_hp:
		return false
	target.hp = mini(target.max_hp, target.hp + healing)
	return true
