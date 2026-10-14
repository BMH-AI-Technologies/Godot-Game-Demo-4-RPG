extends Control
## Chỉ hiển thị trận đấu; luật chiến đấu nằm trong battle.gd.
signal continue_requested
signal defeated
signal action_denied
var battle: Node
var target := 0
var busy := false
@onready var effects = $CombatEffects

func setup(system: Node) -> void:
	battle = system
	battle.changed.connect(render)
	for i in range(3):
		get_node("Enemy%d" % i).pressed.connect(select_target.bind(i))
	%Attack.pressed.connect(perform.bind("attack"))
	%Guard.pressed.connect(perform.bind("guard"))
	%Potion.pressed.connect(perform.bind("potion"))
	%Flee.pressed.connect(perform.bind("flee"))
	%Continue.pressed.connect(func():
		if not busy:
			continue_requested.emit())

func open() -> void:
	busy = false
	target = 0
	%AllyTarget.clear()
	for member in Session.party:
		%AllyTarget.add_item(member.display_name)
	%AllyTarget.select(0)
	show()
	render()

func select_target(index: int) -> void:
	if busy:
		return
	target = index
	render()

func render() -> void:
	if busy or battle == null or battle.foes.is_empty():
		return
	if target >= battle.foes.size() or battle.foes[target].hp <= 0:
		for i in range(battle.foes.size()):
			if battle.foes[i].hp > 0:
				target = i
				break
	for i in range(3):
		var button: Button = get_node("Enemy%d" % i)
		var picture: TextureRect = get_node("EnemyPortrait%d" % i)
		button.visible = i < battle.foes.size()
		picture.visible = button.visible
		get_node("EnemyCard%d" % i).visible = button.visible
		var enemy_bar: ProgressBar = get_node("EnemyHP%d" % i)
		enemy_bar.visible = button.visible
		if button.visible:
			var foe: EnemyData = battle.foes[i]
			var marker := "◆ " if battle.active and target == i else ""
			button.text = "%s%s\nHP %d / %d" % [marker, foe.display_name, foe.hp, foe.max_hp]
			enemy_bar.max_value = foe.max_hp
			enemy_bar.value = foe.hp
			button.disabled = not battle.active or foe.hp <= 0
			button.add_theme_stylebox_override("normal", theme.get_stylebox("pressed" if target == i else "normal", "Button"))
			picture.texture = foe.portrait
			picture.modulate = Color.WHITE if foe.hp > 0 else Color(0.4, 0.4, 0.4)
		var ally_label: Label = get_node("Ally%d" % i)
		var ally_picture: TextureRect = get_node("AllyPortrait%d" % i)
		ally_label.visible = i < Session.party.size()
		ally_picture.visible = ally_label.visible
		var card: Panel = get_node("AllyCard%d" % i)
		card.visible = ally_label.visible
		card.theme_type_variation = &"ActiveCard" if battle.active and battle.actor_index == i else &"CardPanel"
		var ally_bar: ProgressBar = get_node("AllyHP%d" % i)
		ally_bar.visible = ally_label.visible
		if ally_label.visible:
			var member := Session.party[i]
			var marker := "▶ " if battle.active and battle.actor_index == i else ""
			ally_label.text = "%s%s\n%d / %d HP" % [marker, member.display_name, member.hp, member.max_hp]
			ally_bar.max_value = member.max_hp
			ally_bar.value = member.hp
			ally_picture.texture = member.portrait
			ally_picture.modulate = Color.WHITE if member.hp > 0 else Color(0.4, 0.4, 0.4)
	%Log.text = "\n".join(battle.history)
	%Turn.text = "Vòng %d  •  Lượt %s" % [battle.round_number, Session.party[battle.actor_index].display_name] if battle.active else {"victory": "CHIẾN THẮNG", "defeat": "ĐỘI ĐÃ GỤC", "fled": "RÚT LUI"}[battle.result]
	for button in [%Attack, %Guard, %Potion, %Flee]:
		button.visible = battle.active
		button.disabled = false
	%AllyTarget.visible = battle.active
	%AllyTarget.disabled = false
	%Continue.disabled = false
	%PotionLabel.visible = battle.active
	%Potion.disabled = Session.bag.count("potion") == 0
	%Potion.text = "Bình máu ×%d" % Session.bag.count("potion")
	%Flee.disabled = battle.boss
	%Continue.visible = not battle.active and battle.result != "defeat"

func lock_buttons() -> void:
	for button in [%Attack, %Guard, %Potion, %Flee, %AllyTarget, %Continue]:
		button.disabled = true
	for i in range(3):
		get_node("Enemy%d" % i).disabled = true

func perform(action: String) -> void:
	# Khóa nút trước khi tính lượt: bấm nhanh không gây nhiều đòn cùng lúc.
	if busy or not battle.active:
		return
	busy = true
	lock_buttons()
	match action:
		"attack": battle.attack(target)
		"guard": battle.guard()
		"potion": battle.use_potion(%AllyTarget.selected)
		"flee": battle.flee()
	if battle.active and battle.effects.is_empty():
		action_denied.emit()
	var lines: Array[String] = []
	for event in battle.effects:
		show_event_state(event)
		lines.append(event.message)
		if lines.size() > 5:
			lines.pop_front()
		%Log.text = "\n".join(lines)
		await effects.play_event(event, self)
	busy = false
	render()
	if not battle.active:
		busy = true
		lock_buttons()
		await effects.celebrate(self, battle.result == "victory")
		busy = false
		render()
		if battle.result == "defeat":
			defeated.emit()

func show_event_state(event: Dictionary) -> void:
	var actor_name: String = Session.party[event.from].display_name if event.from_side == "ally" else battle.foes[event.from].display_name
	%Turn.text = "Hành động: " + actor_name
	for i in range(3):
		get_node("AllyCard%d" % i).theme_type_variation = &"ActiveCard" if event.from_side == "ally" and event.from == i else &"CardPanel"
	if event.side == "enemy":
		var foe: EnemyData = battle.foes[event.index]
		get_node("Enemy%d" % event.index).text = "%s\nHP %d / %d" % [foe.display_name, event.hp, event.max_hp]
	else:
		var member: PartyMember = Session.party[event.index]
		get_node("Ally%d" % event.index).text = "%s\n%d / %d HP" % [member.display_name, event.hp, event.max_hp]
