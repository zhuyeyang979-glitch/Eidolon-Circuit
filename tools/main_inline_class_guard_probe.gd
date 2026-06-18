extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"

const ALLOWED_INLINE_CLASSES := {}

const EXTRACTED_INLINE_CLASSES := [
	"BackdropView",
	"SortieThumbView",
	"CockpitHudView",
	"BattleInstrumentGaugeView",
	"BattleMinimapView",
	"BattleActionDiagnosticsView",
	"BattlePartPreviewView",
	"TrainingEntryIntroView",
	"PartDragGhostView",
	"ComponentArtView",
	"HitEffect",
	"ComboRippleEffect",
	"ProjectileTraceEffect",
	"SalvoLandingPreviewEffect",
	"LaserAimTelegraphEffect",
	"TrueBulletTargetLockEffect",
	"BlindZoneEffect",
	"FieldAuraEffect",
	"CoinPickupEffect",
	"IdentityTransferEffect",
	"BattleContactVfxPool",
	"MobiusStripSurfaceView",
	"MobiusStardustBandView",
	"PartPreviewTextureRenderCanvas",
	"PartPreviewTextureCache",
	"PartPreviewIconView",
	"CatalogCardTextLayer",
	"CatalogCardBodyTextureRenderCanvas",
	"CatalogCardBodyTextureCache",
	"CatalogCardRetainedItem",
	"PartCatalogCardButton",
	"EditorStatsRailView",
	"EditorPartHoverPopupView",
	"ScoutUnitDetailView",
	"UnitEditorPowerDockView",
	"EngineMomentumAllocationPanelView",
	"TorsoDetailPanelView",
	"AssemblyBoardRenderLayer",
	"AssemblyBoardRenderComponentItem",
	"AssemblyBoardRenderItem",
	"AssemblyBoardView",
]

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _inline_class_names(source: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in source.split("\n"):
		var line := String(raw_line).strip_edges()
		if not line.begins_with("class ") or not line.ends_with(":"):
			continue
		var name := line.substr(6, line.length() - 7).strip_edges()
		if name.find(" ") >= 0 or name.find("\t") >= 0:
			continue
		result.append(name)
	return result


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	if source.is_empty():
		_fail("main.gd source is empty or missing.")
	var inline_classes := _inline_class_names(source)
	if inline_classes.is_empty() and not ALLOWED_INLINE_CLASSES.is_empty():
		_fail("Inline class guard expected existing deferred inline classes in main.gd.")
	for inline_class_name in inline_classes:
		if not ALLOWED_INLINE_CLASSES.has(inline_class_name):
			_fail("New inline class in main.gd must be extracted or explicitly justified in the guard allowlist: %s" % inline_class_name)
	for extracted_class_name in EXTRACTED_INLINE_CLASSES:
		if source.find("\nclass %s:" % extracted_class_name) >= 0:
			_fail("Extracted class should not be reintroduced inline in main.gd: %s" % extracted_class_name)
	if not failures.is_empty():
		print("MAIN_INLINE_CLASS_GUARD_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("MAIN_INLINE_CLASS_GUARD_PROBE ok allowed=%d active=%d extracted=%d" % [ALLOWED_INLINE_CLASSES.size(), inline_classes.size(), EXTRACTED_INLINE_CLASSES.size()])
	quit(0)
