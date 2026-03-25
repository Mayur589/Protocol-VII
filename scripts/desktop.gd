extends Control


@onready var annoy_window: Window = $annoyWindow
@onready var start_button: Button = $Panel/startButton
@onready var map: Button = $Map

var shake_tween: Tween
var original_position: Vector2

var allow = 3

func _ready() -> void:
	annoy_window.visible = false
	original_position = position
	start_button.connect("button_down", _on_start_button_pressed)
	annoy_window.connect("close_requested", _on_close_annoy_window)
	map.connect("button_down", _on_map_clicked)

func _on_start_button_pressed():
	allow -= 1
	
	if allow == 0:
		start_button.disabled = true
		shake_screen()
		await get_tree().create_timer(0.5).timeout
		annoy_window.visible = true
		
func _on_close_annoy_window():
	annoy_window.visible = false
	allow = 3
	start_button.disabled = false

func _on_map_clicked():
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func shake_screen():
	if shake_tween:
		shake_tween.kill()
	
	shake_tween = create_tween()
	var shake_strength = 30
	var shake_duration = 0.05
	
	for i in range(8):
		var offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_tween.tween_property(self, "position", original_position + offset, shake_duration)
	
	shake_tween.tween_property(self, "position", original_position, shake_duration)
