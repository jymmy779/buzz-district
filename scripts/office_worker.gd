extends Node2D


var move_tween: Tween = null


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(
		Rect2(-15, -15, 30, 30),
		Color(0.2, 0.6, 1.0)
	)


func walk_to(
	target_position: Vector2,
	duration: float = 2.0
) -> Tween:
	cancel_movement()

	move_tween = create_tween()

	move_tween.tween_property(
		self,
		"global_position",
		target_position,
		duration
	)

	return move_tween


func cancel_movement() -> void:
	if move_tween != null:
		if move_tween.is_valid():
			move_tween.kill()

	move_tween = null
