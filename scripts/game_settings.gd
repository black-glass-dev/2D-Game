class_name RedlineSettings
extends RefCounted

## Persistent player presentation/input settings. HUD placement stays separate so
## layout resets never discard gameplay/preferences.
const SETTINGS_FILE := "user://operation_redline_settings.cfg"
const QUALITY_TIERS := ["AUTO", "LOW", "MEDIUM", "HIGH", "ULTRA"]
const FIRE_MODES := ["SINGLE", "AUTO"]

var look_sensitivity := 1.0
var aim_assist := true
var screen_effects := true
var quality_tier := "AUTO"
# SINGLE preserves the original tap-to-fire mobile behaviour. AUTO is opt-in
# and only changes how a held FIRE touch is sampled; weapon ammo/damage remain
# entirely owned by the existing rifle/pistol scripts.
var fire_mode := "SINGLE"

func load_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		return
	look_sensitivity = clampf(float(config.get_value("settings", "look_sensitivity", 1.0)), 0.55, 1.65)
	aim_assist = bool(config.get_value("settings", "aim_assist", true))
	screen_effects = bool(config.get_value("settings", "screen_effects", true))
	var saved_tier := str(config.get_value("settings", "quality_tier", "AUTO")).to_upper()
	quality_tier = saved_tier if saved_tier in QUALITY_TIERS else "AUTO"
	var saved_fire_mode := str(config.get_value("settings", "fire_mode", "SINGLE")).to_upper()
	fire_mode = saved_fire_mode if saved_fire_mode in FIRE_MODES else "SINGLE"

func save_to_disk() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "look_sensitivity", look_sensitivity)
	config.set_value("settings", "aim_assist", aim_assist)
	config.set_value("settings", "screen_effects", screen_effects)
	config.set_value("settings", "quality_tier", quality_tier)
	config.set_value("settings", "fire_mode", fire_mode)
	config.save(SETTINGS_FILE)

func cycle_quality_tier() -> void:
	var current := QUALITY_TIERS.find(quality_tier)
	quality_tier = QUALITY_TIERS[(current + 1) % QUALITY_TIERS.size()]

func toggle_fire_mode() -> void:
	fire_mode = "AUTO" if fire_mode == "SINGLE" else "SINGLE"

func uses_adaptive_quality() -> bool:
	return quality_tier == "AUTO"

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
