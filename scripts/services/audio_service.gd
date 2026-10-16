extends Node

## Shared audio authority. Gameplay sounds route through SFX and menu/UI feedback
## through UI; focus muting preserves the player's saved Master-volume intent.
signal bus_volume_changed(bus_name: String, linear_volume: float)
signal focus_mute_changed(is_muted: bool)

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"
const UI_CONFIRM_SOUND := preload("res://assets/audio/reload_click.wav")

var application_has_focus := true
var muted_for_focus := false
var ui_feedback: AudioStreamPlayer

func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_UI)
	_build_ui_feedback()
	SettingsService.setting_changed.connect(_on_setting_changed)
	_apply_saved_volumes()

func set_bus_linear_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var clamped := clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(clamped, 0.0001)))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(clamped))
	if bus_name == "Master":
		_apply_focus_mute_policy()
	bus_volume_changed.emit(bus_name, clamped)

func set_muted_when_unfocused(enabled: bool) -> void:
	SettingsService.set_setting("mute_when_unfocused", enabled)

func set_application_focus(has_focus: bool) -> void:
	application_has_focus = has_focus
	_apply_focus_mute_policy()

func play_ui_confirm() -> void:
	_play_ui_feedback(1.0)

func play_ui_back() -> void:
	_play_ui_feedback(0.86)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_application_focus(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		set_application_focus(true)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)

func _build_ui_feedback() -> void:
	ui_feedback = AudioStreamPlayer.new()
	ui_feedback.name = "UI feedback"
	ui_feedback.stream = UI_CONFIRM_SOUND
	ui_feedback.bus = BUS_UI
	ui_feedback.volume_db = -18.0
	add_child(ui_feedback)

func _play_ui_feedback(pitch: float) -> void:
	if ui_feedback == null:
		return
	ui_feedback.pitch_scale = pitch
	if ui_feedback.playing:
		ui_feedback.stop()
	ui_feedback.play()

func _apply_saved_volumes() -> void:
	set_bus_linear_volume("Master", float(SettingsService.get_setting("master_volume", 1.0)))
	set_bus_linear_volume(BUS_MUSIC, float(SettingsService.get_setting("music_volume", 0.75)))
	set_bus_linear_volume(BUS_SFX, float(SettingsService.get_setting("sfx_volume", 0.85)))
	set_bus_linear_volume(BUS_UI, float(SettingsService.get_setting("ui_volume", 0.85)))
	_apply_focus_mute_policy()

func _apply_focus_mute_policy() -> void:
	var master_index := AudioServer.get_bus_index("Master")
	if master_index < 0:
		return
	var should_mute := not application_has_focus and bool(SettingsService.get_setting("mute_when_unfocused", true))
	if should_mute:
		AudioServer.set_bus_mute(master_index, true)
	else:
		var master_volume := clampf(float(SettingsService.get_setting("master_volume", 1.0)), 0.0, 1.0)
		AudioServer.set_bus_mute(master_index, is_zero_approx(master_volume))
	if muted_for_focus != should_mute:
		muted_for_focus = should_mute
		focus_mute_changed.emit(muted_for_focus)

func _on_setting_changed(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			set_bus_linear_volume("Master", float(value))
		"music_volume":
			set_bus_linear_volume(BUS_MUSIC, float(value))
		"sfx_volume":
			set_bus_linear_volume(BUS_SFX, float(value))
		"ui_volume":
			set_bus_linear_volume(BUS_UI, float(value))
		"mute_when_unfocused":
			_apply_focus_mute_policy()
