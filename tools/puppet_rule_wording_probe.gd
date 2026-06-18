extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var forbidden_main_phrases := [
		"\"PUPPET AI:",
		"/ AI %s / source",
		"\nAI %s  FIELD",
		"傀儡AI %s",
		"SOURCE: %d bodies / AI",
		"机小队 AI",
		"squad AI, policy",
	]
	for phrase in forbidden_main_phrases:
		if main_source.find(phrase) >= 0:
			_fail("Player-facing puppet wording still implies AI or model control: %s" % phrase)
			return

	var readme := FileAccess.get_file_as_string("res://README.md")
	var required_readme_phrases := [
		"deterministic",
		"large language model",
		"Source Code",
	]
	for phrase in required_readme_phrases:
		if readme.find(phrase) < 0:
			_fail("README should explain deterministic puppet control without model integration: %s" % phrase)
			return

	print("PUPPET_RULE_WORDING_PROBE ok")
	quit()
