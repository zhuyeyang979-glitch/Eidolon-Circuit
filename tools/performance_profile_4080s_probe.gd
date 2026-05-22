extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for profile in ["ultra_4080s", "balanced_4080s", "compat_60"]:
		if not MainScene.PERFORMANCE_PROFILE_SPECS.has(profile):
			_fail("Missing performance profile: %s" % profile)
			return
	main._apply_performance_profile("balanced_4080s", true)
	if main.performance_profile != "balanced_4080s":
		_fail("Balanced 4080S profile was not applied.")
		return
	if Engine.max_fps != 120:
		_fail("Balanced 4080S fps cap should be 120, got %d." % Engine.max_fps)
		return
	if int(main._runtime_quality_value("battle_vfx_budget", 0)) != 260:
		_fail("Balanced 4080S VFX budget mismatch.")
		return
	main._apply_performance_profile("ultra_4080s", true)
	if Engine.max_fps != 144 or int(main._runtime_quality_value("contact_particle_pool", 0)) != 192:
		_fail("Ultra 4080S runtime settings were not applied.")
		return
	main._apply_performance_profile("balanced_4080s", true)
	if not FileAccess.file_exists(MainScene.PERFORMANCE_SETTINGS_PATH):
		_fail("Performance settings were not persisted.")
		return
	print("PERFORMANCE_PROFILE_4080S_PROBE ok profile=%s fps=%d" % [main.performance_profile, Engine.max_fps])
	quit(0)
