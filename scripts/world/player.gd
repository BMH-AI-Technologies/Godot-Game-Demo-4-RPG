extends PartyWalker
## Đọc trạng thái Input Map mỗi khung hình để giữ phím là đi liên tục.
## Vẫn đi từng ô; chỉ bắt đầu bước mới khi tween của bước cũ đã xong.
signal move_requested(direction: Vector2i)
signal interact_requested
signal inventory_requested
var active := true
var repeat_delay := 0.0
var last_action := "move_down"

func _process(delta: float) -> void:
	repeat_delay = maxf(0.0, repeat_delay - delta)
	if not active or moving or repeat_delay > 0.0:
		return
	if Input.is_action_pressed(last_action):
		request_step(last_action)
		return
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		if Input.is_action_pressed(action):
			request_step(action)
			return

func request_step(action: String) -> void:
	var directions := {"move_up": Vector2i.UP, "move_down": Vector2i.DOWN,
		"move_left": Vector2i.LEFT, "move_right": Vector2i.RIGHT}
	last_action = action
	facing = directions[action]
	face_direction()
	# Nếu đang tì vào tường, chỉ thử lại 10 lần/giây.
	repeat_delay = 0.10
	move_requested.emit(facing)

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		if event.is_action_pressed(action):
			last_action = action
			if not moving:
				request_step(action)
			get_viewport().set_input_as_handled()
			return
	if moving:
		return
	if event.is_action_pressed("interact"):
		interact_requested.emit()
	elif event.is_action_pressed("inventory"):
		inventory_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()
