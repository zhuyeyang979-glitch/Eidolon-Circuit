extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for slot_key in ["special", "module", "joint"]:
		for raw_part in main._catalog_for("hero", slot_key):
			if not (raw_part is Dictionary):
				continue
			var part: Dictionary = raw_part
			if part.has("hp") or part.has("health") or part.has("max_hp"):
				_fail("%s/%s still exposes HP" % [slot_key, String(part.get("name", "?"))])
			if main._component_has_combat_volume(part, slot_key):
				_fail("%s/%s is software but reports combat volume" % [slot_key, String(part.get("name", "?"))])
	print("SOFTWARE_NO_HP_CATALOG_PROBE ok")
	quit()
