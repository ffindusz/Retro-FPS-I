extends AnyKeyScreen
## Win/lose screen. Brief input grace period so a panic-click at the moment
## of death doesn't instantly restart.

signal restart_requested

@onready var _result: Label = $Layout/ResultLabel
@onready var _sub: Label = $Layout/SubLabel
@onready var _stats: Label = $Layout/StatsLabel


func set_stats(text: String) -> void:
	_stats.text = text


func set_result(win: bool) -> void:
	_accept_after_ms = Time.get_ticks_msec() + 700
	if win:
		_result.text = "YOU WIN"
		_result.label_settings.font_color = Color(0.95, 0.8, 0.35)
		_sub.text = "THE PILE OF GOLD IS YOURS"
	else:
		_result.text = "YOU DIED"
		_result.label_settings.font_color = Color(0.85, 0.2, 0.15)
		_sub.text = "THE FACILITY CLAIMS ANOTHER"


func _on_confirm() -> void:
	restart_requested.emit()
