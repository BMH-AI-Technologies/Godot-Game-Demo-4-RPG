extends Node2D
signal party_recovered
## Điều phối các hệ thống nhỏ. Bản đồ và đối tượng đều là scene sửa được trong editor.
enum Mode { EXPLORE, DIALOGUE, INVENTORY, BATTLE, SETTINGS, DEFEAT }
var mode := Mode.EXPLORE
var mode_before_settings := Mode.EXPLORE
var current_map: RPGMap
var dialogue_npc: TownNPC
var encounter: Encounter
var trail: Array[Vector2i] = []
@onready var player = $World/Player
@onready var prompt = $World/InteractionPrompt
@onready var battle = $Battle
@onready var dialogue = $UI/Screen/Dialogue
@onready var inventory_ui = $UI/Screen/Inventory
@onready var battle_ui = $UI/Screen/BattleUI
@onready var settings_ui = $UI/Screen/Settings
@onready var defeat_ui = $UI/Screen/Defeat

func _ready() -> void:
	player.move_requested.connect(try_move)
	player.interact_requested.connect(interact)
	player.inventory_requested.connect(open_inventory)
	%BagButton.pressed.connect(open_inventory)
	%SettingsButton.pressed.connect(open_settings)
	settings_ui.closed.connect(close_settings)
	settings_ui.reset_requested.connect(reset_game)
	defeat_ui.respawn_requested.connect(respawn)
	dialogue.closed.connect(resume_exploration)
	dialogue.action_requested.connect(dialogue_action)
	inventory_ui.closed.connect(resume_exploration)
	battle_ui.setup(battle)
	battle_ui.continue_requested.connect(end_battle)
	battle_ui.defeated.connect(show_defeat)
	load_map("village", Vector2i(11, 11))
	set_status("Nói chuyện với dân làng để tìm bạn đồng hành.")

func set_mode(value: Mode) -> void:
	mode = value
	player.active = mode == Mode.EXPLORE
	update_prompt()

func load_map(id: String, spawn: Vector2i) -> void:
	if is_instance_valid(current_map):
		$World.remove_child(current_map)
		current_map.queue_free()
	var scene: PackedScene = load("res://scenes/maps/" + id + ".tscn")
	current_map = scene.instantiate()
	$World.add_child(current_map)
	player.move_to(spawn)
	player.get_node("Camera2D").fit_map(Vector2i(current_map.width, current_map.height) * 32)
	trail.clear()
	for i in range(2):
		var follower: PartyWalker = get_node("World/Follower%d" % i)
		follower.move_to(spawn)
		follower.hide()
	for entity in current_map.entities.get_children():
		if Session.cleared.has(current_map.object_id(entity)):
			entity.hide()
		if entity is TownNPC and entity.companion and Session.has_member(entity.companion.id):
			entity.hide()
	%MapName.text = current_map.display_name
	refresh_party()
	set_status("Khám phá và tìm lại vương miện.")

func try_move(direction: Vector2i) -> void:
	if mode != Mode.EXPLORE or player.moving:
		return
	var destination: Vector2i = player.get_cell() + direction
	if current_map.is_blocked(destination):
		return
	var entity := current_map.entity_at(destination)
	if entity is Encounter:
		start_battle(entity)
		return
	if entity != null and not entity is MapPortal:
		update_prompt()
		return
	trail.push_front(player.get_cell())
	if trail.size() > 2:
		trail.pop_back()
	player.step_to(destination)
	move_followers()
	refresh_party()
	var exit_portal := current_map.exit_at(destination)
	if exit_portal:
		load_map(exit_portal.target_map, exit_portal.spawn)
		player.repeat_delay = 0.20

func interact() -> void:
	if mode != Mode.EXPLORE:
		return
	var entity := interaction_target()
	if entity is TownNPC:
		dialogue_npc = entity
		var action := ""
		if entity.companion and not Session.has_member(entity.companion.id):
			action = "Mời vào đội"
		elif entity.offers_rest:
			action = "Nghỉ ngơi"
		set_mode(Mode.DIALOGUE)
		dialogue.open(entity.display_name, entity.dialogue, action)
	elif entity is LootChest:
		Session.bag.add(entity.item, entity.amount)
		Session.cleared[current_map.object_id(entity)] = true
		entity.opened.emit()
		entity.hide()
		show_message("Rương báu", "Nhận %s ×%d." % [entity.item.item_name, entity.amount])
	elif entity is Encounter:
		start_battle(entity)
	elif entity is MapPortal:
		load_map(entity.target_map, entity.spawn)

func show_message(title: String, text: String) -> void:
	dialogue_npc = null
	set_mode(Mode.DIALOGUE)
	dialogue.open(title, text)

