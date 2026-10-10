extends Node3D

const PLAYER_SPAWN := Vector3(0, 0.12, 13)
const SPAWN_POINTS := [
	Vector3(-45, 0.15, -39), Vector3(44, 0.15, -38), Vector3(-44, 0.15, 38),
	Vector3(43, 0.15, 38), Vector3(-6, 0.15, -47), Vector3(7, 0.15, 47),
	Vector3(47, 0.15, 3), Vector3(-48, 0.15, 3)
]
const HUD_LAYOUT_FILE := "user://operation_redline_hud.cfg"
const HUD_KEYS := ["joystick", "fire", "aim", "reload", "jump", "crouch"]

var player: OutpostPlayer
var rifle: ServiceRifle
var director: SurvivalDirector
var hud: CanvasLayer
var controls_root: Control
var health_label: Label
var ammo_label: Label
var wave_label: Label
var score_label: Label
var accuracy_label: Label
var status_label: Label
var alert_label: Label
var damage_overlay: ColorRect
var aim_button: Button
var reload_button: Button
var fire_button: Button
var jump_button: Button
var crouch_button: Button
var restart_button: Button
var hud_edit_button: Button
var movement_stick: TouchJoystick
var adjustable_controls: Dictionary = {}
var editor_surface: Control
var editor_panel: Panel
var editor_title: Label
var selected_hud_key := ""
var drag_control: Control
var drag_offset := Vector2.ZERO
var hud_layout_loaded := false
var score := 0
var shots := 0
var hits := 0
var touch_aim := false
var damage_flash := 0.0

func _ready() -> void:
	WorldBuilder.build(self)
	player = OutpostPlayer.new()
	player.position = PLAYER_SPAWN
	add_child(player)
	player.fire_requested.connect(_fire)
	player.movement_touch_changed.connect(_update_movement_stick)
	player.health_changed.connect(_on_health_changed)
	player.player_down.connect(_on_player_down)

	rifle = ServiceRifle.new()
	player.camera.add_child(rifle)
	rifle.bind_player(player)
	rifle.ammo_changed.connect(_on_ammo_changed)
	rifle.weapon_message.connect(_set_status)
	rifle.shot_resolved.connect(_on_shot_resolved)

	director = SurvivalDirector.new()
	add_child(director)
	director.wave_started.connect(_on_wave_started)
	director.enemy_spawn_requested.connect(_spawn_raider)
	director.wave_cleared.connect(_on_wave_cleared)
	director.operation_complete.connect(_on_operation_complete)

	_build_hud()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_set_status("SECURE THE OUTPOST")
	_show_alert("OPERATION REDLINE", 2.1)
	director.start_operation()

func _process(delta: float) -> void:
	if player != null and player.can_control:
		# Android maps every screen press to a mouse click on some devices. Restrict
		# desktop auto-fire to non-mobile platforms so only the FIRE control shoots.
		var desktop_mouse := not OS.has_feature("mobile")
		if desktop_mouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_fire()
		player.set_aim(touch_aim or (desktop_mouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)))
	damage_flash = maxf(damage_flash - delta * 1.8, 0.0)
	if damage_overlay != null:
		damage_overlay.color.a = damage_flash

func _fire() -> void:
	if player == null or not player.can_control or rifle == null:
		return
	if rifle.try_fire(player.camera):
		shots += 1
		_update_accuracy()

func _update_movement_stick(direction: Vector2, active: bool) -> void:
	if movement_stick != null:
		movement_stick.set_input(direction, active)

func _on_jump_button_down() -> void:
	if player != null:
		player.request_jump()

func _on_jump_button_up() -> void:
	if player != null:
		player.set_jump_held(false)

func _on_crouch_button_down() -> void:
	if player != null:
		player.request_crouch()

func _spawn_raider(serial: int) -> void:
	if not player.can_control:
		return
	var enemy := Raider.new()
	enemy.setup(serial)
	var candidate: Vector3 = SPAWN_POINTS[(serial - 1) % SPAWN_POINTS.size()]
	# Vary lanes slightly so every wave is readable but not mechanically identical.
	var lateral := Vector3(float((serial * 7) % 5 - 2) * 0.9, 0, float((serial * 3) % 5 - 2) * 0.7)
	enemy.position = candidate + lateral
	add_child(enemy)
	enemy.eliminated.connect(_on_raider_eliminated)

