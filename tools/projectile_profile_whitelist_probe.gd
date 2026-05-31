extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var expected := ["gun_activate", "rifle_burst_activate", "grenade_arc_activate", "laser_beam_activate", "missile_lock_activate", "web_tether_activate"]
	for profile in expected:
		if not main._gun_activation_profiles().has(profile):
			_fail("Projectile whitelist missing %s." % profile)
	var fake_melee := {"module_part": {"module_action_profile": "two_link_forward_snap"}}
	if main._runtime_binding_is_gun_activation(fake_melee):
		_fail("Melee profile entered projectile whitelist.")
	var fake_grenade := {"module_action_profile": "grenade_arc_activate"}
	if not main._runtime_binding_is_gun_activation(fake_grenade):
		_fail("Grenade profile did not enter projectile whitelist.")
	print("PROJECTILE_PROFILE_WHITELIST_PROBE ok")
	quit()
