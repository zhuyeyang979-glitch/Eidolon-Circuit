extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for raw_part in main._catalog_for("hero", "module"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		if part.has("hp"):
			_fail("%s still exposes module HP" % String(part.get("name", "?")))
		for key in main.ACTION_MODULE_COMBAT_FIELD_KEYS:
			if part.has(String(key)):
				_fail("%s still exposes action-module combat field %s" % [String(part.get("name", "?")), String(key)])
	print("ACTION_MODULE_NO_DAMAGE_FIELDS_PROBE ok")
	quit()
