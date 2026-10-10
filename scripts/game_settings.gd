class_name RedlineSettings
extends RefCounted

## Small persistent presentation/input settings store. HUD placement remains in
## its own config so a player can reset layout without losing preferences.
const SETTINGS_FILE := "user://operation_redline_settings.cfg"

var look_sensitivity := 1.0
var aim_assist := true
var screen_effects := true

func load_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		return
	look_sensitivity = clampf(float(config.get_value("settings", "look_sensitivity", 1.0)), 0.55, 1.65)
	aim_assist = bool(config.get_value("settings", "aim_assist", true))
	screen_effects = bool(config.get_value("settings", "screen_effects", true))

func save_to_disk() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "look_sensitivity", look_sensitivity)
	config.set_value("settings", "aim_assist", aim_assist)
	config.set_value("settings", "screen_effects", screen_effects)
	config.save(SETTINGS_FILE)
