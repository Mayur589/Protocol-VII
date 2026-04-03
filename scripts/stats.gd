extends Control

@onready var stats_text: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/StatsText
@onready var back_arrow: Area2D = $BackArrow
@onready var back_arrow_sprite: Sprite2D = $BackArrow/Sprite2D

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_fill_stats()


func _fill_stats() -> void:
	var completed := Global.total_puzzle_completed
	stats_text.text = (
		"[center][outline_size=4][outline_color=#000000]" +
		"[font_size=40][color=#00d2ff][b]DOMINATION[/b][/color] " +
		"[color=#ffffff]%d%%[/color][/font_size][/outline_color][/outline_size][/center]\n" +
		"[center][outline_size=4][outline_color=#000000]" +
		"[font_size=34][color=#7cff6b][b]PUZZLES COMPLETED[/b][/color] " +
		"[color=#ffffff]%d[/color][/font_size][/outline_color][/outline_size][/center]\n" +
		"[center][outline_size=4][outline_color=#000000]" +
		"[font_size=34][color=#ff4d4d][b]PENALTY[/b][/color] " +
		"[color=#ffffff]%d[/color][/font_size][/outline_color][/outline_size][/center]\n" +
		"[center][outline_size=4][outline_color=#000000]" +
		"[font_size=34][color=#ffd166][b]OMNI AWARENESS[/b][/color] " +
		"[color=#ffffff]%d%%[/color][/font_size][/outline_color][/outline_size][/center]"
	) % [
		Global.domination,
		completed,
		Global.penalty,
		Global.omni_awareness
	]


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
