extends Control

signal puzzle_complete(success)
signal puzzle_failed(penalty)

var speed: float = 2.0
var target_min: float = 40.0
var target_max: float = 60.0
var moving_right: bool = true
var is_active: bool = false

@onready var bar = $ProgressBar 
@onready var label = $Label # Assuming you have a label for instructions

func start_puzzle(difficulty: float):
	_reset_round(difficulty)

func _reset_round(difficulty: float):
	is_active = true
	bar.value = 0 # Reset bar position
	speed = 2.0 * difficulty
	
	# Randomize zone again
	var zone_size = 30.0 / difficulty
	var zone_center = randf_range(20.0, 80.0)
	target_min = zone_center - (zone_size / 2)
	target_max = zone_center + (zone_size / 2)
	
	# Update visuals (Optional: Move a color rect if you have one)
	if label: label.text = "PRESS [SPACE] TO LOCK SIGNAL"
	if label: label.modulate = Color.WHITE

func _process(delta):
	if not is_active: return
	
	# Move the bar
	if moving_right:
		bar.value += speed * delta * 50.0
		if bar.value >= 100: moving_right = false
	else:
		bar.value -= speed * delta * 50.0
		if bar.value <= 0: moving_right = true
		
	if Input.is_action_just_pressed("ui_accept"): # Spacebar
		check_lock()

func check_lock():
	is_active = false # Stop the bar
	
	if bar.value >= target_min and bar.value <= target_max:
		# SUCCESS
		if label: label.text = "SIGNAL LOCKED"
		if label: label.modulate = Color.GREEN
		emit_signal("puzzle_complete", true)
	else:
		# FAILURE
		if label: label.text = "SIGNAL LOST... RETRYING"
		if label: label.modulate = Color.RED
		
		# Emit penalty
		emit_signal("puzzle_failed", 15.0)
		
		# --- THE FIX: RESTART AFTER 1 SECOND ---
		await get_tree().create_timer(1.0).timeout
		_reset_round(speed / 2.0) # Restart with current speed
