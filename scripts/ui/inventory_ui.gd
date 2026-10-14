extends Control
## Giao diện túi đồ gọi các phương thức của Inventory, không tính chỉ số tại đây.
signal closed
signal healed
signal opened
signal equipped
signal unequipped
signal denied
var ids: Array[String] = []
var selected := 0

func _ready() -> void:
	%Close.pressed.connect(close)
	%Members.item_selected.connect(func(_index): render_details())
	%Items.item_selected.connect(select_item)
	%Use.pressed.connect(use_selected)
	%RemoveWeapon.pressed.connect(unequip.bind("weapon"))
	%RemoveArmor.pressed.connect(unequip.bind("armor"))

func open() -> void:
	show()
	%Members.clear()
	for member in Session.party:
		%Members.add_item(member.display_name)
	%Members.select(0)
	%Feedback.text = "Chọn một vật phẩm và người sử dụng."
	refresh()
	opened.emit()

func selected_item() -> RPGItem:
	if ids.is_empty():
		return null
	return Session.bag.items[ids[selected]]

func refresh() -> void:
	ids.clear()
	%Items.clear()
	for id in Session.bag.items:
		if Session.bag.count(id) > 0:
			ids.append(id)
			var item: RPGItem = Session.bag.items[id]
			%Items.add_item("%s  ×%d" % [item.item_name, Session.bag.count(id)], item.icon)
	selected = clampi(selected, 0, maxi(0, ids.size() - 1))
	if not ids.is_empty():
		%Items.select(selected)
	render_details()

func select_item(index: int) -> void:
	selected = index
	render_details()

func render_details() -> void:
	var member := Session.party[%Members.selected]
	%Portrait.texture = member.portrait
	%Stats.text = "%s\nHP %d / %d   |   ATK %d   DEF %d\nVũ khí: %s\nGiáp: %s" % [
		member.display_name, member.hp, member.max_hp, member.attack(), member.defense(),
		member.equipment_name("weapon"), member.equipment_name("armor")]
	%RemoveWeapon.disabled = member.weapon == null
	%RemoveArmor.disabled = member.armor == null
	var item := selected_item()
	%Use.disabled = item == null
	%ItemIcon.texture = item.icon if item else null
	%Description.text = item.item_name + "\n" + item.description if item else "Túi đồ trống."
	%Use.text = "Trang bị" if item is Equipment else "Dùng vật phẩm"

func use_selected() -> void:
	var item := selected_item()
	var member := Session.party[%Members.selected]
	if item is Consumable:
		var used := Session.bag.use(item, member)
		if used:
			healed.emit()
		else:
			denied.emit()
		%Feedback.text = "Đã hồi máu." if used else "Chỉ hồi máu cho người còn sống và chưa đầy HP."
	elif item is Equipment:
		if Session.bag.equip(item, member):
			equipped.emit()
			%Feedback.text = "Đã trang bị. Đồ cũ được trả về túi."
		else:
			denied.emit()
	refresh()

func unequip(slot: String) -> void:
	if Session.bag.unequip(slot, Session.party[%Members.selected]):
		unequipped.emit()
		%Feedback.text = "Đã cất trang bị vào túi."
	else:
		denied.emit()
	refresh()

func close() -> void:
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("inventory") or event.is_action_pressed("cancel")):
		close()
		get_viewport().set_input_as_handled()
