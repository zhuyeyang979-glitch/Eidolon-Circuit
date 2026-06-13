extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _reset_player_roster(main: Node, roster: Dictionary) -> void:
	main.blueprints[1] = roster
	main.active_roster_indices[1] = {"hero": 0, "puppet": 0, "barrier": 0}
	main.sortie_loadouts[1] = []
	main.initial_sortie_slot[1] = 0
	main.initial_role[1] = "hero"


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	_reset_player_roster(main, main._blank_player_roster())
	main._show_training_config(true)
	var missing_hint := String(main.scout_hint_label.text) if main.scout_hint_label != null else ""
	if missing_hint.find("未找到英雄") < 0 and missing_hint.find("No hero") < 0:
		_fail("Training readiness should explain missing hero fallback, got: %s" % missing_hint)
		return
	var invalid_roster := main._blank_player_roster()
	invalid_roster["hero"] = [main._make_editor_blank_blueprint("hero")]
	_reset_player_roster(main, invalid_roster)
	main._show_training_config(true)
	var invalid_hint := String(main.scout_hint_label.text) if main.scout_hint_label != null else ""
	if invalid_hint.find("没有合法英雄") < 0 and invalid_hint.find("No legal hero") < 0:
		_fail("Training readiness should explain invalid roster fallback, got: %s" % invalid_hint)
		return
	print("TRAINING_READINESS_FEEDBACK_PROBE ok")
	quit(0)
