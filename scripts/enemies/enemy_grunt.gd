extends EnemyBase
## Melee grunt. Adds a simple run-cycle bob on top of the base FSM.

var _bob_time := 0.0


func _process(delta: float) -> void:
	if state == State.CHASE:
		_bob_time += delta * 10.0
		visual.position.y = absf(sin(_bob_time)) * 0.09
	elif state != State.DEAD:
		visual.position.y = lerpf(visual.position.y, 0.0, minf(delta * 8.0, 1.0))
