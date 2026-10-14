class_name Inventory
extends RefCounted
## Túi chung của cả đội. counts lưu số lượng chưa được trang bị.
var items: Dictionary = {}
var counts: Dictionary = {}

func add(item: RPGItem, amount: int = 1) -> void:
	if amount <= 0:
		return
	items[item.id] = item
	counts[item.id] = count(item.id) + amount

func count(id: String) -> int:
	return int(counts.get(id, 0))

func remove(id: String) -> bool:
	if count(id) == 0:
		return false
	counts[id] -= 1
	return true

func use(item: Consumable, target: PartyMember) -> bool:
	if count(item.id) == 0 or not item.use(target):
		return false
	remove(item.id)
	return true

func equip(item: Equipment, target: PartyMember) -> bool:
	if count(item.id) == 0:
		return false
	var previous: Equipment = target.get(item.slot)
	remove(item.id)
	target.set(item.slot, item)
	if previous:
		add(previous)
	return true

func unequip(slot: String, target: PartyMember) -> bool:
	var item: Equipment = target.get(slot)
	if item == null:
		return false
	target.set(slot, null)
	add(item)
	return true
