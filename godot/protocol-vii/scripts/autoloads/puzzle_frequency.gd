extends Control

signal puzzle_complete(success)
signal puzzle_failed(penalty)

var speed: float = 2.0
var target_min: float = 40.0
var target_max: float = 60.0
var moving_right: bool = true
var is_active: bool = false

@onready var bar = $ProgressBar # Ensure you have a ProgressBar child named 'ProgressBar'

func start_puzzle(difficulty: float):
	is_active = true
	speed = 2.0 * difficulty
	var zone_size = 30.0 / difficulty
	var zone_center = randf_range(20.0, 80.0)
	target_min = zone_center - (zone_size / 2)
	target_max = zone_center + (zone_size / 2)

func _process(delta):
	if not is_active: return
	
	if moving_right:
		bar.value += speed * delta * 50.0
		if bar.value >= 100: moving_right = false
	else:
		bar.value -= speed * delta * 50.0
		if bar.value <= 0: moving_right = true
		
	if Input.is_action_just_pressed("ui_accept"):
		check_lock()

func check_lock():
	is_active = false
	if bar.value >= target_min and bar.value <= target_max:
		emit_signal("puzzle_complete", true)
	else:
		emit_signal("puzzle_failed", 15.0)
