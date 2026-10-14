class_name PartyWalker
extends GridEntity
## Chung cho Athena và đồng đội: vị trí logic theo ô, hình ảnh trượt bằng Tween.
signal step_finished
const STEP_TIME := 0.20
var moving := false
var facing := Vector2i.DOWN
var walk_tween: Tween
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	face_direction()

func face_direction() -> void:
	var names := {Vector2i.DOWN: "down", Vector2i.LEFT: "left",
		Vector2i.RIGHT: "right", Vector2i.UP: "up"}
	sprite.animation = names[facing]
	sprite.frame = 0

func move_to(cell: Vector2i) -> void:
	if walk_tween:
		walk_tween.kill()
	moving = false
	super.move_to(cell)
	if is_instance_valid(sprite):
		sprite.position = Vector2.ZERO
		sprite.stop()
		face_direction()

func step_to(cell: Vector2i) -> void:
	var previous := get_cell()
	move_to(cell)
	animate_step(cell - previous)

func animate_step(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	facing = direction
	face_direction()
	moving = true
	sprite.position = Vector2(-direction * TILE)
	sprite.play()
	walk_tween = create_tween()
	walk_tween.tween_property(sprite, "position", Vector2.ZERO, STEP_TIME)
	walk_tween.finished.connect(finish_step)

func finish_step() -> void:
	moving = false
	sprite.stop()
	sprite.frame = 0
	step_finished.emit()
