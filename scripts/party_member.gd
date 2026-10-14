class_name PartyMember
extends Resource
## Dữ liệu nhân vật. Khi gia nhập đội, tạo bản sao để không sửa file mẫu.
@export var id := ""
@export var display_name := ""
@export var portrait: Texture2D
@export var walk_frames: SpriteFrames
@export var max_hp := 36
@export var base_attack := 8
@export var base_defense := 2
var hp := 0
var weapon: Equipment
var armor: Equipment

func fresh() -> PartyMember:
	var member: PartyMember = duplicate()
	member.hp = max_hp
	member.weapon = null
	member.armor = null
	return member

func attack() -> int:
	return base_attack + (weapon.attack_bonus if weapon else 0) + (armor.attack_bonus if armor else 0)

func defense() -> int:
	return base_defense + (weapon.defense_bonus if weapon else 0) + (armor.defense_bonus if armor else 0)

func equipment_name(slot: String) -> String:
	var item: Equipment = get(slot)
	return item.item_name if item else "Chưa có"
