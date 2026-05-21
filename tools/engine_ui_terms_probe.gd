extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _contains(lines: Array, needle: String) -> bool:
	for line in lines:
		if String(line).contains(needle):
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var index: int = main._component_index_by_exact_name("hero", "engine", "LONGSIGHT FIRE CONTROL CORE")
	if index < 0:
		_fail("Missing LONGSIGHT FIRE CONTROL CORE.")
	else:
		var part: Dictionary = main._selected_component("hero", "engine", index)
		var entries: Array = main._hover_card_stat_entries("engine", part)
		var labels: Array = []
		for raw in entries:
			labels.append(String(Dictionary(raw).get("label", "")))
		if not labels.has("Fire Ctrl") and not labels.has("火控稳定"):
			_fail("Engine hover stats should show fire control.")
		if not labels.has("Boost Ctrl") and not labels.has("推进控制"):
			_fail("Engine hover stats should show boost control.")
		var lines: Array = main._hover_card_detail_lines("engine", part, {"cost": 0, "mass": 0.0, "required_power": 0.0}, {"cost": 0, "mass": 0.0, "required_power": 0.0})
		if not _contains(lines, "fire_control") and not _contains(lines, "火控"):
			_fail("Engine detail text should include team role/philosophy.")
		if _contains(lines, "Load Capacity") or _contains(lines, "pointer"):
			_fail("Engine UI should not use old pointer/load wording.")
	if failed:
		quit(1)
		return
	print("ENGINE_UI_TERMS_PROBE ok")
	quit()
