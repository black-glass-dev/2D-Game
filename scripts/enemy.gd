class_name Raider
extends CharacterBody3D

signal eliminated(raider: Raider, score_value: int)

const MAX_HEALTH := 100
const MOVE_SPEED := 2.35
const MOVE_ACCELERATION := 9.5
const MOVE_DECELERATION := 13.0
const ATTACK_RANGE := 14.0
const ATTACK_COOLDOWN := 1.65
const SIGHT_CHECK_INTERVAL := 0.22
const GRAVITY := 18.0
const RADAR_NEAR_RANGE := 22.0

# Genuine low-poly human character rigs from KayKit's CC0 library. Their
# provenance is retained in assets/third_party/kaykit_cc0/README.md. The source
# accessories are hidden below; only the human mesh and authored movement clips
# are used as the base for the game's original circa-2000 tactical kit.
const KAYKIT_SMUGGLER_SCENES := [
	preload("res://assets/third_party/kaykit_cc0/characters/Rogue.glb"),
	preload("res://assets/third_party/kaykit_cc0/characters/Rogue_Hooded.glb"),
]
const KENNEY_MACHINEGUN_SCENE := preload("res://assets/third_party/kenney_cc0/weapons/machinegun.glb")

var health := MAX_HEALTH
var attack_timer := 1.0
var sight_timer := 0.0
var radar_reveal_left := 0.0
var active := true
var body_visual: Node3D
var hit_light: OmniLight3D
var head_hitbox: Area3D
var tactics := RaiderTactics.new()
var line_of_sight := false
var attack_serial := 0
var walk_phase := 0.0
var spawn_index := 0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var weapon_root: Node3D
var weapon_flash: MeshInstance3D
var weapon_muzzle_light: OmniLight3D
var tactical_label: Label3D
var footstep_dust: GPUParticles3D
var muzzle_flash_left := 0.0
var hit_react := 0.0
var reload_motion := 0.0
var imported_smuggler: Node3D
var imported_animator: AnimationPlayer
var imported_animation := ""

func setup(index: int) -> void:
	spawn_index = index
	tactics.setup(index)

func _ready() -> void:
	name = "Raider_%02d" % spawn_index
	add_to_group("raiders")
	collision_layer = 4
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.75
	collider.shape = shape
	collider.position.y = 0.87
	add_child(collider)
	_build_headshot_hitbox()
	_build_model()

func _physics_process(delta: float) -> void:
	if not active:
		return
	radar_reveal_left = maxf(radar_reveal_left - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as OutpostPlayer
	if player == null or not player.can_control:
		_update_visual_motion(delta)
		return
	var player_target := player.global_position + Vector3(0, 0.75, 0)
	var flat_player_offset := player_target - global_position
	flat_player_offset.y = 0.0
	var player_distance := flat_player_offset.length()
	sight_timer -= delta
	if sight_timer <= 0.0:
		sight_timer = SIGHT_CHECK_INTERVAL + float(spawn_index % 3) * 0.03
		line_of_sight = _has_line_of_sight(player)
	tactics.update(delta, global_position, player.global_position, line_of_sight)
	_move_to_goal(tactics.move_goal, delta)
	_update_visual_motion(delta)
	_update_detail_lod(player_distance)

	attack_timer -= delta
	if player_distance <= ATTACK_RANGE and line_of_sight and tactics.can_attack() and attack_timer <= 0.0:
		attack_timer = ATTACK_COOLDOWN + float(spawn_index % 3) * 0.12
		radar_reveal_left = 1.9
		_attempt_attack(player, player_distance)

func hear_weapon_fire(origin: Vector3) -> void:
	if active:
		tactics.hear_weapon_fire(origin, global_position)

func take_damage(amount: int, was_headshot := false) -> bool:
	if not active:
		return false
	health -= amount
	radar_reveal_left = 2.4
	tactics.receive_hit()
	hit_react = 1.0
	_update_nameplate()
	_flash_body(Color("fff2c4") if not was_headshot else Color("ffdb78"))
	if health > 0:
		return false
	active = false
	collision_layer = 0
	if head_hitbox != null:
		head_hitbox.collision_layer = 0
	velocity = Vector3.ZERO
	if tactical_label != null:
		tactical_label.visible = false
	eliminated.emit(self, 100)
	var tween := create_tween()
	tween.tween_property(body_visual, "rotation:z", deg_to_rad(84 if spawn_index % 2 == 0 else -84), 0.22)
	tween.parallel().tween_property(body_visual, "position:y", -0.48, 0.22)
	tween.tween_interval(2.3)
	tween.tween_callback(queue_free)
	return true

func is_radar_visible(observer_position: Vector3) -> bool:
	if not active:
		return false
	var horizontal_delta := observer_position - global_position
	horizontal_delta.y = 0.0
	return horizontal_delta.length_squared() <= RADAR_NEAR_RANGE * RADAR_NEAR_RANGE or radar_reveal_left > 0.0

func _move_to_goal(goal: Vector3, delta: float) -> void:
	var flat_goal := goal - global_position
	flat_goal.y = 0.0
	var distance := flat_goal.length()
	var target_velocity := Vector3.ZERO
	if distance > 0.65:
		var direction := flat_goal / distance
		var speed := MOVE_SPEED * tactics.speed_multiplier()
		target_velocity = direction * speed
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-delta * 8.5))
	var rate := MOVE_ACCELERATION if distance > 0.65 else MOVE_DECELERATION
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	move_and_slide()

