class_name TouchJoystick
extends Control

## A visible, passive touch-stick display. Input remains in OutpostPlayer so GUI
## buttons can consume their own touches without competing with movement input.
const BASE_RADIUS := 68.0
const KNOB_RADIUS := 29.0
const KNOB_TRAVEL := 43.0

var direction := Vector2.ZERO
var active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_input(value: Vector2, is_active: bool) -> void:
	direction = value.limit_length(1.0)
	active = is_active
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var idle_alpha := 0.55 if active else 0.34
	var outer := Color(0.08, 0.13, 0.12, idle_alpha)
	var rim := Color(0.94, 0.80, 0.52, 0.82 if active else 0.48)
	var cross := Color(0.94, 0.80, 0.52, 0.24)
	draw_circle(center, BASE_RADIUS, outer)
	draw_arc(center, BASE_RADIUS, 0.0, TAU, 32, rim, 3.0, true)
	draw_arc(center, BASE_RADIUS * 0.62, 0.0, TAU, 24, cross, 1.0, true)
	draw_line(center - Vector2(BASE_RADIUS * 0.7, 0), center + Vector2(BASE_RADIUS * 0.7, 0), cross, 1.0)
	draw_line(center - Vector2(0, BASE_RADIUS * 0.7), center + Vector2(0, BASE_RADIUS * 0.7), cross, 1.0)
	var knob_center := center + direction * KNOB_TRAVEL
	draw_circle(knob_center, KNOB_RADIUS, Color(0.77, 0.66, 0.39, 0.76 if active else 0.50))
	draw_arc(knob_center, KNOB_RADIUS, 0.0, TAU, 24, Color(1.0, 0.91, 0.64, 0.9), 2.0, true)
