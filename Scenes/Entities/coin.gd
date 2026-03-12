class_name Coin
extends Area2D

@export var amplitude: float = 4.0
@export var frequency: float = 5.0

var time_passed: float = 0.0
var initial_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	initial_position = position

func _process(delta: float) -> void:
	time_passed += delta
	position.y = initial_position.y + amplitude * sin(frequency * time_passed)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		AudioManager.coin_pickup_sfx.play()
		GameManager.add_score()
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
		await tween.finished
		queue_free()
