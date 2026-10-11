class_name PerformanceGovernor
extends Node

## Watches frame rate at a low cadence and reduces only presentation features if
## sustained load threatens the mobile 60 FPS target. Gameplay simulation, input
## and HUD are never changed by this controller.
const SAMPLE_INTERVAL := 1.0
const REDUCE_THRESHOLD := 50.0
const RESTORE_THRESHOLD := 58.0
const REDUCE_AFTER := 3.0
const RESTORE_AFTER := 7.0

var world_root: Node3D
var effects_requested := true
var adaptive_reduced := false
var sample_left := SAMPLE_INTERVAL
var low_fps_time := 0.0
var high_fps_time := 0.0

func configure(root: Node3D) -> void:
	world_root = root
	_apply_presentation()

func set_effects_requested(enabled: bool) -> void:
	effects_requested = enabled
	_apply_presentation()

func _process(delta: float) -> void:
	if world_root == null:
		return
	sample_left -= delta
	if sample_left > 0.0:
		return
	sample_left = SAMPLE_INTERVAL
	var fps := Engine.get_frames_per_second()
	if fps < REDUCE_THRESHOLD:
		low_fps_time += SAMPLE_INTERVAL
		high_fps_time = 0.0
	elif fps > RESTORE_THRESHOLD:
		high_fps_time += SAMPLE_INTERVAL
		low_fps_time = 0.0
	else:
		low_fps_time = maxf(low_fps_time - SAMPLE_INTERVAL * 0.5, 0.0)
		high_fps_time = maxf(high_fps_time - SAMPLE_INTERVAL * 0.5, 0.0)
	if not adaptive_reduced and low_fps_time >= REDUCE_AFTER:
		adaptive_reduced = true
		_apply_presentation()
	elif adaptive_reduced and high_fps_time >= RESTORE_AFTER:
		adaptive_reduced = false
		_apply_presentation()

func _apply_presentation() -> void:
	if world_root != null:
		WorldBuilder.set_presentation_quality(world_root, effects_requested, adaptive_reduced)
