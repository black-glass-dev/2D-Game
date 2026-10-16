extends Node3D

const PLAYER_SPAWN := Vector3(0, 0.12, 13)
const SPAWN_POINTS := [
	Vector3(-45, 0.15, -39), Vector3(44, 0.15, -38), Vector3(-44, 0.15, 38),
	Vector3(43, 0.15, 38), Vector3(-6, 0.15, -47), Vector3(7, 0.15, 47),
	Vector3(47, 0.15, 3), Vector3(-48, 0.15, 3)
]
const HUD_LAYOUT_FILE := "user://operation_redline_hud.cfg"
const HUD_KEYS := ["joystick", "fire", "fire_mode", "aim", "reload", "jump", "crouch", "swap", "minimap"]
const ADS_GLASS_SHADER := preload("res://assets/shaders/ads_glass.gdshader")
const REDLINE_THEME := preload("res://ui/theme/redline_theme.tres")
const PAUSE_FLOW_TEST_ARGUMENT := "--verify-pause-flow"
const RESULT_FLOW_TEST_ARGUMENT := "--verify-result-flow"
const AUDIO_FLOW_TEST_ARGUMENT := "--verify-audio-flow"
const INPUT_ACCESSIBILITY_TEST_ARGUMENT := "--verify-input-accessibility-flow"
const PAUSE_CAPTURE_BENGALI_ARGUMENT := "--capture-pause-bengali"
const PAUSE_CAPTURE_OUTPUT_ARGUMENT := "--pause-screenshot-dir"

var player: OutpostPlayer
var rifle: ServiceRifle
var pistol: ServicePistol
var active_weapon: Node
var weapon_switch_left := 0.0
var director: SurvivalDirector
var hud: CanvasLayer
var controls_root: Control
var health_label: Label
var health_bar_fill: ColorRect
var ammo_label: Label
var weapon_label: Label
var wave_label: Label
var score_label: Label
var accuracy_label: Label
var status_label: Label
var alert_label: Label
var damage_overlay: ColorRect
var damage_edges: Array[ColorRect] = []
var damage_indicator: Label
var hit_marker: Label
var reticle_root: Control
var reticle_segments: Array[ColorRect] = []
var ads_overlay: ColorRect
var ads_reticle: Label
var kill_feed: VBoxContainer
var minimap: TacticalRadar
var settings := RedlineSettings.new()
var performance_governor: PerformanceGovernor
var settings_button: Button
var pause_button: Button
var pause_overlay: Control
var pause_panel: PanelContainer
var pause_resume_button: Button
var pause_settings_center: CenterContainer
var pause_settings_menu: RedlineSettingsMenu
var settings_panel: Panel
var settings_summary: Label
var aim_button: Button
var reload_button: Button
var fire_button: Button
var fire_mode_button: Button
var mobile_fire_held := false
var jump_button: Button
var crouch_button: Button
var swap_button: Button
var restart_button: Button
var end_panel: Control
var operation_result_recorded := false
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
var displayed_health := 100
var displayed_health_maximum := 100
var respawn_left := -1.0
var respawn_last_second := -1

func _ready() -> void:
	# Main remains independently runnable; BootFlow sets Loading, then this
	# compatibility hand-off marks the legacy Desert session as actively playing.
	# It must keep receiving pause/back/focus input while the simulation tree is
	# paused, so gameplay work explicitly early-outs in _process below.
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.set_state(GameManager.State.PLAYING)
	if OS.get_cmdline_user_args().has(PAUSE_CAPTURE_BENGALI_ARGUMENT):
		# Screenshot-only CI route: initialize all newly created gameplay/pause
		# controls in Bengali without mutating the player's saved preference.
		LocalizationService.apply_preference("BN")
	settings.load_from_disk()
	WorldBuilder.build(self)
	performance_governor = PerformanceGovernor.new()
	add_child(performance_governor)
	performance_governor.configure(self, settings.resolved_quality_tier(), settings.uses_adaptive_quality())
	player = OutpostPlayer.new()
	player.position = PLAYER_SPAWN
	add_child(player)
	player.fire_requested.connect(_fire)
	player.weapon_swap_requested.connect(_switch_weapon)
	player.reload_requested.connect(_reload_active_weapon)
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
	_build_pause_overlay()
	_build_loading_splash()
	_refresh_active_ammo()
	_apply_settings()
	SettingsService.setting_changed.connect(_on_runtime_setting_changed)
	_apply_accessibility_settings()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_set_status("SECURE THE OUTPOST")
	_show_alert("OPERATION REDLINE", 2.1)
	director.start_operation()
	if OS.get_cmdline_user_args().has("--verify-boot-flow"):
		call_deferred("_finish_boot_flow_verification")
	elif OS.get_cmdline_user_args().has(PAUSE_FLOW_TEST_ARGUMENT):
		call_deferred("_run_pause_flow_verification")
	elif OS.get_cmdline_user_args().has(RESULT_FLOW_TEST_ARGUMENT):
		call_deferred("_run_result_flow_verification")
	elif OS.get_cmdline_user_args().has(AUDIO_FLOW_TEST_ARGUMENT):
		call_deferred("_run_audio_flow_verification")
	elif OS.get_cmdline_user_args().has(INPUT_ACCESSIBILITY_TEST_ARGUMENT):
		call_deferred("_run_input_accessibility_verification")

