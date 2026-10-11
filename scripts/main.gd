extends Node3D

const PLAYER_SPAWN := Vector3(0, 0.12, 13)
const SPAWN_POINTS := [
	Vector3(-45, 0.15, -39), Vector3(44, 0.15, -38), Vector3(-44, 0.15, 38),
	Vector3(43, 0.15, 38), Vector3(-6, 0.15, -47), Vector3(7, 0.15, 47),
	Vector3(47, 0.15, 3), Vector3(-48, 0.15, 3)
]
const HUD_LAYOUT_FILE := "user://operation_redline_hud.cfg"
const HUD_KEYS := ["joystick", "fire", "aim", "reload", "jump", "crouch", "swap", "minimap"]

var player: OutpostPlayer
var rifle: ServiceRifle
var pistol: ServicePistol
var active_weapon: Node
var weapon_switch_left := 0.0
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
var damage_edges: Array[ColorRect] = []
var damage_indicator: Label
var hit_marker: Label
var kill_feed: VBoxContainer
var minimap: TacticalRadar
var settings := RedlineSettings.new()
var performance_governor: PerformanceGovernor
var settings_button: Button
var settings_panel: Panel
var settings_summary: Label
var aim_button: Button
var reload_button: Button
var fire_button: Button
var jump_button: Button
var crouch_button: Button
var swap_button: Button
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
var damage_indicator_left := 0.0
var respawn_left := -1.0
var respawn_last_second := -1

func _ready() -> void:
	settings.load_from_disk()
	WorldBuilder.build(self)
	performance_governor = PerformanceGovernor.new()
	add_child(performance_governor)
	performance_governor.configure(self)
	player = OutpostPlayer.new()
	player.position = PLAYER_SPAWN
	add_child(player)
	player.fire_requested.connect(_fire)
	player.weapon_swap_requested.connect(_switch_weapon)
	player.movement_touch_changed.connect(_update_movement_stick)
	player.health_changed.connect(_on_health_changed)
	player.damage_taken.connect(_on_player_damage)
	player.player_down.connect(_on_player_down)

	rifle = ServiceRifle.new()
	player.camera.add_child(rifle)
	rifle.bind_player(player)
	pistol = ServicePistol.new()
	player.camera.add_child(pistol)
	pistol.bind_player(player)
	pistol.set_equipped(false)
	active_weapon = rifle
	rifle.ammo_changed.connect(_on_rifle_ammo_changed)
	rifle.weapon_message.connect(_set_status)
	rifle.shot_resolved.connect(_on_shot_resolved)
	rifle.shot_feedback.connect(_on_shot_feedback)
	rifle.weapon_fired.connect(_on_weapon_fired)
	pistol.ammo_changed.connect(_on_pistol_ammo_changed)
	pistol.weapon_message.connect(_set_status)
	pistol.shot_resolved.connect(_on_shot_resolved)
	pistol.shot_feedback.connect(_on_shot_feedback)
	pistol.weapon_fired.connect(_on_weapon_fired)

	director = SurvivalDirector.new()
	add_child(director)
	director.wave_started.connect(_on_wave_started)
	director.enemy_spawn_requested.connect(_spawn_raider)
	director.wave_cleared.connect(_on_wave_cleared)
	director.operation_complete.connect(_on_operation_complete)

	_build_hud()
	_refresh_active_ammo()
	_apply_settings()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_set_status("SECURE THE OUTPOST")
	_show_alert("OPERATION REDLINE", 2.1)
	director.start_operation()

func _process(delta: float) -> void:
	weapon_switch_left = maxf(weapon_switch_left - delta, 0.0)
	if player != null and player.can_control:
		# Android maps every screen press to a mouse click on some devices. Restrict
		# desktop auto-fire to non-mobile platforms so only the FIRE control shoots.
		var desktop_mouse := not OS.has_feature("mobile")
		if desktop_mouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_fire()
		player.set_aim(touch_aim or (desktop_mouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)))
	_update_respawn(delta)
	damage_flash = maxf(damage_flash - delta * 1.8, 0.0)
	damage_indicator_left = maxf(damage_indicator_left - delta, 0.0)
	var effect_alpha := damage_flash if settings.screen_effects else 0.0
	if damage_overlay != null:
		damage_overlay.color.a = effect_alpha * 0.08
	for edge in damage_edges:
		edge.color.a = effect_alpha * 0.48
	if damage_indicator != null:
		damage_indicator.modulate.a = clampf(damage_indicator_left * 1.6, 0.0, 1.0) if settings.screen_effects else 0.0

