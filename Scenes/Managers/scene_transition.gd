extends CanvasLayer

enum TransitionType { FADE, SCALE }

@export var transition_type: TransitionType

@onready var scene_transition_anim: AnimationPlayer = $SceneTransitionAnim
@onready var dissolve_rect: ColorRect = $DissolveRect

func _ready() -> void:
	dissolve_rect.hide()

# Call this from any script: SceneTransition.load_scene(target_scene)
func load_scene(target_scene: PackedScene) -> void:
	match transition_type:
		TransitionType.FADE:
			transition_animation("fade", target_scene)
		TransitionType.SCALE:
			transition_animation("scale", target_scene)

func transition_animation(animation_name: String, scene: PackedScene) -> void:
	scene_transition_anim.play(animation_name)
	await scene_transition_anim.animation_finished
	get_tree().change_scene_to_packed(scene)
	scene_transition_anim.play_backwards(animation_name)
