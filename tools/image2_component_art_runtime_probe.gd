extends SceneTree

const ComponentArtView := preload("res://scripts/views/component_art_view.gd")

const OUT_PATH := "res://assets/concepts/parts/image2_individual/runtime_image2_component_art_probe_v1.png"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	call_deferred("_run")


func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label


func _part_specs() -> Array:
	return [
		{"id": "torso_core", "slot": "muscle", "label": "Torso Core / 躯干核心", "part": {"name": "IMAGE2 TORSO CORE", "slot": "muscle", "is_torso": true, "material_class": "torso", "connection_ends": 6}},
		{"id": "ball_joint", "slot": "joint", "label": "Ball Joint / 球形连接", "part": {"name": "IMAGE2 BALL JOINT", "slot": "joint", "shape": "ball_180", "connection_ends": 2}},
		{"id": "telescopic_joint", "slot": "joint", "label": "Telescopic Joint / 伸缩连接", "part": {"name": "IMAGE2 TELESCOPIC RAIL", "slot": "joint", "shape": "telescopic", "range": 0.3, "connection_ends": 2}},
		{"id": "light_forearm_strut", "slot": "limb_muscle", "label": "Light Strut / 轻型肢体梁", "part": {"name": "IMAGE2 LIGHT FOREARM STRUT", "slot": "limb_muscle", "shape": "ceramic_linear_strut", "material_class": "ceramic", "connection_ends": 2}},
		{"id": "heavy_barrier_strut", "slot": "limb_muscle", "label": "Heavy Strut / 重型结界梁", "part": {"name": "IMAGE2 HEAVY BARRIER STRUT", "slot": "limb_muscle", "shape": "barrier_strut", "material_class": "hardlight", "connection_ends": 2}},
		{"id": "curved_blade_claw", "slot": "muscle", "label": "Blade Claw / 弧形刀爪", "part": {"name": "IMAGE2 CURVED BLADE", "slot": "muscle", "terminal_weapon": true, "weapon_family": "saber", "damage_type": "tear", "connection_ends": 1}},
		{"id": "paired_pincer_claw", "slot": "muscle", "label": "Pincer Claw / 双钳爪", "part": {"name": "IMAGE2 PAIRED CLAW", "slot": "muscle", "terminal_weapon": true, "weapon_family": "claw", "damage_type": "tear", "connection_ends": 1}},
		{"id": "railgun_pod", "slot": "muscle", "label": "Railgun Pod / 轨道炮舱", "part": {"name": "IMAGE2 RAILGUN SNIPER", "slot": "muscle", "projectile": true, "gun_kind": "sniper", "projectile_style": "true_bullet", "projectile_damage_type": "bullet", "material_class": "gun", "connection_ends": 1}},
		{"id": "missile_tube_pod", "slot": "muscle", "label": "Missile Pod / 导弹管舱", "part": {"name": "IMAGE2 MISSILE LAUNCHER", "slot": "muscle", "projectile": true, "gun_kind": "missile_launcher", "projectile_style": "missile", "projectile_damage_type": "explosive", "material_class": "missile_launcher", "connection_ends": 1}},
		{"id": "thruster_nozzle_pair", "slot": "booster", "label": "Thruster Pair / 双推进喷口", "part": {"name": "IMAGE2 THRUSTER NOZZLE PAIR", "slot": "booster", "thruster_family": "cruise_blue", "boost_momentum": 160.0}},
		{"id": "barrier_emitter_plate", "slot": "muscle", "label": "Barrier Plate / 结界发生板", "part": {"name": "IMAGE2 BARRIER EMITTER PLATE", "slot": "muscle", "shape": "one_way_shield", "barrier_panel": true, "material_class": "hardlight", "connection_ends": 2}},
		{"id": "sensor_eye_array", "slot": "module", "label": "Sensor Array / 传感器阵列", "part": {"name": "IMAGE2 SENSOR SOFTWARE MODULE", "slot": "module", "material_class": "software"}},
		{"id": "cooling_fin_module", "slot": "cooling", "label": "Cooling Fins / 散热鳍片", "part": {"name": "IMAGE2 COOLING FIN MODULE", "slot": "cooling", "material_class": "cooling"}},
		{"id": "engine_reactor_capsule", "slot": "engine", "label": "Reactor / 引擎反应舱", "part": {"name": "IMAGE2 ENGINE REACTOR CAPSULE", "slot": "engine", "engine_family": "reactor", "power": 96.0}},
		{"id": "ammo_pod", "slot": "module", "label": "Ammo Pod / 弹药舱", "part": {"name": "IMAGE2 AMMO POD", "slot": "module", "material_class": "software", "ammo_kind": "bullet"}},
		{"id": "soul_source_ether_chip", "slot": "special", "label": "Ether Chip / 魂源以太芯片", "part": {"name": "IMAGE2 SOUL SOURCE ETHER CHIP", "slot": "special", "kind": "soul", "material_class": "software"}},
	]


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("IMAGE2_COMPONENT_ART_RUNTIME_PROBE skipped headless")
		quit(0)
		return
	root.size = Vector2i(1280, 720)
	var panel := Control.new()
	panel.size = Vector2(1280.0, 720.0)
	root.add_child(panel)
	var back := ColorRect.new()
	back.position = Vector2.ZERO
	back.size = panel.size
	back.color = Color(0.006, 0.01, 0.014, 1.0)
	panel.add_child(back)
	_label(panel, "IMAGE2 部件接入运行态预览", Vector2(28.0, 20.0), Vector2(560.0, 32.0), 24, Color(0.92, 0.98, 1.0, 1.0))
	_label(panel, "ComponentArtView now resolves the 16 standalone image2 PNG parts before falling back to procedural art.", Vector2(28.0, 52.0), Vector2(900.0, 24.0), 13, Color(0.56, 0.72, 0.78, 1.0))
	var specs := _part_specs()
	var card_size := Vector2(284.0, 132.0)
	var art_size := Vector2(264.0, 82.0)
	var start := Vector2(28.0, 92.0)
	var gap := Vector2(28.0, 22.0)
	for i in range(specs.size()):
		var spec: Dictionary = specs[i]
		var col := i % 4
		var row := i / 4
		var card_pos := start + Vector2(float(col) * (card_size.x + gap.x), float(row) * (card_size.y + gap.y))
		var card := ColorRect.new()
		card.position = card_pos
		card.size = card_size
		card.color = Color(0.015, 0.025, 0.033, 0.98)
		panel.add_child(card)
		var art := ComponentArtView.new()
		art.position = card_pos + Vector2(10.0, 10.0)
		art.size = art_size
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(art)
		art.set_component(String(spec.get("slot", "")), Dictionary(spec.get("part", {})), 0.0)
		_label(panel, String(spec.get("label", "")), card_pos + Vector2(12.0, 98.0), Vector2(card_size.x - 24.0, 22.0), 13, Color(0.86, 0.94, 0.98, 1.0))
	for frame in range(4):
		RenderingServer.force_draw()
		await process_frame
	RenderingServer.force_draw()
	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		_fail("Runtime probe could not read viewport texture.")
		return
	var image := viewport_texture.get_image()
	if image == null:
		_fail("Runtime probe viewport image is null.")
		return
	var err := image.save_png(OUT_PATH)
	if err != OK:
		_fail("Runtime probe could not save screenshot to %s, err=%d." % [OUT_PATH, err])
		return
	print("IMAGE2_COMPONENT_ART_RUNTIME_PROBE ok %s" % OUT_PATH)
	quit(0)
