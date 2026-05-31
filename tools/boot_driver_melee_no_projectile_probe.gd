extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const ProbeLib := preload("res://tools/boot_driver_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	ProbeLib.prepare_main(main)
	var fixture := ProbeLib.build_fixture(main)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, fixture["unit_bp"])
	var bindings: Array = Array(stats.get("runtime_module_bindings", []))
	if bindings.is_empty():
		_fail("Boot Driver runtime binding missing.")
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "BOOT_DRIVER_NO_PROJECTILE", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	main.active_units = {1: {"hero": fighter, "barrier": null, "puppet": []}, 2: {"hero": null, "barrier": null, "puppet": []}}
	main.all_units = [fighter]
	var event: Dictionary = fighter.begin_runtime_module_action("active", Dictionary(bindings[0]), Vector2.RIGHT)
	if event.is_empty():
		_fail("Boot Driver did not start: %s" % String(fighter.get_meta("last_module_gate_reason", "")))
	if bool(event.get("projectile", false)) or bool(event.get("projectile_only", false)):
		_fail("Boot Driver event must be explicit non-projectile melee: %s" % str(event))
	if not bool(event.get("runtime_melee_contact", false)):
		_fail("Boot Driver event must be marked as runtime melee contact.")
	if String(event.get("projectile_style", "")) != "" or String(event.get("travel_path", "")) != "":
		_fail("Boot Driver event should not carry projectile style/path: %s" % str(event))
	main.battle_message = ""
	main.battle_message_timer = 0.0
	main.battle_projectile_trace_spawn_count = 0
	main.pending_chemical_projectiles.clear()
	main.pending_missile_projectiles.clear()
	main._resolve_attack(fighter, event)
	var message := String(main.battle_message)
	if message.contains("Projectile requires") or message.contains("投射物"):
		_fail("Boot Driver leaked into projectile warning: %s" % message)
	if main.battle_projectile_trace_spawn_count != 0 or not main.pending_chemical_projectiles.is_empty() or not main.pending_missile_projectiles.is_empty():
		_fail("Boot Driver spawned projectile runtime artifacts.")
	print("BOOT_DRIVER_MELEE_NO_PROJECTILE_PROBE ok")
	quit()
