extends Node3D

@export var globe_spin_speed: float = 0.7
@export var globe_bob_speed: float = 1.15
@export var globe_bob_height: float = 0.08
@export var monitor_click_range: float = 4.0

@onready var globe: Node3D = $globe
@onready var monitor_click_area: Area3D = get_node_or_null("DesktopStation/MonitorClickArea")
@onready var player_body: CharacterBody3D = get_node_or_null("PlayerController/CharacterBody3D")
@onready var player_camera: Camera3D = get_node_or_null("PlayerController/CharacterBody3D/head/Camera3D")
@onready var player_controller: Node = get_node_or_null("PlayerController")
@onready var stats_monitor_text: Label = get_node_or_null("StatsViewport/Overlay/StatsText")
@onready var notification_monitor_text: Label = get_node_or_null("NotificationsViewport/Overlay/NotificationText")
@onready var crosshair: CanvasItem = get_node_or_null("HUD/Crosshair")
@onready var main_menu_layer: CanvasLayer = get_node_or_null("MainMenu")
@onready var main_backdrop: ColorRect = get_node_or_null("MainMenu/Backdrop")
@onready var main_scanline_tint: ColorRect = get_node_or_null("MainMenu/ScanlineTint")
@onready var main_menu_center: CenterContainer = get_node_or_null("MainMenu/MenuCenter")
@onready var menu_card: PanelContainer = get_node_or_null("MainMenu/MenuCenter/MenuCard")
@onready var briefing_panel: PanelContainer = get_node_or_null("MainMenu/BriefingPanel")
@onready var pause_backdrop: ColorRect = get_node_or_null("MainMenu/PauseBackdrop")
@onready var pause_panel: PanelContainer = get_node_or_null("MainMenu/PausePanel")
@onready var start_button: Button = get_node_or_null("MainMenu/MenuCenter/MenuCard/ContentMargin/Content/StartButton")
@onready var briefing_button: Button = get_node_or_null("MainMenu/MenuCenter/MenuCard/ContentMargin/Content/BriefingButton")
@onready var exit_button: Button = get_node_or_null("MainMenu/MenuCenter/MenuCard/ContentMargin/Content/ExitButton")
@onready var close_briefing_button: Button = get_node_or_null("MainMenu/BriefingPanel/BriefingMargin/BriefingContent/CloseBriefingButton")
@onready var resume_button: Button = get_node_or_null("MainMenu/PausePanel/PauseMargin/PauseContent/ResumeButton")
@onready var return_to_menu_button: Button = get_node_or_null("MainMenu/PausePanel/PauseMargin/PauseContent/ReturnToMenuButton")
@onready var pause_exit_button: Button = get_node_or_null("MainMenu/PausePanel/PauseMargin/PauseContent/PauseExitButton")
@onready var sensitivity_slider: HSlider = get_node_or_null("MainMenu/PausePanel/PauseMargin/PauseContent/SensitivityRow/SensitivitySlider")
@onready var sensitivity_value_label: Label = get_node_or_null("MainMenu/PausePanel/PauseMargin/PauseContent/SensitivityRow/SensitivityValue")
@onready var volume_slider: HSlider = get_node_or_null("MainMenu/PausePanel/PauseMargin/PauseContent/VolumeRow/VolumeSlider")
@onready var volume_value_label: Label = get_node_or_null("MainMenu/PausePanel/PauseMargin/PauseContent/VolumeRow/VolumeValue")

var _base_globe_y: float = 1.12
var _time_accumulator: float = 0.0
var _player_near_desktop: bool = false
var _monitor_refresh_timer: float = 0.0
var _menu_active: bool = false
var _pause_menu_active: bool = false

func _ready() -> void:
	var returning_from_desktop := bool(Global.get("should_restore_desktop_return"))
	_connect_menu_buttons()
	_sync_option_controls()

	if is_instance_valid(globe):
		_base_globe_y = globe.position.y

	if returning_from_desktop:
		if is_instance_valid(player_body):
			player_body.global_position = Global.desktop_return_player_pos
		if is_instance_valid(player_camera):
			player_camera.rotation = Global.desktop_return_camera_rot
		Global.should_restore_desktop_return = false

	_set_menu_state(not returning_from_desktop)

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

func _input(event: InputEvent) -> void:
	if _menu_active or _pause_menu_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_try_open_desktop_from_click()

func _unhandled_input(event: InputEvent) -> void:
	if _menu_active:
		if event.is_action_pressed("ui_cancel") and is_instance_valid(briefing_panel) and briefing_panel.visible:
			briefing_panel.visible = false
		return

	if event.is_action_pressed("ui_cancel"):
		_set_pause_menu_state(not _pause_menu_active)
		return

	if _pause_menu_active:
		return

	#if event.is_action_pressed("ui_enter") and _player_near_desktop:
		#get_tree().change_scene_to_file("res://scenes/desktop.tscn")
		#return

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
	if collider == monitor_click_area or collider.get_parent() == monitor_click_area:
		if is_instance_valid(player_body):
			Global.desktop_return_player_pos = player_body.global_position
		if is_instance_valid(player_camera):
			Global.desktop_return_camera_rot = player_camera.rotation
		Global.should_restore_desktop_return = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/desktop.tscn")

