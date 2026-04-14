extends Node2D

const MAX_PROGRESS: float = 21.0
const TICK_ON = Color(0.35, 1.0, 0.6, 1.0)
const TICK_OFF = Color(0.08, 0.18, 0.14, 1.0)
const TICK_HEIGHT = 12.0

@onready var bar_back: Control = $Frame/MarginContainer/VBoxContainer/BarBack
@onready var bar_fill: Control = $Frame/MarginContainer/VBoxContainer/BarBack/BarFill
@onready var percent_label: Label = $Frame/MarginContainer/VBoxContainer/HeaderRow/PercentLabel

var ticks: Array[ColorRect] = []


func _process(_delta: float) -> void:
	_update_progress()

func _update_progress() -> void:
	var value := Global.total_puzzle_completed
	var ratio := value / MAX_PROGRESS
	var percent := int(ceil(ratio * 100.0))

	percent_label.text = str(percent) + "%"

	var width := bar_back.size.x * ratio
	bar_fill.size = Vector2(width, bar_back.size.y)

	var count := int(value)
	for i in range(ticks.size()):
		ticks[i].color = TICK_ON if i < count else TICK_OFF
