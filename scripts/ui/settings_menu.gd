class_name RedlineSettingsMenu
extends PanelContainer

## Reusable settings surface for front-end and future pause-menu hosting. It
## edits SettingsService only; compatibility persistence keeps the existing
## Desert runtime's RedlineSettings path in sync for the next map hand-off.
signal close_requested

const MIN_TARGET := Vector2(210, 52)

enum Section {
	GRAPHICS,
	AUDIO,
	CONTROLS,
	ACCESSIBILITY,
	OTHER,
}

var current_section: Section = Section.GRAPHICS
var section_body: VBoxContainer
var tab_buttons: Array[Button] = []
var reset_dialog: ConfirmationDialog

func _ready() -> void:
	name = "Settings Menu"
	custom_minimum_size = Vector2(760, 470)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_shell()
	_render_section()

func focus_initial_control() -> void:
	if not tab_buttons.is_empty():
		tab_buttons[current_section].grab_focus()

func _build_shell() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = tr("menu.settings")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_font_override("font", get_theme_font("font", "Button"))
	header.add_child(title)
	var close_button := _make_button("menu.back", _close, "Return to main menu")
	close_button.custom_minimum_size = Vector2(150, MIN_TARGET.y)
	header.add_child(close_button)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	for section in Section.values():
		var tab := Button.new()
		tab.text = _section_title(section)
		tab.custom_minimum_size = Vector2(132, 48)
		tab.toggle_mode = true
		tab.button_pressed = section == current_section
		tab.pressed.connect(_select_section.bind(section))
		tabs.add_child(tab)
		tab_buttons.append(tab)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	section_body = VBoxContainer.new()
	section_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_body.add_theme_constant_override("separation", 9)
	scroll.add_child(section_body)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	root.add_child(footer)
	var reset := _make_button("settings.reset_defaults", _ask_reset, "Reset all settings")
	reset.custom_minimum_size = Vector2(240, MIN_TARGET.y)
	footer.add_child(reset)

	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = tr("settings.reset_title")
	reset_dialog.dialog_text = tr("settings.reset_warning")
	reset_dialog.ok_button_text = tr("settings.confirm_reset")
	reset_dialog.cancel_button_text = tr("menu.back")
	reset_dialog.confirmed.connect(_reset_defaults)
	add_child(reset_dialog)

func _select_section(section: Section) -> void:
	current_section = section
	for index in range(tab_buttons.size()):
		tab_buttons[index].button_pressed = index == current_section
	_render_section()

func _render_section() -> void:
	for child in section_body.get_children():
		child.queue_free()
	var hint := Label.new()
	hint.text = _section_hint(current_section)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate.a = 0.78
	section_body.add_child(hint)
	match current_section:
		Section.GRAPHICS:
			_build_graphics()
		Section.AUDIO:
			_build_audio()
		Section.CONTROLS:
			_build_controls()
		Section.ACCESSIBILITY:
			_build_accessibility()
		Section.OTHER:
			_build_other()

func _build_graphics() -> void:
	_add_choice("settings.quality_tier", "quality_tier", ["AUTO", "LOW", "MEDIUM", "HIGH", "ULTRA"], ["AUTO", "LOW", "MEDIUM", "HIGH", "ULTRA"])
	_add_choice("settings.render_scale", "render_scale", ["65%", "75%", "85%", "100%"], [0.65, 0.75, 0.85, 1.0])
	_add_toggle("settings.shadows", "shadows_enabled")
	_add_choice("settings.anti_aliasing", "anti_aliasing", [tr("settings.off"), "FXAA"], ["OFF", "FXAA"])
	_add_slider("settings.fov", "fov", 60.0, 100.0, 1.0, "°")
	_add_slider("settings.brightness", "brightness", 0.5, 1.5, 0.05, "%")
	_add_choice("settings.fps_limit", "fps_limit", [tr("settings.unlimited"), "30", "45", "60"], [0, 30, 45, 60])
	_add_toggle("settings.show_fps", "show_fps")

func _build_audio() -> void:
	_add_slider("settings.master_volume", "master_volume", 0.0, 1.0, 0.05, "%")
	_add_slider("settings.music_volume", "music_volume", 0.0, 1.0, 0.05, "%")
	_add_slider("settings.sfx_volume", "sfx_volume", 0.0, 1.0, 0.05, "%")
	_add_slider("settings.ui_volume", "ui_volume", 0.0, 1.0, 0.05, "%")
	_add_toggle("settings.mute_unfocused", "mute_when_unfocused")

func _build_controls() -> void:
	_add_slider("settings.look_sensitivity", "look_sensitivity", 0.55, 1.65, 0.05, "×")
	_add_toggle("settings.aim_assist", "aim_assist")
	_add_slider("settings.aim_assist_strength", "auto_aim_strength", 0.0, 1.0, 0.05, "%")
	_add_choice("settings.fire_mode", "fire_mode", [tr("settings.single"), tr("settings.auto_fire")], ["SINGLE", "AUTO"])
	_add_slider("settings.joystick_scale", "touch_joystick_scale", 0.75, 1.35, 0.05, "×")
	_add_slider("settings.touch_opacity", "touch_opacity", 0.35, 1.0, 0.05, "%")
	_add_slider("settings.button_scale", "button_scale", 0.75, 1.35, 0.05, "×")
	_add_toggle("settings.left_handed", "touch_left_handed")
	_add_note("settings.hud_layout_note")

