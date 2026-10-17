extends Control

## First player-facing shell for Operation Redline. The legacy Main scene remains
## a playable map scene; this boot flow owns only title, menu, map selection,
## lightweight settings and the hand-off to SceneLoader.

enum View {
	SPLASH,
	MENU,
	MAP_SELECT,
	SETTINGS,
	LOADING,
}

const REDLINE_THEME := preload("res://ui/theme/redline_theme.tres")
const SPLASH_SECONDS := 1.35
const MIN_TOUCH_TARGET := Vector2(320, 58)
const BOOT_FLOW_TEST_ARGUMENT := "--verify-boot-flow"
const SETTINGS_MENU_TEST_ARGUMENT := "--verify-settings-menu"
const MAP_SELECT_TEST_ARGUMENT := "--verify-map-select"
const PAUSE_FLOW_TEST_ARGUMENT := "--verify-pause-flow"
const RESULT_FLOW_TEST_ARGUMENT := "--verify-result-flow"
const AUDIO_FLOW_TEST_ARGUMENT := "--verify-audio-flow"
const INPUT_ACCESSIBILITY_TEST_ARGUMENT := "--verify-input-accessibility-flow"
const CONTROL_LAYOUT_TEST_ARGUMENT := "--verify-control-layout-flow"
const REBIND_FLOW_TEST_ARGUMENT := "--verify-rebind-flow"
const LOADING_FLOW_TEST_ARGUMENT := "--verify-loading-flow"
const BACK_FLOW_TEST_ARGUMENT := "--verify-back-flow"

var active_view: View = View.SPLASH
var selected_map_id := "MP_DS_01"
var background: ColorRect
var root_margin: MarginContainer
var title_label: Label
var subtitle_label: Label
var content: PanelContainer
var footer_label: Label
var splash_layer: CenterContainer
var splash_title: Label
var splash_hint: Label
var loading_label: Label
var loading_bar: ProgressBar
var loading_stage := "REQUESTED"
var loading_progress := 0.0
var splash_left := SPLASH_SECONDS
var menu_ready := false

func _ready() -> void:
	theme = REDLINE_THEME
	selected_map_id = SaveService.get_last_map()
	if MapRegistry.get_map(selected_map_id) == null:
		selected_map_id = "MP_DS_01"
	GameManager.set_state(GameManager.State.SPLASH)
	SceneLoader.load_stage_changed.connect(_on_load_stage_changed)
	SceneLoader.load_progress.connect(_on_load_progress)
	SceneLoader.load_failed.connect(_on_load_failed)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_build_shell()
	_show_splash()
	if OS.get_cmdline_user_args().has(BACK_FLOW_TEST_ARGUMENT):
		call_deferred("_begin_back_flow_test")
	elif OS.get_cmdline_user_args().has(LOADING_FLOW_TEST_ARGUMENT):
		call_deferred("_begin_loading_flow_test")
	elif OS.get_cmdline_user_args().has(BOOT_FLOW_TEST_ARGUMENT) or OS.get_cmdline_user_args().has(PAUSE_FLOW_TEST_ARGUMENT) or OS.get_cmdline_user_args().has(RESULT_FLOW_TEST_ARGUMENT) or OS.get_cmdline_user_args().has(AUDIO_FLOW_TEST_ARGUMENT) or OS.get_cmdline_user_args().has(INPUT_ACCESSIBILITY_TEST_ARGUMENT) or OS.get_cmdline_user_args().has(CONTROL_LAYOUT_TEST_ARGUMENT) or OS.get_cmdline_user_args().has(REBIND_FLOW_TEST_ARGUMENT):
		call_deferred("_begin_headless_handoff_test")
	elif OS.get_cmdline_user_args().has(SETTINGS_MENU_TEST_ARGUMENT):
		call_deferred("_begin_settings_menu_test")
	elif OS.get_cmdline_user_args().has(MAP_SELECT_TEST_ARGUMENT):
		call_deferred("_begin_map_select_test")

func _begin_headless_handoff_test() -> void:
	_show_menu()
	_start_selected_map()

