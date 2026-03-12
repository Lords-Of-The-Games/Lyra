class_name LevelFinishDoor
extends Area2D

@export var next_scene: PackedScene

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().call_group("Player", "death_tween")
		AudioManager.level_complete_sfx.play()
		SceneTransition.load_scene(next_scene)