func _fire() -> void:
	if player == null or not player.can_control or active_weapon == null or weapon_switch_left > 0.0:
		return
	if active_weapon.has_method("try_fire") and active_weapon.try_fire(player.camera):
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

func _reload_active_weapon() -> void:
	if active_weapon != null and active_weapon.has_method("start_reload"):
		active_weapon.start_reload()

func _switch_weapon() -> void:
	if weapon_switch_left > 0.0 or rifle == null or pistol == null:
		return
	weapon_switch_left = 0.30
	if active_weapon == rifle:
		rifle.set_equipped(false)
		pistol.set_equipped(true)
		active_weapon = pistol
		_set_status("SIDEARM READY")
	else:
		pistol.set_equipped(false)
		rifle.set_equipped(true)
		active_weapon = rifle
		_set_status("RIFLE READY")
	_refresh_active_ammo()

func _refresh_active_ammo() -> void:
	if active_weapon == rifle and rifle != null:
		_on_ammo_changed(rifle.ammo, rifle.reserve)
	elif active_weapon == pistol and pistol != null:
		_on_ammo_changed(pistol.ammo, pistol.reserve)

func _on_weapon_fired(origin: Vector3) -> void:
	# Sound awareness is dispatched only per shot, not as a per-frame group scan.
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		if raider != null:
			raider.hear_weapon_fire(origin)

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
	damage_flash = 1.0
	respawn_left = 2.8
	respawn_last_second = -1
	_set_status("YOU ARE DOWN")
	_show_alert("REDEPLOYING", 2.5)
	_show_end_panel("MISSION FAILED", "Redeploy sequence started.", Color("ed8a74"))

func _update_respawn(delta: float) -> void:
	if respawn_left <= 0.0:
		return
	respawn_left -= delta
	var remaining := maxi(0, ceili(respawn_left))
	if remaining != respawn_last_second:
		respawn_last_second = remaining
		_set_status("REDEPLOYING  %d" % remaining)
	if respawn_left <= 0.0:
		_restart()

func _on_health_changed(current: int, maximum: int) -> void:
	if health_label == null:
		return
	health_label.text = "HP  %03d / %03d" % [current, maximum]

func _on_player_damage(amount: int, source_position: Vector3) -> void:
	damage_flash = maxf(damage_flash, clampf(float(amount) / 14.0, 0.30, 0.85))
	damage_indicator_left = 0.62
	if damage_indicator == null or player == null:
		return
	var toward_source := source_position - player.global_position
	toward_source.y = 0.0
	if toward_source.length_squared() < 0.01:
		return
	toward_source = toward_source.normalized()
	var screen_direction := Vector2(toward_source.dot(player.global_transform.basis.x), toward_source.dot(-player.global_transform.basis.z))
	damage_indicator.position = screen_direction * 62.0 + Vector2(-14, -18)
	damage_indicator.rotation = atan2(screen_direction.y, screen_direction.x) + PI * 0.5

func _on_rifle_ammo_changed(in_magazine: int, reserve: int) -> void:
	if active_weapon == rifle:
		_on_ammo_changed(in_magazine, reserve)

func _on_pistol_ammo_changed(in_magazine: int, reserve: int) -> void:
	if active_weapon == pistol:
		_on_ammo_changed(in_magazine, reserve)

func _on_ammo_changed(in_magazine: int, reserve: int) -> void:
	if ammo_label != null:
		ammo_label.text = "%02d  /  %03d" % [in_magazine, reserve]

func _on_shot_resolved(hit: bool, _target_name: String) -> void:
	if hit:
		hits += 1
		_show_hit_marker(false, false)
	_update_accuracy()

func _on_shot_feedback(headshot: bool, eliminated: bool, target_name: String) -> void:
	if headshot or eliminated:
		_show_hit_marker(headshot, eliminated)
	if eliminated:
		_push_kill_feed("HEADSHOT  •  %s" % target_name if headshot else "HOSTILE CAPTURED  •  %s" % target_name, headshot)
		_show_alert("HEADSHOT" if headshot else "HOSTILE DOWN", 0.55)

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

