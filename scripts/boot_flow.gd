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
var splash_left := SPLASH_SECONDS
var menu_ready := false

func _ready() -> void:
	theme = REDLINE_THEME
	selected_map_id = SaveService.get_last_map()
	if MapRegistry.get_map(selected_map_id) == null:
		selected_map_id = "MP_DS_01"
	GameManager.set_state(GameManager.State.SPLASH)
	SceneLoader.load_progress.connect(_on_load_progress)
	SceneLoader.load_failed.connect(_on_load_failed)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_build_shell()
	_show_splash()
	if OS.get_cmdline_user_args().has(BOOT_FLOW_TEST_ARGUMENT):
		call_deferred("_begin_headless_handoff_test")
	elif OS.get_cmdline_user_args().has(SETTINGS_MENU_TEST_ARGUMENT):
		call_deferred("_begin_settings_menu_test")

func _begin_headless_handoff_test() -> void:
	_show_menu()
	_start_selected_map()

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

func _process(delta: float) -> void:
	if active_view == View.SPLASH:
		splash_left = maxf(splash_left - delta, 0.0)
		if splash_left <= 0.0:
			_show_menu()

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
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var heading := Label.new()
	heading.text = tr("menu.map_select")
	heading.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	heading.add_theme_font_size_override("font_size", 29)
	layout.add_child(heading)
	var cards := HBoxContainer.new()
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 16)
	layout.add_child(cards)
	var maps: Array[RedlineMapData] = MapRegistry.get_all_maps()
	for map_data in maps:
		cards.add_child(_make_map_card(map_data))
	if maps.is_empty():
		var empty := Label.new()
		empty.text = tr("menu.no_maps")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cards.add_child(empty)
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
	loading_bar.value = 4.0
	loading_bar.show_percentage = false
	loading_bar.custom_minimum_size = Vector2(0, 28)
	box.add_child(loading_bar)
	loading_label = Label.new()
	loading_label.text = tr("loading.progress")
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(loading_label)

func _make_map_card(map_data: RedlineMapData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(320, 300)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 16)
	padding.add_theme_constant_override("margin_top", 16)
	padding.add_theme_constant_override("margin_right", 16)
	padding.add_theme_constant_override("margin_bottom", 16)
	card.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	padding.add_child(column)
	var name_label := Label.new()
	name_label.text = map_data.localized_name(LocalizationService.active_locale)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	name_label.add_theme_font_size_override("font_size", 25)
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
	details.text = "%s  •  %s  •  %d %s" % [map_data.size_label, "★".repeat(map_data.difficulty_stars), map_data.max_waves, tr("map.waves")]
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_color_override("font_color", Color("f7b06e"))
	column.add_child(details)
	var select_button := _make_menu_button("", _select_map.bind(map_data.id), "Select %s" % map_data.id)
	select_button.text = tr("menu.selected") if map_data.id == selected_map_id else tr("menu.select")
	select_button.disabled = not map_data.playable or not SaveService.is_map_unlocked(map_data.id)
	column.add_child(select_button)
	return card

func _make_menu_button(key: String, callback: Callable, accessible_name: String) -> Button:
	var button := Button.new()
	button.text = tr(key) if not key.is_empty() else ""
	button.tooltip_text = accessible_name
	button.custom_minimum_size = MIN_TOUCH_TARGET
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	return button

func _select_map(map_id: String) -> void:
	selected_map_id = map_id
	GameManager.select_map(map_id)
	_show_map_select()

func _continue_last_map() -> void:
	selected_map_id = SaveService.get_last_map()
	if not _selected_map_is_playable():
		_show_map_select()
		return
	_start_selected_map()

func _start_selected_map() -> void:
	var map_data := MapRegistry.get_map(selected_map_id)
	if map_data == null or not map_data.playable or not SaveService.is_map_unlocked(map_data.id):
		_show_map_select()
		return
	SaveService.set_last_map(map_data.id)
	GameManager.select_map(map_data.id)
	_show_loading(map_data)
	var result := SceneLoader.load_scene(map_data.scene_path)
	if result != OK:
		_on_load_failed(map_data.scene_path, result)

func _selected_map_is_playable() -> bool:
	var map_data := MapRegistry.get_map(selected_map_id)
	return map_data != null and map_data.playable and SaveService.is_map_unlocked(map_data.id)

func _on_load_progress(_scene_path: String, progress: float) -> void:
	if active_view != View.LOADING or loading_bar == null:
		return
	loading_bar.value = clampf(progress, 0.0, 1.0) * 100.0

func _on_load_failed(_scene_path: String, _error_code: Error) -> void:
	if active_view != View.LOADING:
		return
	_show_map_select()

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
