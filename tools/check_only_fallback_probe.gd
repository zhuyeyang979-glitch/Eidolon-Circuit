extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const FighterScript := preload("res://scripts/fighter.gd")
const AssemblyBoardRendererScript := preload("res://scripts/assembly_board_renderer.gd")
const PartArtScript := preload("res://scripts/part_art.gd")


func _init() -> void:
	var loaded := [
		MainScript,
		FighterScript,
		AssemblyBoardRendererScript,
		PartArtScript,
	]
	for item in loaded:
		if item == null:
			push_error("CHECK_ONLY_FALLBACK_PROBE failed to preload a critical script")
			quit(1)
			return
	print("CHECK_ONLY_FALLBACK_PROBE ok")
	quit(0)
