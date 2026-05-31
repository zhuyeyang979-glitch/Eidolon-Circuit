extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const ActionProfileRegistry := preload("res://scripts/services/action_profile_registry.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var registry := ActionProfileRegistry.new()
	for profile in registry.projectile_profiles():
		var contract := registry.projectile_mobility_contract(profile)
		if contract.is_empty():
			_fail("Projectile profile missing mobility contract: %s" % profile)
		if not bool(contract.get("move_while_firing", false)):
			_fail("Projectile profile should allow movement while firing: %s" % profile)
		if not bool(contract.get("direction_boost_while_firing", false)):
			_fail("Projectile profile should allow directional boost while firing: %s" % profile)
		if String(contract.get("aim_input_mode", "")) != "turn_keys":
			_fail("Projectile profile should use turn-key aim: %s" % profile)
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._selected_component("hero", "module", i)
		var profile := String(part.get("module_action_profile", "")).to_lower()
		if not registry.is_projectile_profile(profile):
			continue
		if String(part.get("gun_aim_input_mode", "")) != "turn_keys":
			_fail("Catalog module missing turn-key aim default: %s" % profile)
		if not bool(part.get("move_while_firing", false)) or not bool(part.get("direction_boost_while_firing", false)):
			_fail("Catalog module missing fire-movement contract: %s" % profile)
	print("GUN_ACTIVATION_MOBILITY_CONTRACT_PROBE ok profiles=%d" % registry.projectile_profiles().size())
	quit()