func _finish_boot_flow_verification() -> void:
	if GameManager.state != GameManager.State.PLAYING or GameManager.selected_map_id != "MP_DS_01":
		push_error("Boot-flow verification reached Main with invalid game state.")
		get_tree().quit(1)
		return
	print("BOOT_FLOW_PASS map=", GameManager.selected_map_id)
	get_tree().quit()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	weapon_switch_left = maxf(weapon_switch_left - delta, 0.0)
	if player != null and player.can_control:
		# Android maps every screen press to a mouse click on some devices. Restrict
		# desktop auto-fire to non-mobile platforms so only the FIRE control shoots.
		var desktop_mouse := not OS.has_feature("mobile")
		# Desktop retains its existing held-mouse automatic path. On mobile, the
		# default SINGLE mode fires once per tap; AUTO samples the same held FIRE
		# button every frame and weapon cooldowns remain the rate authority.
		var action_fire_held := Input.is_action_pressed(InputService.ACTION_FIRE)
		if (desktop_mouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) or (settings.fire_mode == "AUTO" and (mobile_fire_held or action_fire_held)):
			_fire()
		_set_aim_state(touch_aim or Input.is_action_pressed(InputService.ACTION_AIM) or (desktop_mouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)))
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
	_update_dynamic_reticle()
	_update_ads_presentation()

func _set_aim_state(enabled: bool) -> void:
	if player == null:
		return
	# The main camera always renders ADS. No SubViewport or scope texture is
	# allocated on mobile, eliminating the black second-camera failure mode.
	player.set_ads_fov(OutpostPlayer.CARBINE_ADS_FOV if active_weapon == rifle else OutpostPlayer.SIDEARM_ADS_FOV)
	player.set_aim(enabled)

func _cancel_aim() -> void:
	touch_aim = false
	if player != null:
		player.set_aim(false)
	if aim_button != null:
		aim_button.text = _button_display_text("AIM")
	_update_ads_presentation()

func _update_ads_presentation() -> void:
	var aiming := player != null and player.is_aiming
	if ads_overlay != null:
		ads_overlay.visible = aiming
		if ads_overlay.material is ShaderMaterial:
			var glass := ads_overlay.material as ShaderMaterial
			glass.set_shader_parameter("radius", 0.30 if active_weapon == rifle else 0.37)
	if ads_reticle != null:
		ads_reticle.visible = aiming
		ads_reticle.text = "+" if active_weapon == rifle else "○"

func _fire() -> void:
	if player == null or not player.can_control or active_weapon == null or weapon_switch_left > 0.0:
		return
	if active_weapon.has_method("try_fire") and active_weapon.try_fire(player.camera):
		shots += 1
		_update_accuracy()

func _on_mobile_fire_down() -> void:
	mobile_fire_held = true
	# Both modes answer immediately. AUTO continues on _process while the touch
	# remains held; SINGLE deliberately stops after this one existing shot.
	_fire()

func _on_mobile_fire_up() -> void:
	mobile_fire_held = false

func _toggle_fire_mode() -> void:
	settings.toggle_fire_mode()
	mobile_fire_held = false
	if fire_mode_button != null:
		fire_mode_button.text = _button_display_text(settings.fire_mode)
	_set_status("AUTO FIRE" if settings.fire_mode == "AUTO" else "SINGLE FIRE")
	settings.save_to_disk()

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
	_cancel_aim()
	if active_weapon != null and active_weapon.has_method("start_reload"):
		active_weapon.start_reload()

func _switch_weapon() -> void:
	if weapon_switch_left > 0.0 or rifle == null or pistol == null:
		return
	_cancel_aim()
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
	enemy.damaged.connect(_on_raider_damaged)
	enemy.eliminated.connect(_on_raider_eliminated)

func _on_raider_damaged(enemy: Raider, amount: int, headshot: bool) -> void:
	_show_damage_number_at(enemy.global_position + Vector3(0, 1.55, 0), amount, headshot)

func _show_damage_number_at(point: Vector3, amount: int, headshot: bool) -> void:
	if not bool(SettingsService.get_setting("damage_numbers", true)) or player == null or player.camera == null:
		return
	var camera := player.camera
	if camera.is_position_behind(point):
		return
	var number := Label.new()
	number.name = "Damage number"
	number.text = "%d" % amount
	number.position = camera.unproject_position(point) + Vector2(-22, -18)
	number.size = Vector2(44, 28)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_font_size_override("font_size", 20 if headshot else 16)
	number.add_theme_color_override("font_color", _hud_color("headshot" if headshot else "damage_number"))
	number.add_theme_color_override("font_outline_color", Color("07161a"))
	number.add_theme_constant_override("outline_size", 3)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(number)
	var tween := create_tween()
	tween.tween_property(number, "position:y", number.position.y - 30.0, 0.38)
	tween.parallel().tween_property(number, "modulate:a", 0.0, 0.38)
	tween.tween_callback(number.queue_free)

func _on_raider_eliminated(_enemy: Raider, points: int) -> void:
	score += points
	score_label.text = "SCORE  %05d" % score
	director.enemy_eliminated()

func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	WorldBuilder.set_wave_atmosphere(self, wave_number)
	wave_label.text = "WAVE  %d / 3   •   %d INBOUND" % [wave_number, enemy_count]
	_show_alert("WAVE %d  —  HOLD THE LINE" % wave_number, 1.5)

func _on_wave_cleared(wave_number: int) -> void:
	wave_label.text = "WAVE %d CLEARED" % wave_number
	if wave_number < 3:
		_show_alert("AREA SECURED  •  RELOAD NOW", 2.1)

func _on_operation_complete() -> void:
	GameManager.set_state(GameManager.State.MISSION_COMPLETE)
	var result := _record_operation_result()
	_set_status("OPERATION COMPLETE")
	_show_alert("OUTPOST SECURED", 100.0)
	player.can_control = false
	_show_end_panel(tr("result.mission_complete"), _result_summary(result, true), Color("8fcf9a"))

func _on_player_down() -> void:
	GameManager.set_state(GameManager.State.GAME_OVER)
	var result := _record_operation_result()
	director.stop_operation()
	damage_flash = 1.0
	respawn_left = 2.8
	respawn_last_second = -1
	_set_status("YOU ARE DOWN")
	_show_alert("REDEPLOYING", 2.5)
	_show_end_panel(tr("result.mission_failed"), _result_summary(result, false), Color("ed8a74"))

