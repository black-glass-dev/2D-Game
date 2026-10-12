class_name RedlineSettings
extends RefCounted

## Persistent player presentation/input settings. HUD placement stays separate so
## layout resets never discard gameplay/preferences.
const SETTINGS_FILE := "user://operation_redline_settings.cfg"
const QUALITY_TIERS := ["AUTO", "LOW", "MEDIUM", "HIGH", "ULTRA"]

var look_sensitivity := 1.0
var aim_assist := true
var screen_effects := true
var quality_tier := "AUTO"

func load_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		return
	look_sensitivity = clampf(float(config.get_value("settings", "look_sensitivity", 1.0)), 0.55, 1.65)
	aim_assist = bool(config.get_value("settings", "aim_assist", true))
	screen_effects = bool(config.get_value("settings", "screen_effects", true))
	var saved_tier := str(config.get_value("settings", "quality_tier", "AUTO")).to_upper()
	quality_tier = saved_tier if saved_tier in QUALITY_TIERS else "AUTO"

func save_to_disk() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "look_sensitivity", look_sensitivity)
	config.set_value("settings", "aim_assist", aim_assist)
	config.set_value("settings", "screen_effects", screen_effects)
	config.set_value("settings", "quality_tier", quality_tier)
	config.save(SETTINGS_FILE)

func cycle_quality_tier() -> void:
	var current := QUALITY_TIERS.find(quality_tier)
	quality_tier = QUALITY_TIERS[(current + 1) % QUALITY_TIERS.size()]

func resolved_quality_tier() -> String:
	if quality_tier != "AUTO":
		return quality_tier
	# CPU-count is intentionally conservative: the automatic first launch starts
	# at a stable tier, and the governor can only reduce visual quality.
	var cores := OS.get_processor_count()
	if not OS.has_feature("mobile"):
		return "ULTRA" if cores >= 8 else "HIGH"
	if cores <= 4:
		return "LOW"
	if cores <= 6:
		return "MEDIUM"
	return "HIGH"
