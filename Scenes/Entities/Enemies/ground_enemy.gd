class_name GroundEnemy
extends BaseEnemy

# --------- VARIABLES ---------- #

@export_category("Patrol")
@export var patrol_distance: float = 260.0

var _start_position: Vector2
var _turn_cooldown: float = 0.0

@onready var ledge_check: RayCast2D = $LedgeCheck

# --------- BUILT-IN FUNCTIONS ---------- #

func _ready() -> void:
	_start_position = global_position

# --------- MOVEMENT ---------- #

func apply_movement(delta: float) -> void:
	_turn_cooldown = max(0.0, _turn_cooldown - delta)

	if not is_on_floor():
		velocity.y += gravity_force

	velocity.x = direction * speed

	if _turn_cooldown <= 0.0:
		# Turn at patrol bounds — set direction explicitly so it can't double-flip
		var offset := global_position.x - _start_position.x
		if offset >= patrol_distance:
			_turn(-1.0)
		elif offset <= -patrol_distance:
			_turn(1.0)
		# Turn at walls
		elif is_on_wall():
			_turn(-direction)
		# Turn at platform edges
		elif is_on_floor() and not ledge_check.is_colliding():
			_turn(-direction)

	# Keep raycast pointing in movement direction
	ledge_check.target_position.x = direction * 25.0

func _turn(new_direction: float) -> void:
	direction = new_direction
	_turn_cooldown = 0.15

# --------- SIGNALS ---------- #

func _on_turn_zone_area_entered(_area: Area2D) -> void:
	_turn(-direction)
