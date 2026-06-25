extends SceneTree

const StarSoulBPView := preload("res://scripts/views/star_soul_bp_view.gd")
const StarSoulBPScreenService := preload("res://scripts/services/star_soul_bp_screen_service.gd")

var failed := false


func _init() -> void:
	var service = StarSoulBPScreenService.new()
	var model: Dictionary = service.initial_model(1, 1)
	var view = StarSoulBPView.new()
	root.add_child(view)
	view.set_model(model, "zh")
	_require(view.visible, "BP view should be visible after receiving a model.")
	var turn_label = view.find_child("TurnStatus", true, false)
	_require(turn_label is Label and String(turn_label.text).contains("P1"), "Turn label should name the current player.")
	var soul_button = view.find_child("Soul_defense_tower_a", true, false)
	_require(soul_button is Button and not soul_button.disabled, "Available Star Soul should have an enabled button.")
	var selected := {"player": 0, "id": ""}
	view.star_soul_selected.connect(func(player: int, star_soul_id: String) -> void:
		selected["player"] = player
		selected["id"] = star_soul_id
	)
	soul_button.emit_signal("pressed")
	_require(int(selected.get("player", 0)) == 1, "Pool selection should emit the current player.")
	_require(String(selected.get("id", "")) == "defense_tower_a", "Pool selection should emit the Star Soul id.")
	var confirm_p1 = view.find_child("ConfirmP1", true, false)
	_require(confirm_p1 is Button and confirm_p1.disabled, "Confirm should stay disabled before P1 has enough picks.")
	if failed:
		quit(1)
		return
	print("STAR_SOUL_BP_VIEW_PROBE ok button=", selected)
	view.queue_free()
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
