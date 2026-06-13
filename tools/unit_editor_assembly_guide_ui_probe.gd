extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _filter_index(main, group_key: String, filter_key: String) -> int:
	var options: Array = main._part_filter_options_for_group(group_key)
	for i in range(options.size()):
		if options[i] is Dictionary and String(Dictionary(options[i]).get("key", "")) == filter_key:
			return i
	return -1


func _assert_catalog(main, group_key: String, filter_key: String, message: String) -> void:
	if String(main.editor_part_group_mode) != group_key:
		_fail("%s group mismatch: expected %s got %s." % [message, group_key, String(main.editor_part_group_mode)])
	if String(main.editor_part_filter_mode) != filter_key:
		_fail("%s filter mismatch: expected %s got %s." % [message, filter_key, String(main.editor_part_filter_mode)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var guide_label := main.find_child("AssemblyGuideLabel", true, false) as Label
	if guide_label == null:
		_fail("Unit Edit should expose an AssemblyGuideLabel.")
		return
	if not guide_label.visible:
		_fail("Assembly guide label should be visible on the parts panel.")
	if guide_label.text.find("1/9") < 0 or guide_label.text.find("躯干") < 0:
		_fail("Assembly guide should start at the torso step, got: %s." % guide_label.text)
	for action_key in ["assembly_guide_prev", "assembly_guide_apply", "assembly_guide_next", "auto_connect", "evaluate_connection", "restore_suggested_connection"]:
		if not main.editor_action_buttons.has(action_key):
			_fail("Missing guide or connection action button: %s." % action_key)
		var button: Button = main.editor_action_buttons[action_key]
		if not button.visible:
			_fail("Guide or connection action should be visible: %s." % action_key)
	main._editor_action("assembly_guide_next")
	_assert_catalog(main, "limb", "connector_limb", "Guide next should jump to joint/muscle.")
	main._editor_action("assembly_guide_next")
	_assert_catalog(main, "terminal_weapon", "weapon_all", "Guide next should jump to weapon.")
	main._editor_action("assembly_guide_next")
	if guide_label.text.find("4/9") < 0 or guide_label.text.find("连接") < 0:
		_fail("Guide should expose connection as step 4, got: %s | step=%d group=%s filter=%s." % [guide_label.text, int(main.editor_assembly_guide_step_index), String(main.editor_part_group_mode), String(main.editor_part_filter_mode)])
	main._editor_action("assembly_guide_next")
	if guide_label.text.find("4/9") < 0:
		_fail("Guide should stay on connection until evaluation passes, got: %s | step=%d group=%s filter=%s." % [guide_label.text, int(main.editor_assembly_guide_step_index), String(main.editor_part_group_mode), String(main.editor_part_filter_mode)])
	var next_button: Button = main.editor_action_buttons["assembly_guide_next"]
	if not next_button.disabled:
		_fail("Guide next should be disabled until connection evaluation passes.")
	main.editor_connection_evaluation = {
		"state": "passed",
		"topology_signature": main._editor_connection_topology_signature(main._editor_current_blueprint()),
	}
	main._editor_action("assembly_guide_next")
	_assert_catalog(main, "software_muscle", "engine", "Guide next after a fresh passed evaluation should jump to engine.")
	var cooling_filter := _filter_index(main, "software_muscle", "cooling")
	if cooling_filter < 0:
		_fail("Missing cooling filter in equipment group.")
	main._select_editor_part_group("software_muscle")
	main._select_editor_part_filter(cooling_filter)
	if guide_label.text.find("6/9") < 0 or guide_label.text.find("散热") < 0:
		_fail("Manual cooling selection should sync guide state, got: %s." % guide_label.text)
	main._editor_action("assembly_guide_next")
	_assert_catalog(main, "software_muscle", "booster", "Guide next after manual cooling should continue to booster.")
	var torso_group_button: Button = main.editor_part_group_buttons.get("torso", null)
	if torso_group_button == null or not torso_group_button.visible or torso_group_button.disabled:
		_fail("Manual part group buttons should remain available while guide is visible.")
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_ASSEMBLY_GUIDE_UI_PROBE ok")
	quit(0)