func _attempt_attack(player: OutpostPlayer, distance: float) -> void:
	attack_serial += 1
	reload_motion = 1.0 if attack_serial % 7 == 0 else reload_motion
	_trigger_weapon_flash()
	var range_factor := clampf(1.0 - distance / ATTACK_RANGE, 0.0, 1.0)
	var hit_chance := lerpf(0.36, 0.68, range_factor)
	var roll := fposmod(sin(float(spawn_index * 97 + attack_serial * 31)) * 43758.5453, 1.0)
	_flash_body(Color("ffb55e"))
	if roll <= hit_chance:
		player.take_damage(3 + (spawn_index % 3), global_position)

func _update_visual_motion(delta: float) -> void:
	if body_visual == null or not active:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	if imported_smuggler != null:
		# Use the CC0 rig's own two-handed ranged and walk clips. They provide a
		# believable human weapon stance without a separate robot-like limb rig.
		if muzzle_flash_left > 0.0:
			_set_imported_animation("2H_Ranged_Shooting")
		elif speed > .38:
			_set_imported_animation("Walking_A")
		else:
			_set_imported_animation("2H_Ranged_Aiming")
	walk_phase += delta * (3.2 + speed * 3.8)
	hit_react = maxf(hit_react - delta * 7.0, 0.0)
	reload_motion = maxf(reload_motion - delta * 1.8, 0.0)
	muzzle_flash_left = maxf(muzzle_flash_left - delta, 0.0)
	var gait := sin(walk_phase) * minf(speed * 0.56, 0.52)
	var bob := sin(walk_phase * 2.0) * minf(speed * 0.018, 0.045)
	body_visual.position.y = lerpf(body_visual.position.y, bob, 1.0 - exp(-delta * 10.0))
	body_visual.rotation.x = lerpf(body_visual.rotation.x, sin(walk_phase * .5) * minf(speed * .035, .08) - hit_react * .09, 1.0 - exp(-delta * 8.0))
	if left_leg != null:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, gait, 1.0 - exp(-delta * 13.0))
	if right_leg != null:
		right_leg.rotation.x = lerpf(right_leg.rotation.x, -gait, 1.0 - exp(-delta * 13.0))
	# The arm roots begin at the shoulders. A proper shouldered-carbine pose must
	# rotate them decisively forward rather than leaving the old mannequin-like
	# vertical silhouette. The compact procedural rig still blends walk, hit and
	# reload movement without a per-Raider AnimationPlayer allocation.
	# Godot's +X rotation takes a downward local limb toward camera-facing -Z.
	# Keeping this positive puts the carbine and both hands in front of the vest.
	var aim_pose := 1.12 + sin(walk_phase) * minf(speed * .08, .06) + hit_react * .22
	if left_arm != null:
		left_arm.rotation.x = lerpf(left_arm.rotation.x, aim_pose + gait * .35 + reload_motion * .72, 1.0 - exp(-delta * 15.0))
	if right_arm != null:
		right_arm.rotation.x = lerpf(right_arm.rotation.x, aim_pose - gait * .35 - reload_motion * .25, 1.0 - exp(-delta * 15.0))
	if weapon_root != null:
		weapon_root.position.y = .94 + sin(walk_phase) * minf(speed * .012, .018)
		weapon_root.rotation.x = reload_motion * .38
	if weapon_flash != null:
		weapon_flash.visible = muzzle_flash_left > 0.0
	if weapon_muzzle_light != null:
		weapon_muzzle_light.light_energy = 1.8 if muzzle_flash_left > 0.0 else 0.0
	if footstep_dust != null:
		footstep_dust.emitting = speed > 0.75

