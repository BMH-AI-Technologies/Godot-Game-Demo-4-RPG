extends Camera2D
## Camera là con của Player, chỉ theo hình ảnh; không đổi tọa độ ô hay va chạm.
## Player đổi ô ngay, còn AnimatedSprite2D trượt trong 0,2 giây.
## Theo vị trí sprite giúp camera trượt cùng bước chân, không giật sang ô mới.

func _process(_delta: float) -> void:
	position = get_parent().sprite.position
	force_update_scroll()

func fit_map(map_size: Vector2i) -> void:
	# Chừa chỗ cho HUD trên/dưới để nhân vật ở mép bản đồ không bị che.
	limit_left = 0
	limit_top = -58
	limit_right = map_size.x
	limit_bottom = map_size.y + 44
	position = Vector2.ZERO
	reset_smoothing()
	force_update_scroll()
