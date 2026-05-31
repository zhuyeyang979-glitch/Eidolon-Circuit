extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _append_card_text(main, slot_key: String, part: Dictionary, out: Array) -> void:
	for raw in main._hover_card_stat_entries(slot_key, part):
		if raw is Dictionary:
			var entry: Dictionary = raw
			out.append(String(entry.get("label", "")))
			out.append(String(entry.get("value_text", "")))
	for line in main._hover_card_player_detail_lines(slot_key, part):
		out.append(String(line))
	for line in main._catalog_card_data_lines(slot_key, part):
		out.append(String(line))


func _first_part(main, slot_key: String, predicate: Callable) -> Dictionary:
	for i in range(main._catalog_for("hero", slot_key).size()):
		var part: Dictionary = main._selected_component("hero", slot_key, i)
		if bool(predicate.call(part)):
			return part
	_fail("Missing %s sample." % slot_key)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.ui_language = "zh"
	var lines: Array = []
	_append_card_text(main, "cooling", _first_part(main, "cooling", func(_part: Dictionary) -> bool: return true), lines)
	_append_card_text(main, "engine", _first_part(main, "engine", func(_part: Dictionary) -> bool: return true), lines)
	_append_card_text(main, "booster", _first_part(main, "booster", func(_part: Dictionary) -> bool: return true), lines)
	_append_card_text(main, "module", _first_part(main, "module", func(_part: Dictionary) -> bool: return true), lines)
	_append_card_text(main, "muscle", _first_part(main, "muscle", func(part: Dictionary) -> bool: return bool(part.get("projectile", false))), lines)
	var text := "\n".join(lines)
	var lowered := text.to_lower()
	for required in ["热池", "常热负载", "散热/秒", "事件热", "专项减免", "主动排热"]:
		if text.find(required) < 0:
			_fail("Thermal UI text missing player term %s in:\n%s" % [required, text])
	for forbidden in ["heat:", "heat_event:", "external heat", "debug reason", "legacy load", "attack group", "damage unit"]:
		if lowered.find(forbidden) >= 0:
			_fail("Thermal UI text exposes raw/debug term %s in:\n%s" % [forbidden, text])
	if failed:
		quit(1)
		return
	print("THERMAL_UI_TERMS_PROBE ok")
	quit()
