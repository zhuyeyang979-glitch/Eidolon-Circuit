extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.mobius_enabled = true
	var expected_s := MainScene.RING_LENGTH + 0.35
	var hero = FighterScene.new()
	root.add_child(hero)
	hero.setup_unit({"owner_id": 1, "role": "hero", "stats": {"health": 100, "mass": 12.0}})
	hero.deploy(0.35, 0.42)
	hero.mobius_s = expected_s
	hero.mobius_v = 0.42
	hero.ring_pos = 0.35
	hero.lane = 0.42
	main.active_units[1]["hero"] = hero
	main.all_units = [hero]
	main.camera_mobius_s = MainScene.RING_LENGTH - 0.2
	main.camera_center = fposmod(main.camera_mobius_s, MainScene.RING_LENGTH)
	main._update_camera_center()
	if absf(main.camera_mobius_s - expected_s) > 0.001:
		_fail("Mobius camera discarded unwrapped hero coordinate; expected %.3f got %.3f." % [expected_s, main.camera_mobius_s])
	if absf(float(main.player_camera_centers[1]) - expected_s) > 0.001:
		_fail("Per-player camera cache should keep unwrapped coordinate.")
	var screen: Vector2 = main._mobius_project_coord(main._unit_combat_coord(hero)).get("position", Vector2.ZERO)
	var center := Vector2((MainScene.ARENA_LEFT + MainScene.ARENA_RIGHT) * 0.5, (MainScene.ARENA_TOP + MainScene.ARENA_BOTTOM) * 0.5)
	if screen.distance_to(center) > 1.0:
		_fail("Followed hero should project to camera center; error %.3f." % screen.distance_to(center))
	print("BATTLE_CAMERA_FOLLOW_MOBIUS_UNWRAPPED_PROBE ok s=%.3f" % main.camera_mobius_s)
	quit()
