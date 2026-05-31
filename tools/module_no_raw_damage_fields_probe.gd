extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for raw_part in main._catalog_for("hero", "module"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		for key in main.ACTION_MODULE_COMBAT_FIELD_KEYS:
			if part.has(String(key)):
				_fail("%s exposes normalized module combat field %s" % [String(part.get("name", "?")), String(key)])
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var begin := source.find("const LIVE_BACKFILLED_MODULE_NAMES")
	var end := source.find("const LIVE_BACKFILLED_PROJECTILE_NAMES")
	if begin < 0 or end <= begin:
		_fail("Could not locate module backfill catalog block.")
	else:
		var module_block := source.substr(begin, end - begin)
		for key in main.ACTION_MODULE_COMBAT_FIELD_KEYS:
			var needle := "\"%s\"" % String(key)
			if module_block.find(needle) >= 0:
				_fail("Raw module backfill block still contains combat field %s" % String(key))
	if failed:
		quit(1)
		return
	print("MODULE_NO_RAW_DAMAGE_FIELDS_PROBE ok modules=%d" % main._catalog_for("hero", "module").size())
	quit()