func _on_raider_eliminated(_enemy: Raider, points: int) -> void:
	score += points
	score_label.text = "SCORE  %05d" % score
	director.enemy_eliminated()

func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	wave_label.text = "WAVE  %d / 3   •   %d INBOUND" % [wave_number, enemy_count]
	_show_alert("WAVE %d  —  HOLD THE LINE" % wave_number, 1.5)

func _on_wave_cleared(wave_number: int) -> void:
	wave_label.text = "WAVE %d CLEARED" % wave_number
	if wave_number < 3:
		_show_alert("AREA SECURED  •  RELOAD NOW", 2.1)

func _on_operation_complete() -> void:
	_set_status("OPERATION COMPLETE")
	_show_alert("OUTPOST SECURED", 100.0)
	player.can_control = false
	_show_end_panel("MISSION COMPLETE", "The cargo is secured. Final score: %05d" % score, Color("8fcf9a"))

func _on_player_down() -> void:
	director.stop_operation()
	damage_flash = 0.75
	_set_status("YOU ARE DOWN")
	_show_alert("MISSION FAILED", 100.0)
	_show_end_panel("MISSION FAILED", "Regroup and hold the outpost again.", Color("ed8a74"))

func _on_health_changed(current: int, maximum: int) -> void:
	if health_label == null:
		return
	health_label.text = "HP  %03d / %03d" % [current, maximum]
	if current < maximum:
		damage_flash = maxf(damage_flash, 0.22)

func _on_ammo_changed(in_magazine: int, reserve: int) -> void:
	if ammo_label != null:
		ammo_label.text = "%02d  /  %03d" % [in_magazine, reserve]

func _on_shot_resolved(hit: bool, _target_name: String) -> void:
	if hit:
		hits += 1
		_show_hit_marker()
	_update_accuracy()

func _update_accuracy() -> void:
	if accuracy_label != null:
		var percentage := 0 if shots == 0 else int(round(float(hits) * 100.0 / float(shots)))
		accuracy_label.text = "ACC  %d%%" % percentage

func _set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message

func _show_alert(message: String, duration: float) -> void:
	if alert_label == null:
		return
	alert_label.text = message
	alert_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(alert_label, "modulate:a", 0.0, 0.45)

