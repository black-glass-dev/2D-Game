class_name TacticalRadar
extends Control

## A compact top-down radar. World coordinates are transformed into player-local
## coordinates, so the player arrow stays upright while the outpost rotates below.
const RADAR_RANGE := 48.0
const CONTACT_REFRESH := 0.16
const REDRAW_INTERVAL := 1.0 / 30.0
const BUILDINGS := [
	[Vector3(-8.5, 0, -5.5), Vector2(9.0, 9.0)],
	[Vector3(9.0, 0, -8.0), Vector2(8.0, 6.0)],
	[Vector3(11.0, 0, 8.5), Vector2(11.0, 8.0)],
	[Vector3(-35.0, 0, 14.0), Vector2(22.0, 20.0)],
	[Vector3(-33.0, 0, -31.0), Vector2(21.0, 13.0)],
	[Vector3(36.0, 0, -27.0), Vector2(20.0, 15.0)],
	[Vector3(0.0, 0, 35.0), Vector2(30.0, 17.0)]
]
const OBJECTIVES := [Vector3(-8.5, 0, -5.5), Vector3(0.0, 0, 35.0)]

var tracked_player: OutpostPlayer
var contacts: Array[Vector3] = []
var refresh_left := 0.0
var redraw_left := 0.0
var pulse_time := 0.0

func _ready() -> void:
	name = "Tactical radar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func track_player(player_value: OutpostPlayer) -> void:
	tracked_player = player_value

func _process(delta: float) -> void:
	pulse_time += delta
	refresh_left -= delta
	if refresh_left <= 0.0:
		refresh_left = CONTACT_REFRESH
		_refresh_contacts()
	redraw_left -= delta
	if redraw_left <= 0.0:
		redraw_left = REDRAW_INTERVAL
		queue_redraw()

func _refresh_contacts() -> void:
	contacts.clear()
	if tracked_player == null:
		return
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		if raider != null and raider.is_radar_visible(tracked_player.global_position):
			contacts.append(raider.global_position)

func _draw() -> void:
	if tracked_player == null or size.x < 8.0 or size.y < 8.0:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.48
	draw_circle(center + Vector2(0, 3), radius, Color(0.0, 0.02, 0.03, 0.58))
	draw_circle(center, radius, Color(0.025, 0.10, 0.115, 0.70))
	draw_circle(center, radius * .92, Color(0.08, 0.22, 0.22, 0.26))
	var fov := PackedVector2Array([center, center + Vector2(-radius * .62, -radius * .72), center + Vector2(radius * .62, -radius * .72)])
	draw_colored_polygon(fov, Color(0.35, 0.95, 0.84, 0.10))
	draw_arc(center, radius, 0.0, TAU, 48, Color("7de2d1"), 2.4, true)
	draw_arc(center, radius - 3.0, 0.0, TAU, 48, Color("ffcf85"), .8, true)
	draw_arc(center, radius * 0.50, 0.0, TAU, 32, Color(0.68, 0.92, 0.82, 0.21), 1.0, true)
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color(0.68, 0.92, 0.82, 0.15), 1.0)
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color(0.68, 0.92, 0.82, 0.15), 1.0)
	for entry in BUILDINGS:
		_draw_building(entry[0], entry[1], center, radius)
	for objective in OBJECTIVES:
		var objective_point := _world_to_radar(objective, center, radius)
		if objective_point.distance_to(center) < radius - 5.0:
			draw_circle(objective_point, 3.3, Color("e9c76e"))
	var pulse_radius := 4.0 + sin(pulse_time * 4.0) * .8
	for contact in contacts:
		var contact_point := _world_to_radar(contact, center, radius)
		if contact_point.distance_to(center) < radius - 4.0:
			draw_circle(contact_point, pulse_radius, Color(.95, .25, .20, .18))
			draw_circle(contact_point, 3.1, Color("f05d4f"))
	var arrow := PackedVector2Array([center + Vector2(0, -9), center + Vector2(5.8, 6), center + Vector2(0, 3), center + Vector2(-5.8, 6)])
	draw_colored_polygon(arrow, Color("eaf6d8"))
	draw_arc(center, 9.0, 0.0, TAU, 20, Color("ffffff"), 1.2, true)

func _draw_building(world_center: Vector3, half_extents: Vector2, center: Vector2, radius: float) -> void:
	var corners := PackedVector2Array([
		_world_to_radar(world_center + Vector3(-half_extents.x * 0.5, 0, -half_extents.y * 0.5), center, radius),
		_world_to_radar(world_center + Vector3(half_extents.x * 0.5, 0, -half_extents.y * 0.5), center, radius),
		_world_to_radar(world_center + Vector3(half_extents.x * 0.5, 0, half_extents.y * 0.5), center, radius),
		_world_to_radar(world_center + Vector3(-half_extents.x * 0.5, 0, half_extents.y * 0.5), center, radius)
	])
	var building_point := _world_to_radar(world_center, center, radius)
	if building_point.distance_to(center) <= radius - 12.0:
		draw_colored_polygon(corners, Color(0.35, 0.53, 0.47, 0.32))
		draw_polyline(corners, Color(0.62, 0.80, 0.69, 0.50), 1.0, true)

func _world_to_radar(world_position: Vector3, center: Vector2, radius: float) -> Vector2:
	var offset := world_position - tracked_player.global_position
	var right: Vector3 = tracked_player.global_transform.basis.x
	var forward: Vector3 = -tracked_player.global_transform.basis.z
	var local_x := offset.dot(right)
	var local_z := offset.dot(forward)
	return center + Vector2(local_x, -local_z) * (radius / RADAR_RANGE)
