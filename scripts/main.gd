extends Node3D

const PLAYER_SPAWN := Vector3(0, 0.12, 13)
const SPAWN_POINTS := [
	Vector3(-25, 0.15, -18), Vector3(24, 0.15, -18), Vector3(-24, 0.15, 19),
	Vector3(23, 0.15, 20), Vector3(-5, 0.15, -25), Vector3(6, 0.15, 25),
	Vector3(25, 0.15, 2), Vector3(-26, 0.15, 3)
]

var player: OutpostPlayer
var rifle: ServiceRifle
var director: SurvivalDirector
var hud: CanvasLayer
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
var restart_button: Button
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
	player.health_changed.connect(_on_health_changed)
	player.player_down.connect(_on_player_down)

	rifle = ServiceRifle.new()
	player.camera.add_child(rifle)
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
	_set_status("SECURE THE OUTPOST")
	_show_alert("OPERATION REDLINE", 2.1)
	director.start_operation()

func _process(delta: float) -> void:
	if player != null and player.can_control:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_fire()
		player.set_aim(touch_aim or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
	damage_flash = maxf(damage_flash - delta * 1.8, 0.0)
	if damage_overlay != null:
		damage_overlay.color.a = damage_flash

func _fire() -> void:
	if player == null or not player.can_control or rifle == null:
		return
	if rifle.try_fire(player.camera):
		shots += 1
		_update_accuracy()

func _spawn_raider(serial: int) -> void:
	if not player.can_control:
		return
	var enemy := Raider.new()
	enemy.setup(serial)
	var candidate: Vector3 = SPAWN_POINTS[(serial - 1) % SPAWN_POINTS.size()]
	# Do not make every wave feel identical: rotate the selected lane each round.
	var lateral := Vector3(float((serial * 7) % 5 - 2) * 0.7, 0, float((serial * 3) % 5 - 2) * 0.5)
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
	top_bar.color = Color(0.035, 0.055, 0.05, 0.74)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.size.y = 58
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_bar)

	health_label = _label("HP  100 / 100", Vector2(18, 14), Vector2(220, 28), 19, Color("d8f5d0"))
	ammo_label = _label("24  /  144", Vector2(-186, -58), Vector2(170, 40), 27, Color("f7e0ad"), Control.PRESET_BOTTOM_RIGHT)
	wave_label = _label("WAVE  1 / 3", Vector2(0, 15), Vector2(420, 28), 18, Color("f4d8a6"), Control.PRESET_CENTER_TOP, HORIZONTAL_ALIGNMENT_CENTER)
	score_label = _label("SCORE  00000", Vector2(-205, 14), Vector2(188, 28), 18, Color("d8f5d0"), Control.PRESET_TOP_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	accuracy_label = _label("ACC  0%", Vector2(18, -45), Vector2(140, 25), 15, Color("d8f5d0"), Control.PRESET_BOTTOM_LEFT)
	status_label = _label("SECURE THE OUTPOST", Vector2(-160, -83), Vector2(320, 22), 14, Color("f0b574"), Control.PRESET_CENTER_BOTTOM, HORIZONTAL_ALIGNMENT_CENTER)
	alert_label = _label("", Vector2(-300, 74), Vector2(600, 42), 24, Color("fff0cc"), Control.PRESET_CENTER_TOP, HORIZONTAL_ALIGNMENT_CENTER)

	var reticle := _label("+", Vector2(-14, -18), Vector2(28, 36), 30, Color("f5eccf"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	reticle.name = "Reticle"
	var hit_marker := _label("×", Vector2(-22, -31), Vector2(44, 50), 42, Color("ffdf9a"), Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	hit_marker.name = "HitMarker"
	hit_marker.modulate.a = 0.0

	# The left pad is a non-blocking visual guide. Finger drags on this zone steer movement.
	var move_pad := _label("◉\nMOVE", Vector2(30, -151), Vector2(110, 112), 16, Color(0.85, 0.92, 0.77, 0.52), Control.PRESET_BOTTOM_LEFT, HORIZONTAL_ALIGNMENT_CENTER)
	move_pad.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fire_button = _button("FIRE", Vector2(-132, -154), Vector2(112, 88), Control.PRESET_BOTTOM_RIGHT, Color("a74f3e"))
	fire_button.button_down.connect(_fire)
	reload_button = _button("RELOAD", Vector2(-250, -76), Vector2(105, 48), Control.PRESET_BOTTOM_RIGHT, Color("5d684a"))
	reload_button.pressed.connect(rifle.start_reload)
	aim_button = _button("AIM", Vector2(-368, -76), Vector2(105, 48), Control.PRESET_BOTTOM_RIGHT, Color("455f5a"))
	aim_button.pressed.connect(_toggle_aim)

	jump_button = _button("JUMP", Vector2(-486, -76), Vector2(105, 48), Control.PRESET_BOTTOM_RIGHT, Color("3b6b58"))
	jump_button.pressed.connect(_jump)

	damage_overlay = ColorRect.new()
	damage_overlay.name = "Damage vignette"
	damage_overlay.color = Color(0.75, 0.04, 0.02, 0.0)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(damage_overlay)

func _jump() -> void:
	if player != null:
		player.jump()

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

func _button(text_value: String, position_offset: Vector2, control_size: Vector2, preset: int, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = position_offset
	button.size = control_size
	button.set_anchors_preset(preset)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("fff1ce"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color.r, color.g, color.b, 0.82)
	normal.border_color = Color("f4d39a")
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_left = 5
	normal.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("normal", normal)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("e5a45b")
	pressed.border_color = Color("fff0c4")
	pressed.set_border_width_all(2)
	pressed.corner_radius_top_left = 5
	pressed.corner_radius_top_right = 5
	pressed.corner_radius_bottom_left = 5
	pressed.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("pressed", pressed)
	hud.add_child(button)
	return button
