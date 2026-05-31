extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(MainScene.MOBIUS_SURFACE_TEXTURE_PATH):
		_fail("Mobius surface texture asset is missing: %s" % MainScene.MOBIUS_SURFACE_TEXTURE_PATH)
		return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.mobius_surface_texture == null:
		_fail("Mobius surface texture did not load.")
		return
	if main.mobius_surface_texture.get_size().x < 1024.0 or main.mobius_surface_texture.get_size().y < 512.0:
		_fail("Mobius surface texture should be a wide gameplay-sized asset, got %s" % str(main.mobius_surface_texture.get_size()))
		return
	if String(main.mobius_surface_texture.get_meta("runtime_source_path", "")) != MainScene.MOBIUS_SURFACE_TEXTURE_PATH:
		_fail("Mobius surface texture should use the direct source PNG loader.")
		return
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main._refresh_mobius_surface_view()
	if main.mobius_strip_surface_view == null or not main.mobius_strip_surface_view.visible:
		_fail("Mobius surface view should be visible in battle.")
		return
	if main.mobius_strip_surface_view.surface_texture != main.mobius_surface_texture:
		_fail("Mobius surface view should receive the generated surface texture.")
		return
	if not (main.mobius_strip_surface_view.material is ShaderMaterial):
		_fail("Mobius surface view should use the Mobius shader material.")
		return
	var shader_material := main.mobius_strip_surface_view.material as ShaderMaterial
	if shader_material.get_shader_parameter("surface_texture") != main.mobius_surface_texture:
		_fail("Mobius surface shader should receive the generated surface texture uniform.")
		return
	if not bool(shader_material.get_shader_parameter("surface_texture_enabled")):
		_fail("Mobius surface shader texture sampling should be enabled.")
		return
	main.mobius_strip_surface_view.queue_redraw()
	await process_frame
	print("MOBIUS_SURFACE_TEXTURE_ASSET_PROBE ok size=%s" % str(main.mobius_surface_texture.get_size()))
	quit()
