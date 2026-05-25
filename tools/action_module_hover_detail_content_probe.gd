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


func _assert_terms(text: String, terms: Array, label: String) -> void:
	var lowered := text.to_lower()
	for term in terms:
		if lowered.find(String(term).to_lower()) < 0:
			_fail("%s missing '%s' in: %s" % [label, String(term), text])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "en"
	var module := _module_by_profile(main, "gun_activate")
	var lines: Array = main._hover_card_player_detail_lines("module", module)
	var joined := _joined(lines)
	_assert_terms(joined, ["Use Scope", "Action", "Timing", "Resolve Source", "Drive & Heat"], "gun_activate detail sections")
	_assert_terms(joined, ["Can bind", "Hold X", "bound firearm", "projectile momentum", "Action speed"], "gun_activate explanatory copy")
	var melee := _module_by_profile(main, "two_link_forward_snap")
	var melee_joined := _joined(main._hover_card_player_detail_lines("module", melee))
	_assert_terms(melee_joined, ["real contact", "allocated drive", "no fixed damage"], "melee module resolve copy")
	print("ACTION_MODULE_HOVER_DETAIL_CONTENT_PROBE ok")
	quit()