func _update_detail_lod(distance: float) -> void:
	if tactical_label != null:
		var player := get_tree().get_first_node_in_group("player") as OutpostPlayer
		# A floating health name should not cross the optic reticle. It returns as
		# soon as ADS releases and remains available for normal hip-fire targeting.
		var hide_for_ads := player != null and player.is_aiming
		tactical_label.visible = distance < 30.0 and active and not hide_for_ads
	if weapon_flash != null and distance > 28.0:
		weapon_flash.visible = false

func _has_line_of_sight(player: OutpostPlayer) -> bool:
	var eye := global_position + Vector3(0, 1.35, 0)
	var aim_point := player.global_position + Vector3(0, 1.2, 0)
	var query := PhysicsRayQueryParameters3D.create(eye, aim_point, 3)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == player

func _build_headshot_hitbox() -> void:
	head_hitbox = Area3D.new()
	head_hitbox.name = "Headshot hitbox"
	head_hitbox.collision_layer = 8
	head_hitbox.collision_mask = 0
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	shape_node.shape = shape
	shape_node.position = Vector3(0, 1.38, 0)
	head_hitbox.add_child(shape_node)
	add_child(head_hitbox)

func _build_model() -> void:
	body_visual = Node3D.new()
	body_visual.name = "Articulated tactical raider"
	add_child(body_visual)
	hit_light = OmniLight3D.new()
	hit_light.name = "Raider hit flash"
	hit_light.position = Vector3(0, 1.25, 0)
	hit_light.omni_range = 3.2
	hit_light.light_energy = 0.0
	body_visual.add_child(hit_light)
	var variant := spawn_index % 3
	# Dark tactical values maintain a readable Raider silhouette against the
	# sunlit sand. Each variation retains the same restrained hostile-red accent,
	# so gameplay readability survives dust and fog without a glowing outline.
	var uniform := _mat([Color("283a38"), Color("34433c"), Color("423a35")][variant], .82, .0)
	var vest := _mat(Color("111d20"), .58, .22)
	var accent := _mat([Color("a4342d"), Color("c14431"), Color("802d30")][variant], .68, .05)
	var face_wrap := _mat([Color("2c2927"), Color("27312e"), Color("382923")][variant], .94, .0)
	# Preserve a distinct, human face on the CC0 base rather than flattening the
	# complete model into one uniform colour. The scarf/helmet layers below keep
	# the figure tactically anonymous without turning it into a sci-fi robot.
	var head_skin := _mat([Color("8b5f45"), Color("76503b"), Color("9a6848")][variant], .91, .0)
	var black := _mat(Color("0b1215"), .50, .58)
	# The imported KayKit CC0 rig provides a readable human silhouette, proportions
	# and authored movement clips. Its medieval accessories are disabled and every
	# visible material is replaced by grounded field clothing, a plate carrier,
	# helmet and conventional carbine so it reads as a circa-2000 armed smuggler.
	if _build_imported_smuggler(uniform, vest, head_skin, face_wrap, black, accent):
		_build_weapon(black, accent)
		_build_footstep_dust()
		_build_nameplate()
		return
	# Conservative fallback for an interrupted/missing asset import. It remains
	# a conventional, non-scifi combatant and preserves gameplay if a developer
	# intentionally removes the optional CC0 asset directory.
	var visor := _mat(Color("263b3a"), .20, .55, Color.TRANSPARENT, .0)
	var plate_edge := _mat(Color("486560"), .50, .34)
	_part_capsule("Tactical uniform torso", Vector3(0, 1.20, 0), .29, .72, uniform)
	_part_box("Plate carrier", Vector3(0, 1.20, -.238), Vector3(.54, .50, .09), vest)
	_part_box("Carrier upper plate", Vector3(0, 1.38, -.292), Vector3(.38, .13, .035), plate_edge)
	_part_box("Carrier lower plate", Vector3(0, 1.04, -.292), Vector3(.40, .10, .035), plate_edge)
	for pouch_x in [-.17, 0.0, .17]:
		_part_box("Front magazine pouch", Vector3(pouch_x, 1.13, -.305), Vector3(.13, .20, .07), black)
	_part_box("Faction red shoulder", Vector3(.34, 1.46, 0), Vector3(.13, .19, .28), accent)
	_part_box("Faction red armband", Vector3(-.35, 1.34, -.015), Vector3(.14, .10, .27), accent)
	# A compact head stack avoids a floating helmet silhouette at close range:
	# neck → balaclava → low-profile helmet shell → front visor/mask. A shallow
	# hard shell reads better than a large spherical dome on the mobile camera.
	_part_sphere("Balaclava head", Vector3(0, 1.78, 0), .17, face_wrap)
	_part_box("Armoured helmet shell", Vector3(0, 1.915, .018), Vector3(.38, .19, .32), vest)
	_part_box("Helmet crown", Vector3(0, 2.025, .018), Vector3(.32, .045, .27), black)
	_part_box("Ballistic visor", Vector3(0, 1.83, -.194), Vector3(.30, .10, .045), visor)
	_part_box("Breather mask", Vector3(0, 1.70, -.185), Vector3(.24, .115, .08), black)
	_part_box("Back radio", Vector3(0, 1.24, .19), Vector3(.24, .33, .10), black)
	_part_box("Utility belt", Vector3(0, .94, -.01), Vector3(.48, .10, .27), black)
	left_arm = _limb("Left arm", Vector3(-.34, 1.45, 0), uniform, black)
	right_arm = _limb("Right arm", Vector3(.34, 1.45, 0), uniform, black)
	left_leg = _leg("Left leg", Vector3(-.16, .86, 0), uniform, black)
	right_leg = _leg("Right leg", Vector3(.16, .86, 0), uniform, black)
	_build_weapon(black, accent)
	_build_footstep_dust()
	_build_nameplate()

