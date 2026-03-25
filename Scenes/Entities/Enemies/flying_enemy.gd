class_name FlyingEnemy
extends BaseEnemy

# --------- VARIABLES ---------- #

@export_category("Flying")
@export var amplitude: float = 40.0
@export var frequency: float = 2.0
@export var patrol_distance: float = 150.0

var _start_position: Vector2
var _time_passed: float = 0.0

# --------- BUILT-IN FUNCTIONS ---------- #

func _ready() -> void:
	_start_position = global_position

func _physics_process(delta: float) -> void:
	_time_passed += delta
	apply_movement(delta)
	update_visual()
	move_and_slide()
	# Sine wave applied after move_and_slide so physics doesn't interfere
	global_position.y = _start_position.y + amplitude * sin(frequency * _time_passed)

# --------- MOVEMENT ---------- #

func apply_movement(_delta: float) -> void:
	velocity.x = direction * speed
	velocity.y = 0

	# Turn at patrol bounds
	if abs(global_position.x - _start_position.x) >= patrol_distance:
		direction *= -1.0
