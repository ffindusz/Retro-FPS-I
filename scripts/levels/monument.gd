@tool
extends LevelRoot
## The endgame monument. A stone slab engraved with the best runs, reached by
## the portal beside the treasure in level 7. main banks the finished run
## before loading this, so GameState.runs already includes it.

## Rows the slab has room for; the table itself is capped by
## GameState.RUN_TABLE_SIZE, this just guards the layout.
const MAX_ROWS := 5

@onready var _face: Label3D = $Monolith/Face


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	_face.text = _engraving()


## Best-first table, with the run just finished marked. Matching on score AND
## loop rather than an index because finalize_run() re-sorts, so the run's row
## is wherever it placed.
func _engraving() -> String:
	var lines := PackedStringArray(["THE FALLEN AND THE RICH", ""])
	if GameState.runs.is_empty():
		lines.append("NO RUNS RECORDED")
		return "\n".join(lines)
	var marked := false
	for i in mini(GameState.runs.size(), MAX_ROWS):
		var run: Dictionary = GameState.runs[i]
		var run_score := int(run["score"])
		var run_loop := int(run["loop"])
		# Mark one row only: several runs can tie on both numbers.
		var mine := not marked and run_score == GameState.score \
				and run_loop == GameState.loop
		if mine:
			marked = true
		lines.append("%s %d.  %-7d  LOOP %d" % [
				">" if mine else " ", i + 1, run_score, run_loop])
	lines.append("")
	lines.append("THIS RUN   %d" % GameState.score)
	return "\n".join(lines)
