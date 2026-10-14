extends Node

## Schema-versioned preferences service. It migrates the existing settings file
## without deleting it, allowing the current Desert runtime to continue reading
## its legacy configuration until the later compatibility hand-off.
signal setting_changed(key: String, value: Variant)
signal settings_loaded

const SETTINGS_PATH := "user://settings.cfg"
const LEGACY_SETTINGS_PATH := "user://operation_redline_settings.cfg"
const SCHEMA_VERSION := 1

const DEFAULTS := {
	"language": "AUTO",
	"quality_tier": "AUTO",
	"render_scale": 1.0,
	"shadows_enabled": true,
	"anti_aliasing": "OFF",
	"fov": 75.0,
	"brightness": 1.0,
	"fps_limit": 0,
	"show_fps": false,
	"master_volume": 1.0,
	"music_volume": 0.75,
	"sfx_volume": 0.85,
	"ui_volume": 0.85,
	"mute_when_unfocused": true,
	"look_sensitivity": 1.0,
	"aim_assist": true,
	"auto_aim_strength": 1.0,
	"touch_joystick_scale": 1.0,
	"touch_opacity": 1.0,
	"touch_left_handed": false,
	"button_scale": 1.0,
	"gamepad_deadzone": 0.20,
	"subtitles": true,
	"damage_numbers": true,
	"reduce_screen_shake": false,
	"colorblind_mode": "OFF",
	"haptics": true,
	"fire_mode": "SINGLE",
}

var values: Dictionary = {}

func _ready() -> void:
	load_from_disk()

func load_from_disk() -> void:
	values = DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		_load_current_schema(config)
	else:
		_migrate_legacy_settings()
	_save_to_disk()
	settings_loaded.emit()

func get_setting(key: String, fallback: Variant = null) -> Variant:
	return values.get(key, fallback)

func set_setting(key: String, value: Variant, persist := true) -> void:
	values[key] = value
	if persist:
		_save_to_disk()
	setting_changed.emit(key, value)

func reset_to_defaults() -> void:
	values = DEFAULTS.duplicate(true)
	_save_to_disk()
	for key in values:
		setting_changed.emit(str(key), values[key])

func _load_current_schema(config: ConfigFile) -> void:
	var version := int(config.get_value("meta", "schema_version", 0))
	for key in DEFAULTS:
		values[key] = config.get_value("settings", key, DEFAULTS[key])
	if version < SCHEMA_VERSION:
		_migrate_schema(version)

func _migrate_schema(_from_version: int) -> void:
	# Schema 1 is additive. Defaults above safely populate any absent key.
	pass

func _migrate_legacy_settings() -> void:
	var legacy := ConfigFile.new()
	if legacy.load(LEGACY_SETTINGS_PATH) != OK:
		return
	for key in ["look_sensitivity", "aim_assist", "screen_effects", "quality_tier", "fire_mode"]:
		if legacy.has_section_key("settings", key):
			values[key] = legacy.get_value("settings", key)
	# The old presentation flag maps to a new accessibility-friendly default.
	if legacy.has_section_key("settings", "screen_effects"):
		values["reduce_screen_shake"] = not bool(legacy.get_value("settings", "screen_effects", true))

func _save_to_disk() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	for key in values:
		config.set_value("settings", key, values[key])
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		push_warning("SettingsService could not save settings.cfg: %s" % result)
