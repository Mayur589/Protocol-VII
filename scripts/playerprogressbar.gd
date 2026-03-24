extends Node2D

@onready var player_progress: TextureProgressBar = $playerProgress

func _process(delta: float) -> void:
	player_progress.value = min(Global.total_puzzle_completed, 21)
