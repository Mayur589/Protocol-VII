extends Control

@onready var message: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var buttons: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var start: Button = $VBoxContainer/HBoxContainer/Start
@onready var back: Button = $VBoxContainer/HBoxContainer/Back

var speed = 0.1
var tween: Tween = create_tween()

func _ready() -> void:
	var text = "We have INTERCEPTED GOVERMENT transmission....."
	message.text = text
	#message.visible_ratio = 0
	tween.tween_property(message, "visible_ratio", 1.0, 2.0).from(0.0)


		


func _on_start_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			print("Start Clicked")
			


func _on_back_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/terminal.tscn")
