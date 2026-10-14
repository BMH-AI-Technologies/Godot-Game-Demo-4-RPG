extends Node2D
## Một popup dùng chung, đặt ngay phía trên đối tượng mà phím E sẽ tương tác.
var target: GridEntity
var age := 0.0
@onready var box: PanelContainer = $Box
@onready var label: Label = $Box/Label

func show_for(entity: GridEntity, message: String) -> void:
	if entity != target:
		age = 0.0
	target = entity
	label.text = message
	box.reset_size()
	show()

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(target):
		return
	age += delta
	global_position = target.global_position + Vector2(0, -28 + sin(age * 4.0) * 2.0)
	box.position = Vector2(-box.size.x / 2.0, -box.size.y)
	# Đổi tọa độ màn hình về tọa độ popup: vẫn đúng khi camera cuộn/zoom.
	var inverse := get_global_transform_with_canvas().affine_inverse()
	var top_left := inverse * Vector2(24, 176)
	var bottom_right := inverse * (get_viewport_rect().size - Vector2(24, 132))
	box.position.x = clampf(box.position.x, top_left.x, bottom_right.x - box.size.x)
	box.position.y = maxf(box.position.y, top_left.y)
