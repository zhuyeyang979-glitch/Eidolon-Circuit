extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const OUT_PATH := "res://assets/concepts/parts/image2_individual/runtime_editor_image2_component_preview_v1.png"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("IMAGE2_EDITOR_RUNTIME_SCREENSHOT_PROBE skipped headless")
		quit(0)
		return
	root.size = Vector2i(1280, 720)
	var main = MainScene.new()
	root.add_child(main)
	await process_frame
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main._update_editor_ui()
	var preview_part := {
		"name": "IMAGE2 RAILGUN SNIPER",
		"slot": "muscle",
		"projectile": true,
		"gun_kind": "sniper",
		"projectile_style": "true_bullet",
		"projectile_damage_type": "bullet",
		"material_class": "gun",
		"connection_ends": 1,
	}
	main._refresh_editor_selected_part_preview("muscle", preview_part, 1.0, true)
	if main.component_art_view == null:
		_fail("Editor ComponentArtView is missing.")
		return
	main.component_art_view.visible = true
	main.component_art_view.z_index = 320
	main.component_art_view.queue_redraw()
	for frame in range(18):
		MainScene.PartPreviewTextureCache.process_queue(main, 6)
		RenderingServer.force_draw()
		await process_frame
	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		_fail("Editor runtime probe could not read viewport texture.")
		return
	var image := viewport_texture.get_image()
	if image == null:
		_fail("Editor runtime probe viewport image is null.")
		return
	var err := image.save_png(OUT_PATH)
	if err != OK:
		_fail("Editor runtime probe could not save screenshot to %s, err=%d." % [OUT_PATH, err])
		return
	print("IMAGE2_EDITOR_RUNTIME_SCREENSHOT_PROBE ok %s" % OUT_PATH)
	quit(0)