func _record_operation_result() -> Dictionary:
	if operation_result_recorded:
		return SaveService.get_best_result(GameManager.selected_map_id)
	var map_id: String = GameManager.selected_map_id
	var previous := SaveService.get_best_result(map_id)
	var best := SaveService.set_best_result(map_id, score, _current_wave_number())
	operation_result_recorded = true
	return {
		"score": score,
		"wave": _current_wave_number(),
		"accuracy": _accuracy_percent(),
		"best_score": int(best.get("score", 0)),
		"best_wave": int(best.get("wave", 0)),
		"new_best": score > int(previous.get("score", 0)) or _current_wave_number() > int(previous.get("wave", 0)),
	}

func _current_wave_number() -> int:
	return director.current_wave if director != null else 0

func _accuracy_percent() -> int:
	return roundi(float(hits) / float(maxi(shots, 1)) * 100.0)

func _result_summary(result: Dictionary, completed: bool) -> String:
	var outcome := tr("result.cargo_secured") if completed else tr("result.redeploying")
	var lines := [
		outcome,
		tr("result.final_score") % int(result.get("score", score)),
		tr("result.wave") % int(result.get("wave", _current_wave_number())),
		tr("result.accuracy") % int(result.get("accuracy", _accuracy_percent())),
		tr("result.best_score") % int(result.get("best_score", score)),
	]
	if bool(result.get("new_best", false)):
		lines.append(tr("result.new_best"))
	return "\n".join(lines)

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
	displayed_health = current
	displayed_health_maximum = maximum
	if health_label != null:
		health_label.text = "VITALS  %03d / %03d" % [current, maximum]
	_refresh_health_presentation()

func _refresh_health_presentation() -> void:
	if health_bar_fill == null:
		return
	health_bar_fill.size.x = 188.0 * clampf(float(displayed_health) / float(maxi(displayed_health_maximum, 1)), 0.0, 1.0)
	health_bar_fill.color = _hud_color("health_good" if displayed_health > displayed_health_maximum * .42 else "health_low")

func _on_runtime_setting_changed(key: String, _value: Variant) -> void:
	if key in ["reduce_screen_shake", "colorblind_mode", "damage_numbers", "haptics", "gamepad_deadzone"]:
		_apply_accessibility_settings()

func _apply_accessibility_settings() -> void:
	if player != null:
		player.set_reduce_screen_shake(bool(SettingsService.get_setting("reduce_screen_shake", false)))
	_refresh_health_presentation()
	if damage_overlay != null:
		var overlay_color := _hud_color("damage")
		overlay_color.a = damage_overlay.color.a
		damage_overlay.color = overlay_color
	for edge in damage_edges:
		var edge_color := _hud_color("damage")
		edge_color.a = edge.color.a
		edge.color = edge_color
	for segment in reticle_segments:
		segment.color = _hud_color("reticle")

func _hud_color(role: String) -> Color:
	var mode := str(SettingsService.get_setting("colorblind_mode", "OFF"))
	if mode == "PROTANOPIA" or mode == "DEUTERANOPIA":
		match role:
			"health_good", "reticle":
				return Color("67dbe9")
			"health_low", "damage", "damage_number":
				return Color("ffb85c")
			"headshot":
				return Color("fff1a1")
	if mode == "TRITANOPIA":
		match role:
			"health_good", "reticle":
				return Color("73e2b0")
			"health_low", "damage", "damage_number":
				return Color("ff7f69")
			"headshot":
				return Color("ffd56e")
	match role:
		"health_good":
			return Color("80d88a")
		"health_low", "damage", "damage_number":
			return Color("ef7c62")
		"headshot":
			return Color("ffda78")
		_:
			return Color("fff1cf")

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
	if weapon_label != null:
		weapon_label.text = "CARBINE" if active_weapon == rifle else "SIDEARM"

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
		accuracy_label.text = "ACC  %d%%" % _accuracy_percent()

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
	hit_marker.add_theme_color_override("font_color", _hud_color("headshot") if headshot else (_hud_color("damage_number") if eliminated else _hud_color("reticle")))
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
	entry.add_theme_color_override("font_color", _hud_color("headshot") if headshot else Color("f1ded0"))
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kill_feed.add_child(entry)
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(entry, "modulate:a", 0.0, 0.35)
	tween.tween_callback(entry.queue_free)

func _build_dynamic_reticle() -> void:
	reticle_root = Control.new()
	var root := reticle_root
	root.name = "Dynamic spread reticle"
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(-1, -1)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	for index in range(4):
		var segment := ColorRect.new()
		segment.name = "Reticle segment"
		segment.color = _hud_color("reticle")
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.size = Vector2(10, 2) if index < 2 else Vector2(2, 10)
		root.add_child(segment)
		reticle_segments.append(segment)
	_update_dynamic_reticle()

func _update_dynamic_reticle() -> void:
	if reticle_segments.size() != 4:
		return
	var aiming := player != null and player.is_aiming
	if reticle_root != null:
		reticle_root.visible = not aiming
	if aiming:
		return
	var movement := player.get_move_amount() if player != null else 0.0
	var gap := lerpf(7.0, 18.0, movement)
	reticle_segments[0].position = Vector2(-gap - 10.0, -1.0)
	reticle_segments[1].position = Vector2(gap, -1.0)
	reticle_segments[2].position = Vector2(-1.0, -gap - 10.0)
	reticle_segments[3].position = Vector2(-1.0, gap)

