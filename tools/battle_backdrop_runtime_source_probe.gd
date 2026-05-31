extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _sha256_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	while not file.eof_reached():
		context.update(file.get_buffer(65536))
	return context.finish().hex_encode().to_upper()


func _init() -> void:
	var source_path := MainScene.GENERATED_SPACE_BACKDROP_PATH
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.space_backdrop_texture == null:
		_fail("Runtime fallback space backdrop texture did not load.")
		return
	var texture: Texture2D = main.space_backdrop_texture
	if String(texture.get_meta("runtime_source_loader", "")) != "source_image":
		_fail("Runtime fallback backdrop should be created from source PNG image data, not imported .ctex.")
		return
	if String(texture.get_meta("runtime_source_path", "")) != source_path:
		_fail("Runtime backdrop source path metadata mismatch.")
		return
	if String(texture.resource_path).contains(".godot/imported") or String(texture.resource_path).contains(".ctex"):
		_fail("Runtime backdrop still appears to use imported cache path: %s" % texture.resource_path)
		return
	var backdrop := main.find_child("GeneratedSpaceBackdrop", true, false) as Sprite2D
	if backdrop == null:
		_fail("GeneratedSpaceBackdrop fallback node is missing.")
		return
	if backdrop.texture != texture:
		_fail("GeneratedSpaceBackdrop should use the direct source PNG runtime texture for fallback.")
		return
	main.game_state = MainScene.STATE_BATTLE
	main.mobius_enabled = true
	main._refresh_mobius_surface_view()
	if backdrop.visible:
		_fail("GeneratedSpaceBackdrop fallback should be hidden in active Möbius battle rendering.")
		return
	if main.mobius_surface_texture == null:
		_fail("Mobius surface texture should load alongside the fallback backdrop.")
		return
	print("BATTLE_BACKDROP_RUNTIME_SOURCE_PROBE ok fallback=%s surface=%s loader=%s" % [
		str(texture.get_size()),
		str(main.mobius_surface_texture.get_size()),
		String(texture.get_meta("runtime_source_loader", "")),
	])
	quit(0)
