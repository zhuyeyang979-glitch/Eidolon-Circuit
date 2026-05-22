extends SceneTree

const GameStateStoreScript = preload("res://scripts/state/game_state_store.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var store = GameStateStoreScript.new()
	if store.revision("editor") != 0:
		_fail("Fresh editor revision should be 0.")
		return
	store.mark_dirty("editor", 4, "hover")
	if store.revision("editor") != 0:
		_fail("mark_dirty must not mutate revision.")
		return
	if store.dirty_flags("editor") != 4:
		_fail("mark_dirty did not preserve dirty flags.")
		return
	store.mutate("editor", "topology", 2)
	if store.revision("editor") != 1:
		_fail("mutate did not advance editor revision.")
		return
	if (store.dirty_flags("editor") & 6) != 6:
		_fail("mutate did not merge dirty flags.")
		return
	store.clear_dirty("editor", 2)
	if store.dirty_flags("editor") != 4:
		_fail("clear_dirty(flags) cleared the wrong flags.")
		return
	store.set_app_mode("editor", "probe")
	if store.app_mode != "editor" or store.revision("global") != 1:
		_fail("set_app_mode did not update global state.")
		return
	print("STATE_STORE_REVISION_PROBE ok")
	quit(0)
