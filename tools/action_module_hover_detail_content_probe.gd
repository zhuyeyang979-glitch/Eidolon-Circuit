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
	_assert_terms(joined, ["Use Scope", "Action", "Timing", "Resolve Source", "Consistency", "Drive & Heat"], "gun_activate detail sections")
	_assert_terms(joined, ["Can bind", "Hold X", "bound firearm", "projectile momentum", "Action speed"], "gun_activate explanatory copy")
	var melee := _module_by_profile(main, "two_link_forward_snap")
	var melee_joined := _joined(main._hover_card_player_detail_lines("module", melee))
	_assert_terms(
			melee_joined,
			[
				"linkage-style",
				"Can bind",
				"two-part non-torso chain",
				"Forward + X",
				"Back + X",
				"startup 1/3",
				"recovery 2/3",
				"real contact",
				"allocated drive",
				"no fixed damage",
				"Consistency",
				"does not float",
				"no projectile",
			],
			"two-link player contract copy"
	)
	for raw_impl_term in ["TopologyPoseResolver", "runtime_topology_segments"]:
		if melee_joined.find(raw_impl_term) >= 0:
			_fail("Two-link detail leaked implementation term %s in: %s" % [raw_impl_term, melee_joined])
	if melee_joined.to_lower().strip_edges() == "x: two-link forward snap.":
		_fail("Two-link detail regressed to a one-line input label.")
	print("ACTION_MODULE_HOVER_DETAIL_CONTENT_PROBE ok")
	quit()
