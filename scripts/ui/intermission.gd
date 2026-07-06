extends AnyKeyScreen
## Between-level stats screen shown while the tree is paused. Any key or
## click (except Esc) continues to the next level.

signal continue_requested

@onready var _title: Label = $Layout/TitleLabel
@onready var _stats: Label = $Layout/StatsLabel


func show_stats(level_number: int, stats_text: String) -> void:
	_accept_after_ms = Time.get_ticks_msec() + 500
	_title.text = "LEVEL %d CLEAR" % level_number
	_stats.text = stats_text


func _on_confirm() -> void:
	continue_requested.emit()
