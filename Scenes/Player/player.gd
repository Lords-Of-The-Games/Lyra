class_name Player
extends CharacterBody2D

# --------- ENUMS ---------- #

enum State { IDLE, WALK, JUMP, FALL, DEAD }

# --------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed: float = 400
@export var jump_force: float = 800
@export var gravity: float = 30
@export var fall_gravity_multiplier: float = 1.8  # Extra gravity while falling
@export var max_jump_count: int = 2

@export_category("Polish")
@export var coyote_time: float = 0.12        # Seconds to jump after walking off an edge
@export var jump_buffer_time: float = 0.15   # Seconds a pre-pressed jump stays buffered
@export var jump_cut_multiplier: float = 0.4  # Upward velocity kept on early jump release

@export_category("Toggle Functions")
@export var double_jump: bool = false

var current_state: State = State.IDLE
var jump_count: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_coyote_jump: bool = false  # Coyote jumps don't consume a jump count

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_point: Marker2D = %SpawnPoint
@onready var particle_trails: CPUParticles2D = $ParticleTrails
@onready var death_particles: CPUParticles2D = $DeathParticles

# --------- BUILT-IN FUNCTIONS ---------- #

func _ready() -> void:
	floor_snap_length = 4.0  # Keeps is_on_floor() stable when velocity is near zero
	jump_count = max_jump_count
	enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	tick_timers(delta)
	apply_gravity()
	apply_jump_cut()
	process_state_machine()
	update_state()
	flip_player()
	move_and_slide()

# --------- TIMERS ---------- #

func tick_timers(delta: float) -> void:
	coyote_timer      = max(0.0, coyote_timer - delta)
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	# Stamp the buffer whenever jump is pressed, even mid-air
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = jump_buffer_time

# --------- STATE MACHINE ---------- #

func process_state_machine() -> void:
	var jump_just := Input.is_action_just_pressed("Jump")

	# Coyote jump — grace window after walking off an edge (free jump, no count cost)
	if current_state == State.FALL and jump_just and coyote_timer > 0.0:
		coyote_timer = 0.0
		is_coyote_jump = true
		transition_to(State.JUMP)
		return

	# Double jump — mid-air jump; handles same-state JUMP re-entry too
	if double_jump and jump_just and jump_count > 0:
		if current_state == State.JUMP or current_state == State.FALL:
			transition_to(State.JUMP)
			return

	var next_state := get_next_state()
	if next_state != current_state:
		transition_to(next_state)

func get_next_state() -> State:
	if current_state == State.DEAD:
		return State.DEAD

	var on_floor  := is_on_floor()
	var input_x   := Input.get_axis("Left", "Right")
	var jump_just := Input.is_action_just_pressed("Jump")

	match current_state:
		State.IDLE:
			if not on_floor:      return State.FALL
			if jump_just:         return State.JUMP
			if abs(input_x) > 0:  return State.WALK
		State.WALK:
			if not on_floor:      return State.FALL
			if jump_just:         return State.JUMP
			if abs(input_x) == 0: return State.IDLE
		State.JUMP:
			if velocity.y > 0:    return State.FALL
			if on_floor:
				return State.IDLE if abs(input_x) == 0 else State.WALK
		State.FALL:
			if on_floor:
				# Jump buffer: jump was pre-pressed in the air, fire it now on landing
				if jump_buffer_timer > 0.0:
					jump_buffer_timer = 0.0
					jump_count = max_jump_count  # Touching ground resets the count
					return State.JUMP
				return State.IDLE if abs(input_x) == 0 else State.WALK

	return current_state

func transition_to(new_state: State) -> void:
	exit_state(current_state, new_state)
	enter_state(new_state)

func enter_state(state: State) -> void:
	current_state = state
	match state:
		State.IDLE:
			jump_count = max_jump_count
			velocity.y = 0.0
			particle_trails.emitting = false
			player_sprite.play("Idle")
		State.WALK:
			jump_count = max_jump_count
			velocity.y = 0.0
			particle_trails.emitting = true
			player_sprite.play("Walk", 1.5)
		State.JUMP:
			particle_trails.emitting = false
			player_sprite.play("Jump")
			velocity.y = -jump_force
			if not is_coyote_jump:  # Coyote jumps are free — don't cost a count
				jump_count -= 1
			is_coyote_jump = false
			#jump_tween()
			AudioManager.jump_sfx.play()
		State.FALL:
			particle_trails.emitting = false
			player_sprite.play("Jump")
		State.DEAD:
			particle_trails.emitting = false
			velocity = Vector2.ZERO

func exit_state(from: State, to: State) -> void:
	match from:
		State.IDLE, State.WALK:
			# Only start coyote window when falling off an edge, not when jumping
			if to == State.FALL:
				coyote_timer = coyote_time
		#State.FALL:
			## Landing squash only when actually touching down, not on a double jump
			#if is_on_floor():
				#land_tween()

func update_state() -> void:
	var input_x := Input.get_axis("Left", "Right")
	match current_state:
		State.IDLE:
			velocity.x = 0
		State.WALK, State.JUMP, State.FALL:
			velocity.x = input_x * move_speed
		State.DEAD:
			velocity = Vector2.ZERO

# --------- CUSTOM FUNCTIONS ---------- #

func apply_gravity() -> void:
	if not is_on_floor() and current_state != State.DEAD:
		var grav := gravity * (fall_gravity_multiplier if current_state == State.FALL else 1.0)
		velocity.y += grav

func apply_jump_cut() -> void:
	# Release jump early → multiply upward velocity down for a shorter arc
	if current_state == State.JUMP and Input.is_action_just_released("Jump"):
		if velocity.y < 0.0:
			velocity.y *= jump_cut_multiplier

func flip_player() -> void:
	if velocity.x < 0:
		player_sprite.flip_h = true
	elif velocity.x > 0:
		player_sprite.flip_h = false

# --------- TWEEN ANIMATIONS ---------- #

func death_tween() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	AudioManager.respawn_sfx.play()
	#respawn_tween()

func respawn_tween() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	await tween.finished
	enter_state(State.IDLE)

func jump_tween() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func land_tween() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 0.7), 0.07)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)

# --------- SIGNALS ---------- #

func _on_collision_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("Traps") and current_state != State.DEAD:
		AudioManager.death_sfx.play()
		death_particles.emitting = true
		transition_to(State.DEAD)
		#death_tween()
