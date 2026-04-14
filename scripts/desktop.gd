extends Control


@onready var annoy_window: Window = $annoyWindow
@onready var start_button: Button = $Panel/startButton
@onready var map: Button = $Map
@onready var stats: Button = $Stats
@onready var notifications: Button = $Notifications
@onready var select_audio: AudioStreamPlayer = $select_audio
@onready var menu_selection: AudioStreamPlayer = $menu_selection

var shake_tween: Tween
var original_position: Vector2

var allow = 3

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	annoy_window.visible = false
	original_position = position
	start_button.connect("button_down", _on_start_button_pressed)
	annoy_window.connect("close_requested", _on_close_annoy_window)
	map.connect("button_down", _on_map_clicked)
	stats.connect("button_down", _on_stats_clicked)
	notifications.connect("button_down", _on_notifications_clicked)

func _on_start_button_pressed():
	allow -= 1
	
	if allow == 0:
		select_audio.play()
		start_button.disabled = true
		shake_screen()
		await get_tree().create_timer(0.5).timeout
		annoy_window.visible = true
		
func _on_close_annoy_window():
	annoy_window.visible = false
	allow = 3
	start_button.disabled = false

func _on_map_clicked():
	menu_selection.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_stats_clicked():
	menu_selection.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/stats.tscn")

func _on_notifications_clicked():
	menu_selection.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/notification_log.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_main()
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_return_to_main()

func _return_to_main() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

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
