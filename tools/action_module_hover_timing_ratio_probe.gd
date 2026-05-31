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


func _joined(lines: Array) -> String:
	var text := ""
	for raw in lines:
		text += " %s" % String(raw)
	return text


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "en"
	var two_link := _module_by_profile(main, "two_link_forward_snap")
	var two_link_text := _joined(main._hover_card_player_detail_lines("module", two_link)).to_lower()
	if two_link_text.find("startup 1/3") < 0 or two_link_text.find("recovery 2/3") < 0:
		_fail("Two-link module should explain startup 1/3 and recovery 2/3: %s" % two_link_text)
	for term in ["pose persists", "two-bar linkage", "stays attached"]:
		if two_link_text.find(term) < 0:
			_fail("Two-link timing detail should explain linked recovery contract term %s in %s" % [term, two_link_text])
	var gun := _module_by_profile(main, "gun_activate")
	var gun_text := _joined(main._hover_card_player_detail_lines("module", gun)).to_lower()
	for term in ["hold", "interval", "release", "bound firearm"]:
		if gun_text.find(term) < 0:
			_fail("Gun activate timing missing %s in %s" % [term, gun_text])
	if gun_text.find("startup 1/3") >= 0 or gun_text.find("recovery 2/3") >= 0:
		_fail("Gun activate should not fake fixed melee timing ratios: %s" % gun_text)
	print("ACTION_MODULE_HOVER_TIMING_RATIO_PROBE ok")
	quit()