func _build_imported_smuggler(uniform: Material, vest: Material, head_skin: Material, face_wrap: Material, black: Material, accent: Material) -> bool:
	var source_index := spawn_index % KAYKIT_SMUGGLER_SCENES.size()
	var source_scene := KAYKIT_SMUGGLER_SCENES[source_index] as PackedScene
	var scene_visual := source_scene.instantiate() as Node3D if source_scene != null else null
	if scene_visual == null:
		return false
	imported_smuggler = scene_visual
	imported_smuggler.name = "KayKit CC0 field-clothed smuggler"
	# KayKit's rig is a 2.18 m source character. A 0.80 scale matches the 1.75 m
	# gameplay capsule and headshot position while preserving natural adult human
	# proportions instead of the previous rectangular block-character silhouette.
	imported_smuggler.scale = Vector3.ONE * 0.80
	body_visual.add_child(imported_smuggler)
	_apply_imported_character_materials(imported_smuggler, uniform, head_skin)
	_hide_imported_medieval_accessories(imported_smuggler)
	imported_animator = _find_animation_player(imported_smuggler)
	_set_imported_animation("2H_Ranged_Aiming")
	_build_imported_tactical_overlays(vest, face_wrap, black, accent)
	return true

func _hide_imported_medieval_accessories(node: Node) -> void:
	# The KayKit human rigs ship with medieval knives, crossbows, throwable props,
	# a cape and a deliberately exaggerated adventurer head. Hide those source
	# elements — never repurpose them — while retaining the fully rigged arms,
	# legs and body for natural movement. A restrained original helmeted head is
	# added below to keep the 2000-era combat silhouette proportionate.
	var part_name := str(node.name).to_lower()
	if "knife" in part_name or "crossbow" in part_name or "throwable" in part_name or "cape" in part_name or part_name == "rogue_head":
		_set_imported_mesh_visibility(node, false)
		return
	for child in node.get_children():
		_hide_imported_medieval_accessories(child)

