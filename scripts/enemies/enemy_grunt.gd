extends EnemyBase
## Melee grunt. Adds a simple run-cycle bob on top of the base FSM.

const BOB_SPEED := 10.0  ## Radians/sec advanced while chasing.
const BOB_HEIGHT := 0.09
const BOB_SETTLE_RATE := 8.0  ## Lerp rate back to neutral when not chasing.

var _bob_time := 0.0


func _process(delta: float) -> void:
	if state == State.CHASE:
		_bob_time += delta * BOB_SPEED
		visual.position.y = absf(sin(_bob_time)) * BOB_HEIGHT
	elif state != State.DEAD:
		visual.position.y = lerpf(visual.position.y, 0.0, minf(delta * BOB_SETTLE_RATE, 1.0))
