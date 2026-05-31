extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var frozen_count := 0
	var checked_special_projectile := false
	for slot_key in ["muscle", "module"]:
		var catalog: Array = main._catalog_for("hero", slot_key)
		for i in range(catalog.size()):
			var part: Dictionary = main._selected_component("hero", slot_key, i)
			if not main._part_is_catalog_frozen(slot_key, part):
				continue
			frozen_count += 1
			var lifecycle: Dictionary = main._catalog_lifecycle_for_part(slot_key, part)
			if String(lifecycle.get("reason", "")).strip_edges() == "" or String(lifecycle.get("future_dev_tag", "")).strip_edges() == "":
				_fail("Frozen part lacks reason/future tag: %s" % String(part.get("name", "")))
			if part.has("attack_groups") or part.has("action_groups"):
				_fail("Frozen part still exposes old action pointer fields: %s" % String(part.get("name", "")))
			if String(part.get("name", "")) in ["REDLINE MIRV POD", "LIGHT-SINK NEEDLE", "TRACKING MISSILE POD"]:
				checked_special_projectile = true
	if frozen_count < 8:
		_fail("Expected a meaningful frozen backlog, got %d." % frozen_count)
	if not checked_special_projectile:
		_fail("No special projectile was found in frozen backlog.")
	var laser_index: int = main._component_index_by_exact_name("hero", "muscle", "LASER EMITTER GUN")
	if laser_index < 0:
		_fail("Backfilled LASER EMITTER GUN missing from catalog.")
	var laser: Dictionary = main._selected_component("hero", "muscle", laser_index)
	if main._part_is_catalog_frozen("muscle", laser):
		_fail("Backfilled LASER EMITTER GUN should no longer be frozen.")
	print("FROZEN_FUTURE_DEV_PROBE ok frozen=%d" % frozen_count)
	quit()
