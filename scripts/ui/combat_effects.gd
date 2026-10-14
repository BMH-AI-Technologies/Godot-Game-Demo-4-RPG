extends Control
signal ally_attack_started
signal enemy_attack_started
signal hit_landed
signal healed
## Chỉ hiệu ứng: tiến lên đánh, chớp màu, rung nhẹ, số nổi và thanh HP.
## Mỗi hàm chờ Tween xong trước khi trả về; không tự thay đổi luật trận đấu.
const SWORD = preload("res://assets/icons/icon_9.tres")
const POTION = preload("res://assets/icons/icon_8.tres")
const ARMOR = preload("res://assets/icons/icon_10.tres")

func portrait(ui: Control, side: String, index: int) -> TextureRect:
	return ui.get_node("%sPortrait%d" % ["Ally" if side == "ally" else "Enemy", index])

func play_event(event: Dictionary, ui: Control) -> void:
	var source := portrait(ui, event.from_side, event.from)
	var target := portrait(ui, event.side, event.index)
	var source_home := source.position
	var target_home := target.position
	var target_color := target.modulate
	var center := target.position + target.size / 2.0
	var hit: bool = event.kind == "hit"
	if hit:
		if event.from_side == "ally":
			ally_attack_started.emit()
		else:
			enemy_attack_started.emit()
		var advance := Vector2(0, -18 if event.from_side == "ally" else 18)
		var windup := create_tween()
		windup.tween_property(source, "position", source_home + advance, 0.10)
		await windup.finished
		hit_landed.emit()
		var retreat := create_tween()
		retreat.tween_property(source, "position", source_home, 0.14)
	elif event.kind == "heal":
		healed.emit()

	$Impact.texture = SWORD if hit else (POTION if event.kind == "heal" else ARMOR)
	$Impact.position = center - $Impact.size / 2.0
	$Impact.rotation = -0.8 if hit else 0.0
	$Impact.scale = Vector2(0.6, 0.6)
	$Impact.modulate = Color.WHITE
	$Impact.show()
	var words := "-%d" % event.amount if hit else ("+%d HP" % event.amount if event.kind == "heal" else "PHÒNG THỦ")
	var tint := Color("ffdbad") if hit else (Color("aef7a0") if event.kind == "heal" else Color("a5ddff"))
	$Number.text = words
	$Number.position = center + Vector2(-$Number.size.x / 2.0, -45)
	$Number.modulate = tint
	$Number.show()
	target.modulate = Color("ff806b") if hit else tint

	var bar: ProgressBar = ui.get_node("%sHP%d" % ["Ally" if event.side == "ally" else "Enemy", event.index])
	var tween := create_tween().set_parallel(true)
	tween.tween_property($Impact, "scale", Vector2(1.35, 1.35), 0.18)
	tween.tween_property($Impact, "rotation", 0.55 if hit else 0.0, 0.18)
	tween.tween_property($Impact, "modulate:a", 0.0, 0.22).set_delay(0.10)
	tween.tween_property($Number, "position:y", $Number.position.y - 30.0, 0.40)
	tween.tween_property($Number, "modulate:a", 0.0, 0.16).set_delay(0.28)
	tween.tween_property(target, "modulate", target_color, 0.26)
	tween.tween_property(bar, "value", event.hp, 0.22)
	if hit:
		target.position.x += 5
		tween.tween_property(target, "position:x", target_home.x - 4, 0.05)
		tween.tween_property(target, "position:x", target_home.x + 2, 0.05).set_delay(0.05)
		tween.tween_property(target, "position:x", target_home.x, 0.07).set_delay(0.10)
	await tween.finished
	source.position = source_home
	target.position = target_home
	$Impact.hide()
	$Number.hide()
	if event.hp <= 0:
		var fall := create_tween()
		fall.tween_property(target, "modulate", Color(0.35, 0.35, 0.35, 0.55), 0.15)
		await fall.finished

func celebrate(ui: Control, won: bool) -> void:
	var banner: Label = ui.get_node("Turn")
	banner.pivot_offset = banner.size / 2.0
	var tween := create_tween()
	tween.tween_property(banner, "scale", Vector2(1.10, 1.10), 0.12)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.18)
	if won:
		for i in range(Session.party.size()):
			var picture := portrait(ui, "ally", i)
			var home := picture.position
			var hop := create_tween()
			hop.tween_interval(i * 0.07)
			hop.tween_property(picture, "position:y", home.y - 10, 0.12)
			hop.tween_property(picture, "position:y", home.y, 0.14)
	await tween.finished
	await get_tree().create_timer(0.20).timeout