func _begin_loading_flow_test() -> void:
	_show_menu()
	_start_selected_map()
	if active_view != View.LOADING or loading_bar == null or loading_label == null:
		push_error("Loading-flow verification could not construct the loading presentation.")
		get_tree().quit(1)
		return
	if not is_zero_approx(loading_bar.value) or loading_stage != SceneLoader.STAGE_REQUESTED:
		push_error("Loading-flow verification found fabricated initial loading telemetry.")
		get_tree().quit(1)
		return
	if not loading_label.text.contains(tr("loading.preparing")):
		push_error("Loading-flow verification could not localize the preparing stage.")
		get_tree().quit(1)
		return

func _begin_back_flow_test() -> void:
	await get_tree().process_frame
	if not InputService.menu_back_bindings_ready():
		push_error("Back-flow verification found incomplete keyboard/gamepad menu-back bindings.")
		get_tree().quit(1)
		return
	# Exercise the exact Android back-request callback from splash rather than
	# only calling the shared helper. Splash must return to menu, never exit.
	_show_splash()
	_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	if active_view != View.MENU or GameManager.state != GameManager.State.MAIN_MENU:
		push_error("Back-flow verification could not return from splash.")
		get_tree().quit(1)
		return
	# ESC uses the same named menu action as desktop keyboard navigation.
	_show_settings()
	var keyboard_back := InputEventKey.new()
	keyboard_back.physical_keycode = KEY_ESCAPE
	keyboard_back.pressed = true
	_unhandled_input(keyboard_back)
	if active_view != View.MENU:
		push_error("Back-flow verification could not return from settings by keyboard.")
		get_tree().quit(1)
		return
	# Controller B must follow the same route from map selection.
	_show_map_select()
	var gamepad_back := InputEventJoypadButton.new()
	gamepad_back.button_index = JOY_BUTTON_B
	gamepad_back.pressed = true
	_unhandled_input(gamepad_back)
	if active_view != View.MENU:
		push_error("Back-flow verification could not return from map selection by gamepad.")
		get_tree().quit(1)
		return
	print("BACK_FLOW_PASS views=splash,settings,map_select")
	get_tree().quit()

func _begin_settings_menu_test() -> void:
	_show_menu()
	_show_settings()
	await get_tree().process_frame
	var settings_menu: RedlineSettingsMenu
	for child in content.get_children():
		settings_menu = child as RedlineSettingsMenu
		if settings_menu != null:
			break
	if settings_menu == null:
		push_error("Settings-menu verification could not create RedlineSettingsMenu.")
		get_tree().quit(1)
		return
	var original_tier := str(SettingsService.get_setting("quality_tier", "AUTO"))
	SettingsService.set_setting("quality_tier", "HIGH")
	if str(SettingsService.get_setting("quality_tier", "")) != "HIGH":
		push_error("Settings-menu verification could not persist quality selection.")
		get_tree().quit(1)
		return
	SettingsService.set_setting("quality_tier", original_tier)
	print("SETTINGS_MENU_PASS section=", settings_menu.current_section)
	get_tree().quit()

func _begin_map_select_test() -> void:
	_show_menu()
	_show_map_select()
	await get_tree().process_frame
	var maps: Array[RedlineMapData] = MapRegistry.get_all_maps()
	var highrise: RedlineMapData = MapRegistry.get_map("MP_RF_02")
	if maps.size() < 2 or highrise == null or highrise.can_launch():
		push_error("Map-select verification did not register the locked Highrise card.")
		get_tree().quit(1)
		return
	_select_map(highrise.id)
	await get_tree().process_frame
	if selected_map_id != highrise.id or _selected_map_is_playable():
		push_error("Map-select verification exposed a launch route for a locked map.")
		get_tree().quit(1)
		return
	print("MAP_SELECT_PASS maps=", maps.size(), " selected=", selected_map_id)
	get_tree().quit()

func _process(delta: float) -> void:
	if active_view == View.SPLASH:
		splash_left = maxf(splash_left - delta, 0.0)
		if splash_left <= 0.0:
			_show_menu()
	elif active_view == View.LOADING:
		_refresh_loading_telemetry()

