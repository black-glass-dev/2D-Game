class_name PerformanceGovernor
extends Node

## Presentation-only governor. Manual LOW/MEDIUM/HIGH/ULTRA selections are
## locked exactly as selected; only AUTO may reduce presentation after sustained
## frame pressure. Simulation, controls, waves, damage and ammo are untouched.
const SAMPLE_INTERVAL := 1.0
const REDUCE_AFTER := 2.0
const RESTORE_AFTER := 7.0

var world_root: Node3D
var effects_requested := true
var requested_tier := "HIGH"
var resolved_tier := "HIGH"
var adaptive_enabled := false
var adaptive_reduced := false
var sample_left := SAMPLE_INTERVAL
var low_fps_time := 0.0
var high_fps_time := 0.0

func configure(root: Node3D, tier := "HIGH", allow_adaptive := false) -> void:
	world_root = root
	requested_tier = tier
	resolved_tier = tier
	adaptive_enabled = allow_adaptive
	_apply_presentation()

func set_effects_requested(enabled: bool) -> void:
	effects_requested = enabled
	_apply_presentation()

func set_quality_tier(tier: String, allow_adaptive := false) -> void:
	requested_tier = tier
	resolved_tier = tier
	adaptive_enabled = allow_adaptive
	adaptive_reduced = false
	low_fps_time = 0.0
	high_fps_time = 0.0
	sample_left = SAMPLE_INTERVAL
	_apply_presentation()

func display_tier() -> String:
	if not adaptive_enabled:
		return resolved_tier
	return resolved_tier + (" • OPTIMIZING" if adaptive_reduced else " • ADAPTIVE")

func _process(delta: float) -> void:
	if world_root == null or not adaptive_enabled:
		return
	sample_left -= delta
	if sample_left > 0.0:
		return
	sample_left = SAMPLE_INTERVAL
	var fps := Engine.get_frames_per_second()
	var target_fps := 60.0 if resolved_tier != "LOW" else 45.0
	var reduce_threshold := target_fps - 7.0
	var restore_threshold := target_fps - 2.0
	if fps < reduce_threshold:
		low_fps_time += SAMPLE_INTERVAL
		high_fps_time = 0.0
	elif fps > restore_threshold:
		high_fps_time += SAMPLE_INTERVAL
		low_fps_time = 0.0
	else:
		low_fps_time = maxf(low_fps_time - SAMPLE_INTERVAL * .5, 0.0)
		high_fps_time = maxf(high_fps_time - SAMPLE_INTERVAL * .5, 0.0)
	if not adaptive_reduced and low_fps_time >= REDUCE_AFTER:
		adaptive_reduced = true
		_apply_presentation()
	elif adaptive_reduced and high_fps_time >= RESTORE_AFTER:
		adaptive_reduced = false
		_apply_presentation()

func _apply_presentation() -> void:
	if world_root == null:
		return
	WorldBuilder.set_presentation_quality(world_root, effects_requested, adaptive_reduced, resolved_tier)
	var viewport := world_root.get_viewport()
	if viewport != null:
		viewport.scaling_3d_scale = _render_scale()

func _render_scale() -> float:
	# Fixed manual tiers are predictable and visibly distinct. AUTO begins at
	# the detected tier, then is the only path permitted to shed 3D scale.
	var scale_by_tier := {
		"LOW": .68,
		"MEDIUM": .75,
		"HIGH": .90,
		"ULTRA": 1.0,
	}
	var scale_value := float(scale_by_tier.get(resolved_tier, .90))
	return maxf(.60, scale_value - (.10 if adaptive_reduced else 0.0))
