extends CanvasLayer

@onready var label: RichTextLabel = $MarginContainer/Panel/Label
@onready var load_bar = $MarginContainer/Panel/LoadBar
@onready var header_bar: ColorRect = $MarginContainer/Panel/HeaderBar
@onready var header_label: Label = $MarginContainer/Panel/HeaderLabel

var message: String = ""
var duration: float = 3.0
var pulse_tween: Tween

func setup(text: String, time: float = 3.0):
	message = text
	duration = time

func _ready():
	label.text = message
	if is_instance_valid(header_label):
		header_label.text = "OMNI LINK"
	_start_pulse()
	await get_tree().process_frame
	var full_width = load_bar.size.x
	load_bar.anchor_left = 1.0
	load_bar.anchor_right = 1.0
	load_bar.offset_right = -13.0
	load_bar.offset_left = -13.0 - full_width
	
	
	offset.x = 1000.0 
	var tween = create_tween()
	
	tween.tween_property(self, "offset:x", 0.0, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(load_bar, "size:x", 0.0, duration)
	
	tween.tween_property(self, "offset:x", 1000.0, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(queue_free)

func _start_pulse() -> void:
	if not is_instance_valid(header_bar):
		return
	if pulse_tween:
		pulse_tween.kill()
	header_bar.modulate.a = 0.5
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(header_bar, "modulate:a", 0.9, 0.6)
	pulse_tween.tween_property(header_bar, "modulate:a", 0.35, 0.6)
