extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_by_profile(main, profile: String) -> Dictionary:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		if String(part.get("module_action_profile", "")) == profile:
			return part
	_fail("Missing module profile %s." % profile)
	return {}


func _rows_text(main, profile: String) -> String:
	var model: Dictionary = main._module_action_card_model(_module_by_profile(main, profile))
	var text := ""
	for row in Array(model.get("input_rows", [])):
		text += " %s" % String(row)
	return text


func _assert_profile(main, profile: String, must_have: Array, must_not_have: Array) -> void:
	var text := _rows_text(main, profile)
	for term in must_have:
		if text.find(String(term)) < 0:
			_fail("%s missing %s in %s" % [profile, String(term), text])
	for term in must_not_have:
		if text.find(String(term)) >= 0:
			_fail("%s should not show %s in %s" % [profile, String(term), text])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "zh"
	_assert_profile(main, "two_link_forward_snap", ["X：", "6X", "4X"], ["236X", "214X"])
	_assert_profile(main, "blade_arc_return", ["X：普通斩击", "6X", "4X"], ["236X"])
	_assert_profile(main, "scythe_hook_return", ["236X必杀", "214X必杀"], [])
	_assert_profile(main, "blunt_gauntlet_extend_swing", ["236X必杀", "214X必杀"], [])
	_assert_profile(main, "blunt_shield_guard_bash", ["236X必杀", "214X必杀"], [])
	_assert_profile(main, "blunt_hammer_windup_slam", ["236X必杀", "214X必杀"], [])
	_assert_profile(main, "laser_beam_activate", ["按住X", "松开X"], ["236X", "214X"])
	_assert_profile(main, "missile_lock_activate", ["按住X", "松开X"], ["236X", "214X"])
	print("MODULE_DETAIL_SPECIAL_MOVES_PROBE ok")
	quit()
