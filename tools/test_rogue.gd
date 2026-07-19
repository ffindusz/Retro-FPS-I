extends "res://tools/test_base.gd"
## Debug helper: headless rogue AI test in the dungeon (level 5). Places the
## player across the great hall from Rogue1, watches it wake and cloak while
## chasing (mesh transparency up), verifies damage rips the cloak away, that
## it decloaks inside strike range and stabs (player health drops), then
## kills it. Afterwards blasts the rubble blockade sealing the secret nook
## and confirms the freed passage lets the secret trigger.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_rogue.gd

var _placed := false
var _start_ms := 0
var _saw_cloaked := false
var _hit_done := false
var _killed := false
var _blasted := false
var _entered_nook := false


func _boot_level_index() -> int:
	return 4  # dungeon is level 5


func _mesh_transparency(rogue: Node) -> float:
	var mesh: GeometryInstance3D = rogue.get_node("Visual").find_child(
			"Skeleton_Rogue_Body", true, false)
	return mesh.transparency if mesh != null else -1.0


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node("Player")
	var rogue: CharacterBody3D = world.get_node_or_null("Level05/Enemies/Rogue1")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	if not _placed:
		_placed = true
		_start_ms = Time.get_ticks_msec()
		# Effectively invincible: only the "health dropped" delta matters.
		gs.health = 100000
		# Far side of the hall: ~12m from Rogue1 at (0, 0.1, -4), within
		# notice range 15 but well outside decloak range 4.
		player.global_position = Vector3(0, 0.1, 8)
		player.velocity = Vector3.ZERO
		print("t=0.0s rogue state=%d cloaked=%s (expect 0 false)"
				% [rogue.state, rogue.cloaked])
		# Clear the rest of the level so grunts/spitters can't pile onto the
		# player and muddy the rogue-only assertions (their death rattles
		# wake the rogue early, which is harmless).
		for e in get_nodes_in_group("enemies"):
			if e != rogue:
				e.take_damage(99999.0)
		return false
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	# The rogue closes 12m fast; sample every frame so the cloaked window
	# (before it reaches decloak range) can't be missed between steps.
	if rogue != null and rogue.cloaked and not _saw_cloaked:
		_saw_cloaked = true
		print("t=%.1fs rogue cloaked while chasing: transparency=%.2f (expect 0.94)"
				% [t, _mesh_transparency(rogue)])
		# Freeze it in place (well outside decloak range) so the hit-reveal
		# check below isn't raced by its approach.
		rogue.move_speed = 0.0
		rogue.take_damage(5.0)
		print("after hit: cloaked=%s transparency=%.2f (expect false 0.00)"
				% [rogue.cloaked, _mesh_transparency(rogue)])
	if t > 4.0 and not _hit_done and _saw_cloaked:
		_hit_done = true
		print("t=%.1fs after reveal_time: cloaked=%s (expect true, recloaked)"
				% [t, rogue.cloaked])
		# Release it to close in: inside decloak_range it must drop the
		# cloak and start stabbing.
		rogue.move_speed = 5.2
	if t > 7.0 and not _killed:
		_killed = true
		print("t=%.1fs rogue state=%d cloaked=%s (expect 3 ATTACK, false) "
				% [t, rogue.state, rogue.cloaked]
				+ "player health=%d (expect <100000 from stabs)" % gs.health)
		rogue.take_damage(999.0)
		print("after kill: state=%d cloaked=%s (expect 4 DEAD, false)"
				% [rogue.state, rogue.cloaked])
	if t > 9.5 and not _blasted:
		_blasted = true
		print("rogue freed after death: %s (expect true)" % str(not is_instance_valid(rogue)))
		var rubble: Node = world.get_node("Level05/Props/RubbleBlockade")
		rubble.take_damage(30.0)
		print("rubble after 30 dmg: alive=%s (expect true, takes 60)"
				% str(is_instance_valid(rubble) and not rubble.is_queued_for_deletion()))
		rubble.take_damage(999.0)
	if t > 10.3 and not _entered_nook:
		_entered_nook = true
		var rubble: Node = world.get_node_or_null("Level05/Props/RubbleBlockade")
		print("rubble after blast: freed=%s (expect true)" % str(rubble == null))
		# Walk into the opened nook; the secret area should trigger.
		player.global_position = Vector3(-25.5, 0.1, 4)
		player.velocity = Vector3.ZERO
	if t > 11.3:
		print("secret behind rubble found: %d/%d (expect 1/2)"
				% [gs.secrets_found, gs.total_secrets])
		print("rogue test done")
		return true
	return false
