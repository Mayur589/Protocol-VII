extends Node3D

@export var globe_spin_speed: float = 0.7
@export var globe_bob_speed: float = 1.15
@export var globe_bob_height: float = 0.08
@export var monitor_click_range: float = 4.0

@onready var globe: Node3D = $globe
@onready var monitor_click_area: Area3D = get_node_or_null("DesktopStation/MonitorClickArea")
@onready var player_body: CharacterBody3D = get_node_or_null("PlayerController/CharacterBody3D")
@onready var player_camera: Camera3D = get_node_or_null("PlayerController/CharacterBody3D/head/Camera3D")
@onready var stats_monitor_text: Label = get_node_or_null("StatsViewport/Overlay/StatsText")
@onready var notification_monitor_text: Label = get_node_or_null("NotificationsViewport/Overlay/NotificationText")

var _base_globe_y: float = 1.12
var _time_accumulator: float = 0.0
var _player_near_desktop: bool = false
var _monitor_refresh_timer: float = 0.0

func _ready() -> void:
	if is_instance_valid(globe):
		_base_globe_y = globe.position.y

func _process(delta: float) -> void:
	if not is_instance_valid(globe):
		return

	_time_accumulator += delta
	globe.rotate_y(delta * globe_spin_speed)
	globe.position.y = _base_globe_y + sin(_time_accumulator * globe_bob_speed) * globe_bob_height

	_monitor_refresh_timer += delta
	if _monitor_refresh_timer >= 0.2:
		_monitor_refresh_timer = 0.0
		_update_top_monitors()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_enter") and _player_near_desktop:
		get_tree().change_scene_to_file("res://scenes/desktop.tscn")
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_try_open_desktop_from_click()

func _try_open_desktop_from_click() -> void:
	if player_camera == null or monitor_click_area == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var screen_center := viewport_size * 0.5
	var ray_origin := player_camera.project_ray_origin(screen_center)
	var ray_end := ray_origin + player_camera.project_ray_normal(screen_center) * monitor_click_range

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider = hit["collider"]
	if collider == monitor_click_area:
		get_tree().change_scene_to_file("res://scenes/desktop.tscn")

func _update_top_monitors() -> void:
	if stats_monitor_text != null:
		var domination := int(_global_number("domination"))
		var puzzle_done := int(_global_number("total_puzzle_completed"))
		var penalty := int(_global_number("penalty"))
		var omni := int(_global_number("omni_awareness"))
		stats_monitor_text.text = "DOMINATION: %d%%\nPUZZLES: %d/21\nPENALTY: %d\nOMNI: %d%%" % [domination, puzzle_done, penalty, omni]

	if notification_monitor_text != null:
		var logs = Global.get("notification_log")
		if logs is Array and not logs.is_empty():
			notification_monitor_text.text = "LATEST:\n%s" % str(logs[logs.size() - 1])
		else:
			notification_monitor_text.text = "No notifications yet"

func _global_number(property_name: String, fallback: float = 0.0) -> float:
	var value = Global.get(property_name)
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	return fallback

func _on_desktop_area_body_entered(body: Node) -> void:
	if body == player_body:
		_player_near_desktop = true

func _on_desktop_area_body_exited(body: Node) -> void:
	if body == player_body:
		_player_near_desktop = false
