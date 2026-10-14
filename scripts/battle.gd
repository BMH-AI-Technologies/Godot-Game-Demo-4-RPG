extends Node
## Một vòng: từng đồng đội còn sống hành động, rồi từng địch còn sống.
## Không dùng timer: một lần bấm chỉ giải quyết một hành động và cập nhật giao diện.
signal changed
var effects: Array[Dictionary] = []
var foes: Array[EnemyData] = []
var actor_index := 0
var round_number := 1
var active := false
var result := ""
var boss := false
var guards: Dictionary = {}
var history: Array[String] = []

func begin(templates: Array[EnemyData], is_boss: bool) -> void:
	effects.clear()
	foes.clear()
	for template in templates:
		foes.append(template.fresh())
	boss = is_boss
	round_number = 1
	actor_index = 0
	result = ""
	active = true
	guards.clear()
	history.clear()
	skip_fallen()
	log_line("Trận chiến bắt đầu!")
	changed.emit()

func log_line(message: String) -> void:
	history.append(message)
	if history.size() > 5:
		history.pop_front()

func living_allies() -> Array[int]:
	var indexes: Array[int] = []
	for i in range(Session.party.size()):
		if Session.party[i].hp > 0:
			indexes.append(i)
	return indexes

func skip_fallen() -> void:
	while actor_index < Session.party.size() and Session.party[actor_index].hp <= 0:
		actor_index += 1

func attack(target_index: int) -> void:
	effects.clear()
	if not active or target_index < 0 or target_index >= foes.size() or foes[target_index].hp <= 0:
		return
	var actor := Session.party[actor_index]
	var target := foes[target_index]
	var damage := maxi(1, actor.attack() - target.defense)
	target.hp = maxi(0, target.hp - damage)
	log_line("%s đánh %s: -%d HP." % [actor.display_name, target.display_name, damage])
	add_effect("hit", "ally", actor_index, "enemy", target_index, damage, target.hp, target.max_hp)
	end_action()

func guard() -> void:
	effects.clear()
	if not active:
		return
	var actor := Session.party[actor_index]
	guards[actor.id] = true
	log_line("%s phòng thủ đến hết vòng." % actor.display_name)
	add_effect("guard", "ally", actor_index, "ally", actor_index, 0, actor.hp, actor.max_hp)
	end_action()

func use_potion(ally_index: int) -> void:
	effects.clear()
	if not active or ally_index < 0 or ally_index >= Session.party.size():
		return
	var target := Session.party[ally_index]
	var previous_hp := target.hp
	if not Session.bag.use(Session.POTION, target):
		log_line("Không thể dùng bình: hết bình, đầy HP hoặc đồng đội đã gục.")
		changed.emit()
		return
	log_line("%s hồi máu cho %s." % [Session.party[actor_index].display_name, target.display_name])
	add_effect("heal", "ally", actor_index, "ally", ally_index, target.hp - previous_hp, target.hp, target.max_hp)
	end_action()

func flee() -> void:
	effects.clear()
	if active and not boss:
		active = false
		result = "fled"
		log_line("Cả đội rút lui an toàn.")
		changed.emit()

func end_action() -> void:
	var any_alive := false
	for foe in foes:
		if foe.hp > 0:
			any_alive = true
	if not any_alive:
		active = false
		result = "victory"
		# Đồng đội gục đứng dậy với 1 HP khi thắng, chưa được hồi đầy.
		for member in Session.party:
			member.hp = maxi(1, member.hp)
		log_line("Chiến thắng! Nhận một bình hồi máu.")
		changed.emit()
		return
	actor_index += 1
	skip_fallen()
	if actor_index >= Session.party.size():
		enemy_turn()
	changed.emit()

func enemy_turn() -> void:
	for i in range(foes.size()):
		var foe := foes[i]
		if foe.hp <= 0:
			continue
		var alive := living_allies()
		if alive.is_empty():
			break
		var target := Session.party[alive[(round_number + i - 1) % alive.size()]]
		var damage := maxi(1, foe.attack - target.defense())
		if guards.has(target.id):
			damage = maxi(1, int(ceil(damage / 2.0)))
		target.hp = maxi(0, target.hp - damage)
		log_line("%s đánh %s: -%d HP." % [foe.display_name, target.display_name, damage])
		add_effect("hit", "enemy", i, "ally", Session.party.find(target), damage, target.hp, target.max_hp)
	guards.clear()
	if living_allies().is_empty():
		active = false
		result = "defeat"
		log_line("Đội đã gục. Người dân sẽ đưa bạn về làng.")
		return
	round_number += 1
	actor_index = 0
	skip_fallen()

func add_effect(kind: String, from_side: String, from_index: int, side: String,
		index: int, amount: int, hp: int, max_hp: int) -> void:
	# UI phát lần lượt danh sách này. Không đặt Tween/ảnh vào luật chiến đấu.
	effects.append({"kind": kind, "from_side": from_side, "from": from_index,
		"side": side, "index": index, "amount": amount, "hp": hp,
		"max_hp": max_hp, "message": history.back()})