func _set_imported_mesh_visibility(node: Node, is_visible: bool) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).visible = is_visible
	for child in node.get_children():
		_set_imported_mesh_visibility(child, is_visible)

func _build_imported_tactical_overlays(vest: Material, face_wrap: Material, black: Material, accent: Material) -> void:
	# These grounded equipment layers sit on the scaled CC0 person rather than
	# replacing it. The KayKit bind pose keeps the legs below .43 and torso at
	# .30–1.00. Its stylised source head is intentionally hidden; the compact
	# covered head below restores a credible field-combat proportion.
	var plate_edge := _mat(Color("4e5e50"), .56, .22)
	var visor := _mat(Color("253a35"), .25, .30, Color.TRANSPARENT, .0)
	_part_box("Smuggler plate carrier", Vector3(0, .88, -.250), Vector3(.48, .36, .08), vest)
	_part_box("Carrier upper plate", Vector3(0, .995, -.302), Vector3(.34, .09, .032), plate_edge)
	_part_box("Carrier lower plate", Vector3(0, .765, -.302), Vector3(.36, .075, .032), plate_edge)
	for pouch_x in [-.15, 0.0, .15]:
		_part_box("Front magazine pouch", Vector3(pouch_x, .86, -.315), Vector3(.115, .15, .065), black)
	_part_box("Faction red shoulder", Vector3(.31, .96, 0), Vector3(.11, .14, .24), accent)
	_part_box("Raider faction armband", Vector3(-.31, .88, -.01), Vector3(.125, .085, .24), accent)
	_part_sphere("Raider balaclava head", Vector3(0, 1.32, 0), .22, face_wrap)
	_part_box("Desert patrol helmet", Vector3(0, 1.48, .018), Vector3(.48, .14, .38), vest)
	_part_box("Helmet crown", Vector3(0, 1.56, .018), Vector3(.40, .035, .30), black)
	_part_box("Breather mask", Vector3(0, 1.25, -.235), Vector3(.29, .11, .055), black)
	_part_box("Ballistic visor", Vector3(0, 1.39, -.255), Vector3(.34, .065, .025), visor)
	_part_box("Back radio", Vector3(0, .89, .19), Vector3(.21, .25, .09), black)
	_part_box("Utility belt", Vector3(0, .63, -.01), Vector3(.43, .075, .24), black)
	# The external rig keeps its own animated human arms. Do not layer the old
	# primitive arms over them; that was the source of the floating shoulder-ball
	# look in close-range captures.
	left_arm = null
	right_arm = null
	_part_box("Left combat boot", Vector3(-.14, .18, -.070), Vector3(.15, .13, .27), black)
	_part_box("Right combat boot", Vector3(.14, .18, -.070), Vector3(.15, .13, .27), black)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _set_imported_animation(short_name: String) -> void:
	if imported_animator == null:
		return
	var animation_name := ""
	for candidate in imported_animator.get_animation_list():
		if candidate == short_name or candidate.ends_with("/" + short_name):
			animation_name = candidate
			break
	if animation_name.is_empty() or imported_animation == animation_name:
		return
	imported_animator.play(animation_name, .12)
	imported_animation = animation_name