func _show_hit_marker(headshot: bool, eliminated: bool) -> void:
	if hit_marker == null:
		return
	hit_marker.text = "✕"
	hit_marker.add_theme_color_override("font_color", Color("ffda78") if headshot else (Color("ff8069") if eliminated else Color("ffdf9a")))
	hit_marker.add_theme_font_size_override("font_size", 50 if headshot or eliminated else 42)
	hit_marker.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(hit_marker, "modulate:a", 0.0, 0.16 if headshot or eliminated else 0.10)

func _push_kill_feed(message: String, headshot: bool) -> void:
	if kill_feed == null:
		return
	var entry := Label.new()
	entry.text = message
	entry.add_theme_font_size_override("font_size", 14)
	entry.add_theme_color_override("font_color", Color("ffdb7b") if headshot else Color("f1ded0"))
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kill_feed.add_child(entry)
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(entry, "modulate:a", 0.0, 0.35)
	tween.tween_callback(entry.queue_free)

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
	hit_marker = _label("✕", Vector2(-25, -31), Vector2(50, 50), 42, Color("ffdf9a"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	hit_marker.name = "HitMarker"
	hit_marker.modulate.a = 0.0
	damage_indicator = _label("▲", Vector2(-14, -80), Vector2(28, 36), 26, Color("ff8a76"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	damage_indicator.name = "Damage direction indicator"
	damage_indicator.modulate.a = 0.0
	kill_feed = VBoxContainer.new()
	kill_feed.name = "Kill feed"
	kill_feed.position = Vector2(16, 62)
	kill_feed.size = Vector2(300, 130)
	kill_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(kill_feed)

	controls_root = Control.new()
	controls_root.name = "Customizable controls"
	controls_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(controls_root)

	movement_stick = TouchJoystick.new()
	movement_stick.name = "Movement joystick"
	controls_root.add_child(movement_stick)
	minimap = TacticalRadar.new()
	minimap.track_player(player)
	controls_root.add_child(minimap)
	fire_button = _button("FIRE", Vector2.ZERO, Vector2(154, 132), Control.PRESET_TOP_LEFT, Color("a94f3f"), controls_root)
	reload_button = _button("RELOAD", Vector2.ZERO, Vector2(128, 58), Control.PRESET_TOP_LEFT, Color("596b4e"), controls_root)
	aim_button = _button("AIM", Vector2.ZERO, Vector2(128, 58), Control.PRESET_TOP_LEFT, Color("3d6661"), controls_root)
	jump_button = _button("JUMP", Vector2.ZERO, Vector2(104, 72), Control.PRESET_TOP_LEFT, Color("4a6370"), controls_root)
	crouch_button = _button("CROUCH", Vector2.ZERO, Vector2(112, 62), Control.PRESET_TOP_LEFT, Color("6e5f43"), controls_root)
	swap_button = _button("SWAP", Vector2.ZERO, Vector2(92, 52), Control.PRESET_TOP_LEFT, Color("67556f"), controls_root)
	fire_button.button_down.connect(_fire)
	reload_button.pressed.connect(_reload_active_weapon)
	aim_button.pressed.connect(_toggle_aim)
	jump_button.button_down.connect(_on_jump_button_down)
	jump_button.button_up.connect(_on_jump_button_up)
	crouch_button.button_down.connect(_on_crouch_button_down)
	swap_button.pressed.connect(_switch_weapon)
	adjustable_controls = {
		"joystick": movement_stick,
		"fire": fire_button,
		"aim": aim_button,
		"reload": reload_button,
		"jump": jump_button,
		"crouch": crouch_button,
		"swap": swap_button,
		"minimap": minimap,
	}

	hud_edit_button = _button("HUD", Vector2(245, 9), Vector2(70, 34), Control.PRESET_TOP_LEFT, Color("526b68"))
	hud_edit_button.add_theme_font_size_override("font_size", 14)
	hud_edit_button.pressed.connect(_enter_hud_edit)
	settings_button = _button("SET", Vector2(326, 9), Vector2(64, 34), Control.PRESET_TOP_LEFT, Color("605b72"))
	settings_button.add_theme_font_size_override("font_size", 14)
	settings_button.pressed.connect(_open_settings)
	_build_hud_editor()
	_build_settings_panel()

	damage_overlay = ColorRect.new()
	damage_overlay.name = "Damage vignette"
	damage_overlay.color = Color(0.75, 0.04, 0.02, 0.0)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(damage_overlay)
	_build_damage_edges()
	call_deferred("_load_hud_layout")

func _build_damage_edges() -> void:
	var edge_specs := [
		[Control.PRESET_TOP_WIDE, Vector2(0, 0), Vector2(0, 42)],
		[Control.PRESET_BOTTOM_WIDE, Vector2(0, -42), Vector2(0, 42)],
		[Control.PRESET_LEFT_WIDE, Vector2(0, 0), Vector2(46, 0)],
		[Control.PRESET_RIGHT_WIDE, Vector2(-46, 0), Vector2(46, 0)]
	]
	for spec in edge_specs:
		var edge := ColorRect.new()
		edge.color = Color(0.72, 0.025, 0.01, 0.0)
		edge.set_anchors_preset(spec[0])
		edge.position = spec[1]
		edge.size = spec[2]
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(edge)
		damage_edges.append(edge)

func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.name = "Settings panel"
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-230, -108)
	settings_panel.size = Vector2(460, 216)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.07, 0.065, 0.96)
	style.border_color = Color("8bc5b3")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	settings_panel.add_theme_stylebox_override("panel", style)
	settings_panel.visible = false
	hud.add_child(settings_panel)
	var title := Label.new()
	title.text = "FIELD SETTINGS"
	title.position = Vector2(18, 12)
	title.size = Vector2(424, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("d9f0d4"))
	settings_panel.add_child(title)
	settings_summary = Label.new()
	settings_summary.position = Vector2(22, 46)
	settings_summary.size = Vector2(416, 38)
	settings_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_summary.add_theme_font_size_override("font_size", 15)
	settings_summary.add_theme_color_override("font_color", Color("f0d6a1"))
	settings_panel.add_child(settings_summary)
	var less := _button("− LOOK", Vector2(24, 102), Vector2(110, 44), Control.PRESET_TOP_LEFT, Color("576a6e"), settings_panel)
	less.pressed.connect(_adjust_sensitivity.bind(-0.10))
	var more := _button("+ LOOK", Vector2(146, 102), Vector2(110, 44), Control.PRESET_TOP_LEFT, Color("526d6a"), settings_panel)
	more.pressed.connect(_adjust_sensitivity.bind(0.10))
	var assist := _button("AIM ASSIST", Vector2(268, 102), Vector2(168, 44), Control.PRESET_TOP_LEFT, Color("665849"), settings_panel)
	assist.pressed.connect(_toggle_aim_assist)
	var effects := _button("EFFECTS", Vector2(88, 158), Vector2(130, 42), Control.PRESET_TOP_LEFT, Color("5d684a"), settings_panel)
	effects.pressed.connect(_toggle_screen_effects)
	var close := _button("CLOSE", Vector2(242, 158), Vector2(130, 42), Control.PRESET_TOP_LEFT, Color("54734f"), settings_panel)
	close.pressed.connect(_close_settings)

func _open_settings() -> void:
	settings_panel.visible = true
	settings_button.visible = false
	_update_settings_summary()

func _close_settings() -> void:
	settings.save_to_disk()
	settings_panel.visible = false
	settings_button.visible = true
	_set_status("SETTINGS SAVED")

func _adjust_sensitivity(amount: float) -> void:
	settings.look_sensitivity = clampf(settings.look_sensitivity + amount, 0.55, 1.65)
	_apply_settings()

func _toggle_aim_assist() -> void:
	settings.aim_assist = not settings.aim_assist
	_apply_settings()

func _toggle_screen_effects() -> void:
	settings.screen_effects = not settings.screen_effects
	_apply_settings()

func _apply_settings() -> void:
	if player != null:
		player.set_look_sensitivity(settings.look_sensitivity)
	if rifle != null:
		rifle.set_aim_assist_enabled(settings.aim_assist)
		rifle.set_effects_enabled(settings.screen_effects)
	if pistol != null:
		pistol.set_aim_assist_enabled(settings.aim_assist)
		pistol.set_effects_enabled(settings.screen_effects)
	if performance_governor != null:
		performance_governor.set_effects_requested(settings.screen_effects)
	_update_settings_summary()

func _update_settings_summary() -> void:
	if settings_summary != null:
		settings_summary.text = "LOOK  %.0f%%   •   ASSIST  %s   •   EFFECTS  %s\nAUTO 60 FPS  •  ACTIVE" % [settings.look_sensitivity * 100.0, "ON" if settings.aim_assist else "OFF", "ON" if settings.screen_effects else "OFF"]

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
	_set_control_rect("swap", Vector2(screen.x - 550, screen.y - 144), Vector2(92, 52))
	_set_control_rect("minimap", Vector2(screen.x - 166, 62), Vector2(148, 148))

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
