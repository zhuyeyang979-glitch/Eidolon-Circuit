extends SceneTree

const README_PATH := "res://README.md"
const TODO_PATH := "res://docs/TODO.md"
const SUMMARY_PATH := "res://docs/reports/2026-06-24-star-soul-loop-gameplay-polish-summary.md"

var failed := false


func _init() -> void:
	var readme := FileAccess.get_file_as_string(ProjectSettings.globalize_path(README_PATH))
	var todo := FileAccess.get_file_as_string(ProjectSettings.globalize_path(TODO_PATH))
	var summary := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SUMMARY_PATH))

	for token in [
		"## Current Implementation Status",
		"Implemented in the current prototype:",
		"Designed but not yet connected to battle/editor runtime:",
		"## Compatibility Glossary",
		"`torso`, `is_torso`",
		"`limb_muscle`, `muscle`, `joint`",
		"`booster`",
		"`laser` in projectile damage paths",
		"docs/plans/2026-06-24-unit-editor-legality-roadmap.md",
		"docs/plans/2026-06-24-hardware-fault-runtime.md",
		"docs/plans/2026-06-24-source-code-priority-ui.md",
		"docs/reports/2026-06-24-star-soul-loop-balance-examples.md",
	]:
		_require(readme.find(token) >= 0, "README reconciliation token missing: %s" % token)

	for token in [
		"## Star Soul Loop Gameplay Follow-Ups",
		"Unit editor legality:",
		"Hardware fault runtime:",
		"Source Code priority:",
		"Mode families:",
		"Combat contract cleanup:",
	]:
		_require(todo.find(token) >= 0, "TODO reconciliation token missing: %s" % token)

	for token in ["## 已完成", "## 后续实现", "## 兼容策略", "Source Code", "normal -> faulted -> destroyed"]:
		_require(summary.find(token) >= 0, "Summary reconciliation token missing: %s" % token)

	if failed:
		quit(1)
		return
	print("STAR_SOUL_LOOP_DOCS_RECONCILIATION_PROBE ok")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