func _build_accessibility() -> void:
	_add_toggle("settings.subtitles", "subtitles")
	_add_toggle("settings.damage_numbers", "damage_numbers")
	_add_toggle("settings.reduce_shake", "reduce_screen_shake")
	_add_choice("settings.colorblind", "colorblind_mode", [tr("settings.off"), "Protanopia", "Deuteranopia", "Tritanopia"], ["OFF", "PROTANOPIA", "DEUTERANOPIA", "TRITANOPIA"])
	_add_toggle("settings.haptics", "haptics")

func _build_other() -> void:
	_add_choice("settings.language", "language", [tr("settings.auto"), "English", "বাংলা"], ["AUTO", "EN", "BN"])
	_add_toggle("settings.show_fps", "show_fps")
	_add_note("settings.persistence_note")

func _add_choice(label_key: String, setting_key: String, labels: Array[String], values: Array) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)
	section_body.add_child(row)
	var label := Label.new()
	label.text = tr(label_key)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var choice := OptionButton.new()
	choice.custom_minimum_size = Vector2(250, 48)
	var selected_value: Variant = SettingsService.get_setting(setting_key, values[0])
	for index in range(labels.size()):
		choice.add_item(labels[index])
		if str(values[index]) == str(selected_value):
			choice.select(index)
	choice.item_selected.connect(_set_choice.bind(setting_key, values))
	row.add_child(choice)

func _add_toggle(label_key: String, setting_key: String) -> void:
	var toggle := CheckButton.new()
	toggle.text = tr(label_key)
	toggle.button_pressed = bool(SettingsService.get_setting(setting_key, false))
	toggle.custom_minimum_size = Vector2(0, 48)
	toggle.toggled.connect(_set_toggle.bind(setting_key))
	section_body.add_child(toggle)

func _add_slider(label_key: String, setting_key: String, minimum: float, maximum: float, step: float, suffix: String) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	section_body.add_child(row)
	var header := HBoxContainer.new()
	row.add_child(header)
	var label := Label.new()
	label.text = tr(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(80, 0)
	header.add_child(value_label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = clampf(float(SettingsService.get_setting(setting_key, minimum)), minimum, maximum)
	slider.custom_minimum_size = Vector2(0, 30)
	row.add_child(slider)
	_update_slider_label(value_label, slider.value, suffix)
	slider.value_changed.connect(_set_slider.bind(setting_key, value_label, suffix))

func _add_note(key: String) -> void:
	var note := Label.new()
	note.text = tr(key)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate.a = 0.72
	section_body.add_child(note)

func _set_choice(index: int, setting_key: String, values: Array) -> void:
	if index < 0 or index >= values.size():
		return
	var value: Variant = values[index]
	SettingsService.set_setting(setting_key, value)
	if setting_key == "language":
		LocalizationService.set_language_preference(str(value))
	elif setting_key == "fps_limit":
		Engine.max_fps = int(value)

func _set_toggle(enabled: bool, setting_key: String) -> void:
	SettingsService.set_setting(setting_key, enabled)

func _set_slider(value: float, setting_key: String, value_label: Label, suffix: String) -> void:
	SettingsService.set_setting(setting_key, value)
	_update_slider_label(value_label, value, suffix)

func _update_slider_label(value_label: Label, value: float, suffix: String) -> void:
	if suffix == "%":
		value_label.text = "%d%%" % roundi(value * 100.0)
	else:
		value_label.text = "%.2f%s" % [value, suffix]

func _ask_reset() -> void:
	reset_dialog.popup_centered(Vector2i(520, 220))

func _reset_defaults() -> void:
	SettingsService.reset_to_defaults()
	LocalizationService.set_language_preference(str(SettingsService.get_setting("language", "AUTO")))
	Engine.max_fps = int(SettingsService.get_setting("fps_limit", 0))
	_render_section()

func _close() -> void:
	close_requested.emit()

func _make_button(key: String, callback: Callable, hint: String) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.tooltip_text = hint
	button.custom_minimum_size = MIN_TARGET
	button.pressed.connect(callback)
	return button

func _section_title(section: Section) -> String:
	match section:
		Section.GRAPHICS:
			return tr("settings.graphics")
		Section.AUDIO:
			return tr("settings.audio")
		Section.CONTROLS:
			return tr("settings.controls")
		Section.ACCESSIBILITY:
			return tr("settings.accessibility")
		_:
			return tr("settings.other")

func _section_hint(section: Section) -> String:
	match section:
		Section.GRAPHICS:
			return tr("settings.graphics_hint")
		Section.AUDIO:
			return tr("settings.audio_hint")
		Section.CONTROLS:
			return tr("settings.controls_hint")
		Section.ACCESSIBILITY:
			return tr("settings.accessibility_hint")
		_:
			return tr("settings.other_hint")
