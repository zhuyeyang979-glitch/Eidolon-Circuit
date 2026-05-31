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


func _joined(values: Array) -> String:
	var text := ""
	for value in values:
		text += " %s" % String(value)
	return text


func _assert_no_hidden_terms(text: String, label: String) -> void:
	var lowered := text.to_lower()
	for forbidden in ["legacy load", "compat view", "projectile mass", "collision speed", "damage unit", "attack group", "momentum cap", "购买词条", "装入预览", "兼容显示", "投射物质量", "碰撞速度"]:
		if lowered.find(forbidden) >= 0:
			_fail("%s exposes hidden term: %s" % [label, forbidden])


func _assert_module_card(main, profile: String, required_terms: Array) -> void:
	var part := _module_by_profile(main, profile)
	var stats: Array = main._hover_card_stat_entries("module", part)
	if stats.size() < 6 or stats.size() > 8:
		_fail("%s module stats should expose 6-8 focused tiles, got %d." % [profile, stats.size()])
	var stat_text := ""
	for raw in stats:
		if not (raw is Dictionary):
			_fail("%s has non-dictionary stat entry." % profile)
		var entry: Dictionary = raw
		if String(entry.get("label", "")) == "" or String(entry.get("icon", "")) == "":
			_fail("%s stat entry lacks label/icon: %s" % [profile, str(entry)])
		stat_text += " %s %s %s" % [String(entry.get("label", "")), String(entry.get("value_text", "")), String(entry.get("icon", ""))]
	var lowered_stat_text := stat_text.to_lower()
	for stat_term in ["input", "joint", "weapon", "damage"]:
		if lowered_stat_text.find(stat_term) < 0:
			_fail("%s stats missing %s in %s" % [profile, stat_term, stat_text])
	var lines: Array = main._hover_card_player_detail_lines("module", part)
	var joined := _joined(lines)
	var lowered_joined := joined.to_lower()
	_assert_no_hidden_terms(joined, profile)
	for term in required_terms:
		if lowered_joined.find(String(term).to_lower()) < 0:
			_fail("%s missing %s in detail lines: %s" % [profile, String(term), joined])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "en"
	_assert_module_card(main, "two_link_forward_snap", ["action module", "bind", "X:", "6X", "data:"])
	_assert_module_card(main, "blade_arc_return", ["blade", "X: normal cut", "6X", "4X", "real contact"])
	_assert_module_card(main, "blunt_gauntlet_extend_swing", ["gauntlet", "hybrid", "extend", "retract", "4X", "6X", "236X special", "214X special", "real contact", "no projectile"])
	_assert_module_card(main, "blunt_shield_guard_bash", ["shield", "ball joint", "4X", "6X", "236X special", "214X special", "real contact", "no projectile"])
	_assert_module_card(main, "blunt_hammer_windup_slam", ["hammer", "ball joint", "4X", "6X", "236X special", "214X special", "real contact", "no projectile"])
	_assert_module_card(main, "laser_beam_activate", ["laser gun", "hold X", "release X", "explicit beam"])
	_assert_module_card(main, "missile_lock_activate", ["missile pod", "hold X", "release X", "explicit missile"])
	print("MODULE_DETAIL_ACTION_PAGE_PROBE ok")
	quit()