func _unhandled_input(event: InputEvent) -> void:
	if active_view == View.SPLASH and (event is InputEventScreenTouch or event.is_action_pressed(InputService.ACTION_MENU_ACCEPT) or event.is_action_pressed(InputService.ACTION_MENU_BACK)):
		if event is InputEventScreenTouch and not event.pressed:
			return
		_show_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(InputService.ACTION_MENU_BACK):
		_go_back()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(InputService.ACTION_MENU_ACCEPT):
		var focused_control := get_viewport().gui_get_focus_owner()
		if focused_control is Button and not focused_control.disabled:
			focused_control.pressed.emit()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()

func _build_shell() -> void:
	background = ColorRect.new()
	background.name = "Menu Background"
	background.color = Color("07141c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var top_band := ColorRect.new()
	top_band.color = Color(0.04, 0.20, 0.27, 0.68)
	top_band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_band.offset_bottom = 8.0
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(top_band)

	root_margin = MarginContainer.new()
	root_margin.name = "Safe Menu Margin"
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 42)
	root_margin.add_theme_constant_override("margin_top", 32)
	root_margin.add_theme_constant_override("margin_right", 42)
	root_margin.add_theme_constant_override("margin_bottom", 28)
	add_child(root_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	root_margin.add_child(column)

	title_label = Label.new()
	title_label.name = "Operation title"
	title_label.text = tr("app.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color("8ef7ff"))
	title_label.custom_minimum_size = Vector2(0, 54)
	column.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = tr("app.subtitle")
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", Color("f5803a"))
	column.add_child(subtitle_label)

	content = PanelContainer.new()
	content.name = "Menu Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(content)

	footer_label = Label.new()
	footer_label.name = "Menu footer"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 15)
	footer_label.add_theme_color_override("font_color", Color(0.65, 0.80, 0.83, 0.92))
	footer_label.custom_minimum_size = Vector2(0, 28)
	column.add_child(footer_label)

	splash_layer = CenterContainer.new()
	splash_layer.name = "Splash"
	splash_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(splash_layer)
	var splash_box := VBoxContainer.new()
	splash_box.alignment = BoxContainer.ALIGNMENT_CENTER
	splash_box.add_theme_constant_override("separation", 10)
	splash_layer.add_child(splash_box)
	splash_title = Label.new()
	splash_title.text = tr("app.title")
	splash_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_title.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	splash_title.add_theme_font_size_override("font_size", 48)
	splash_title.add_theme_color_override("font_color", Color("8ef7ff"))
	splash_box.add_child(splash_title)
	var line := HSeparator.new()
	line.custom_minimum_size = Vector2(500, 6)
	splash_box.add_child(line)
	var splash_subtitle := Label.new()
	splash_subtitle.text = tr("app.subtitle")
	splash_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_subtitle.add_theme_font_size_override("font_size", 19)
	splash_subtitle.add_theme_color_override("font_color", Color("f5803a"))
	splash_box.add_child(splash_subtitle)
	splash_hint = Label.new()
	splash_hint.text = tr("menu.press_to_continue")
	splash_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_hint.add_theme_font_size_override("font_size", 15)
	splash_hint.modulate.a = 0.78
	splash_box.add_child(splash_hint)

func _show_splash() -> void:
	active_view = View.SPLASH
	GameManager.set_state(GameManager.State.SPLASH)
	root_margin.visible = false
	splash_layer.visible = true
	splash_layer.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(splash_layer, "modulate:a", 1.0, 0.25)

func _show_menu() -> void:
	active_view = View.MENU
	GameManager.set_state(GameManager.State.MAIN_MENU)
	menu_ready = true
	splash_layer.visible = false
	root_margin.visible = true
	footer_label.text = tr("menu.navigation_hint")
	_clear_content()
	var center := CenterContainer.new()
	content.add_child(center)
	var menu := VBoxContainer.new()
	menu.name = "Main Menu Actions"
	menu.custom_minimum_size = Vector2(420, 0)
	menu.add_theme_constant_override("separation", 14)
	center.add_child(menu)
	menu.add_child(_make_menu_button("menu.play", _show_map_select, "Start map selection"))
	menu.add_child(_make_menu_button("menu.continue", _continue_last_map, "Load last playable map"))
	menu.add_child(_make_menu_button("menu.settings", _show_settings, "Open settings"))
	menu.add_child(_make_menu_button("menu.quit", _request_quit, "Close game"))
	_focus_first_button(menu)

func _show_map_select() -> void:
	active_view = View.MAP_SELECT
	GameManager.set_state(GameManager.State.MAP_SELECT)
	footer_label.text = tr("menu.back_hint")
	_clear_content()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	content.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var heading := Label.new()
	heading.text = tr("menu.map_select")
	heading.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	heading.add_theme_font_size_override("font_size", 29)
	layout.add_child(heading)
	var cards_scroll := ScrollContainer.new()
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_scroll.custom_minimum_size = Vector2(0, 238)
	layout.add_child(cards_scroll)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	cards_scroll.add_child(cards)
	var maps: Array[RedlineMapData] = MapRegistry.get_all_maps()
	for map_data in maps:
		cards.add_child(_make_map_card(map_data))
	if maps.is_empty():
		var empty := Label.new()
		empty.text = tr("menu.no_maps")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(420, 0)
		cards.add_child(empty)
	var selected_map := MapRegistry.get_map(selected_map_id)
	if selected_map != null:
		layout.add_child(_make_map_detail(selected_map))
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	var back_button := _make_menu_button("menu.back", _show_menu, "Return to main menu")
	back_button.custom_minimum_size = Vector2(180, MIN_TOUCH_TARGET.y)
	actions.add_child(back_button)
	var deploy_button := _make_menu_button("menu.start_mission", _start_selected_map, "Load selected map")
	deploy_button.custom_minimum_size = Vector2(260, MIN_TOUCH_TARGET.y)
	deploy_button.disabled = not _selected_map_is_playable()
	if deploy_button.disabled:
		deploy_button.text = tr("menu.coming_soon") if selected_map != null and selected_map.is_coming_soon() else tr("menu.locked")
	actions.add_child(deploy_button)
	_focus_first_button(cards)

func _show_settings() -> void:
	active_view = View.SETTINGS
	GameManager.set_state(GameManager.State.MAIN_MENU)
	footer_label.text = tr("menu.back_hint")
	_clear_content()
	var settings_menu := RedlineSettingsMenu.new()
	settings_menu.close_requested.connect(_show_menu)
	content.add_child(settings_menu)
	settings_menu.call_deferred("focus_initial_control")

func _show_loading(map_data: RedlineMapData) -> void:
	active_view = View.LOADING
	GameManager.set_state(GameManager.State.LOADING)
	loading_stage = SceneLoader.STAGE_REQUESTED
	loading_progress = 0.0
	footer_label.text = ""
	_clear_content()
	var center := CenterContainer.new()
	content.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(500, 0)
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var heading := Label.new()
	heading.text = tr("loading.title")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	heading.add_theme_font_size_override("font_size", 32)
	box.add_child(heading)
	var map_name := Label.new()
	map_name.text = map_data.localized_name(LocalizationService.active_locale)
	map_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_name.add_theme_font_size_override("font_size", 24)
	box.add_child(map_name)
	loading_bar = ProgressBar.new()
	loading_bar.min_value = 0.0
	loading_bar.max_value = 100.0
	loading_bar.value = 0.0
	loading_bar.show_percentage = false
	loading_bar.custom_minimum_size = Vector2(0, 28)
	box.add_child(loading_bar)
	loading_label = Label.new()
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(loading_label)
	_refresh_loading_telemetry()

func _make_map_card(map_data: RedlineMapData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(282, 224)
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 14)
	padding.add_theme_constant_override("margin_top", 14)
	padding.add_theme_constant_override("margin_right", 14)
	padding.add_theme_constant_override("margin_bottom", 14)
	card.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	padding.add_child(column)
	var name_label := Label.new()
	name_label.text = map_data.localized_name(LocalizationService.active_locale)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	name_label.add_theme_font_size_override("font_size", 23)
	column.add_child(name_label)
	var environment := Label.new()
	environment.text = map_data.localized_environment(LocalizationService.active_locale)
	environment.modulate.a = 0.78
	column.add_child(environment)
	var description := Label.new()
	description.text = map_data.localized_tagline(LocalizationService.active_locale)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var details := Label.new()
	details.text = _map_card_details(map_data)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_color_override("font_color", Color("f7b06e"))
	column.add_child(details)
	var select_button := _make_menu_button("", _select_map.bind(map_data.id), "Select %s" % map_data.id)
	if map_data.id == selected_map_id:
		select_button.text = tr("menu.selected")
	elif map_data.is_coming_soon():
		select_button.text = tr("menu.coming_soon")
	elif not SaveService.is_map_unlocked(map_data.id):
		select_button.text = tr("menu.locked")
	else:
		select_button.text = tr("menu.select")
	column.add_child(select_button)
	return card

func _make_map_detail(map_data: RedlineMapData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 220)
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 16)
	padding.add_theme_constant_override("margin_top", 14)
	padding.add_theme_constant_override("margin_right", 16)
	padding.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	padding.add_child(column)
	var map_heading := Label.new()
	map_heading.text = "%s  ·  %s" % [tr("map.deployment"), map_data.localized_name(LocalizationService.active_locale)]
	map_heading.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	map_heading.add_theme_font_size_override("font_size", 24)
	map_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(map_heading)
	var status := Label.new()
	status.text = tr("menu.coming_soon") if map_data.is_coming_soon() else (tr("menu.locked") if not SaveService.is_map_unlocked(map_data.id) else tr("map.ready"))
	status.add_theme_color_override("font_color", Color("f7b06e"))
	column.add_child(status)
	var record := Label.new()
	var best_result := SaveService.get_best_result(map_data.id)
	if int(best_result.get("score", 0)) > 0 or int(best_result.get("wave", 0)) > 0:
		record.text = "%s  %05d   •   %s  %d" % [tr("map.best_score"), int(best_result.get("score", 0)), tr("map.best_wave"), int(best_result.get("wave", 0))]
	else:
		record.text = tr("map.no_record")
	record.modulate.a = 0.78
	column.add_child(record)
	var legend_title := Label.new()
	legend_title.text = tr("map.legend")
	legend_title.add_theme_font_size_override("font_size", 18)
	column.add_child(legend_title)
	var legend := Label.new()
	legend.text = "\n".join(_localized_legend(map_data))
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.modulate.a = 0.83
	column.add_child(legend)
	if map_data.can_launch() and SaveService.is_map_unlocked(map_data.id):
		column.add_child(_make_session_selector(tr("map.difficulty"), [tr("game.easy"), tr("game.normal"), tr("game.hard"), tr("game.nightmare")], ["EASY", "NORMAL", "HARD", "NIGHTMARE"], GameManager.selected_difficulty, _set_difficulty))
		column.add_child(_make_session_selector(tr("map.mode"), [tr("game.survival"), tr("game.endless")], ["SURVIVAL", "ENDLESS"], GameManager.selected_mode, _set_mode))
	else:
		var unavailable := Label.new()
		unavailable.text = tr("map.unavailable_detail")
		unavailable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unavailable.modulate.a = 0.76
		column.add_child(unavailable)
	return panel

