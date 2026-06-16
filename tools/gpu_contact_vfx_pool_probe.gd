extends SceneTree

const CONTACT_POOL_PATH := "res://scripts/effects/battle_contact_vfx_pool.gd"
const MAIN_PATH := "res://scripts/main.gd"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var pool_source := FileAccess.get_file_as_string(CONTACT_POOL_PATH)
	if pool_source.strip_edges() == "":
		_fail("Unable to read battle_contact_vfx_pool.gd")
		return
	if pool_source.find("class_name BattleContactVfxPool") < 0:
		_fail("BattleContactVfxPool extracted class_name missing")
		return
	if pool_source.find("GPUParticles2D") < 0:
		_fail("BattleContactVfxPool is not GPU-backed")
		return
	if pool_source.find("func setup_pool") < 0 or pool_source.find("func emit_gpu_contact") < 0:
		_fail("BattleContactVfxPool pool API missing")
		return
	var source := FileAccess.get_file_as_string(MAIN_PATH)
	if source.strip_edges() == "":
		_fail("Unable to read main.gd")
		return
	if source.find("preload(\"%s\")" % CONTACT_POOL_PATH) < 0:
		_fail("main.gd should preload BattleContactVfxPool")
		return
	if source.find("class BattleContactVfxPool") >= 0:
		_fail("BattleContactVfxPool should not remain inline in main.gd")
		return
	if source.find("func _emit_gpu_contact_vfx_descriptor") < 0:
		_fail("Runtime GPU VFX descriptor consumer missing")
		return
	var contact_start := source.find("func _resolve_runtime_gpu_contact_once")
	var next_start := source.find("func _emit_gpu_contact_vfx_descriptor", contact_start)
	if contact_start < 0 or next_start < 0:
		_fail("Unable to locate GPU contact VFX callsite")
		return
	var contact_body := source.substr(contact_start, next_start - contact_start)
	if contact_body.find("_emit_gpu_contact_vfx_descriptor") < 0:
		_fail("GPU contact response does not emit through the VFX pool")
		return
	var pool_script := load(CONTACT_POOL_PATH)
	if pool_script == null:
		_fail("BattleContactVfxPool script should load after source checks")
		return
	var pool = pool_script.new()
	root.add_child(pool)
	pool.setup_pool(2, 0.2)
	if pool.particles.size() != 2 or absf(pool.pool_scale - 0.35) > 0.001:
		_fail("BattleContactVfxPool setup should clamp low effect scale")
		return
	pool.emit_gpu_contact(Vector2(4.0, 8.0), Vector2.UP, 3.0, 0)
	if pool.cursor != 1 or pool.emitted_count != 1:
		_fail("BattleContactVfxPool should advance cursor and emission count")
		return
	var particle := pool.particles[0] as GPUParticles2D
	if particle == null or particle.position != Vector2(4.0, 8.0) or not particle.visible:
		_fail("BattleContactVfxPool should update emitted GPU particle")
		return
	var material := particle.process_material as ParticleProcessMaterial
	if material == null or material.initial_velocity_min <= 0.0 or material.initial_velocity_max <= material.initial_velocity_min:
		_fail("BattleContactVfxPool should configure GPU particle material")
		return
	pool.queue_free()
	print("gpu_contact_vfx_pool_probe ok")
	quit(0)
