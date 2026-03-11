@tool
extends Resource
class_name Continent

@export var Name : String
@export var Military_Power: int
@export var Cyber_strength: int
@export var Political_influence: int
@export var Puzzles = {}

var Difficulty: int:
	get:
		return _apply_difficulty(Military_Power, Cyber_strength, Political_influence)

func _apply_difficulty(power: int, strength: int, influence: int) -> int:
	@warning_ignore("integer_division")
	var avg: int = (power + strength + influence) / 3
	if avg > 7:
		return 3
	elif avg > 4:
		return 2
	else:
		return 1
