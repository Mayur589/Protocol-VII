extends Control

const DOMINATION_MAX: float = 100.0
const OMNI_MAX: float = 100.0
const PENALTY_MAX: float = 100.0
const PUZZLES_MAX: float = 21.0

const DOMINATION_TICKS: int = 20
const OMNI_TICKS: int = 20
const PENALTY_TICKS: int = 20
const PUZZLES_TICKS: int = 21

const DOMINATION_COLOR = Color(0.0, 0.82, 1.0, 1.0)
const PUZZLES_COLOR = Color(0.49, 1.0, 0.42, 1.0)
const PENALTY_COLOR = Color(1.0, 0.3, 0.3, 1.0)
const OMNI_COLOR = Color(1.0, 0.82, 0.4, 1.0)
const TICK_HEIGHT = 12.0

@onready var domination_value: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/DominationRow/DominationHeader/DominationValue
@onready var puzzles_value: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/PuzzlesRow/PuzzlesHeader/PuzzlesValue
@onready var penalty_value: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/PenaltyRow/PenaltyHeader/PenaltyValue
@onready var omni_value: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/OmniRow/OmniHeader/OmniValue

@onready var domination_ticks: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/DominationRow/DominationTicks
@onready var puzzles_ticks: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/PuzzlesRow/PuzzlesTicks
@onready var penalty_ticks: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/PenaltyRow/PenaltyTicks
@onready var omni_ticks: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/StatsRows/OmniRow/OmniTicks
@onready var back_arrow: Area2D = $BackArrow
@onready var back_arrow_sprite: Sprite2D = $BackArrow/Sprite2D

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_build_all_ticks()
	_fill_stats()


func _fill_stats() -> void:
	_update_stat(
		Global.domination,
		DOMINATION_MAX,
		DOMINATION_TICKS,
		DOMINATION_COLOR,
		domination_value,
		"%"
	)
	_update_stat(
		Global.total_puzzle_completed,
		PUZZLES_MAX,
		PUZZLES_TICKS,
		PUZZLES_COLOR,
		puzzles_value,
		"/" + str(int(PUZZLES_MAX))
	)
	_update_stat(
		Global.penalty,
		PENALTY_MAX,
		PENALTY_TICKS,
		PENALTY_COLOR,
		penalty_value,
		""
	)
	_update_stat(
		Global.omni_awareness,
		OMNI_MAX,
		OMNI_TICKS,
		OMNI_COLOR,
		omni_value,
		"%"
	)

func _build_all_ticks() -> void:
	_build_ticks(domination_ticks, DOMINATION_TICKS)
	_build_ticks(puzzles_ticks, PUZZLES_TICKS)
	_build_ticks(penalty_ticks, PENALTY_TICKS)
	_build_ticks(omni_ticks, OMNI_TICKS)

func _build_ticks(container: HBoxContainer, count: int) -> void:
	for child in container.get_children():
		child.queue_free()

	for _i in range(count):
		var tick := ColorRect.new()
		tick.custom_minimum_size = Vector2(0, TICK_HEIGHT)
		tick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(tick)

func _update_stat(
		value: float,
		max_value: float,
		tick_count: int,
		color: Color,
		label: Label,
		suffix: String
	) -> void:
	var safe_max = max(1.0, max_value)
	var clamped = clamp(value, 0.0, safe_max)
	var filled := int(round((clamped / safe_max) * tick_count))
	filled = clamp(filled, 0, tick_count)

	if suffix.begins_with("/"):
		label.text = str(int(clamped)) + suffix
	else:
		label.text = str(int(clamped)) + suffix

	var off_color := color.darkened(0.7)
	off_color.a = 0.35

	var container: HBoxContainer = _container_for_label(label)
	if container == null:
		return
	var ticks: Array[Node] = container.get_children()
	for i in range(ticks.size()):
		var tick := ticks[i] as ColorRect
		if tick == null:
			continue
		tick.color = color if i < filled else off_color

func _container_for_label(label: Label) -> HBoxContainer:
	if label == domination_value:
		return domination_ticks
	if label == puzzles_value:
		return puzzles_ticks
	if label == penalty_value:
		return penalty_ticks
	if label == omni_value:
		return omni_ticks
	return null


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
