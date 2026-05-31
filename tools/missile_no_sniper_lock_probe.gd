extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var spec := main._gun_activation_spec("missile_launcher", "missile_lock_activate")
	if String(spec.get("semantic", "")) != "release_missile_lock":
		_fail("Missile activation should use release_missile_lock semantic.")
	var before: int = main.pending_true_bullet_shots.size()
	var missile_event := {"projectile": true, "projectile_only": true, "gun_activation": true, "module_action_profile": "missile_lock_activate", "muscle_node": 0, "collision_group": {"projectile": true, "projectile_only": true, "material_class": "missile_launcher", "shape": "missile_rack"}, "gun_kind": "missile_launcher", "ammo_kind": "explosive", "projectile_style": "missile", "projectile_behavior": "explosive", "travel_path": "homing", "direction": Vector2.RIGHT, "range": 3.4, "lane_range": 0.11}
	if main._is_true_bullet_event(missile_event):
		_fail("Missile event should not enter true bullet lock path.")
	if main.pending_true_bullet_shots.size() != before:
		_fail("Missile checks should not queue true bullets.")
	print("MISSILE_NO_SNIPER_LOCK_PROBE ok")
	quit()