func dialogue_action() -> void:
	if not is_instance_valid(dialogue_npc):
		return
	if dialogue_npc.companion:
		if Session.recruit(dialogue_npc.companion):
			dialogue_npc.hide()
			set_status(dialogue_npc.display_name + " đã gia nhập đội!")
	elif dialogue_npc.offers_rest:
		Session.rest()
		party_recovered.emit()
		set_status("Cả đội đã hồi đầy HP.")
	dialogue.close()

func resume_exploration() -> void:
	dialogue_npc = null
	set_mode(Mode.EXPLORE)
	refresh_party()

func open_inventory() -> void:
	if mode != Mode.EXPLORE:
		return
	set_mode(Mode.INVENTORY)
	inventory_ui.open()

func start_battle(enemy: Encounter) -> void:
	if enemy.foes.is_empty():
		return
	encounter = enemy
	set_mode(Mode.BATTLE)
	battle.begin(enemy.foes, enemy.boss)
	battle_ui.open()

func end_battle() -> void:
	if battle.active:
		return
	battle_ui.hide()
	var result: String = battle.result
	if result == "victory":
		Session.cleared[current_map.object_id(encounter)] = true
		Session.bag.add(Session.POTION)
		if encounter.reward:
			Session.bag.add(encounter.reward)
		encounter.hide()
		if encounter.boss:
			Session.cleared["quest_complete"] = true
			show_message("Vương miện đã trở về",
				"Bạn và những người bạn đã đánh bại Kỵ sĩ Tro.\nLàng Bình Minh được bình yên. Bạn vẫn có thể khám phá, mở rương và thử trang bị khác.")
			refresh_party()
			return
		set_status("Chiến thắng! Nhận một bình máu và chiến lợi phẩm.")
	elif result == "defeat":
		show_defeat()
		return
	else:
		set_status("Đã rút lui. Bạn có thể quay lại trận này sau.")
	encounter = null
	resume_exploration()

func refresh_party() -> void:
	var parts: Array[String] = []
	for member in Session.party:
		parts.append("%s  %d/%d HP" % [member.display_name, member.hp, member.max_hp])
	%PartySummary.text = "    |    ".join(parts)
	%Objective.text = "Vương miện đã được thu hồi" if Session.cleared.has("quest_complete") else "Mục tiêu: tìm đồng đội và đến thành cổ"
	update_prompt()

func move_followers() -> void:
	for i in range(2):
		var follower: PartyWalker = get_node("World/Follower%d" % i)
		if i + 1 >= Session.party.size() or i >= trail.size():
			continue
		follower.sprite.sprite_frames = Session.party[i + 1].walk_frames
		if not follower.visible:
			follower.move_to(trail[i])
			follower.show()
		else:
			follower.step_to(trail[i])

func _process(_delta: float) -> void:
	update_prompt()

func interaction_target() -> GridEntity:
	var cell: Vector2i = player.get_cell()
	var directions: Array[Vector2i] = [player.facing, Vector2i.UP,
		Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for direction in directions:
		var entity := current_map.entity_at(cell + direction)
		if entity is TownNPC or entity is LootChest or entity is Encounter or entity is MapPortal:
			return entity
	return null

func update_prompt() -> void:
	if not is_instance_valid(current_map) or mode != Mode.EXPLORE or player.moving:
		prompt.hide()
		return
	var entity := interaction_target()
	if entity == null:
		prompt.hide()
		return
	var action := "[E] Nói chuyện"
	if entity is LootChest:
		action = "[E] Mở rương"
	elif entity is Encounter:
		action = "[E] Chiến đấu"
	elif entity is MapPortal:
		action = "Đi tiếp →" if entity.get_cell().x > 0 else "← Quay lại"
	elif entity.offers_rest:
		action = "[E] Nói chuyện / nghỉ ngơi"
	prompt.show_for(entity, action)

func set_status(message: String) -> void:
	%Status.text = message

func open_settings() -> void:
	if mode == Mode.SETTINGS:
		return
	mode_before_settings = mode
	set_mode(Mode.SETTINGS)
	settings_ui.open()
	get_tree().paused = true

func close_settings() -> void:
	get_tree().paused = false
	set_mode(mode_before_settings)

func reset_game() -> void:
	# Thay cả scene để mọi Tween, popup và trận cũ được dọn cùng nhau.
	Preferences.save_settings()
	Session.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func show_defeat() -> void:
	battle_ui.hide()
	set_mode(Mode.DEFEAT)
	defeat_ui.open()
	refresh_party()

func respawn() -> void:
	if mode != Mode.DEFEAT:
		return
	defeat_ui.hide()
	Session.recover_after_defeat()
	party_recovered.emit()
	encounter = null
	load_map("village", Vector2i(11, 11))
	resume_exploration()
	set_status("Cả đội đã hồi sinh. Nghỉ ngơi rồi tiếp tục cuộc phiêu lưu.")
