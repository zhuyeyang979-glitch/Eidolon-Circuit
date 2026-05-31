extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _hidden_or_empty(node: Node) -> bool:
	if node == null:
		return true
	if node is CanvasItem and not bool(node.visible):
		return true
	if node is Label and String(node.text).strip_edges() != "":
		return false
	return true


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	for node_name in ["EditorTitle", "EditorHelp", "BoardTitle", "CanvasToolsTitle", "BoardZoomTitle", "CanvasTopologyText"]:
		var node: Node = main.editor_layer.find_child(node_name, true, false)
		if not _hidden_or_empty(node):
			_fail("%s should be hidden or empty in the fullscreen Unit Edit layout." % node_name)
	print("UNIT_EDITOR_NO_HEADER_HELP_PROBE ok")
	quit()
