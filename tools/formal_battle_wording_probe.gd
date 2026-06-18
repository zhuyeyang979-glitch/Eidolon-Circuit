extends SceneTree


var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing wording source: %s" % path)
	return FileAccess.get_file_as_string(path)


func _assert_absent(path: String, text: String, forbidden: PackedStringArray) -> void:
	for phrase in forbidden:
		if text.find(phrase) >= 0:
			_fail("%s still contains player-facing AI wording: %s" % [path, phrase])


func _assert_present(path: String, text: String, required: PackedStringArray) -> void:
	for phrase in required:
		if text.find(phrase) < 0:
			_fail("%s is missing required formal-battle wording: %s" % [path, phrase])


func _init() -> void:
	var player_facing_sources := PackedStringArray([
		"res://README.md",
		"res://scripts/controllers/menu_controller.gd",
		"res://scripts/main.gd",
		"res://docs/superpowers/specs/2026-06-13-unit-editor-onboarding-design.md",
	])
	var forbidden := PackedStringArray([
		"AI Battle",
		"AI BATTLE",
		"AI 对战",
		"AI对战",
		"AI 队伍",
		"AI队伍",
		"AI 自动",
		"AI自动",
		"AI AUTO",
		"AIs auto-pick",
		"P2/AI",
		"/AI",
		"复制AI",
		"AI Starter Core",
		"AI Reserve",
		"guard AI",
		"external AI service",
	])
	for path in player_facing_sources:
		_assert_absent(path, _read_text(path), forbidden)

	var readme := _read_text("res://README.md")
	_assert_present("res://README.md", readme, PackedStringArray([
		"Computer Battle",
		"PVP / Local Versus",
		"No large language model",
	]))

	var todo := _read_text("res://docs/TODO.md")
	_assert_present("res://docs/TODO.md", todo, PackedStringArray([
		"Online Battle / Deferred",
		"local two-player formal battle",
		"network-ready",
	]))

	print("FORMAL_BATTLE_WORDING_PROBE sources=%d" % player_facing_sources.size())
	quit(1 if failed else 0)
