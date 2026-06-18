class_name BattleContactVfxPool
extends Node2D

var particles: Array[GPUParticles2D] = []
var cursor := 0
var emitted_count := 0
var pool_scale := 1.0


func setup_pool(size: int = 96, effect_scale: float = 1.0) -> void:
	pool_scale = clampf(effect_scale, 0.35, 1.65)
	if particles.size() >= size:
		for particle in particles:
			if particle is GPUParticles2D:
				(particle as GPUParticles2D).amount = maxi(1, int(roundf(10.0 * pool_scale)))
		return
	for i in range(particles.size(), size):
		var particle := GPUParticles2D.new()
		particle.name = "GpuContactVfx%d" % i
		particle.one_shot = true
		particle.emitting = false
		particle.amount = maxi(1, int(roundf(10.0 * pool_scale)))
		particle.lifetime = 0.18
		particle.explosiveness = 1.0
		particle.randomness = 0.35
		var material := ParticleProcessMaterial.new()
		material.direction = Vector3(1, 0, 0)
		material.spread = 36.0
		material.initial_velocity_min = 22.0
		material.initial_velocity_max = 72.0
		material.scale_min = 1.5
		material.scale_max = 3.8
		material.color = Color(1.0, 0.86, 0.32, 0.86)
		particle.process_material = material
		particle.visible = false
		add_child(particle)
		particles.append(particle)


func emit_gpu_contact(screen_position: Vector2, normal: Vector2, strength: float, kind: int) -> void:
	if particles.is_empty():
		setup_pool()
	var particle: GPUParticles2D = particles[cursor % particles.size()]
	cursor += 1
	emitted_count += 1
	particle.position = screen_position
	particle.rotation = normal.angle() if normal.length() > 0.001 else 0.0
	var material := particle.process_material as ParticleProcessMaterial
	if material != null:
		var clamped := clampf(strength, 0.1, 4.0)
		material.initial_velocity_min = (18.0 + clamped * 12.0) * pool_scale
		material.initial_velocity_max = (52.0 + clamped * 26.0) * pool_scale
		material.color = Color(1.0, 0.84, 0.24, 0.82) if kind == 1 else Color(0.35, 0.9, 1.0, 0.74)
	particle.visible = true
	particle.restart()
	particle.emitting = true