func _make_session_selector(title: String, labels: Array[String], values: Array[String], selected_value: String, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = title
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(132, 0)
	row.add_child(label)
	for index in range(labels.size()):
		var choice := Button.new()
		choice.text = labels[index]
		choice.toggle_mode = true
		choice.button_pressed = values[index] == selected_value
		choice.custom_minimum_size = Vector2(124, 48)
		choice.pressed.connect(callback.bind(values[index]))
		row.add_child(choice)
	return row

func _map_card_details(map_data: RedlineMapData) -> String:
	if map_data.is_coming_soon():
		return "%s  •  %s" % [map_data.size_label, tr("menu.coming_soon")]
	return "%s  •  %s  •  %d %s" % [map_data.size_label, "★".repeat(map_data.difficulty_stars), map_data.max_waves, tr("map.waves")]

func _localized_legend(map_data: RedlineMapData) -> PackedStringArray:
	return map_data.legend_bn if LocalizationService.is_bengali() else map_data.legend_en

func _make_menu_button(key: String, callback: Callable, accessible_name: String) -> Button:
	var button := Button.new()
	button.text = tr(key) if not key.is_empty() else ""
	button.tooltip_text = accessible_name
	button.custom_minimum_size = MIN_TOUCH_TARGET
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	button.pressed.connect(AudioService.play_ui_confirm)
	return button

func _select_map(map_id: String) -> void:
	selected_map_id = map_id
	GameManager.select_map(map_id)
	_show_map_select()

func _set_difficulty(difficulty: String) -> void:
	GameManager.set_session_options(difficulty, GameManager.selected_mode)
	_show_map_select()

func _set_mode(mode: String) -> void:
	GameManager.set_session_options(GameManager.selected_difficulty, mode)
	_show_map_select()

func _continue_last_map() -> void:
	selected_map_id = SaveService.get_last_map()
	if not _selected_map_is_playable():
		_show_map_select()
		return
	_start_selected_map()

func _start_selected_map() -> void:
	var map_data := MapRegistry.get_map(selected_map_id)
	if map_data == null or not map_data.can_launch() or not SaveService.is_map_unlocked(map_data.id):
		_show_map_select()
		return
	SaveService.set_last_map(map_data.id)
	GameManager.select_map(map_data.id)
	_show_loading(map_data)
	SceneLoader.load_scene(map_data.scene_path)

func _selected_map_is_playable() -> bool:
	var map_data := MapRegistry.get_map(selected_map_id)
	return map_data != null and map_data.can_launch() and SaveService.is_map_unlocked(map_data.id)

func _on_load_stage_changed(_scene_path: String, stage: String, progress: float, _elapsed_msec: int) -> void:
	if active_view != View.LOADING:
		return
	loading_stage = stage
	loading_progress = clampf(progress, 0.0, 1.0)
	_refresh_loading_telemetry()

func _on_load_progress(_scene_path: String, progress: float) -> void:
	if active_view != View.LOADING:
		return
	loading_progress = clampf(progress, 0.0, 1.0)
	_refresh_loading_telemetry()

func _on_load_failed(_scene_path: String, _error_code: Error, _elapsed_msec: int) -> void:
	if active_view != View.LOADING:
		return
	loading_stage = SceneLoader.STAGE_FAILED
	_refresh_loading_telemetry()
	await get_tree().create_timer(1.2).timeout
	if active_view == View.LOADING:
		_show_map_select()

func _refresh_loading_telemetry() -> void:
	if loading_bar == null or loading_label == null:
		return
	var telemetry := SceneLoader.get_active_telemetry()
	if not telemetry.is_empty():
		loading_stage = str(telemetry.get("stage", loading_stage))
		loading_progress = clampf(float(telemetry.get("progress", loading_progress)), 0.0, 1.0)
	var elapsed_msec := int(telemetry.get("elapsed_msec", 0))
	loading_bar.value = loading_progress * 100.0
	loading_label.text = tr("loading.telemetry") % [_loading_stage_label(loading_stage), roundi(loading_progress * 100.0), float(elapsed_msec) / 1000.0]

func _loading_stage_label(stage: String) -> String:
	match stage:
		SceneLoader.STAGE_STREAMING:
			return tr("loading.streaming")
		SceneLoader.STAGE_READY:
			return tr("loading.ready")
		SceneLoader.STAGE_TRANSITIONING:
			return tr("loading.finalizing")
		SceneLoader.STAGE_FAILED:
			return tr("loading.failed")
		_:
			return tr("loading.preparing")

func _on_locale_changed(_locale: String) -> void:
	call_deferred("_refresh_view_for_locale")

func _refresh_view_for_locale() -> void:
	_refresh_translated_shell()
	match active_view:
		View.MENU:
			_show_menu()
		View.MAP_SELECT:
			_show_map_select()
		View.SETTINGS:
			_show_settings()

func _refresh_translated_shell() -> void:
	title_label.text = tr("app.title")
	subtitle_label.text = tr("app.subtitle")
	splash_title.text = tr("app.title")
	splash_hint.text = tr("menu.press_to_continue")

func _go_back() -> void:
	if active_view == View.SPLASH:
		_show_menu()
	elif active_view == View.MAP_SELECT or active_view == View.SETTINGS:
		_show_menu()
	elif active_view == View.MENU:
		_request_quit()

func _request_quit() -> void:
	get_tree().quit()

func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()

func _focus_first_button(root: Node) -> void:
	for child in root.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			return
		_focus_first_button(child)
