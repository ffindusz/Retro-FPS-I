extends SceneTree
## Debug helper: stats, secrets, and barrel test in level 1.
## - kill/total tallies update (barrels don't count as enemies)
## - secret area triggers once
## - a shot barrel explodes after its fuse and splashes the nearby player
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_stats.gd

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
			print("level 1 totals: enemies=%d secrets=%d (expect 8 2)"
					% [gs.total_enemies, gs.total_secrets])
			world.get_node("Level01/Enemies/Grunt3").take_damage(999.0)
			world.get_node("Level01/Enemies/Spitter2").take_damage(999.0)
			_step = 1
			_wait_until = Time.get_ticks_msec() + 300
		1:
			print("after 2 kills: kills=%d/%d (expect 2/8)" % [gs.kills, gs.total_enemies])
			# Stand in the under-landing secret nook.
			player.global_position = Vector3(17.4, 0.3, -3)
			player.velocity = Vector3.ZERO
			_step = 2
			_wait_until = Time.get_ticks_msec() + 500
		2:
			print("secret entered: found=%d/%d (expect 1/2)"
					% [gs.secrets_found, gs.total_secrets])
			# Stand near a barrel, then shoot it: fuse -> boom -> splash.
			gs.health = 100
			player.global_position = Vector3(5, 0.3, -2)
			player.velocity = Vector3.ZERO
			world.get_node("Level01/Barrels/Barrel1").take_damage(12.0)
			_step = 3
			_wait_until = Time.get_ticks_msec() + 700
		3:
			var barrel := world.get_node_or_null("Level01/Barrels/Barrel1")
			print("barrel shot: gone=%s player health=%d (expect true, <100 from splash)"
					% [barrel == null, gs.health])
			print("stats test done")
			return true
	return false
