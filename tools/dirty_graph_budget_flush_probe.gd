extends SceneTree

const DirtyGraphScript = preload("res://scripts/state/dirty_graph.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var graph = DirtyGraphScript.new()
	graph.mark("editor", 1, "hover")
	graph.mark("editor", 4, "dashboard")
	graph.mark("saved_units", 2, "page")
	if graph.flags("editor") != 5:
		_fail("DirtyGraph did not merge editor flags.")
		return
	if graph.pending_domains().size() != 2:
		_fail("DirtyGraph did not track pending domains.")
		return
	var started: int = graph.begin_flush("editor")
	graph.finish_flush("editor", started, 1)
	if graph.flags("editor") != 4:
		_fail("DirtyGraph finish_flush did not clear consumed flags only.")
		return
	var remaining: int = graph.consume("editor")
	if remaining != 4 or graph.flags("editor") != 0:
		_fail("DirtyGraph consume did not return remaining flags.")
		return
	if graph.flush_count < 1 or graph.mark_count != 3:
		_fail("DirtyGraph counters are wrong.")
		return
	print("DIRTY_GRAPH_BUDGET_FLUSH_PROBE ok")
	quit(0)
