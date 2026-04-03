extends Node2D

@onready var player_progress: TextureProgressBar = $playerProgress
@onready var progress_score: RichTextLabel = $progressScore


func _process(_delta: float) -> void:
	player_progress.value = min(Global.total_puzzle_completed, 21)
	var text: String = "Progress: " + str(int(ceil(player_progress.value / 21 * 100))) + "%"
	progress_score.text = text
	
	
