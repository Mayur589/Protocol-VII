extends Control

signal action_selected(action_type)
signal menu_cancelled

enum ActionType { INFILTRATE, STABILIZE, DELAY }

func _ready():
	$Panel/VBoxContainer/BtnInfiltrate.pressed.connect(func(): _emit(ActionType.INFILTRATE))
	$Panel/VBoxContainer/BtnStabilize.pressed.connect(func(): _emit(ActionType.STABILIZE))
	$Panel/VBoxContainer/BtnDelay.pressed.connect(func(): _emit(ActionType.DELAY))
	$Panel/VBoxContainer/BtnCancel.pressed.connect(_on_cancel)

func _emit(type):
	emit_signal("action_selected", type)
	queue_free()

func _on_cancel():
	emit_signal("menu_cancelled")
	queue_free()
