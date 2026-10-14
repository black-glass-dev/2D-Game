extends Node

## Player progression/save contract. Current HUD layout remains in its legacy
## ConfigFile until the M1 compatibility adapter imports it; this service never
## deletes or overwrites that file.
signal save_loaded
signal save_changed

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 1
const LEGACY_HUD_LAYOUT_PATH := "user://operation_redline_hud.cfg"

var data: Dictionary = {}

func _ready() -> void:
	load_from_disk()

func load_from_disk() -> void:
	data = _default_data()
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				data.merge(parsed, true)
	_migrate_schema()
	_save_to_disk()
	save_loaded.emit()

func is_map_unlocked(map_id: String) -> bool:
	var unlocked: Array = data.get("unlocked_maps", [])
	return map_id in unlocked

func unlock_map(map_id: String) -> void:
	if map_id.is_empty() or is_map_unlocked(map_id):
		return
	var unlocked: Array = data.get("unlocked_maps", []).duplicate()
	unlocked.append(map_id)
	data["unlocked_maps"] = unlocked
	_commit()

func set_last_map(map_id: String) -> void:
	if map_id.is_empty():
		return
	data["last_map"] = map_id
	_commit()

func get_last_map() -> String:
	return str(data.get("last_map", "MP_DS_01"))

func set_best_result(map_id: String, score: int, wave: int) -> void:
	if map_id.is_empty():
		return
	var best_results: Dictionary = data.get("best_results", {}).duplicate(true)
	var previous: Dictionary = best_results.get(map_id, {})
	best_results[map_id] = {
		"score": maxi(score, int(previous.get("score", 0))),
		"wave": maxi(wave, int(previous.get("wave", 0))),
	}
	data["best_results"] = best_results
	_commit()

func get_best_result(map_id: String) -> Dictionary:
	var best_results: Dictionary = data.get("best_results", {})
	return best_results.get(map_id, {"score": 0, "wave": 0}).duplicate(true)

func set_touch_layout(layout: Dictionary) -> void:
	data["touch_layout"] = layout.duplicate(true)
	_commit()

func get_touch_layout() -> Dictionary:
	return Dictionary(data.get("touch_layout", {})).duplicate(true)

func _default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"unlocked_maps": ["MP_DS_01"],
		"best_results": {},
		"last_map": "MP_DS_01",
		"touch_layout": {},
		"legacy_hud_layout_present": FileAccess.file_exists(LEGACY_HUD_LAYOUT_PATH),
	}

func _migrate_schema() -> void:
	var schema_version := int(data.get("schema_version", 0))
	if schema_version < 1:
		data.merge(_default_data(), false)
	data["schema_version"] = SCHEMA_VERSION
	if not data.has("legacy_hud_layout_present"):
		data["legacy_hud_layout_present"] = FileAccess.file_exists(LEGACY_HUD_LAYOUT_PATH)

func _commit() -> void:
	_save_to_disk()
	save_changed.emit()

func _save_to_disk() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveService could not open save.json for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))