func _connect_menu_buttons() -> void:
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(briefing_button) and not briefing_button.pressed.is_connected(_on_briefing_pressed):
		briefing_button.pressed.connect(_on_briefing_pressed)
	if is_instance_valid(exit_button) and not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)
	if is_instance_valid(close_briefing_button) and not close_briefing_button.pressed.is_connected(_on_close_briefing_pressed):
		close_briefing_button.pressed.connect(_on_close_briefing_pressed)
	if is_instance_valid(resume_button) and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if is_instance_valid(return_to_menu_button) and not return_to_menu_button.pressed.is_connected(_on_return_to_menu_pressed):
		return_to_menu_button.pressed.connect(_on_return_to_menu_pressed)
	if is_instance_valid(pause_exit_button) and not pause_exit_button.pressed.is_connected(_on_pause_exit_pressed):
		pause_exit_button.pressed.connect(_on_pause_exit_pressed)
	if is_instance_valid(sensitivity_slider) and not sensitivity_slider.value_changed.is_connected(_on_sensitivity_changed):
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	if is_instance_valid(volume_slider) and not volume_slider.value_changed.is_connected(_on_volume_changed):
		volume_slider.value_changed.connect(_on_volume_changed)

func _set_menu_state(is_active: bool) -> void:
	_menu_active = is_active
	if is_active:
		_set_pause_menu_state(false)

	if is_instance_valid(main_menu_layer):
		main_menu_layer.visible = true

	if is_instance_valid(main_backdrop):
		main_backdrop.visible = is_active
	if is_instance_valid(main_scanline_tint):
		main_scanline_tint.visible = is_active
	if is_instance_valid(main_menu_center):
		main_menu_center.visible = is_active

	if is_instance_valid(briefing_panel):
		briefing_panel.visible = false

	if is_instance_valid(crosshair):
		crosshair.visible = not is_active and not _pause_menu_active

	if is_instance_valid(player_controller):
		var allow_gameplay_input := not is_active and not _pause_menu_active
		player_controller.set_process_unhandled_input(allow_gameplay_input)
		player_controller.set_physics_process(allow_gameplay_input)

	if is_instance_valid(player_body) and is_active:
		player_body.velocity = Vector3.ZERO

	if is_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_animate_menu_intro()
	else:
		_capture_mouse_for_gameplay()

func _set_pause_menu_state(is_active: bool) -> void:
	if _menu_active:
		return

	_pause_menu_active = is_active

	if is_instance_valid(pause_backdrop):
		pause_backdrop.visible = is_active
	if is_instance_valid(pause_panel):
		pause_panel.visible = is_active

	if is_instance_valid(crosshair):
		crosshair.visible = not _menu_active and not is_active

	if is_instance_valid(player_controller):
		player_controller.set_process_unhandled_input(not is_active)
		player_controller.set_physics_process(not is_active)

	if is_instance_valid(player_body) and is_active:
		player_body.velocity = Vector3.ZERO

	if is_active:
		_sync_option_controls()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_animate_pause_intro()
	else:
		_capture_mouse_for_gameplay()

func _capture_mouse_for_gameplay() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	call_deferred("_ensure_mouse_captured_if_gameplay")

func _ensure_mouse_captured_if_gameplay() -> void:
	if not _menu_active and not _pause_menu_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and not _menu_active and not _pause_menu_active:
		_capture_mouse_for_gameplay()

func _animate_pause_intro() -> void:
	if not is_instance_valid(pause_panel):
		return

	pause_panel.modulate = Color(1, 1, 1, 0)
	pause_panel.scale = Vector2(0.97, 0.97)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pause_panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _sync_option_controls() -> void:
	if is_instance_valid(player_controller) and is_instance_valid(sensitivity_slider):
		var current_sensitivity = player_controller.get("mouse_sensitivity")
		if typeof(current_sensitivity) == TYPE_FLOAT:
			sensitivity_slider.value = float(current_sensitivity)
		_update_sensitivity_label(sensitivity_slider.value)

	if is_instance_valid(volume_slider):
		var master_index := AudioServer.get_bus_index("Master")
		if master_index >= 0:
			var db := AudioServer.get_bus_volume_db(master_index)
			var percent := clampf(db_to_linear(db) * 100.0, 0.0, 100.0)
			volume_slider.value = percent
		_update_volume_label(volume_slider.value)

func _on_sensitivity_changed(value: float) -> void:
	if is_instance_valid(player_controller):
		player_controller.set("mouse_sensitivity", value)
	_update_sensitivity_label(value)

func _on_volume_changed(value: float) -> void:
	var master_index := AudioServer.get_bus_index("Master")
	if master_index >= 0:
		AudioServer.set_bus_volume_db(master_index, linear_to_db(clampf(value / 100.0, 0.0001, 1.0)))
	_update_volume_label(value)

func _update_sensitivity_label(value: float) -> void:
	if is_instance_valid(sensitivity_value_label):
		sensitivity_value_label.text = "%.2f" % (value * 1000.0)

func _update_volume_label(value: float) -> void:
	if is_instance_valid(volume_value_label):
		volume_value_label.text = "%d%%" % int(round(value))

func _animate_menu_intro() -> void:
	if not is_instance_valid(menu_card):
		return

	menu_card.modulate = Color(1, 1, 1, 0)
	menu_card.scale = Vector2(0.96, 0.96)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(menu_card, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_card, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_start_pressed() -> void:
	_set_menu_state(false)

func _on_briefing_pressed() -> void:
	if is_instance_valid(briefing_panel):
		briefing_panel.visible = true

func _on_close_briefing_pressed() -> void:
	if is_instance_valid(briefing_panel):
		briefing_panel.visible = false

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_resume_pressed() -> void:
	_set_pause_menu_state(false)

func _on_return_to_menu_pressed() -> void:
	_set_pause_menu_state(false)
	_set_menu_state(true)

func _on_pause_exit_pressed() -> void:
	get_tree().quit()

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
