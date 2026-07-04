extends SceneTree
## Debug helper: pickup behavior test in level 1's spawn room.
## - Medkit heals a damaged player and disappears
## - A full-health player can NOT collect a medkit (it stays)
## - Shells refuse collection at full ammo, then top up (capped) after firing
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_pickups.gd

var _started := false
var _step := 0
var _wait_until := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game()
		return false
	if Time.get_ticks_msec() < _wait_until:
		return false
	var world := current_scene.get_node("ViewportContainer/GameViewport/World")
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node("GameState")
	match _step:
		0:
			print("pickups in level 1: %d (expect 7)" % get_nodes_in_group("pickups").size())
			# Full health: medkit must refuse collection.
			player.global_position = Vector3(-4.5, 0.3, 19)
			player.velocity = Vector3.ZERO
			_step = 1
			_wait_until = Time.get_ticks_msec() + 600
		1:
			var kit := world.get_node_or_null("Level01/Pickups/HealthA")
			print("full-hp medkit refused: still exists=%s health=%d (expect true 100)"
					% [kit != null, gs.health])
			gs.damage_player(40)
			_step = 2
			_wait_until = Time.get_ticks_msec() + 600
		2:
			var kit := world.get_node_or_null("Level01/Pickups/HealthA")
			print("damaged then healed: health=%d (expect 85), medkit gone=%s (expect true)"
					% [gs.health, kit == null])
			# Shotgun full: shells must refuse collection.
			player.global_position = Vector3(4.7, 0.3, 19.5)
			player.velocity = Vector3.ZERO
			_step = 3
			_wait_until = Time.get_ticks_msec() + 600
		3:
			var shells := world.get_node_or_null("Level01/Pickups/ShellsA")
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			var shotgun: Node3D = wm._weapons[1]
			print("full-ammo shells refused: still exists=%s ammo=%d/%d (expect true 24/24)"
					% [shells != null, shotgun.ammo, shotgun.max_ammo])
			# Step off, fire two shells, come back: +8 should cap at 24.
			player.global_position = Vector3(0, 0.3, 22)
			shotgun.ammo = 22
			player.global_position = Vector3(4.7, 0.3, 19.5)
			player.velocity = Vector3.ZERO
			_step = 4
			_wait_until = Time.get_ticks_msec() + 600
		4:
			var shells := world.get_node_or_null("Level01/Pickups/ShellsA")
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			var shotgun: Node3D = wm._weapons[1]
			print("shells collected: ammo=%d (expect 24 capped), gone=%s (expect true)"
					% [shotgun.ammo, shells == null])
			print("pickup test done")
			return true
	return false
