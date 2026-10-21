extends CanvasLayer

## Centralized asynchronous scene loading with a non-interactive fade overlay.
## Boot owns the player-facing loading presentation; this service reports only
## actual threaded-loader stages, progress samples, and elapsed time.
signal load_started(scene_path: String)
signal load_stage_changed(scene_path: String, stage: String, progress: float, elapsed_msec: int)
signal load_progress(scene_path: String, progress: float)
signal load_failed(scene_path: String, error_code: Error, elapsed_msec: int)
signal load_finished(scene_path: String, elapsed_msec: int)

const STAGE_REQUESTED := "REQUESTED"
const STAGE_STREAMING := "STREAMING"
const STAGE_READY := "READY"
const STAGE_TRANSITIONING := "TRANSITIONING"
const STAGE_COMPLETE := "COMPLETE"
const STAGE_FAILED := "FAILED"

var pending_path := ""
var pending_progress := []
var is_loading := false
var active_stage := ""
var active_progress := 0.0
var active_started_msec := 0
var active_progress_samples := 0
var last_load_telemetry: Dictionary = {}
var fade: ColorRect

func _ready() -> void:
	layer = 100
	fade = ColorRect.new()
	fade.name = "Scene transition fade"
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

func load_scene(scene_path: String) -> Error:
	if is_loading or scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_record_immediate_failure(scene_path, ERR_INVALID_PARAMETER)
		return ERR_INVALID_PARAMETER
	var request_result := ResourceLoader.load_threaded_request(scene_path)
	if request_result != OK:
		_record_immediate_failure(scene_path, request_result)
		return request_result
	pending_path = scene_path
	pending_progress = []
	is_loading = true
	active_stage = STAGE_REQUESTED
	active_progress = 0.0
	active_started_msec = Time.get_ticks_msec()
	active_progress_samples = 0
	load_started.emit(scene_path)
	_emit_stage_changed()
	return OK

func get_active_telemetry() -> Dictionary:
	if not is_loading:
		return {}
	return _telemetry_snapshot("")

func get_last_load_telemetry() -> Dictionary:
	return last_load_telemetry.duplicate(true)

func _process(_delta: float) -> void:
	if not is_loading:
		return
	var status := ResourceLoader.load_threaded_get_status(pending_path, pending_progress)
	if pending_progress.size() > 0:
		var progress := clampf(float(pending_progress[0]), 0.0, 1.0)
		if active_stage == STAGE_REQUESTED:
			active_stage = STAGE_STREAMING
		active_progress = progress
		active_progress_samples += 1
		load_progress.emit(pending_path, active_progress)
		_emit_stage_changed()
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_finish_load()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_fail_active_request(ERR_CANT_ACQUIRE_RESOURCE)

func _finish_load() -> void:
	var scene := ResourceLoader.load_threaded_get(pending_path) as PackedScene
	if scene == null:
		_fail_active_request(ERR_CANT_ACQUIRE_RESOURCE)
		return
	active_progress = 1.0
	active_stage = STAGE_READY
	load_progress.emit(pending_path, active_progress)
	_emit_stage_changed()
	active_stage = STAGE_TRANSITIONING
	_emit_stage_changed()
	var scene_path := pending_path
	var started_msec := active_started_msec
	var progress_samples := active_progress_samples
	_reset_active_request()
	_transition_to(scene, scene_path, started_msec, progress_samples)

func _transition_to(scene: PackedScene, scene_path: String, started_msec: int, progress_samples: int) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.25)
	tween.tween_callback(get_tree().change_scene_to_packed.bind(scene))
	tween.tween_property(fade, "color:a", 0.0, 0.25)
	tween.tween_callback(_complete_load.bind(scene_path, started_msec, progress_samples))

func _complete_load(scene_path: String, started_msec: int, progress_samples: int) -> void:
	var elapsed_msec := maxi(Time.get_ticks_msec() - started_msec, 0)
	last_load_telemetry = {
		"scene_path": scene_path,
		"stage": STAGE_COMPLETE,
		"progress": 1.0,
		"elapsed_msec": elapsed_msec,
		"progress_samples": progress_samples,
		"outcome": "loaded",
	}
	load_finished.emit(scene_path, elapsed_msec)

func _fail_active_request(error_code: Error) -> void:
	active_stage = STAGE_FAILED
	_emit_stage_changed()
	var failed_path := pending_path
	var elapsed_msec := _active_elapsed_msec()
	last_load_telemetry = _telemetry_snapshot("failed")
	_reset_active_request()
	load_failed.emit(failed_path, error_code, elapsed_msec)

func _record_immediate_failure(scene_path: String, error_code: Error) -> void:
	last_load_telemetry = {
		"scene_path": scene_path,
		"stage": STAGE_FAILED,
		"progress": 0.0,
		"elapsed_msec": 0,
		"progress_samples": 0,
		"outcome": "failed",
	}
	load_failed.emit(scene_path, error_code, 0)

func _emit_stage_changed() -> void:
	load_stage_changed.emit(pending_path, active_stage, active_progress, _active_elapsed_msec())

func _telemetry_snapshot(outcome: String) -> Dictionary:
	return {
		"scene_path": pending_path,
		"stage": active_stage,
		"progress": active_progress,
		"elapsed_msec": _active_elapsed_msec(),
		"progress_samples": active_progress_samples,
		"outcome": outcome,
	}

func _active_elapsed_msec() -> int:
	return maxi(Time.get_ticks_msec() - active_started_msec, 0)

func _reset_active_request() -> void:
	is_loading = false
	pending_path = ""
	pending_progress = []
	active_stage = ""
	active_progress = 0.0
	active_started_msec = 0
	active_progress_samples = 0
