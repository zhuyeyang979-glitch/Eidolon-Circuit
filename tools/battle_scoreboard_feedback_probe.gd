extends SceneTree

const BattleHudStateService := preload("res://scripts/services/battle_hud_state_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _terms() -> Dictionary:
	return {
		"resource": "RES",
		"victory_points": "VP",
		"score": "SCORE",
		"tied": "TIED",
		"leads": "LEADS",
		"match_point": "MATCH POINT",
		"portal": "PORT",
		"offline": "OFF",
		"deploy": "DEP",
	}


func _snapshot(p1_points: int, p2_points: int, win_points: int) -> Dictionary:
	return {
		"mode_title": "LOCAL VERSUS",
		"match_time_remaining": 90.0,
		"win_points": win_points,
		"role_order": ["hero", "puppet", "barrier"],
		"terms": _terms(),
		"hp_label": "HP",
		"players": {
			1: {
				"resource": 10,
				"victory_points": p1_points,
				"portal_name": "Gate A",
				"sortie_discount_entries": [],
				"roles": {},
				"hero_ammo": {"has_ammo": false},
			},
			2: {
				"resource": 12,
				"victory_points": p2_points,
				"portal_name": "Gate B",
				"sortie_discount_entries": [],
				"roles": {},
				"hero_ammo": {"has_ammo": false},
			},
		},
	}


func _init() -> void:
	var service := BattleHudStateService.new()
	var model: Dictionary = service.heavy_hud_text_state(_snapshot(6, 4, 7))
	var p1_text := String(Dictionary(model.get("p1_victory", {})).get("text", ""))
	var p2_text := String(Dictionary(model.get("p2_victory", {})).get("text", ""))
	if p1_text != "P1 VP 6/7" or p2_text != "P2 VP 4/7":
		_fail("Per-player VP labels should include side and target: %s / %s" % [p1_text, p2_text])
	var scoreboard := String(Dictionary(model.get("scoreboard", {})).get("text", ""))
	if scoreboard.find("SCORE P1 6 - 4 P2 / 7") < 0 or scoreboard.find("P1 MATCH POINT") < 0:
		_fail("Central scoreboard should show score and match point: %s" % scoreboard)

	var tied := String(Dictionary(service.heavy_hud_text_state(_snapshot(3, 3, 7)).get("scoreboard", {})).get("text", ""))
	if tied.find("TIED") < 0:
		_fail("Central scoreboard should show tied state: %s" % tied)
	var lead := String(Dictionary(service.heavy_hud_text_state(_snapshot(2, 5, 7)).get("scoreboard", {})).get("text", ""))
	if lead.find("P2 LEADS +3") < 0:
		_fail("Central scoreboard should show leader and lead amount: %s" % lead)

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in ["battle_scoreboard_label", "\"scoreboard\": battle_scoreboard_label", "\"Scoreboard\""]:
		if main_source.find(token) < 0:
			_fail("Main HUD should wire a central scoreboard label: %s" % token)
	var readme := FileAccess.get_file_as_string("res://README.md")
	for phrase in ["central scoreboard", "match point", "P1 VP", "P2 VP"]:
		if readme.find(phrase) < 0:
			_fail("README should document visible score feedback: %s" % phrase)

	if failed:
		quit(1)
		return
	print("BATTLE_SCOREBOARD_FEEDBACK_PROBE ok")
	quit(0)
