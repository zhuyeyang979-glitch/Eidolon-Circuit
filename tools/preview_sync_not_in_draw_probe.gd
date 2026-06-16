extends SceneTree


const MAIN_PATH := "res://scripts/main.gd"
const EXTRACTED_CLASS_PATHS := {
	"PartCatalogCardButton": "res://scripts/views/catalog/part_catalog_card_button.gd",
	"PartDragGhostView": "res://scripts/views/part_drag_ghost_view.gd",
	"EditorPartHoverPopupView": "res://scripts/views/editor/editor_part_hover_popup_view.gd",
}

var failures: Array[String] = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _class_block(source: String, klass: String) -> String:
	var start := source.find("class %s" % klass)
	if start < 0:
		start = source.find("class_name %s" % klass)
	if start < 0:
		return ""
	var next := source.find("\nclass ", start + 1)
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _first_draw_block(class_source: String) -> String:
	var start := class_source.find("func _draw() -> void:")
	if start < 0:
		return ""
	var next := class_source.length()
	for marker in ["\n\tfunc ", "\nfunc "]:
		var marker_pos := class_source.find(marker, start + 1)
		if marker_pos >= 0 and marker_pos < next:
			next = marker_pos
	return class_source.substr(start, next - start)


func _init() -> void:
	var source := FileAccess.get_file_as_string(MAIN_PATH)
	if source.is_empty():
		_fail("Unable to read main.gd.")
	var checked := 0
	for klass in ["PartCatalogCardButton", "PartDragGhostView", "EditorPartHoverPopupView"]:
		var block := _class_block(source, klass)
		if block.is_empty() and EXTRACTED_CLASS_PATHS.has(klass):
			var extracted_source := FileAccess.get_file_as_string(String(EXTRACTED_CLASS_PATHS[klass]))
			if extracted_source.find("class_name %s" % klass) >= 0:
				block = extracted_source
		if block.is_empty():
			_fail("%s missing." % klass)
		var draw_block := _first_draw_block(block)
		if draw_block.is_empty():
			_fail("%s._draw missing." % klass)
		if draw_block.contains("_sync_preview_icon"):
			_fail("%s._draw still synchronizes preview state." % klass)
		if klass != "PartDragGhostView" and draw_block.contains("AssemblyBoardRenderer.draw_part_preview"):
			_fail("%s._draw still calls full preview renderer." % klass)
		checked += 1
	if not failures.is_empty():
		print("PREVIEW_SYNC_NOT_IN_DRAW_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("PREVIEW_SYNC_NOT_IN_DRAW_PROBE ok checked=%d" % checked)
	quit(0)