func _apply_imported_character_materials(node: Node, uniform: Material, head_skin: Material) -> void:
	# KayKit's CC0 rig keeps the human head/body/arm/leg meshes semantically
	# separate. Preserve a visible face and olive field clothing rather than
	# flattening the character into the old featureless rectangular silhouette.
	if node is MeshInstance3D:
		var part_name := str(node.name).to_lower()
		var material := uniform
		if "head" in part_name:
			material = head_skin
		elif "leg" in part_name or "arm" in part_name:
			material = uniform
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_imported_character_materials(child, uniform, head_skin)

func _apply_imported_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_imported_material(child, material)

func _limb(limb_name: String, local_position: Vector3, uniform: Material, glove: Material) -> Node3D:
	var limb := Node3D.new()
	limb.name = limb_name
	limb.position = local_position
	body_visual.add_child(limb)
	_part_capsule_on(limb, "Uniform upper arm", Vector3(0, -.18, -.015), .09, .36, uniform)
	_part_sphere_on(limb, "Elbow pad", Vector3(0, -.34, -.04), .098, glove)
	_part_capsule_on(limb, "Gloved forearm", Vector3(0, -.43, -.07), .075, .32, glove)
	_part_sphere_on(limb, "Articulated gloved hand", Vector3(0, -.60, -.14), .10, glove)
	return limb

func _leg(limb_name: String, local_position: Vector3, uniform: Material, boot: Material) -> Node3D:
	var limb := Node3D.new()
	limb.name = limb_name
	limb.position = local_position
	body_visual.add_child(limb)
	_part_capsule_on(limb, "Trouser leg", Vector3(0, -.25, 0), .115, .52, uniform)
	_part_sphere_on(limb, "Armoured knee pad", Vector3(0, -.40, -.095), .11, boot)
	_part_box_on(limb, "Combat boot", Vector3(0, -.57, -.075), Vector3(.17, .15, .30), boot)
	return limb

func _build_weapon(black: Material, accent: Material) -> void:
	weapon_root = Node3D.new()
	weapon_root.name = "Raider shouldered carbine"
	weapon_root.position = Vector3(0, .94, -.31)
	weapon_root.rotation_degrees = Vector3(-8, 0, 0)
	body_visual.add_child(weapon_root)
	if imported_smuggler != null:
		var imported_carbine := KENNEY_MACHINEGUN_SCENE.instantiate() as Node3D
		if imported_carbine != null:
			imported_carbine.name = "Kenney CC0 conventional carbine"
			# Kenney's machinegun model is a compact real-world-style service weapon
			# pointing along local -Z, matching the existing muzzle/effects contract.
			imported_carbine.position = Vector3(-.075, -.045, -.13)
			imported_carbine.scale = Vector3(1.12, 1.12, 1.12)
			_apply_imported_material(imported_carbine, black)
			weapon_root.add_child(imported_carbine)
	else:
		_part_box_on(weapon_root, "Carbine stock", Vector3(0, -.01, .24), Vector3(.11, .10, .22), black)
		_part_box_on(weapon_root, "Carbine receiver", Vector3(0, 0, 0), Vector3(.12, .12, .38), black)
		_part_box_on(weapon_root, "Carbine red handguard", Vector3(0, 0, -.28), Vector3(.10, .095, .28), accent)
		_part_box_on(weapon_root, "Carbine top rail", Vector3(0, .08, -.12), Vector3(.045, .025, .48), black)
		_part_box_on(weapon_root, "Carbine sight", Vector3(0, .13, -.12), Vector3(.08, .08, .11), black)
		_part_box_on(weapon_root, "Carbine magazine", Vector3(0, -.14, .04), Vector3(.085, .22, .12), black)
		_part_box_on(weapon_root, "Carbine barrel", Vector3(0, .005, -.53), Vector3(.055, .055, .28), black)
	weapon_flash = MeshInstance3D.new()
	weapon_flash.name = "Raider muzzle flash"
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = .045
	flash_mesh.height = .09
	weapon_flash.mesh = flash_mesh
	weapon_flash.position = Vector3(0, 0, -.53)
	weapon_flash.material_override = _mat(Color("fff0b0"), .2, .0, Color("ff8d28"), 4.5)
	weapon_flash.visible = false
	weapon_root.add_child(weapon_flash)
	weapon_muzzle_light = OmniLight3D.new()
	weapon_muzzle_light.name = "Raider pooled muzzle light"
	weapon_muzzle_light.light_color = Color("ff9d42")
	weapon_muzzle_light.light_energy = 0.0
	weapon_muzzle_light.omni_range = 2.0
	weapon_muzzle_light.position = Vector3(0, 0, -.48)
	weapon_root.add_child(weapon_muzzle_light)

