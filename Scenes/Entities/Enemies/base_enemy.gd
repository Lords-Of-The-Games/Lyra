class_name BaseEnemy
extends CharacterBody2D

# --------- VARIABLES ---------- #

@export_category("Movement")
@export var speed: float = 100.0
@export var gravity_force: float = 30.0

var direction: float = 1.0
var _is_dead: bool = false

# --------- BUILT-IN FUNCTIONS ---------- #

func _physics_process(_delta: float) -> void:
	apply_movement(_delta)
	update_visual()
	move_and_slide()

# --------- VIRTUAL ---------- #

func apply_movement(_delta: float) -> void:
	pass

# --------- SHARED ---------- #

func update_visual() -> void:
	$Visual.scale.x = -1.0 if direction < 0.0 else 1.0

func die() -> void:
	_is_dead = true
	set_physics_process(false)
	$Hitbox.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	queue_free()

# --------- SIGNALS ---------- #

func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_dead:
		return
	if not body is Player or body.current_state == Player.State.DEAD:
		return
	# Stomp: player is falling and above the enemy
	if body.velocity.y > 0 and body.global_position.y < global_position.y:
		body.velocity.y = -body.jump_force * 0.6
		die()
	else:
		AudioManager.death_sfx.play()
		body.death_particles.emitting = true
		body.transition_to(Player.State.DEAD)
