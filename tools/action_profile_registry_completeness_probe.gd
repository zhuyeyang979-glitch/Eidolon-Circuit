extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const ActionProfileRegistry := preload("res://scripts/services/action_profile_registry.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var registry := ActionProfileRegistry.new()
	var required := [
		"gun_activate",
		"rifle_burst_activate",
		"grenade_arc_activate",
		"laser_beam_activate",
		"missile_lock_activate",
		"web_tether_activate",
		"two_link_forward_snap",
		"blunt_gauntlet_extend_swing",
		"blunt_shield_guard_bash",
		"blunt_hammer_windup_slam",
		"blade_arc_return",
		"katana_quickdraw",
		"scythe_hook_return",
		"greatsword_commit_cleave",
		"triple_limb_cross_cut",
		"extend_slash_driver",
		"pierce_telescopic_lunge",
		"rapier_feint_thrust",
		"lance_couched_charge",
		"drill_breach_drive",
		"reeling_hook_rip",
	]
	for profile in required:
		if not registry.is_live_profile(profile):
			_fail("Registry missing live profile %s." % profile)
	if registry.command_state_for("4X") != "active" or registry.command_state_for("214X") != "active":
		_fail("Active command state mapping is wrong.")
	if registry.command_state_for("6X") != "armor" or registry.command_state_for("236X") != "armor":
		_fail("Armor command state mapping is wrong.")
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for profile in registry.projectile_profiles():
		if not main._gun_activation_profiles().has(profile):
			_fail("Main projectile whitelist diverged from registry: %s." % profile)
	for raw_part in main._catalog_for("hero", "module"):
		if not (raw_part is Dictionary):
			continue
		var part: Dictionary = raw_part
		var profile := String(part.get("module_action_profile", "")).to_lower()
		if profile == "":
			continue
		if not registry.is_live_profile(profile):
			continue
		var lifecycle := main._catalog_lifecycle_for_part("module", part)
		if String(lifecycle.get("catalog_lifecycle", "")) != "live":
			_fail("Live profile %s is frozen by main lifecycle: %s" % [profile, String(lifecycle.get("reason", ""))])
	print("ACTION_PROFILE_REGISTRY_COMPLETENESS_PROBE ok live=%d projectile=%d" % [registry.live_profiles().size(), registry.projectile_profiles().size()])
	quit()
