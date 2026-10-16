extends Node

## Adds named actions without removing legacy direct-input behaviour. Player and
## menu migration can therefore move action-by-action while existing touch and
## keyboard paths continue to work.
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

func _ready() -> void:
	_register_defaults()

func _register_defaults() -> void:
	_add_key(ACTION_MOVE_FORWARD, KEY_W)
	_add_key(ACTION_MOVE_FORWARD, KEY_UP)
	_add_key(ACTION_MOVE_BACK, KEY_S)
	_add_key(ACTION_MOVE_BACK, KEY_DOWN)
	_add_key(ACTION_MOVE_LEFT, KEY_A)
	_add_key(ACTION_MOVE_LEFT, KEY_LEFT)
	_add_key(ACTION_MOVE_RIGHT, KEY_D)
	_add_key(ACTION_MOVE_RIGHT, KEY_RIGHT)
	_add_key(ACTION_JUMP, KEY_SPACE)
	_add_key(ACTION_CROUCH, KEY_C)
	_add_key(ACTION_SWAP, KEY_Q)
	_add_key(ACTION_RELOAD, KEY_R)
	_add_key(ACTION_PAUSE, KEY_ESCAPE)
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
	_add_joy_button(ACTION_JUMP, JOY_BUTTON_A)
	_add_joy_button(ACTION_CROUCH, JOY_BUTTON_RIGHT_STICK)
	_add_joy_button(ACTION_RELOAD, JOY_BUTTON_X)
	_add_joy_button(ACTION_SWAP, JOY_BUTTON_Y)
	_add_joy_button(ACTION_PAUSE, JOY_BUTTON_START)
	_add_joy_button(ACTION_FIRE, JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button(ACTION_AIM, JOY_BUTTON_LEFT_SHOULDER)
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
