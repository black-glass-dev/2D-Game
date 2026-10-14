extends CanvasLayer

## Centralized asynchronous scene loading with a non-interactive fade overlay.
## No existing scene calls this service yet, so Main.tscn remains directly
## runnable until the menu flow adopts it in M2.
signal load_started(scene_path: String)
signal load_progress(scene_path: String, progress: float)
signal load_failed(scene_path: String, error_code: Error)
signal load_finished(scene_path: String)

var pending_path := ""
var pending_progress := []
var is_loading := false
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
		return ERR_INVALID_PARAMETER
	var request_result := ResourceLoader.load_threaded_request(scene_path)
	if request_result != OK:
		load_failed.emit(scene_path, request_result)
		return request_result
	pending_path = scene_path
	pending_progress = []
	is_loading = true
	load_started.emit(scene_path)
	return OK

func _process(_delta: float) -> void:
	if not is_loading:
		return
	var status := ResourceLoader.load_threaded_get_status(pending_path, pending_progress)
	if pending_progress.size() > 0:
		load_progress.emit(pending_path, clampf(float(pending_progress[0]), 0.0, 1.0))
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_finish_load()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		var failed_path := pending_path
		_reset_request()
		load_failed.emit(failed_path, ERR_CANT_ACQUIRE_RESOURCE)

func _finish_load() -> void:
	var scene := ResourceLoader.load_threaded_get(pending_path) as PackedScene
	var loaded_path := pending_path
	_reset_request()
	if scene == null:
		load_failed.emit(loaded_path, ERR_CANT_ACQUIRE_RESOURCE)
		return
	_transition_to(scene, loaded_path)

func _transition_to(scene: PackedScene, scene_path: String) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.25)
	tween.tween_callback(get_tree().change_scene_to_packed.bind(scene))
	tween.tween_property(fade, "color:a", 0.0, 0.25)
	tween.tween_callback(load_finished.emit.bind(scene_path))

func _reset_request() -> void:
	is_loading = false
	pending_path = ""
	pending_progress = []
