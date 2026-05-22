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


func _assert_icons(main, profile: String, expected_icons: Array, required_labels: Array) -> void:
	var part := _module_by_profile(main, profile)
	var model: Dictionary = main._module_action_card_model(part)
	var icons: Array = Array(model.get("icon_tags", []))
	for expected in expected_icons:
		if not icons.has(String(expected)):
			_fail("%s missing icon %s in %s" % [profile, String(expected), str(icons)])
	var labels := "%s %s %s" % [String(model.get("joint_label", "")), String(model.get("weapon_label", "")), String(model.get("damage_source", ""))]
	for term in required_labels:
		if labels.find(String(term)) < 0:
			_fail("%s missing label %s in %s" % [profile, String(term), labels])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "zh"
	_assert_icons(main, "two_link_forward_snap", ["joint_ball", "input", "contact"], ["双段", "真实接触"])
	_assert_icons(main, "blade_arc_return", ["weapon_blade", "input", "contact"], ["刃系", "真实接触"])
	_assert_icons(main, "blunt_gauntlet_extend_swing", ["joint_hybrid", "weapon_blunt", "input", "contact"], ["混合", "拳套"])
	_assert_icons(main, "blunt_shield_guard_bash", ["weapon_shield", "input", "contact"], ["盾牌", "真实接触"])
	_assert_icons(main, "blunt_hammer_windup_slam", ["weapon_hammer", "input", "contact"], ["大锤", "真实接触"])
	_assert_icons(main, "laser_beam_activate", ["weapon_gun", "input", "projectile"], ["激光枪", "显式光束"])
	_assert_icons(main, "missile_lock_activate", ["weapon_gun", "input", "projectile"], ["导弹架", "显式导弹"])
	print("MODULE_DETAIL_ICON_FIT_PROBE ok")
	quit()
