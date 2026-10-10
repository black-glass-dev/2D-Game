class_name RaiderTactics
extends RefCounted

## Throttled tactical decision model for a single raider. It stores goals instead
## of building paths or allocating command objects every physics frame.
enum Mode { REACT, APPROACH, STRAFE, FLANK, TAKE_COVER }

const COVER_POINTS := [
	Vector3(-2, 0.15, 5), Vector3(3, 0.15, 7), Vector3(-2, 0.15, 14),
	Vector3(17, 0.15, -1), Vector3(-18, 0.15, 5), Vector3(18, 0.15, 17),
	Vector3(-12, 0.15, 19), Vector3(-39, 0.15, 10), Vector3(-31, 0.15, 19),
	Vector3(-40, 0.15, -19), Vector3(-21, 0.15, -39), Vector3(29, 0.15, -20),
	Vector3(44, 0.15, -34), Vector3(21, 0.15, 36), Vector3(-3, 0.15, 42)
]

var mode := Mode.REACT
var move_goal := Vector3.ZERO
var reaction_left := 0.0
var think_left := 0.0
var strafe_left := 0.0
var cover_left := 0.0
var pressure_left := 0.0
var heard_noise_left := 0.0
var strafe_sign := 1.0
var serial := 0

func setup(index: int) -> void:
	serial = index
	strafe_sign = -1.0 if index % 2 == 0 else 1.0
	reaction_left = 0.26 + float(index % 4) * 0.07
	think_left = 0.08 + float(index % 3) * 0.04

func hear_weapon_fire(origin: Vector3, self_position: Vector3) -> void:
	if origin.distance_squared_to(self_position) > 44.0 * 44.0:
		return
	heard_noise_left = 2.2
	think_left = minf(think_left, 0.06)

func receive_hit() -> void:
	pressure_left = 2.6
	reaction_left = maxf(reaction_left, 0.11)
	think_left = 0.0

func update(delta: float, self_position: Vector3, player_position: Vector3, has_line_of_sight: bool) -> void:
	reaction_left = maxf(reaction_left - delta, 0.0)
	pressure_left = maxf(pressure_left - delta, 0.0)
	heard_noise_left = maxf(heard_noise_left - delta, 0.0)
	strafe_left = maxf(strafe_left - delta, 0.0)
	cover_left = maxf(cover_left - delta, 0.0)
	think_left -= delta
	if reaction_left > 0.0:
		mode = Mode.REACT
		move_goal = self_position
		return
	if think_left > 0.0:
		_update_goal(self_position, player_position)
		return
	think_left = 0.22 + float(serial % 3) * 0.035
	var flat_to_player := player_position - self_position
	flat_to_player.y = 0.0
	var distance := flat_to_player.length()
	if pressure_left > 0.0 and _select_cover(self_position, player_position):
		mode = Mode.TAKE_COVER
		cover_left = 1.5 + float(serial % 3) * 0.22
	elif not has_line_of_sight:
		mode = Mode.FLANK
		if strafe_left <= 0.0:
			strafe_sign *= -1.0
			strafe_left = 1.1 + float(serial % 3) * 0.16
	elif distance > 11.5:
		mode = Mode.APPROACH
	elif cover_left > 0.0 and mode == Mode.TAKE_COVER:
		mode = Mode.TAKE_COVER
	else:
		mode = Mode.STRAFE
		if strafe_left <= 0.0:
			strafe_sign *= -1.0
			strafe_left = 0.85 + float(serial % 3) * 0.14
	_update_goal(self_position, player_position)

func can_attack() -> bool:
	return reaction_left <= 0.0 and mode != Mode.REACT and mode != Mode.TAKE_COVER

func speed_multiplier() -> float:
	if mode == Mode.FLANK:
		return 1.12
	if mode == Mode.TAKE_COVER:
		return 1.04
	if mode == Mode.STRAFE:
		return 0.86
	return 1.0

func _update_goal(self_position: Vector3, player_position: Vector3) -> void:
	var flat_to_player := player_position - self_position
	flat_to_player.y = 0.0
	if flat_to_player.length_squared() < 0.01:
		move_goal = self_position
		return
	var toward_player := flat_to_player.normalized()
	var lateral := Vector3(-toward_player.z, 0.0, toward_player.x) * strafe_sign
	if mode == Mode.APPROACH:
		move_goal = player_position - toward_player * 7.5
	elif mode == Mode.STRAFE:
		move_goal = self_position + lateral * 3.4
	elif mode == Mode.FLANK:
		move_goal = player_position + lateral * 6.0 - toward_player * 3.5
	elif mode == Mode.TAKE_COVER:
		# keep the previously chosen cover point
		move_goal.y = self_position.y

func _select_cover(self_position: Vector3, player_position: Vector3) -> bool:
	var best_score := INF
	var found := false
	for point in COVER_POINTS:
		var self_distance := self_position.distance_to(point)
		var player_distance := player_position.distance_to(point)
		if self_distance < 1.2 or self_distance > 28.0 or player_distance < 5.0:
			continue
		var score := self_distance + absf(player_distance - 13.0) * 0.22
		if score < best_score:
			best_score = score
			move_goal = point
			found = true
	return found