func _show_hit_marker() -> void:
	var marker := hud.get_node_or_null("HitMarker") as Label
	if marker == null:
		return
	marker.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(marker, "modulate:a", 0.0, 0.12)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "Tactical HUD"
	add_child(hud)
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.035, 0.055, 0.05, 0.78)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.size.y = 54
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_bar)

	health_label = _label("HP  100 / 100", Vector2(18, 13), Vector2(210, 28), 19, Color("d8f5d0"))
	wave_label = _label("WAVE  1 / 3", Vector2(0, 13), Vector2(420, 28), 18, Color("f4d8a6"), Control.PRESET_CENTER_TOP, HORIZONTAL_ALIGNMENT_CENTER)
	score_label = _label("SCORE  00000", Vector2(-205, 13), Vector2(188, 28), 18, Color("d8f5d0"), Control.PRESET_TOP_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	accuracy_label = _label("ACC  0%", Vector2(18, -43), Vector2(140, 25), 15, Color("d8f5d0"), Control.PRESET_BOTTOM_LEFT)
	status_label = _label("SECURE THE OUTPOST", Vector2(-170, -80), Vector2(340, 22), 14, Color("f0c079"), Control.PRESET_CENTER_BOTTOM, HORIZONTAL_ALIGNMENT_CENTER)
	alert_label = _label("", Vector2(-300, 70), Vector2(600, 42), 24, Color("fff0cc"), Control.PRESET_CENTER_TOP, HORIZONTAL_ALIGNMENT_CENTER)
	var reticle := _label("+", Vector2(-14, -18), Vector2(28, 36), 30, Color("f5eccf"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	reticle.name = "Reticle"
	var hit_marker := _label("×", Vector2(-22, -31), Vector2(44, 50), 42, Color("ffdf9a"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	hit_marker.name = "HitMarker"
	hit_marker.modulate.a = 0.0

	controls_root = Control.new()
	controls_root.name = "Customizable controls"
	controls_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls_root)

	movement_stick = TouchJoystick.new()
	movement_stick.name = "Movement joystick"
	controls_root.add_child(movement_stick)
	fire_button = _button("FIRE", Vector2.ZERO, Vector2(154, 132), Control.PRESET_TOP_LEFT, Color("a94f3f"), controls_root)
	reload_button = _button("RELOAD", Vector2.ZERO, Vector2(128, 58), Control.PRESET_TOP_LEFT, Color("596b4e"), controls_root)
	aim_button = _button("AIM", Vector2.ZERO, Vector2(128, 58), Control.PRESET_TOP_LEFT, Color("3d6661"), controls_root)
	jump_button = _button("JUMP", Vector2.ZERO, Vector2(104, 72), Control.PRESET_TOP_LEFT, Color("4a6370"), controls_root)
	crouch_button = _button("CROUCH", Vector2.ZERO, Vector2(112, 62), Control.PRESET_TOP_LEFT, Color("6e5f43"), controls_root)
	fire_button.button_down.connect(_fire)
	reload_button.pressed.connect(rifle.start_reload)
	aim_button.pressed.connect(_toggle_aim)
	jump_button.button_down.connect(_on_jump_button_down)
	jump_button.button_up.connect(_on_jump_button_up)
	crouch_button.button_down.connect(_on_crouch_button_down)
	adjustable_controls = {
		"joystick": movement_stick,
		"fire": fire_button,
		"aim": aim_button,
		"reload": reload_button,
		"jump": jump_button,
		"crouch": crouch_button,
	}

	hud_edit_button = _button("HUD", Vector2(245, 9), Vector2(70, 34), Control.PRESET_TOP_LEFT, Color("526b68"))
	hud_edit_button.add_theme_font_size_override("font_size", 14)
	hud_edit_button.pressed.connect(_enter_hud_edit)
	_build_hud_editor()

	damage_overlay = ColorRect.new()
	damage_overlay.name = "Damage vignette"
	damage_overlay.color = Color(0.75, 0.04, 0.02, 0.0)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(damage_overlay)
	call_deferred("_load_hud_layout")

func _build_hud_editor() -> void:
	editor_surface = Control.new()
	editor_surface.name = "HUD edit touch surface"
	editor_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	editor_surface.visible = false
	editor_surface.gui_input.connect(_on_editor_surface_input)
	hud.add_child(editor_surface)

	editor_panel = Panel.new()
	editor_panel.name = "HUD editor panel"
	editor_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	editor_panel.position = Vector2(-245, 62)
	editor_panel.size = Vector2(490, 108)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.07, 0.065, 0.94)
	panel_style.border_color = Color("f0be6e")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	editor_panel.add_theme_stylebox_override("panel", panel_style)
	editor_panel.visible = false
	hud.add_child(editor_panel)
	editor_title = Label.new()
	editor_title.position = Vector2(16, 10)
	editor_title.size = Vector2(458, 28)
	editor_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	editor_title.add_theme_font_size_override("font_size", 17)
	editor_title.add_theme_color_override("font_color", Color("fff0c5"))
	editor_panel.add_child(editor_title)
	var minus := _button("− SIZE", Vector2(34, 48), Vector2(105, 42), Control.PRESET_TOP_LEFT, Color("5d684a"), editor_panel)
	minus.pressed.connect(_resize_selected.bind(0.85))
	var plus := _button("+ SIZE", Vector2(151, 48), Vector2(105, 42), Control.PRESET_TOP_LEFT, Color("526d6a"), editor_panel)
	plus.pressed.connect(_resize_selected.bind(1.18))
	var reset := _button("RESET", Vector2(268, 48), Vector2(94, 42), Control.PRESET_TOP_LEFT, Color("7d5a45"), editor_panel)
	reset.pressed.connect(_reset_hud_layout)
	var done := _button("SAVE", Vector2(374, 48), Vector2(82, 42), Control.PRESET_TOP_LEFT, Color("54734f"), editor_panel)
	done.pressed.connect(_exit_hud_edit)

func _on_viewport_size_changed() -> void:
	if hud_layout_loaded:
		call_deferred("_load_hud_layout")

func _load_hud_layout() -> void:
	if controls_root == null or controls_root.size.x < 10.0:
		call_deferred("_load_hud_layout")
		return
	_apply_default_hud_layout()
	var config := ConfigFile.new()
	if config.load(HUD_LAYOUT_FILE) == OK:
		for key in HUD_KEYS:
			if not config.has_section_key("layout", key + "_x"):
				continue
			var control := adjustable_controls.get(key) as Control
			if control == null:
				continue
			var x := float(config.get_value("layout", key + "_x", 0.0)) * controls_root.size.x
			var y := float(config.get_value("layout", key + "_y", 0.0)) * controls_root.size.y
			var w := float(config.get_value("layout", key + "_w", control.size.x / controls_root.size.x)) * controls_root.size.x
			var h := float(config.get_value("layout", key + "_h", control.size.y / controls_root.size.y)) * controls_root.size.y
			_set_control_rect(key, Vector2(x, y), Vector2(w, h))
	hud_layout_loaded = true
	_sync_movement_touch_region()

func _apply_default_hud_layout() -> void:
	var screen := controls_root.size
	# Keep the thumb zones clear of the screen edge so the first launch is
	# comfortable even before a player opens the HUD editor.
	_set_control_rect("joystick", Vector2(32, screen.y - 278), Vector2(196, 196))
	_set_control_rect("fire", Vector2(screen.x - 176, screen.y - 242), Vector2(148, 148))
	_set_control_rect("aim", Vector2(screen.x - 452, screen.y - 144), Vector2(128, 58))
	_set_control_rect("reload", Vector2(screen.x - 310, screen.y - 144), Vector2(128, 58))
	_set_control_rect("jump", Vector2(screen.x - 306, screen.y - 238), Vector2(104, 72))
	_set_control_rect("crouch", Vector2(screen.x - 434, screen.y - 232), Vector2(112, 62))

func _set_control_rect(key: String, position_value: Vector2, size_value: Vector2) -> void:
	var control := adjustable_controls.get(key) as Control
	if control == null:
		return
	var min_size := 70.0 if key == "joystick" else 58.0
	var max_size := 270.0 if key == "joystick" else 220.0
	var final_size := Vector2(clampf(size_value.x, min_size, max_size), clampf(size_value.y, min_size, max_size))
	if key == "joystick":
		var side := maxf(final_size.x, final_size.y)
		final_size = Vector2(side, side)
	control.size = final_size
	control.position = _clamp_control_position(position_value, final_size)

func _clamp_control_position(position_value: Vector2, control_size: Vector2) -> Vector2:
	return Vector2(
		clampf(position_value.x, 8.0, maxf(8.0, controls_root.size.x - control_size.x - 8.0)),
		clampf(position_value.y, 58.0, maxf(58.0, controls_root.size.y - control_size.y - 8.0))
	)

func _sync_movement_touch_region() -> void:
	if player != null and movement_stick != null:
		player.set_movement_touch_region(
			Rect2(movement_stick.position, movement_stick.size).grow(14.0),
			movement_stick.get_input_radius()
		)

func _enter_hud_edit() -> void:
	if editor_surface == null:
		return
	editor_surface.visible = true
	editor_panel.visible = true
	hud_edit_button.visible = false
	_set_selected_hud_key("fire")
	_set_status("HUD EDIT MODE")

func _exit_hud_edit() -> void:
	_save_hud_layout()
	editor_surface.visible = false
	editor_panel.visible = false
	hud_edit_button.visible = true
	drag_control = null
	for key in HUD_KEYS:
		var control := adjustable_controls.get(key) as Control
		if control != null:
			control.modulate = Color.WHITE
	_set_status("HUD SAVED")

func _set_selected_hud_key(key: String) -> void:
	selected_hud_key = key
	for item_key in HUD_KEYS:
		var control := adjustable_controls.get(item_key) as Control
		if control != null:
			control.modulate = Color("ffe2a0") if item_key == key else Color.WHITE
	if editor_title != null:
		editor_title.text = "HUD EDIT  •  DRAG %s  •  USE SIZE BUTTONS" % key.to_upper()

func _on_editor_surface_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_editor_begin_drag(event.position)
		else:
			_editor_end_drag()
	elif event is InputEventScreenDrag:
		_editor_drag_to(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_editor_begin_drag(event.position)
		else:
			_editor_end_drag()
	elif event is InputEventMouseMotion and drag_control != null:
		_editor_drag_to(event.position)

func _editor_begin_drag(position_value: Vector2) -> void:
	for index in range(HUD_KEYS.size() - 1, -1, -1):
		var key: String = HUD_KEYS[index]
		var control := adjustable_controls.get(key) as Control
		if control != null and Rect2(control.position, control.size).grow(12.0).has_point(position_value):
			_set_selected_hud_key(key)
			drag_control = control
			drag_offset = position_value - control.position
			return
	drag_control = null

func _editor_drag_to(position_value: Vector2) -> void:
	if drag_control == null:
		return
	drag_control.position = _clamp_control_position(position_value - drag_offset, drag_control.size)
	if selected_hud_key == "joystick":
		_sync_movement_touch_region()

func _editor_end_drag() -> void:
	if drag_control != null:
		_save_hud_layout()
	drag_control = null

func _resize_selected(multiplier: float) -> void:
	var control := adjustable_controls.get(selected_hud_key) as Control
	if control == null:
		return
	var old_center := control.position + control.size * 0.5
	_set_control_rect(selected_hud_key, old_center - control.size * multiplier * 0.5, control.size * multiplier)
	_sync_movement_touch_region()
	_save_hud_layout()

func _reset_hud_layout() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HUD_LAYOUT_FILE))
	_apply_default_hud_layout()
	_sync_movement_touch_region()
	_set_selected_hud_key("fire")

func _save_hud_layout() -> void:
	if controls_root == null or controls_root.size.x <= 0.0 or controls_root.size.y <= 0.0:
		return
	var config := ConfigFile.new()
	for key in HUD_KEYS:
		var control := adjustable_controls.get(key) as Control
		if control == null:
			continue
		config.set_value("layout", key + "_x", control.position.x / controls_root.size.x)
		config.set_value("layout", key + "_y", control.position.y / controls_root.size.y)
		config.set_value("layout", key + "_w", control.size.x / controls_root.size.x)
		config.set_value("layout", key + "_h", control.size.y / controls_root.size.y)
	config.save(HUD_LAYOUT_FILE)

func _show_end_panel(title: String, description: String, tint: Color) -> void:
	var panel := ColorRect.new()
	panel.name = "EndPanel"
	panel.color = Color(0.025, 0.04, 0.035, 0.86)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(panel)
	_label(title, Vector2(-260, -85), Vector2(520, 42), 30, tint, Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	_label(description, Vector2(-290, -32), Vector2(580, 35), 17, Color("e6dcc1"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	restart_button = _button("RESTART OPERATION", Vector2(-128, 28), Vector2(256, 56), Control.PRESET_CENTER, Color("596d52"))
	restart_button.pressed.connect(_restart)

func _restart() -> void:
	get_tree().reload_current_scene()

func _toggle_aim() -> void:
	touch_aim = not touch_aim
	if aim_button != null:
		aim_button.text = "AIM ✓" if touch_aim else "AIM"

func _label(text_value: String, position_offset: Vector2, control_size: Vector2, font_size: int, color: Color, preset := Control.PRESET_TOP_LEFT, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.position = position_offset
	label.size = control_size
	label.set_anchors_preset(preset)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(label)
	return label

func _button(text_value: String, position_offset: Vector2, control_size: Vector2, preset: int, color: Color, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = text_value
	button.size = control_size
	if parent == null:
		button.position = position_offset
		button.set_anchors_preset(preset)
		hud.add_child(button)
	else:
		button.position = position_offset
		parent.add_child(button)
	var is_primary_fire := text_value == "FIRE"
	var corner_radius := 66 if is_primary_fire else 12
	button.add_theme_font_size_override("font_size", 22 if is_primary_fire else 18)
	button.add_theme_color_override("font_color", Color("fff6d4"))
	button.add_theme_color_override("font_outline_color", Color("18201c"))
	button.add_theme_constant_override("outline_size", 4)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color.r, color.g, color.b, 0.91 if is_primary_fire else 0.84)
	normal.border_color = Color("ffd88b") if is_primary_fire else Color("f4d39a")
	normal.set_border_width_all(3 if is_primary_fire else 2)
	normal.corner_radius_top_left = corner_radius
	normal.corner_radius_top_right = corner_radius
	normal.corner_radius_bottom_left = corner_radius
	normal.corner_radius_bottom_right = corner_radius
	normal.shadow_color = Color(0.03, 0.02, 0.01, 0.48)
	normal.shadow_size = 8 if is_primary_fire else 3
	normal.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("e5a45b")
	pressed.border_color = Color("fff0c4")
	pressed.set_border_width_all(3 if is_primary_fire else 2)
	pressed.corner_radius_top_left = corner_radius
	pressed.corner_radius_top_right = corner_radius
	pressed.corner_radius_bottom_left = corner_radius
	pressed.corner_radius_bottom_right = corner_radius
	button.add_theme_stylebox_override("pressed", pressed)
	return button