func _build_footstep_dust() -> void:
	footstep_dust = GPUParticles3D.new()
	footstep_dust.name = "Raider footstep dust"
	footstep_dust.position = Vector3(0, .06, 0)
	footstep_dust.amount = 8
	footstep_dust.lifetime = .52
	footstep_dust.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	var dust_mesh := QuadMesh.new()
	dust_mesh.size = Vector2(.18, .18)
	var dust_material := StandardMaterial3D.new()
	dust_material.albedo_color = Color(.80, .43, .26, .40)
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_mesh.material = dust_material
	footstep_dust.draw_pass_1 = dust_mesh
	var dust_process := ParticleProcessMaterial.new()
	dust_process.direction = Vector3(0, .8, 0)
	dust_process.spread = 65.0
	dust_process.initial_velocity_min = .18
	dust_process.initial_velocity_max = .38
	dust_process.gravity = Vector3(0, -.08, 0)
	footstep_dust.process_material = dust_process
	footstep_dust.emitting = false
	body_visual.add_child(footstep_dust)

func _build_nameplate() -> void:
	tactical_label = Label3D.new()
	tactical_label.name = "Raider tactical nameplate"
	tactical_label.position = Vector3(0, 1.88, 0)
	tactical_label.pixel_size = .0045
	tactical_label.font_size = 34
	tactical_label.outline_size = 6
	tactical_label.modulate = Color("ffe2b7")
	tactical_label.outline_modulate = Color("251c1e")
	tactical_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	body_visual.add_child(tactical_label)
	_update_nameplate()

func _update_nameplate() -> void:
	if tactical_label != null:
		tactical_label.text = "RAIDER  %03d%%" % maxi(0, health)

func _trigger_weapon_flash() -> void:
	# Reuse the character's own light/flash instead of allocating a node per shot.
	muzzle_flash_left = .08

func _part_box(part_name: String, local_position: Vector3, size: Vector3, material: Material) -> void:
	_part_box_on(body_visual, part_name, local_position, size, material)

func _part_box_on(parent: Node3D, part_name: String, local_position: Vector3, size: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = material
	part.position = local_position
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(part)

func _part_capsule(part_name: String, local_position: Vector3, radius: float, height: float, material: Material) -> void:
	_part_capsule_on(body_visual, part_name, local_position, radius, height, material)

func _part_capsule_on(parent: Node3D, part_name: String, local_position: Vector3, radius: float, height: float, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	part.mesh = mesh
	part.material_override = material
	part.position = local_position
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(part)

func _part_sphere(part_name: String, local_position: Vector3, radius: float, material: Material) -> void:
	_part_sphere_on(body_visual, part_name, local_position, radius, material)

func _part_sphere_on(parent: Node3D, part_name: String, local_position: Vector3, radius: float, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	part.mesh = mesh
	part.material_override = material
	part.position = local_position
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(part)

func _flash_body(color: Color) -> void:
	if hit_light == null:
		return
	hit_light.light_color = color
	hit_light.light_energy = 2.4
	var tween := create_tween()
	tween.tween_property(hit_light, "light_energy", 0.0, 0.1)

func _mat(color: Color, roughness: float, metallic := 0.0, emission := Color.TRANSPARENT, energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
