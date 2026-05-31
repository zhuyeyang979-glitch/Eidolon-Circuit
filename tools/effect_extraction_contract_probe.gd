extends SceneTree

const HIT_EFFECT_PATH := "res://scripts/effects/hit_effect.gd"
const COMBO_RIPPLE_EFFECT_PATH := "res://scripts/effects/combo_ripple_effect.gd"
const PROJECTILE_TRACE_EFFECT_PATH := "res://scripts/effects/projectile_trace_effect.gd"
const MAIN_PATH := "res://scripts/main.gd"
const HitEffectScript := preload("res://scripts/effects/hit_effect.gd")
const ComboRippleEffectScript := preload("res://scripts/effects/combo_ripple_effect.gd")
const ProjectileTraceEffectScript := preload("res://scripts/effects/projectile_trace_effect.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _require_source(path: String, expected_class_name: String, required_tokens: Array[String]) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing extracted effect script: %s" % path)
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
	if source.find("class_name %s" % expected_class_name) < 0:
		_fail("Extracted %s should publish the legacy class name." % expected_class_name)
	for token in required_tokens:
		if source.find(token) < 0:
			_fail("Extracted %s is missing behavior token: %s" % [expected_class_name, token])
	return source


func _init() -> void:
	_require_source(HIT_EFFECT_PATH, "HitEffect", ["setup", "_draw_damage_motif", "_hit_vfx_index", "_effect_color"])
	_require_source(COMBO_RIPPLE_EFFECT_PATH, "ComboRippleEffect", ["setup", "draw_arc", "mouse_filter"])
	_require_source(PROJECTILE_TRACE_EFFECT_PATH, "ProjectileTraceEffect", ["setup", "_trace_points", "_draw_chemical_firework", "_polyline_length"])
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for preload_path in [HIT_EFFECT_PATH, COMBO_RIPPLE_EFFECT_PATH, PROJECTILE_TRACE_EFFECT_PATH]:
		if main_source.find("preload(\"%s\")" % preload_path) < 0:
			_fail("main.gd should preload extracted effect: %s" % preload_path)
	for inline_class in ["HitEffect", "ComboRippleEffect", "ProjectileTraceEffect"]:
		if main_source.find("\nclass %s:" % inline_class) >= 0:
			_fail("main.gd should not keep the inline %s class." % inline_class)
	var hit = HitEffectScript.new()
	if not (hit is Node2D):
		_fail("HitEffect should instantiate as a Node2D.")
	hit.setup(2, "laser", false, "beam")
	if hit.tier != 2 or hit.damage_type != "laser" or hit.projectile_style != "beam" or hit.lifetime <= 0.0:
		_fail("HitEffect.setup should preserve legacy state fields.")
	hit.free()
	var ripple = ComboRippleEffectScript.new()
	if not (ripple is Control):
		_fail("ComboRippleEffect should instantiate as a Control.")
	ripple.setup(Vector2(12.0, 34.0), Color(0.1, 0.2, 0.3, 1.0), 1.2)
	if ripple.origin != Vector2(12.0, 34.0) or ripple.strength != 1.2 or ripple.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("ComboRippleEffect.setup should preserve legacy state fields.")
	ripple.free()
	var trace = ProjectileTraceEffectScript.new()
	if not (trace is Node2D):
		_fail("ProjectileTraceEffect should instantiate as a Node2D.")
	trace.setup(Vector2.ZERO, Vector2(100.0, 0.0), "chemical", "spray", "burst", null, 0.5)
	if trace.end_point != Vector2(100.0, 0.0) or trace.damage_type != "chemical" or trace.projectile_style != "spray" or trace.travel_path != "burst":
		_fail("ProjectileTraceEffect.setup should preserve legacy state fields.")
	if trace.max_lifetime < 0.6:
		_fail("ProjectileTraceEffect should preserve slow chemical trace lifetime scaling.")
	trace.free()
	print("EFFECT_EXTRACTION_CONTRACT_PROBE ok effects=3")
	quit(0)
