extends Control
## Không đóng bằng Esc: người chơi chủ động chọn hồi sinh.
signal respawn_requested

func _ready() -> void:
	%Respawn.pressed.connect(func(): respawn_requested.emit())

func open() -> void:
	show()

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
