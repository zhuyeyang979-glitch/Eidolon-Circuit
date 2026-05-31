extends SceneTree


const BACKLOG_PATH := "res://docs/development_backlog.md"
const REQUIRED_ISSUES := [
	"EC-SLIM-001",
	"EC-SLIM-002",
	"EC-SLIM-003",
	"EC-SLIM-004",
	"EC-SLIM-005",
	"EC-SLIM-006",
	"EC-SLIM-007",
	"EC-SLIM-008",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(BACKLOG_PATH):
		_fail("Missing Linear-ready codebase slimdown backlog.")
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(BACKLOG_PATH))
	if text.find("Eidolon Circuit Codebase Slimdown 2026-05-27") < 0:
		_fail("Backlog missing intended Linear epic title.")
	if text.find("Linear-ready") < 0:
		_fail("Backlog should state that it is Linear-ready.")
	for issue_id in REQUIRED_ISSUES:
		if text.find(issue_id) < 0:
			_fail("Backlog missing issue %s." % issue_id)
	for token in [
		"UnitEditorBoardController",
		"SavedUnitLibraryService",
		"FighterMovementModel",
		"MobiusWorld",
		"GitHub Actions",
	]:
		if text.find(token) < 0:
			_fail("Backlog missing implementation boundary token: %s" % token)
	print("CODEBASE_SLIMDOWN_BACKLOG_PROBE ok issues=%d" % REQUIRED_ISSUES.size())
	quit()
