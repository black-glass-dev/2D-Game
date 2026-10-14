extends Node

## Shared audio bus authority. Existing weapon/landing players remain on Master
## until the compatibility hand-off assigns them to SFX, so this service cannot
## change current Desert combat audio during the foundation batch.
signal bus_volume_changed(bus_name: String, linear_volume: float)

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_UI)
	_apply_saved_volumes()

func set_bus_linear_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var clamped := clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(clamped, 0.0001)))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(clamped))
	bus_volume_changed.emit(bus_name, clamped)

func set_muted_when_unfocused(enabled: bool) -> void:
	SettingsService.set_setting("mute_when_unfocused", enabled)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and bool(SettingsService.get_setting("mute_when_unfocused", true)):
		AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)

func _apply_saved_volumes() -> void:
	set_bus_linear_volume("Master", float(SettingsService.get_setting("master_volume", 1.0)))
	set_bus_linear_volume(BUS_MUSIC, float(SettingsService.get_setting("music_volume", 0.75)))
	set_bus_linear_volume(BUS_SFX, float(SettingsService.get_setting("sfx_volume", 0.85)))
	set_bus_linear_volume(BUS_UI, float(SettingsService.get_setting("ui_volume", 0.85)))
