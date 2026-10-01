extends Node2D


@onready var patience_bar: ProgressBar = $PatienceBar


var move_tween: Tween = null


func _ready() -> void:
	queue_redraw()
	update_patience_bar()


func _process(_delta: float) -> void:
	update_patience_bar()


func update_patience_bar() -> void:
	if not is_instance_valid(patience_bar):
		return

	var customer_state := str(get_meta("customer_state", ""))
	patience_bar.visible = customer_state == "waiting"

	if not patience_bar.visible:
		return

	var patience_max := float(get_meta("patience_max", 0.0))
	var patience_remaining := float(get_meta("patience_remaining", 0.0))

	if patience_max <= 0.0:
		patience_bar.value = 0.0
		return

	patience_bar.value = clampf(
		patience_remaining / patience_max * 100.0,
		0.0,
		100.0
	)


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
