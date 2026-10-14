extends Node
## Autoload: dữ liệu phiên chơi tồn tại khi đổi bản đồ.
## Bản nhỏ này không có lưu game ra đĩa; đóng game sẽ bắt đầu lại.
const HERO = preload("res://data/party/athena.tres")
const POTION = preload("res://data/items/potion.tres")
const SWORD = preload("res://data/items/sword.tres")
const ARMOR = preload("res://data/items/armor.tres")
var party: Array[PartyMember] = []
var bag := Inventory.new()
var cleared: Dictionary = {}

func _ready() -> void:
	reset()

func reset() -> void:
	party.clear()
	party.append(HERO.fresh())
	bag = Inventory.new()
	bag.add(POTION, 4)
	bag.add(SWORD)
	bag.add(ARMOR)
	cleared.clear()

func has_member(id: String) -> bool:
	for member in party:
		if member.id == id:
			return true
	return false

func recruit(template: PartyMember) -> bool:
	if template == null or has_member(template.id) or party.size() >= 3:
		return false
	party.append(template.fresh())
	return true

func rest() -> void:
	for member in party:
		member.hp = member.max_hp

func recover_after_defeat() -> void:
	rest()
	# Luôn có ít nhất hai bình sau khi thua để tránh bị kẹt.
	bag.add(POTION, maxi(0, 2 - bag.count(POTION.id)))
