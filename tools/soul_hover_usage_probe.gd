extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find_soul(main) -> Dictionary:
	for i in range(main._catalog_for("hero", "special").size()):
		var part: Dictionary = main._selected_component("hero", "special", i)
		if String(part.get("name", "")) == "SOUL: FIRST EDGE ECHO":
			return part
	_fail("SOUL: FIRST EDGE ECHO missing.")
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
	main.ui_language = "zh"
	var soul := _find_soul(main)
	var lines: Array = main._hover_card_player_detail_lines("special", soul)
	var text := _joined(lines)
	for required in [
		"装入英雄躯干的软件槽。",
		"满足决斗誓约后生效；不满足时只提供热池。",
		"适合轻/中型、小半径、三组以上行动模块的近战决斗机。",
		"连续换不同绑定肢体行动，可触发回响窗口，缩短下一次恢复或减轻热负担。",
		"重型盾锤、导弹/纯远程、XL 肢体不会触发誓约。",
		"英雄",
		"软件槽",
		"真实接触",
		"换肢连段",
		"热池",
	]:
		if text.find(String(required)) < 0:
			_fail("Soul hover missing usage text '%s' in %s" % [String(required), text])
	for forbidden in ["legacy", "attack group", "damage unit", "soul cast", "module_action_profile", "soul_archetype"]:
		if text.to_lower().find(forbidden) >= 0:
			_fail("Soul hover exposes hidden/old term: %s" % forbidden)
	var stats: Array = main._hover_card_stat_entries("special", soul)
	if stats.size() < 3:
		_fail("Soul hover should expose heat/echo metric tiles.")
	print("SOUL_HOVER_USAGE_PROBE ok")
	quit()
