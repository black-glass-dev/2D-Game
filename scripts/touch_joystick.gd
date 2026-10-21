class_name TouchJoystick
extends Control

## A visible, passive touch-stick display. Input remains in OutpostPlayer so GUI
## buttons can consume their own touches without competing with movement input.
## The drawing intentionally derives from this Control's current size: the HUD
## editor can therefore resize the joystick as well as reposition it.
const DESIGN_SIDE := 196.0
const BASE_RADIUS := 68.0
const KNOB_RADIUS := 29.0
const KNOB_TRAVEL := 43.0

var direction := Vector2.ZERO
var active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func set_input(value: Vector2, is_active: bool) -> void:
	direction = value.limit_length(1.0)
	active = is_active
	queue_redraw()

func get_input_radius() -> float:
	# Matches the original 78-pixel movement reach at the 196-pixel default.
	return maxf(28.0, minf(size.x, size.y) * 0.4)

func _draw() -> void:
	var center := size * 0.5
	var size_scale := maxf(0.35, minf(size.x, size.y) / DESIGN_SIDE)
	var base_radius := BASE_RADIUS * size_scale
	var knob_radius := KNOB_RADIUS * size_scale
	var knob_travel := KNOB_TRAVEL * size_scale
	var idle_alpha := 0.55 if active else 0.34
	var outer := Color(0.08, 0.13, 0.12, idle_alpha)
	var rim := Color(0.94, 0.80, 0.52, 0.82 if active else 0.48)
	var cross := Color(0.94, 0.80, 0.52, 0.24)
	draw_circle(center, base_radius, outer)
	draw_arc(center, base_radius, 0.0, TAU, 32, rim, maxf(1.5, 3.0 * size_scale), true)
	draw_arc(center, base_radius * 0.62, 0.0, TAU, 24, cross, maxf(1.0, size_scale), true)
	draw_line(center - Vector2(base_radius * 0.7, 0), center + Vector2(base_radius * 0.7, 0), cross, maxf(1.0, size_scale))
	draw_line(center - Vector2(0, base_radius * 0.7), center + Vector2(0, base_radius * 0.7), cross, maxf(1.0, size_scale))
	var knob_center := center + direction * knob_travel
	draw_circle(knob_center, knob_radius, Color(0.77, 0.66, 0.39, 0.76 if active else 0.50))
	draw_arc(knob_center, knob_radius, 0.0, TAU, 24, Color(1.0, 0.91, 0.64, 0.9), maxf(1.5, 2.0 * size_scale), true)
