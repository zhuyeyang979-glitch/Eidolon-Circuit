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
	var index: int = main._component_index_by_exact_name("hero", "cooling", "GLACIER COMBO VENT")
	if index < 0:
		_fail("Missing GLACIER COMBO VENT.")
	else:
		var part := main._selected_component("hero", "cooling", index)
		var entries: Array = main._hover_card_stat_entries("cooling", part)
		var labels: Array = []
		for entry in entries:
			labels.append(String(Dictionary(entry).get("label", "")))
		if not labels.has("Cooling") and not labels.has("散热"):
			_fail("Cooling hover stats should show cooling.")
		if not labels.has("Heat Cap") and not labels.has("热槽"):
			_fail("Cooling hover stats should show heat capacity.")
		var lines: Array = main._hover_card_detail_lines("cooling", part, {"cost": 0, "mass": 0.0, "required_power": 0.0}, {"cost": 0, "mass": 0.0, "required_power": 0.0})
		if not _contains(lines, "combo_vent") and not _contains(lines, "连段"):
			_fail("Cooling hover text should include the cooling profile or philosophy.")
	if failed:
		quit(1)
		return
	print("COOLING_UI_TERMS_PROBE ok")
	quit()
