extends Node

## Owns named gameplay actions, their default keyboard/gamepad bindings, and
## compact conflict-aware keyboard/gamepad rebinding. Touch remains explicit in the
## player HUD and is never converted into a raw screen-wide fire binding.
signal keyboard_binding_changed(action: String, physical_keycode: Key)
signal gamepad_binding_changed(action: String, button_index: JoyButton)
signal keyboard_bindings_reset
signal gamepad_bindings_reset

const BINDINGS_PATH := "user://input_bindings.cfg"
const RESERVED_REBIND_KEYS := [KEY_ENTER, KEY_TAB]
const RESERVED_REBIND_GAMEPAD_BUTTONS := [JOY_BUTTON_B]

const ACTION_MOVE_FORWARD := "redline_move_forward"
const ACTION_MOVE_BACK := "redline_move_back"
const ACTION_MOVE_LEFT := "redline_move_left"
const ACTION_MOVE_RIGHT := "redline_move_right"
const ACTION_FIRE := "redline_fire"
const ACTION_AIM := "redline_aim"
const ACTION_JUMP := "redline_jump"
const ACTION_CROUCH := "redline_crouch"
const ACTION_SWAP := "redline_swap"
const ACTION_RELOAD := "redline_reload"
const ACTION_PAUSE := "redline_pause"
const ACTION_MENU_ACCEPT := "redline_menu_accept"
const ACTION_MENU_BACK := "redline_menu_back"

const GAMEPLAY_ACTIONS := [
	ACTION_MOVE_FORWARD, ACTION_MOVE_BACK, ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT,
	ACTION_FIRE, ACTION_AIM, ACTION_JUMP, ACTION_CROUCH, ACTION_SWAP,
	ACTION_RELOAD, ACTION_PAUSE,
]

const REBINDABLE_KEYBOARD_ACTIONS := GAMEPLAY_ACTIONS
# Stick directions stay fixed so the established left-stick movement convention
# remains compatible; gameplay action buttons can be safely remapped.
const REBINDABLE_GAMEPAD_ACTIONS := [
	ACTION_FIRE, ACTION_AIM, ACTION_JUMP, ACTION_CROUCH, ACTION_SWAP,
	ACTION_RELOAD, ACTION_PAUSE,
]

const DEFAULT_KEY_BINDINGS := {
	ACTION_MOVE_FORWARD: [KEY_W, KEY_UP],
	ACTION_MOVE_BACK: [KEY_S, KEY_DOWN],
	ACTION_MOVE_LEFT: [KEY_A, KEY_LEFT],
	ACTION_MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	ACTION_JUMP: [KEY_SPACE],
	ACTION_CROUCH: [KEY_C],
	ACTION_SWAP: [KEY_Q],
	ACTION_RELOAD: [KEY_R],
	ACTION_PAUSE: [KEY_ESCAPE],
}

const DEFAULT_GAMEPAD_BUTTON_BINDINGS := {
	ACTION_FIRE: [JOY_BUTTON_RIGHT_SHOULDER],
	ACTION_AIM: [JOY_BUTTON_LEFT_SHOULDER],
	ACTION_JUMP: [JOY_BUTTON_A],
	ACTION_CROUCH: [JOY_BUTTON_RIGHT_STICK],
	ACTION_SWAP: [JOY_BUTTON_Y],
	ACTION_RELOAD: [JOY_BUTTON_X],
	ACTION_PAUSE: [JOY_BUTTON_START],
}

const ACTION_LABEL_KEYS := {
	ACTION_MOVE_FORWARD: "bindings.move_forward",
	ACTION_MOVE_BACK: "bindings.move_back",
	ACTION_MOVE_LEFT: "bindings.move_left",
	ACTION_MOVE_RIGHT: "bindings.move_right",
	ACTION_FIRE: "bindings.fire",
	ACTION_AIM: "bindings.aim",
	ACTION_JUMP: "bindings.jump",
	ACTION_CROUCH: "bindings.crouch",
	ACTION_SWAP: "bindings.swap",
	ACTION_RELOAD: "bindings.reload",
	ACTION_PAUSE: "bindings.pause",
}

func _ready() -> void:
	_register_defaults()
	_load_custom_bindings()