func _build_ads_overlay() -> void:
	# This is a screen-space glass treatment, not a second render target. Its
	# transparent center guarantees that the primary camera world remains visible
	# at every quality tier and it ignores input so HUD controls keep working.
	ads_overlay = ColorRect.new()
	ads_overlay.name = "Transparent ADS glass overlay"
	ads_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ads_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glass_material := ShaderMaterial.new()
	glass_material.shader = ADS_GLASS_SHADER
	ads_overlay.material = glass_material
	ads_overlay.visible = false
	hud.add_child(ads_overlay)
	ads_reticle = Label.new()
	ads_reticle.name = "ADS mil reticle"
	ads_reticle.text = "+"
	ads_reticle.set_anchors_preset(Control.PRESET_CENTER)
	ads_reticle.position = Vector2(-14, -22)
	ads_reticle.size = Vector2(28, 44)
	ads_reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ads_reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ads_reticle.add_theme_font_size_override("font_size", 31)
	ads_reticle.add_theme_color_override("font_color", Color("fff6d6"))
	ads_reticle.add_theme_color_override("font_outline_color", Color("182426"))
	ads_reticle.add_theme_constant_override("outline_size", 2)
	ads_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ads_reticle.visible = false
	hud.add_child(ads_reticle)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "Tactical HUD"
	add_child(hud)
	_build_ads_overlay()
	var top_bar := ColorRect.new()
	top_bar.name = "Translucent tactical header"
	top_bar.color = Color(0.018, 0.045, 0.055, 0.76)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 68.0
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_bar)
	var divider := ColorRect.new()
	divider.color = Color("71d5cc")
	divider.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	divider.offset_top = 66.0
	divider.offset_bottom = 67.0
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(divider)

	health_label = _label("VITALS  100 / 100", Vector2(18, 8), Vector2(220, 24), 15, Color("ddf6df"))
	var health_back := ColorRect.new()
	health_back.name = "Health meter frame"
	health_back.position = Vector2(18, 35)
	health_back.size = Vector2(190, 10)
	health_back.color = Color(0.05, 0.11, 0.12, .92)
	health_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(health_back)
	health_bar_fill = ColorRect.new()
	health_bar_fill.name = "Animated health meter"
	health_bar_fill.position = Vector2(19, 36)
	health_bar_fill.size = Vector2(188, 8)
	health_bar_fill.color = Color("80d88a")
	health_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(health_bar_fill)
	wave_label = _label("WAVE  1 / 3", Vector2(0, 10), Vector2(440, 27), 19, Color("ffe0a8"), Control.PRESET_CENTER_TOP, HORIZONTAL_ALIGNMENT_CENTER)
	score_label = _label("SCORE  00000", Vector2(-216, 10), Vector2(198, 25), 16, Color("d8f5d0"), Control.PRESET_TOP_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	weapon_label = _label("CARBINE", Vector2(-220, 33), Vector2(94, 20), 13, Color("77ddd4"), Control.PRESET_TOP_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	ammo_label = _label("24  /  144", Vector2(-122, 29), Vector2(108, 30), 22, Color("fff2cf"), Control.PRESET_TOP_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	accuracy_label = _label("ACC  0%", Vector2(18, -43), Vector2(140, 25), 15, Color("d8f5d0"), Control.PRESET_BOTTOM_LEFT)
	status_label = _label("SECURE THE OUTPOST", Vector2(-190, -72), Vector2(380, 22), 14, Color("f0c079"), Control.PRESET_CENTER_BOTTOM, HORIZONTAL_ALIGNMENT_CENTER)
	alert_label = _label("", Vector2(-330, 78), Vector2(660, 42), 24, Color("fff0cc"), Control.PRESET_CENTER_TOP, HORIZONTAL_ALIGNMENT_CENTER)
	_build_dynamic_reticle()
	hit_marker = _label("✕", Vector2(-25, -31), Vector2(50, 50), 42, Color("ffdf9a"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	hit_marker.name = "HitMarker"
	hit_marker.modulate.a = 0.0
	damage_indicator = _label("▲", Vector2(-14, -80), Vector2(28, 36), 26, Color("ff8a76"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	damage_indicator.name = "Damage direction indicator"
	damage_indicator.modulate.a = 0.0
	kill_feed = VBoxContainer.new()
	kill_feed.name = "Tactical kill feed"
	kill_feed.position = Vector2(16, 78)
	kill_feed.size = Vector2(330, 130)
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
	# First-launch action controls are compact, circular and deliberately spaced
	# as a right-thumb cluster. Saved player layouts retain their own dimensions.
	fire_button = _button("FIRE", Vector2.ZERO, Vector2(144, 144), Control.PRESET_TOP_LEFT, Color("a94f3f"), controls_root)
	fire_mode_button = _button(settings.fire_mode, Vector2.ZERO, Vector2(76, 54), Control.PRESET_TOP_LEFT, Color("45616a"), controls_root)
	fire_mode_button.name = "Fire mode selector"
	reload_button = _button("RELOAD", Vector2.ZERO, Vector2(84, 84), Control.PRESET_TOP_LEFT, Color("596b4e"), controls_root)
	aim_button = _button("AIM", Vector2.ZERO, Vector2(84, 84), Control.PRESET_TOP_LEFT, Color("3d6661"), controls_root)
	jump_button = _button("JUMP", Vector2.ZERO, Vector2(84, 84), Control.PRESET_TOP_LEFT, Color("4a6370"), controls_root)
	crouch_button = _button("CROUCH", Vector2.ZERO, Vector2(84, 84), Control.PRESET_TOP_LEFT, Color("6e5f43"), controls_root)
	swap_button = _button("SWAP", Vector2.ZERO, Vector2(84, 84), Control.PRESET_TOP_LEFT, Color("67556f"), controls_root)
	fire_button.button_down.connect(_on_mobile_fire_down)
	fire_button.button_up.connect(_on_mobile_fire_up)
	fire_mode_button.pressed.connect(_toggle_fire_mode)
	reload_button.pressed.connect(_reload_active_weapon)
	aim_button.pressed.connect(_toggle_aim)
	jump_button.button_down.connect(_on_jump_button_down)
	jump_button.button_up.connect(_on_jump_button_up)
	crouch_button.button_down.connect(_on_crouch_button_down)
	swap_button.pressed.connect(_switch_weapon)
	adjustable_controls = {
		"joystick": movement_stick,
		"fire": fire_button,
		"fire_mode": fire_mode_button,
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
	pause_button = _button("PAUSE", Vector2(402, 7), Vector2(82, 44), Control.PRESET_TOP_LEFT, Color("4b6678"))
	pause_button.add_theme_font_size_override("font_size", 13)
	pause_button.pressed.connect(_toggle_pause)
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

func _build_pause_overlay() -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "Pause overlay"
	pause_overlay.theme = REDLINE_THEME
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	hud.add_child(pause_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.012, 0.028, 0.04, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	pause_panel = PanelContainer.new()
	pause_panel.custom_minimum_size = Vector2(430, 0)
	center.add_child(pause_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	pause_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = tr("pause.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", REDLINE_THEME.get_font("font", "Button"))
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("8ef7ff"))
	column.add_child(title)
	var note := Label.new()
	note.text = tr("pause.subtitle")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate.a = 0.78
	column.add_child(note)
	pause_resume_button = _make_pause_button("pause.resume", _close_pause)
	column.add_child(pause_resume_button)
	column.add_child(_make_pause_button("menu.settings", _show_pause_settings))
	column.add_child(_make_pause_button("pause.restart_operation", _restart_from_pause))
	column.add_child(_make_pause_button("pause.map_select", _return_to_map_select))
	column.add_child(_make_pause_button("pause.quit_to_desktop", _quit_from_pause))
	pause_settings_center = CenterContainer.new()
	pause_settings_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_settings_center.visible = false
	pause_overlay.add_child(pause_settings_center)
	pause_settings_menu = RedlineSettingsMenu.new()
	pause_settings_menu.close_requested.connect(_hide_pause_settings)
	pause_settings_center.add_child(pause_settings_menu)

func _make_pause_button(key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size = Vector2(350, 58)
	button.pressed.connect(callback)
	button.pressed.connect(AudioService.play_ui_confirm)
	return button

func _toggle_pause() -> void:
	if GameManager.state == GameManager.State.PLAYING:
		_open_pause()
	elif GameManager.state == GameManager.State.PAUSED:
		_close_pause()

func _open_pause() -> void:
	if not GameManager.enter_pause():
		return
	mobile_fire_held = false
	_cancel_aim()
	pause_overlay.visible = true
	pause_panel.visible = true
	pause_settings_center.visible = false
	pause_resume_button.call_deferred("grab_focus")

func _close_pause() -> void:
	if GameManager.state != GameManager.State.PAUSED:
		return
	pause_overlay.visible = false
	pause_settings_center.visible = false
	GameManager.leave_pause()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _show_pause_settings() -> void:
	pause_panel.visible = false
	pause_settings_center.visible = true
	pause_settings_menu.call_deferred("focus_initial_control")

func _hide_pause_settings() -> void:
	pause_settings_center.visible = false
	pause_panel.visible = true
	pause_resume_button.call_deferred("grab_focus")

func _restart_from_pause() -> void:
	if GameManager.state == GameManager.State.PAUSED:
		GameManager.leave_pause()
	get_tree().reload_current_scene()

func _return_to_map_select() -> void:
	if GameManager.state == GameManager.State.PAUSED:
		GameManager.leave_pause()
	var result := SceneLoader.load_scene("res://scenes/Boot.tscn")
	if result != OK:
		push_warning("Pause menu could not return to Boot.tscn: %s" % result)

func _quit_from_pause() -> void:
	get_tree().quit()

func _handle_pause_back() -> void:
	if GameManager.state == GameManager.State.PAUSED and pause_settings_center != null and pause_settings_center.visible:
		_hide_pause_settings()
	else:
		_toggle_pause()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputService.ACTION_PAUSE):
		_handle_pause_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputService.ACTION_MENU_BACK):
		_handle_pause_back()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and GameManager.state == GameManager.State.PLAYING:
		_open_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_pause_back()

func _run_pause_flow_verification() -> void:
	# Normal headless validation needs only state transitions. The same real
	# Boot → Main route optionally saves two renderer-backed frames under Xvfb:
	# the active pause menu and its shared Bengali settings surface.
	var capture_directory := _pause_capture_directory()
	if not capture_directory.is_empty():
		await get_tree().create_timer(1.5, true).timeout
	else:
		await get_tree().process_frame
	_open_pause()
	await get_tree().process_frame
	if GameManager.state != GameManager.State.PAUSED or not get_tree().paused or pause_overlay == null or not pause_overlay.visible:
		push_error("Pause-flow verification could not enter paused state.")
		get_tree().quit(1)
		return
	if not capture_directory.is_empty():
		var pause_capture_ok := await _capture_pause_frame(capture_directory.path_join("pause-overlay.png"))
		if not pause_capture_ok:
			get_tree().quit(1)
			return
	_show_pause_settings()
	await get_tree().process_frame
	if not pause_settings_center.visible or pause_panel.visible:
		push_error("Pause-flow verification could not open shared settings.")
		get_tree().quit(1)
		return
	if not capture_directory.is_empty():
		var settings_capture_ok := await _capture_pause_frame(capture_directory.path_join("pause-settings-bn.png"))
		if not settings_capture_ok:
			get_tree().quit(1)
			return
	_handle_pause_back()
	if not pause_panel.visible or pause_settings_center.visible:
		push_error("Pause-flow verification could not return from shared settings.")
		get_tree().quit(1)
		return
	_close_pause()
	# `leave_pause()` and Control visibility update synchronously. Do not await a
	# rendered frame here: the Xvfb capture route can defer it after readback.
	if GameManager.state != GameManager.State.PLAYING or get_tree().paused or pause_overlay.visible:
		push_error("Pause-flow verification could not resume gameplay state.")
		get_tree().quit(1)
		return
	print("PAUSE_FLOW_PASS state=", GameManager.state)
	get_tree().quit()

func _run_result_flow_verification() -> void:
	await get_tree().process_frame
	GameManager.select_map("M3_RESULT_VERIFY")
	score = 275
	shots = 10
	hits = 7
	director.current_wave = 3
	_on_operation_complete()
	var saved_result := SaveService.get_best_result("M3_RESULT_VERIFY")
	if GameManager.state != GameManager.State.MISSION_COMPLETE or end_panel == null or not end_panel.visible:
		push_error("Result-flow verification could not present the mission-complete state.")
		get_tree().quit(1)
		return
	if int(saved_result.get("score", 0)) != 275 or int(saved_result.get("wave", 0)) != 3:
		push_error("Result-flow verification could not persist the best score and wave.")
		get_tree().quit(1)
		return
	print("RESULT_FLOW_PASS score=", saved_result.get("score", 0), " wave=", saved_result.get("wave", 0))
	get_tree().quit()

func _run_audio_flow_verification() -> void:
	await get_tree().process_frame
	var master_index := AudioServer.get_bus_index("Master")
	var sfx_index := AudioServer.get_bus_index(AudioService.BUS_SFX)
	var ui_index := AudioServer.get_bus_index(AudioService.BUS_UI)
	if master_index < 0 or sfx_index < 0 or ui_index < 0:
		push_error("Audio-flow verification could not resolve the required audio buses.")
		get_tree().quit(1)
		return
	var original_master_volume := float(SettingsService.get_setting("master_volume", 1.0))
	var original_focus_mute := bool(SettingsService.get_setting("mute_when_unfocused", true))
	var original_sfx_volume := float(SettingsService.get_setting("sfx_volume", 0.85))
	SettingsService.set_setting("master_volume", 1.0, false)
	SettingsService.set_setting("mute_when_unfocused", true, false)
	AudioService.set_application_focus(false)
	if not AudioServer.is_bus_mute(master_index) or not AudioService.muted_for_focus:
		push_error("Audio-flow verification could not mute Master on focus loss.")
		get_tree().quit(1)
		return
	AudioService.set_application_focus(true)
	if AudioServer.is_bus_mute(master_index) or AudioService.muted_for_focus:
		push_error("Audio-flow verification could not restore Master on focus return.")
		get_tree().quit(1)
		return
	AudioService.set_bus_linear_volume(AudioService.BUS_SFX, 0.40)
	if is_zero_approx(AudioServer.get_bus_volume_db(sfx_index)) or str(rifle.shot_audio.bus) != AudioService.BUS_SFX or str(pistol.shot_audio.bus) != AudioService.BUS_SFX:
		push_error("Audio-flow verification could not route combat audio through SFX.")
		get_tree().quit(1)
		return
	if str(player.landing_audio.bus) != AudioService.BUS_SFX or AudioService.ui_feedback == null or str(AudioService.ui_feedback.bus) != AudioService.BUS_UI:
		push_error("Audio-flow verification could not route landing or UI feedback audio.")
		get_tree().quit(1)
		return
	AudioService.play_ui_confirm()
	SettingsService.set_setting("mute_when_unfocused", original_focus_mute, false)
	SettingsService.set_setting("master_volume", original_master_volume, false)
	AudioService.set_bus_linear_volume(AudioService.BUS_SFX, original_sfx_volume)
	print("AUDIO_FLOW_PASS sfx_bus=", sfx_index, " ui_bus=", ui_index)
	get_tree().quit()

func _run_input_accessibility_verification() -> void:
	await get_tree().process_frame
	if not InputService.gameplay_bindings_ready() or not InputService.gamepad_bindings_ready():
		push_error("Input-accessibility verification found an incomplete named input map.")
		get_tree().quit(1)
		return
	var original_reduce_shake := bool(SettingsService.get_setting("reduce_screen_shake", false))
	var original_colorblind := str(SettingsService.get_setting("colorblind_mode", "OFF"))
	var original_damage_numbers := bool(SettingsService.get_setting("damage_numbers", true))
	var original_haptics := bool(SettingsService.get_setting("haptics", true))
	var original_deadzone := float(SettingsService.get_setting("gamepad_deadzone", 0.20))
	SettingsService.set_setting("reduce_screen_shake", true, false)
	SettingsService.set_setting("colorblind_mode", "DEUTERANOPIA", false)
	SettingsService.set_setting("haptics", false, false)
	SettingsService.set_setting("gamepad_deadzone", 0.35, false)
	if player == null or not player.reduce_screen_shake or reticle_segments.is_empty() or reticle_segments[0].color != _hud_color("reticle"):
		push_error("Input-accessibility verification could not apply reduced-motion or palette settings.")
		get_tree().quit(1)
		return
	_on_health_changed(20, 100)
	if health_bar_fill == null or health_bar_fill.color != _hud_color("health_low"):
		push_error("Input-accessibility verification could not apply the critical-health palette.")
		get_tree().quit(1)
		return
	var probe_point: Vector3 = player.camera.global_position + -player.camera.global_transform.basis.z * 5.0
	SettingsService.set_setting("damage_numbers", true, false)
	var before_count := _damage_number_count()
	_show_damage_number_at(probe_point, 42, true)
	if _damage_number_count() != before_count + 1:
		push_error("Input-accessibility verification could not create an enabled damage number.")
		get_tree().quit(1)
		return
	SettingsService.set_setting("damage_numbers", false, false)
	_show_damage_number_at(probe_point, 42, false)
	if _damage_number_count() != before_count + 1:
		push_error("Input-accessibility verification did not suppress disabled damage numbers.")
		get_tree().quit(1)
		return
	SettingsService.set_setting("reduce_screen_shake", original_reduce_shake, false)
	SettingsService.set_setting("colorblind_mode", original_colorblind, false)
	SettingsService.set_setting("damage_numbers", original_damage_numbers, false)
	SettingsService.set_setting("haptics", original_haptics, false)
	SettingsService.set_setting("gamepad_deadzone", original_deadzone, false)
	_on_health_changed(player.health, OutpostPlayer.MAX_HEALTH)
	print("INPUT_ACCESSIBILITY_PASS actions=", InputService.GAMEPLAY_ACTIONS.size(), " damage_numbers=", before_count + 1)
	get_tree().quit()

func _damage_number_count() -> int:
	var count := 0
	for child in hud.get_children():
		if child.name == "Damage number":
			count += 1
	return count

func _pause_capture_directory() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == PAUSE_CAPTURE_OUTPUT_ARGUMENT:
			var directory := args[index + 1]
			if DirAccess.make_dir_recursive_absolute(directory) == OK:
				return directory
			push_error("Pause screenshot directory could not be created: %s" % directory)
			return ""
	return ""

func _capture_pause_frame(path: String) -> bool:
	# A paused SceneTree can stop `RenderingServer.frame_post_draw` from emitting
	# on CI's Xvfb/llvmpipe path. The normal frame boundary still presents the
	# newly visible Control tree, so two process frames produce the authentic
	# overlay without an unbounded renderer-signal wait.
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(path)
	if result != OK or image.get_width() < 1280 or image.get_height() < 720:
		push_error("Pause screenshot capture failed: %s result=%s size=%sx%s" % [path, result, image.get_width(), image.get_height()])
		return false
	print("PAUSE_VISUAL_CAPTURE ", path, " size=", image.get_width(), "x", image.get_height())
	return true

func _build_loading_splash() -> void:
	# There is no separate menu scene in this survival build, so an in-engine
	# tactical splash gives asset import/world construction a polished first frame.
	var splash := ColorRect.new()
	splash.name = "Operation Redline loading splash"
	splash.color = Color("071317")
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(splash)
	var title := Label.new()
	title.text = "OPERATION\nREDLINE"
	title.position = Vector2(-320, -95)
	title.size = Vector2(640, 120)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("ffca84"))
	title.add_theme_color_override("font_outline_color", Color("172c2e"))
	title.add_theme_constant_override("outline_size", 8)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "REDLINE OUTPOST  •  SECURING THE PERIMETER"
	subtitle.position = Vector2(-300, 36)
	subtitle.size = Vector2(600, 30)
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("7bd9d1"))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(subtitle)
	var tween := create_tween()
	tween.tween_interval(.85)
	tween.tween_property(splash, "modulate:a", 0.0, .42)
	tween.parallel().tween_property(title, "modulate:a", 0.0, .30)
	tween.parallel().tween_property(subtitle, "modulate:a", 0.0, .30)
	tween.tween_callback(splash.queue_free)
	tween.tween_callback(title.queue_free)
	tween.tween_callback(subtitle.queue_free)

func _build_damage_edges() -> void:
	# Offset-based edge strips avoid anchor/size layout overrides on narrow or
	# ultrawide screens, while retaining a low-cost damage vignette fallback.
	var top := ColorRect.new()
	top.color = Color(0.76, 0.035, 0.018, 0.0)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 46.0
	var bottom := ColorRect.new()
	bottom.color = Color(0.76, 0.035, 0.018, 0.0)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -46.0
	var left := ColorRect.new()
	left.color = Color(0.76, 0.035, 0.018, 0.0)
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_right = 50.0
	var right := ColorRect.new()
	right.color = Color(0.76, 0.035, 0.018, 0.0)
	right.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	right.offset_left = -50.0
	for edge in [top, bottom, left, right]:
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(edge)
		damage_edges.append(edge)

func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.name = "Settings panel"
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-230, -138)
	settings_panel.size = Vector2(460, 276)
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
	var effects := _button("EFFECTS", Vector2(24, 158), Vector2(128, 42), Control.PRESET_TOP_LEFT, Color("5d684a"), settings_panel)
	effects.pressed.connect(_toggle_screen_effects)
	var quality := _button("QUALITY", Vector2(166, 158), Vector2(128, 42), Control.PRESET_TOP_LEFT, Color("486e72"), settings_panel)
	quality.pressed.connect(_cycle_quality_tier)
	var close := _button("CLOSE", Vector2(308, 158), Vector2(128, 42), Control.PRESET_TOP_LEFT, Color("54734f"), settings_panel)
	close.pressed.connect(_close_settings)
	var tier_note := Label.new()
	tier_note.text = "QUALITY controls lighting, shadows, particles and dynamic 3D resolution. Gameplay is never reduced."
	tier_note.position = Vector2(24, 215)
	tier_note.size = Vector2(412, 38)
	tier_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tier_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_note.add_theme_font_size_override("font_size", 12)
	tier_note.add_theme_color_override("font_color", Color("a7cac5"))
	settings_panel.add_child(tier_note)

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

func _cycle_quality_tier() -> void:
	settings.cycle_quality_tier()
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
	if fire_mode_button != null:
		fire_mode_button.text = _button_display_text(settings.fire_mode)
	if performance_governor != null:
		performance_governor.set_effects_requested(settings.screen_effects)
		# LOW/MEDIUM/HIGH/ULTRA are fixed, player-selected presentation tiers.
		# Only AUTO may invoke the governor's temporary pressure fallback.
		performance_governor.set_quality_tier(settings.resolved_quality_tier(), settings.uses_adaptive_quality())
	_update_settings_summary()

func _update_settings_summary() -> void:
	if settings_summary != null:
		var active_tier := performance_governor.display_tier() if performance_governor != null else settings.resolved_quality_tier()
		var quality_line := "QUALITY  %s  --  %s" % [settings.quality_tier, active_tier]
		settings_summary.text = "LOOK  %.0f%%   •   ASSIST  %s   •   EFFECTS  %s\n%s" % [settings.look_sensitivity * 100.0, "ON" if settings.aim_assist else "OFF", "ON" if settings.screen_effects else "OFF", quality_line]

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
	# The right-side controls use a collision-free 3×2 thumb cluster: every
	# gap is at least 10 px at the 1280×720 design resolution and it expands with
	# the device canvas. This removes the former SWAP/CROUCH ambiguity.
	_set_control_rect("joystick", Vector2(34, screen.y - 220), Vector2(176, 176))
	_set_control_rect("fire", Vector2(screen.x - 174, screen.y - 226), Vector2(144, 144))
	# Mode switch occupies the gap above-left of FIRE. It never steals the FIRE
	# hit target and is persisted like the existing mobile controls.
	_set_control_rect("fire_mode", Vector2(screen.x - 264, screen.y - 282), Vector2(76, 54))
	_set_control_rect("aim", Vector2(screen.x - 378, screen.y - 112), Vector2(84, 84))
	_set_control_rect("reload", Vector2(screen.x - 284, screen.y - 112), Vector2(84, 84))
	_set_control_rect("jump", Vector2(screen.x - 284, screen.y - 210), Vector2(84, 84))
	_set_control_rect("crouch", Vector2(screen.x - 378, screen.y - 210), Vector2(84, 84))
	_set_control_rect("swap", Vector2(screen.x - 472, screen.y - 112), Vector2(84, 84))
	_set_control_rect("minimap", Vector2(screen.x - 166, 78), Vector2(148, 148))

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
	control.pivot_offset = final_size * 0.5
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
	if end_panel != null and is_instance_valid(end_panel):
		end_panel.queue_free()
	end_panel = Control.new()
	end_panel.name = "Operation Result"
	end_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(end_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.035, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_panel.add_child(shade)
	_label(title, Vector2(-300, -134), Vector2(600, 42), 30, tint, Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER, end_panel)
	var summary := _label(description, Vector2(-300, -78), Vector2(600, 132), 17, Color("e6dcc1"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER, end_panel)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	restart_button = _button(tr("result.restart_operation"), Vector2(-140, 72), Vector2(280, 58), Control.PRESET_CENTER, Color("596d52"), end_panel)
	restart_button.pressed.connect(_restart)
	restart_button.call_deferred("grab_focus")

func _restart() -> void:
	get_tree().reload_current_scene()

func _toggle_aim() -> void:
	touch_aim = not touch_aim
	if aim_button != null:
		aim_button.text = "◉\nAIM" if touch_aim else _button_display_text("AIM")

func _label(text_value: String, position_offset: Vector2, control_size: Vector2, font_size: int, color: Color, preset := Control.PRESET_TOP_LEFT, alignment := HORIZONTAL_ALIGNMENT_LEFT, parent: Control = null) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.position = position_offset
	label.size = control_size
	label.set_anchors_preset(preset)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent == null:
		hud.add_child(label)
	else:
		parent.add_child(label)
	return label

func _button(text_value: String, position_offset: Vector2, control_size: Vector2, preset: int, color: Color, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = _button_display_text(text_value)
	button.size = control_size
	if parent == null:
		button.position = position_offset
		button.set_anchors_preset(preset)
		hud.add_child(button)
	else:
		button.position = position_offset
		button.set_anchors_preset(preset)
		parent.add_child(button)
	var is_primary_fire := text_value == "FIRE"
	var is_action_button := parent == controls_root
	var corner_radius := int(minf(control_size.x, control_size.y) * (0.48 if is_action_button else 0.22))
	button.add_theme_font_size_override("font_size", 19 if is_primary_fire else (15 if is_action_button else 16))
	button.add_theme_color_override("font_color", Color("f6fff4"))
	button.add_theme_color_override("font_outline_color", Color("07161a"))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_constant_override("line_spacing", -2)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color.r, color.g, color.b, .54 if is_action_button else .82)
	normal.border_color = Color("ffcf82") if is_primary_fire else Color("7bd9d1")
	normal.set_border_width_all(3 if is_primary_fire else (2 if is_action_button else 2))
	normal.corner_radius_top_left = corner_radius
	normal.corner_radius_top_right = corner_radius
	normal.corner_radius_bottom_left = corner_radius
	normal.corner_radius_bottom_right = corner_radius
	normal.shadow_color = Color(.0, .08, .10, .58)
	normal.shadow_size = 7 if is_action_button else 3
	normal.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(color.r * 1.15, color.g * 1.15, color.b * 1.15, .68 if is_action_button else .92)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("e7a75d")
	pressed.border_color = Color("fff4ce")
	pressed.set_border_width_all(3 if is_primary_fire else 2)
	pressed.corner_radius_top_left = corner_radius
	pressed.corner_radius_top_right = corner_radius
	pressed.corner_radius_bottom_left = corner_radius
	pressed.corner_radius_bottom_right = corner_radius
	pressed.shadow_color = Color("ffb35e")
	pressed.shadow_size = 9 if is_action_button else 3
	button.add_theme_stylebox_override("pressed", pressed)
	if is_action_button:
		button.pivot_offset = control_size * 0.5
		button.button_down.connect(_pulse_action_control.bind(button))
		button.button_up.connect(_release_action_control.bind(button))
	else:
		button.pressed.connect(AudioService.play_ui_confirm)
	return button

func _pulse_action_control(button: Button) -> void:
	# A small responsive scale pulse gives touch input a tactile visual response;
	# haptics are only requested on mobile and never gate the gameplay signal.
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(.92, .92), .055)
	if OS.has_feature("mobile") and bool(SettingsService.get_setting("haptics", true)):
		Input.vibrate_handheld(14)

func _release_action_control(button: Button) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, .105).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _button_display_text(text_value: String) -> String:
	match text_value:
		"FIRE":
			return "◎\nFIRE"
		"AIM":
			return "⌾\nAIM"
		"RELOAD":
			return "↻\nRELOAD"
		"JUMP":
			return "↑\nJUMP"
		"CROUCH":
			return "↓\nCROUCH"
		"SWAP":
				return "⇄\nSWAP"
		"SINGLE":
				return "•\nSINGLE"
		"AUTO":
				return "≋\nAUTO"
		_:
				return text_value
