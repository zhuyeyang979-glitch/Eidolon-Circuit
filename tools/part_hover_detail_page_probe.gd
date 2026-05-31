extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _joined_lines(lines: Array) -> String:
	var result := ""
	for raw in lines:
		result += " %s" % String(raw)
	return result


func _assert_no_hidden_terms(text: String, label: String) -> void:
	var lowered := text.to_lower()
	for forbidden in [
		"legacy load",
		"compat view",
		"projectile mass",
		"collision speed",
		"damage unit",
		"attack group",
		"momentum cap",
		"购买词条",
		"装入预览",
		"兼容显示",
		"投射物质量",
		"碰撞速度",
	]:
		if lowered.find(forbidden) >= 0:
			_fail("%s exposes hidden engineering term: %s" % [label, forbidden])


func _part(main, slot_key: String, predicate: Callable) -> Dictionary:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if bool(predicate.call(part)):
			return part
	_fail("Missing sample part for %s." % slot_key)
	return {}


func _assert_card(main, slot_key: String, part: Dictionary, required_terms: Array, label: String) -> void:
	var stats: Array = main._hover_card_stat_entries(slot_key, part)
	if stats.is_empty() or stats.size() > 8:
		_fail("%s should expose 1-8 key metric tiles, got %d." % [label, stats.size()])
	for raw in stats:
		if not (raw is Dictionary):
			_fail("%s has a non-dictionary metric entry." % label)
		var entry: Dictionary = raw
		if String(entry.get("label", "")) == "" or String(entry.get("icon", "")) == "":
			_fail("%s metric is missing label or icon: %s" % [label, str(entry)])
	var lines: Array = main._hover_card_player_detail_lines(slot_key, part)
	var joined := _joined_lines(lines)
	_assert_no_hidden_terms(joined, label)
	var lowered_joined := joined.to_lower()
	for term in required_terms:
		if lowered_joined.find(String(term).to_lower()) < 0:
			_fail("%s missing required player-facing term %s in %s" % [label, String(term), joined])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "en"
	var torso := _part(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var limb := _part(main, "limb_muscle", func(_part: Dictionary) -> bool: return true)
	var melee := _part(main, "muscle", func(part: Dictionary) -> bool: return bool(part.get("terminal_weapon", false)) and main._terminal_weapon_kind_for_part(part, "muscle") != "ranged")
	var gun := _part(main, "muscle", func(part: Dictionary) -> bool: return bool(part.get("projectile", false)) and main._terminal_weapon_kind_for_part(part, "muscle") == "ranged")
	var module := _part(main, "module", func(_part: Dictionary) -> bool: return true)
	var engine := _part(main, "engine", func(_part: Dictionary) -> bool: return true)
	var cooling := _part(main, "cooling", func(_part: Dictionary) -> bool: return true)
	var booster := _part(main, "booster", func(_part: Dictionary) -> bool: return true)
	var special := _part(main, "special", func(_part: Dictionary) -> bool: return true)
	var first_soul := _part(main, "special", func(part: Dictionary) -> bool: return String(part.get("name", "")) == "SOUL: FIRST EDGE ECHO")
	_assert_card(main, "muscle", torso, ["ports", "software slots"], "torso")
	_assert_card(main, "limb_muscle", limb, ["drive", "embedded"], "limb")
	_assert_card(main, "muscle", melee, ["physical melee"], "melee")
	_assert_card(main, "muscle", gun, ["range", "ammo"], "gun")
	_assert_card(main, "module", module, ["bind", "data"], "module")
	_assert_card(main, "engine", engine, ["power", "idle load"], "engine")
	_assert_card(main, "cooling", cooling, ["cooling/sec", "fit"], "cooling")
	_assert_card(main, "booster", booster, ["move", "boost"], "booster")
	_assert_card(main, "special", special, ["soul"], "special")
	_assert_card(main, "special", first_soul, ["hero torso software slot", "duelist oath", "different bound limbs", "heavy shield/hammer"], "first soul")
	print("PART_HOVER_DETAIL_PAGE_PROBE ok")
	quit()