func _register_defaults() -> void:
	for action in DEFAULT_KEY_BINDINGS:
		for keycode in DEFAULT_KEY_BINDINGS[action]:
			_add_key(action, keycode)
	_add_key(ACTION_MENU_ACCEPT, KEY_ENTER)
	_add_key(ACTION_MENU_BACK, KEY_ESCAPE)
	_add_mouse_button(ACTION_FIRE, MOUSE_BUTTON_LEFT)
	_add_mouse_button(ACTION_AIM, MOUSE_BUTTON_RIGHT)
	_add_joy_button(ACTION_MENU_ACCEPT, JOY_BUTTON_A)
	_add_joy_button(ACTION_MENU_BACK, JOY_BUTTON_B)
	# Route the D-pad through Godot's built-in UI actions so focused menu
	# controls remain keyboard/mouse/gamepad equivalent without a second
	# navigation system.
	_add_joy_button("ui_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	for action in DEFAULT_GAMEPAD_BUTTON_BINDINGS:
		for button_index in DEFAULT_GAMEPAD_BUTTON_BINDINGS[action]:
			_add_joy_button(action, button_index)
	_add_joy_motion(ACTION_MOVE_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add_joy_motion(ACTION_MOVE_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_add_joy_motion(ACTION_MOVE_FORWARD, JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_motion(ACTION_MOVE_BACK, JOY_AXIS_LEFT_Y, 1.0)

func gameplay_bindings_ready() -> bool:
	for action in GAMEPLAY_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			return false
	return true

func gamepad_bindings_ready() -> bool:
	for action in GAMEPLAY_ACTIONS:
		var has_gamepad_event := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_gamepad_event = true
				break
		if not has_gamepad_event:
			return false
	return true

func menu_back_bindings_ready() -> bool:
	if not InputMap.has_action(ACTION_MENU_BACK):
		return false
	var has_keyboard := false
	var has_gamepad := false
	for event in InputMap.action_get_events(ACTION_MENU_BACK):
		has_keyboard = has_keyboard or event is InputEventKey
		has_gamepad = has_gamepad or event is InputEventJoypadButton
	return has_keyboard and has_gamepad

func get_rebindable_actions() -> Array[String]:
	var actions: Array[String] = []
	for action in REBINDABLE_KEYBOARD_ACTIONS:
		actions.append(action)
	return actions

func get_rebindable_gamepad_actions() -> Array[String]:
	var actions: Array[String] = []
	for action in REBINDABLE_GAMEPAD_ACTIONS:
		actions.append(action)
	return actions

func action_label_key(action: String) -> String:
	return str(ACTION_LABEL_KEYS.get(action, action))

func keyboard_binding_display(action: String) -> String:
	var names: Array[String] = []
	for keycode in get_keyboard_binding_keys(action):
		names.append(OS.get_keycode_string(keycode))
	return " / ".join(names) if not names.is_empty() else "—"

func get_keyboard_binding_keys(action: String) -> Array[Key]:
	var keys: Array[Key] = []
	if not InputMap.has_action(action):
		return keys
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
			if keycode != KEY_NONE:
				keys.append(keycode)
	return keys

func gamepad_binding_display(action: String) -> String:
	var names: Array[String] = []
	for button_index in get_gamepad_binding_buttons(action):
		names.append(_gamepad_button_name(button_index))
	return " / ".join(names) if not names.is_empty() else "—"

func get_gamepad_binding_buttons(action: String) -> Array[JoyButton]:
	var buttons: Array[JoyButton] = []
	if not InputMap.has_action(action):
		return buttons
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			buttons.append((event as InputEventJoypadButton).button_index)
	return buttons

func _gamepad_button_name(button_index: JoyButton) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_LEFT_STICK:
			return "L3"
		JOY_BUTTON_RIGHT_STICK:
			return "R3"
		JOY_BUTTON_START:
			return "START"
		_:
			return "BUTTON %d" % button_index

func keyboard_binding_snapshot() -> Dictionary:
	var snapshot := {}
	for action in REBINDABLE_KEYBOARD_ACTIONS:
		snapshot[action] = get_keyboard_binding_keys(action)
	return snapshot

func gamepad_binding_snapshot() -> Dictionary:
	var snapshot := {}
	for action in REBINDABLE_GAMEPAD_ACTIONS:
		snapshot[action] = get_gamepad_binding_buttons(action)
	return snapshot

func restore_keyboard_binding_snapshot(snapshot: Dictionary, persist := false) -> void:
	for action in REBINDABLE_KEYBOARD_ACTIONS:
		_erase_keyboard_events(action)
		var keys: Array = snapshot.get(action, DEFAULT_KEY_BINDINGS.get(action, []))
		for keycode in keys:
			_add_key(action, Key(keycode))
	if persist:
		_save_custom_bindings()

func restore_gamepad_binding_snapshot(snapshot: Dictionary, persist := false) -> void:
	for action in REBINDABLE_GAMEPAD_ACTIONS:
		_erase_gamepad_button_events(action)
		var buttons: Array = snapshot.get(action, DEFAULT_GAMEPAD_BUTTON_BINDINGS.get(action, []))
		for button_index in buttons:
			_add_joy_button(action, JoyButton(button_index))
	if persist:
		_save_custom_bindings()

func try_rebind_keyboard(action: String, keycode: Key, persist := true) -> Dictionary:
	if not REBINDABLE_KEYBOARD_ACTIONS.has(action) or keycode == KEY_NONE or RESERVED_REBIND_KEYS.has(keycode):
		return {"ok": false, "reason": "invalid", "conflict_action": ""}
	var conflict_action := _keyboard_conflict_action(action, keycode)
	if not conflict_action.is_empty():
		return {"ok": false, "reason": "conflict", "conflict_action": conflict_action}
	_erase_keyboard_events(action)
	_add_key(action, keycode)
	if persist:
		_save_custom_bindings()
	keyboard_binding_changed.emit(action, keycode)
	return {"ok": true, "reason": "applied", "conflict_action": ""}

func try_rebind_gamepad(action: String, button_index: JoyButton, persist := true) -> Dictionary:
	if not REBINDABLE_GAMEPAD_ACTIONS.has(action) or RESERVED_REBIND_GAMEPAD_BUTTONS.has(button_index):
		return {"ok": false, "reason": "invalid", "conflict_action": ""}
	var conflict_action := _gamepad_conflict_action(action, button_index)
	if not conflict_action.is_empty():
		return {"ok": false, "reason": "conflict", "conflict_action": conflict_action}
	_erase_gamepad_button_events(action)
	_add_joy_button(action, button_index)
	if persist:
		_save_custom_bindings()
	gamepad_binding_changed.emit(action, button_index)
	return {"ok": true, "reason": "applied", "conflict_action": ""}

func reset_keyboard_bindings(persist := true) -> void:
	for action in REBINDABLE_KEYBOARD_ACTIONS:
		_erase_keyboard_events(action)
		for keycode in DEFAULT_KEY_BINDINGS.get(action, []):
			_add_key(action, Key(keycode))
	if persist:
		_save_custom_bindings()
	keyboard_bindings_reset.emit()

func reset_gamepad_bindings(persist := true) -> void:
	for action in REBINDABLE_GAMEPAD_ACTIONS:
		_erase_gamepad_button_events(action)
		for button_index in DEFAULT_GAMEPAD_BUTTON_BINDINGS.get(action, []):
			_add_joy_button(action, JoyButton(button_index))
	if persist:
		_save_custom_bindings()
	gamepad_bindings_reset.emit()

func _keyboard_conflict_action(target_action: String, keycode: Key) -> String:
	for action in REBINDABLE_KEYBOARD_ACTIONS:
		if action != target_action and get_keyboard_binding_keys(action).has(keycode):
			return action
	return ""

func _gamepad_conflict_action(target_action: String, button_index: JoyButton) -> String:
	for action in REBINDABLE_GAMEPAD_ACTIONS:
		if action != target_action and get_gamepad_binding_buttons(action).has(button_index):
			return action
	return ""

func _load_custom_bindings() -> void:
	var config := ConfigFile.new()
	if config.load(BINDINGS_PATH) != OK:
		return
	var keyboard_snapshot := keyboard_binding_snapshot()
	for action in REBINDABLE_KEYBOARD_ACTIONS:
		if config.has_section_key("keyboard", action):
			keyboard_snapshot[action] = [Key(int(config.get_value("keyboard", action, KEY_NONE)))]
	restore_keyboard_binding_snapshot(keyboard_snapshot, false)
	var gamepad_snapshot := gamepad_binding_snapshot()
	for action in REBINDABLE_GAMEPAD_ACTIONS:
		if config.has_section_key("gamepad", action):
			gamepad_snapshot[action] = [JoyButton(int(config.get_value("gamepad", action, -1)))]
	restore_gamepad_binding_snapshot(gamepad_snapshot, false)

func _save_custom_bindings() -> void:
	var config := ConfigFile.new()
	for action in REBINDABLE_KEYBOARD_ACTIONS:
		var keys := get_keyboard_binding_keys(action)
		if keys != DEFAULT_KEY_BINDINGS.get(action, []):
			config.set_value("keyboard", action, keys[0] if not keys.is_empty() else KEY_NONE)
	for action in REBINDABLE_GAMEPAD_ACTIONS:
		var buttons := get_gamepad_binding_buttons(action)
		if buttons != DEFAULT_GAMEPAD_BUTTON_BINDINGS.get(action, []):
			config.set_value("gamepad", action, buttons[0] if not buttons.is_empty() else -1)
	var result := config.save(BINDINGS_PATH)
	if result != OK:
		push_warning("InputService could not save input_bindings.cfg: %s" % result)

func _erase_keyboard_events(action: String) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)

func _erase_gamepad_button_events(action: String) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			InputMap.action_erase_event(action, event)

func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

func _add_key(action: String, keycode: Key) -> void:
	_ensure_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _add_mouse_button(action: String, button_index: MouseButton) -> void:
	_ensure_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _add_joy_button(action: String, button_index: JoyButton) -> void:
	_ensure_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _add_joy_motion(action: String, axis: JoyAxis, axis_value: float) -> void:
	_ensure_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
