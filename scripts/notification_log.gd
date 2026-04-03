extends Control

@onready var log_text: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/LogText
@onready var back_arrow: Area2D = $BackArrow
@onready var back_arrow_sprite: Sprite2D = $BackArrow/Sprite2D

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_render_log()


func _render_log() -> void:
	if not is_instance_valid(log_text):
		return
	var logs: Array = Global.notification_log
	if logs.is_empty():
		log_text.text = "[center][color=#7cff6b]NO NOTIFICATIONS YET[/color][/center]"
		return

	var lines: Array[String] = []
	var entry_number := 1
	for i in range(logs.size() - 1, -1, -1):
		lines.append("[color=#00d2ff][b]ENTRY %d[/b][/color]" % entry_number)
		lines.append(logs[i])
		lines.append("[color=#1cff8c]----------------------------------------[/color]")
		lines.append("")
		entry_number += 1

	log_text.text = "\n".join(lines).strip_edges()


func _on_back_arrow_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/desktop.tscn")


func _on_back_arrow_mouse_entered() -> void:
	back_arrow_sprite.modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_back_arrow_mouse_exited() -> void:
	back_arrow_sprite.modulate = Color("cdcbcf")
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
