extends SceneTree

const HIT_EFFECT_PATH := "res://scripts/effects/hit_effect.gd"
const COMBO_RIPPLE_EFFECT_PATH := "res://scripts/effects/combo_ripple_effect.gd"
const PROJECTILE_TRACE_EFFECT_PATH := "res://scripts/effects/projectile_trace_effect.gd"
const SALVO_LANDING_PREVIEW_EFFECT_PATH := "res://scripts/effects/salvo_landing_preview_effect.gd"
const LASER_AIM_TELEGRAPH_EFFECT_PATH := "res://scripts/effects/laser_aim_telegraph_effect.gd"
const TRUE_BULLET_TARGET_LOCK_EFFECT_PATH := "res://scripts/effects/true_bullet_target_lock_effect.gd"
const BLIND_ZONE_EFFECT_PATH := "res://scripts/effects/blind_zone_effect.gd"
const FIELD_AURA_EFFECT_PATH := "res://scripts/effects/field_aura_effect.gd"
const COIN_PICKUP_EFFECT_PATH := "res://scripts/effects/coin_pickup_effect.gd"
const IDENTITY_TRANSFER_EFFECT_PATH := "res://scripts/effects/identity_transfer_effect.gd"
const BATTLE_CONTACT_VFX_POOL_PATH := "res://scripts/effects/battle_contact_vfx_pool.gd"
const MAIN_PATH := "res://scripts/main.gd"
const HitEffectScript := preload("res://scripts/effects/hit_effect.gd")
const ComboRippleEffectScript := preload("res://scripts/effects/combo_ripple_effect.gd")
const ProjectileTraceEffectScript := preload("res://scripts/effects/projectile_trace_effect.gd")
const SalvoLandingPreviewEffectScript := preload("res://scripts/effects/salvo_landing_preview_effect.gd")
const LaserAimTelegraphEffectScript := preload("res://scripts/effects/laser_aim_telegraph_effect.gd")
const TrueBulletTargetLockEffectScript := preload("res://scripts/effects/true_bullet_target_lock_effect.gd")
const BlindZoneEffectScript := preload("res://scripts/effects/blind_zone_effect.gd")
const FieldAuraEffectScript := preload("res://scripts/effects/field_aura_effect.gd")
const CoinPickupEffectScript := preload("res://scripts/effects/coin_pickup_effect.gd")
const IdentityTransferEffectScript := preload("res://scripts/effects/identity_transfer_effect.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _require_source(path: String, expected_class_name: String, required_tokens: Array[String]) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing extracted effect script: %s" % path)
		return ""
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
	_require_source(SALVO_LANDING_PREVIEW_EFFECT_PATH, "SalvoLandingPreviewEffect", ["setup", "refresh", "landing_point", "hold_ratio"])
	_require_source(LASER_AIM_TELEGRAPH_EFFECT_PATH, "LaserAimTelegraphEffect", ["setup", "set_line", "beam_color", "draw_polyline"])
	_require_source(TRUE_BULLET_TARGET_LOCK_EFFECT_PATH, "TrueBulletTargetLockEffect", ["setup", "lock_color", "draw_arc", "draw_line"])
	_require_source(BLIND_ZONE_EFFECT_PATH, "BlindZoneEffect", ["setup", "tick_zone", "is_alive", "OWNER VISIBLE"])
	_require_source(FIELD_AURA_EFFECT_PATH, "FieldAuraEffect", ["setup", "update_screen", "_field_color", "_gravity_visual_direction"])
	_require_source(COIN_PICKUP_EFFECT_PATH, "CoinPickupEffect", ["setup", "collect", "expired", "ttl"])
	_require_source(IDENTITY_TRANSFER_EFFECT_PATH, "IdentityTransferEffect", ["setup", "_payload_color", "_draw_payload", "callback.call"])
	_require_source(BATTLE_CONTACT_VFX_POOL_PATH, "BattleContactVfxPool", ["setup_pool", "emit_gpu_contact", "GPUParticles2D", "ParticleProcessMaterial"])
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for preload_path in [
		HIT_EFFECT_PATH,
		COMBO_RIPPLE_EFFECT_PATH,
		PROJECTILE_TRACE_EFFECT_PATH,
		SALVO_LANDING_PREVIEW_EFFECT_PATH,
		LASER_AIM_TELEGRAPH_EFFECT_PATH,
		TRUE_BULLET_TARGET_LOCK_EFFECT_PATH,
		BLIND_ZONE_EFFECT_PATH,
		FIELD_AURA_EFFECT_PATH,
		COIN_PICKUP_EFFECT_PATH,
		IDENTITY_TRANSFER_EFFECT_PATH,
		BATTLE_CONTACT_VFX_POOL_PATH,
	]:
		if main_source.find("preload(\"%s\")" % preload_path) < 0:
			_fail("main.gd should preload extracted effect: %s" % preload_path)
	for inline_class in [
		"HitEffect",
		"ComboRippleEffect",
		"ProjectileTraceEffect",
		"SalvoLandingPreviewEffect",
		"LaserAimTelegraphEffect",
		"TrueBulletTargetLockEffect",
		"BlindZoneEffect",
		"FieldAuraEffect",
		"CoinPickupEffect",
		"IdentityTransferEffect",
		"BattleContactVfxPool",
	]:
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
	var salvo = SalvoLandingPreviewEffectScript.new()
	if not (salvo is Node2D):
		_fail("SalvoLandingPreviewEffect should instantiate as a Node2D.")
	salvo.setup(Vector2.ZERO, Vector2(24.0, 18.0), 0.8)
	if salvo.landing_point != Vector2(24.0, 18.0) or absf(salvo.hold_ratio - 0.8) > 0.001:
		_fail("SalvoLandingPreviewEffect.setup should preserve landing state.")
	salvo.refresh(Vector2.ONE, Vector2(30.0, 4.0), 2.0)
	if salvo.hold_ratio != 1.0:
		_fail("SalvoLandingPreviewEffect.refresh should clamp hold ratio.")
	salvo.free()
	var laser = LaserAimTelegraphEffectScript.new()
	if not (laser is Node2D):
		_fail("LaserAimTelegraphEffect should instantiate as a Node2D.")
	laser.setup(Vector2.ZERO, Vector2(80.0, 0.0), 0.4, Color.RED)
	laser.set_line(Vector2(2.0, 3.0), Vector2(7.0, 11.0))
	if laser.start_point != Vector2(2.0, 3.0) or laser.end_point != Vector2(7.0, 11.0) or laser.beam_color != Color.RED:
		_fail("LaserAimTelegraphEffect should preserve setup and set_line state.")
	laser.free()
	var lock = TrueBulletTargetLockEffectScript.new()
	if not (lock is Node2D):
		_fail("TrueBulletTargetLockEffect should instantiate as a Node2D.")
	lock.setup(0.9, Color.YELLOW)
	if lock.max_lifetime < 0.89 or lock.lock_color != Color.YELLOW:
		_fail("TrueBulletTargetLockEffect.setup should preserve lock state.")
	lock.free()
	var blind = BlindZoneEffectScript.new()
	if not (blind is Node2D):
		_fail("BlindZoneEffect should instantiate as a Node2D.")
	blind.setup(2, 0.2, -0.3, 0.7, 2.0, 0.6)
	blind.tick_zone(0.25, Vector2(4.0, 9.0), true)
	if not blind.is_alive() or blind.position != Vector2(4.0, 9.0) or not blind.visible:
		_fail("BlindZoneEffect.tick_zone should update screen visibility while alive.")
	blind.free()
	var aura = FieldAuraEffectScript.new()
	if not (aura is Node2D):
		_fail("FieldAuraEffect should instantiate as a Node2D.")
	aura.setup(1, "gravity_up_right", 0.8, 2.0)
	aura.update_screen(Vector2(6.0, 7.0), true, 0.2)
	if aura.position != Vector2(6.0, 7.0) or not aura.visible or aura.field_kind != "gravity_up_right":
		_fail("FieldAuraEffect should preserve field screen state.")
	aura.free()
	var coin = CoinPickupEffectScript.new()
	if not (coin is Node2D):
		_fail("CoinPickupEffect should instantiate as a Node2D.")
	coin.setup(1, 150, 2.5)
	coin.update_screen(Vector2(12.0, 5.0), true, 0.1)
	if coin.value != 150 or coin.position != Vector2(12.0, 5.0) or coin.expired():
		_fail("CoinPickupEffect should preserve coin state before collection.")
	coin.collect()
	if not coin.expired():
		_fail("CoinPickupEffect.collect should mark the effect expired.")
	var source := Node2D.new()
	var target := Node2D.new()
	root.add_child(source)
	root.add_child(target)
	source.global_position = Vector2.ZERO
	target.global_position = Vector2(40.0, 20.0)
	var transfer = IdentityTransferEffectScript.new()
	root.add_child(transfer)
	var callback_state := {"called": false}
	transfer.setup(source, target, ["soul", "code", "ether"], func(): callback_state["called"] = true)
	if not (transfer is Node2D) or transfer.payloads.size() != 3 or transfer.progress != 0.0:
		_fail("IdentityTransferEffect.setup should preserve payload state.")
	transfer._process(1.0)
	if not bool(callback_state.get("called", false)):
		_fail("IdentityTransferEffect should call the finish callback when complete.")
	source.queue_free()
	target.queue_free()
	var contact_pool_script := load(BATTLE_CONTACT_VFX_POOL_PATH)
	if contact_pool_script == null:
		_fail("BattleContactVfxPool script should load after source checks.")
		return
	var contact_pool = contact_pool_script.new()
	root.add_child(contact_pool)
	if not (contact_pool is Node2D):
		_fail("BattleContactVfxPool should instantiate as a Node2D.")
	contact_pool.setup_pool(3, 2.0)
	if contact_pool.particles.size() != 3 or absf(contact_pool.pool_scale - 1.65) > 0.001:
		_fail("BattleContactVfxPool.setup_pool should create a clamped GPU particle pool.")
	contact_pool.emit_gpu_contact(Vector2(9.0, 12.0), Vector2.RIGHT, 2.0, 1)
	if contact_pool.cursor != 1 or contact_pool.emitted_count != 1:
		_fail("BattleContactVfxPool.emit_gpu_contact should advance pool state.")
	var contact_particle := contact_pool.particles[0] as GPUParticles2D
	if contact_particle == null or contact_particle.position != Vector2(9.0, 12.0) or not contact_particle.visible:
		_fail("BattleContactVfxPool.emit_gpu_contact should update the selected particle.")
	contact_pool.queue_free()
	print("EFFECT_EXTRACTION_CONTRACT_PROBE ok effects=11")
	quit(0)
