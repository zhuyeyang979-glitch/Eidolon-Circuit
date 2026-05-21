extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._start_battle(MainScene.MODE_AI)
	main.scout_sortie_player_id = 1
	main._update_scout_ui()
	var p1_x: float = (main.scout_player_buttons[0] as Button).position.x
	var p2_x: float = (main.scout_opponent_buttons[0] as Button).position.x
	if not (p1_x < p2_x):
		_fail("When choosing P1 sortie, P1 column should be on the left and P2 on the right.")
	var detail_x: float = main.scout_detail_scroll.position.x
	if not (p1_x < detail_x and detail_x < p2_x):
		_fail("Scout detail panel should be centered between P1 and P2 columns.")
	main._select_scout_sortie_side(2)
	var p2_own_x: float = (main.scout_player_buttons[0] as Button).position.x
	var p1_opp_x: float = (main.scout_opponent_buttons[0] as Button).position.x
	if not (p1_opp_x < p2_own_x):
		_fail("When choosing P2 sortie, P1 column should be left and P2 column should be right.")
	print("SCOUT_SYMMETRY_LAYOUT_PROBE ok left=%.1f detail=%.1f right=%.1f" % [p1_x, detail_x, p2_x])
	quit()
