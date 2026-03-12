class_name GameUI
extends Control

@onready var score_label: Label = %Score/ScoreLabel

func _process(_delta: float) -> void:
	score_label.text = "x %d" % GameManager.score
