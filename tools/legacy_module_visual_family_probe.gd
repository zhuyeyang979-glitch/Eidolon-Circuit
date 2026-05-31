extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const FAMILIES := [
	"balance_string",
	"vise_close",
	"pickup_dash",
	"crush_windup",
	"feint_thrust",
	"explosive_arc",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var renderer_source := FileAccess.get_file_as_string("res://scripts/assembly_board_renderer.gd")
	if renderer_source.find("_draw_module_visual_family_preview") < 0:
		_fail("AssemblyBoardRenderer lacks module family preview dispatcher.")
	if renderer_source.find("module_visual_family") < 0:
		_fail("AssemblyBoardRenderer no longer reads module_visual_family.")
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for family in FAMILIES:
		if renderer_source.find("\"%s\"" % family) < 0:
			_fail("Renderer missing visual family branch: %s" % family)
		var found := false
		for i in range(main._catalog_for("hero", "module").size()):
			var part: Dictionary = main._selected_component("hero", "module", i)
			if String(part.get("module_visual_family", "")) == family:
				found = true
				var lifecycle: Dictionary = main._catalog_lifecycle_for_part("module", part)
				if String(lifecycle.get("catalog_lifecycle", "")) != "live":
					_fail("%s family module should be live." % family)
				if String(part.get("module_variant_key", "")) == "":
					_fail("%s family module missing variant key." % family)
				break
		if not found:
			_fail("No live module exposes visual family %s." % family)
	print("LEGACY_MODULE_VISUAL_FAMILY_PROBE ok families=%d" % FAMILIES.size())
	quit()
