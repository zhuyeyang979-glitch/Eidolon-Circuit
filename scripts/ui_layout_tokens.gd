extends RefCounted
class_name UILayoutTokens

const DESIGN_SIZE := Vector2(1280.0, 720.0)

const MARGIN_L := 42.0
const MARGIN_R := 42.0
const MARGIN_T := 24.0
const MARGIN_B := 24.0
const GAP_X := 12.0
const GAP_Y := 12.0
const PANEL_PAD := 18.0
const BUTTON_H := 28.0
const SMALL_BUTTON_H := 24.0

const LEFT_SIDEBAR_RECT := Rect2(Vector2(18.0, 104.0), Vector2(164.0, 508.0))
const RIGHT_SIDEBAR_RECT := Rect2(Vector2(932.0, 94.0), Vector2(278.0, 590.0))
const MAIN_BOARD_RECT := Rect2(Vector2(190.0, 166.0), Vector2(726.0, 476.0))
const TOP_DOCK_RECT := Rect2(Vector2(190.0, 24.0), Vector2(726.0, 132.0))
const BOTTOM_BAR_RECT := Rect2(Vector2(18.0, 650.0), Vector2(898.0, 50.0))
const MODAL_Y_OFFSET := -10.0

const MENU_HEADER_RECT := Rect2(Vector2(42.0, 34.0), Vector2(1136.0, 130.0))
const MENU_TITLE_RECT := Rect2(Vector2(64.0, 40.0), Vector2(690.0, 56.0))
const MENU_SUBTITLE_RECT := Rect2(Vector2(68.0, 112.0), Vector2(520.0, 28.0))
const MENU_ACCENT_RECT := Rect2(Vector2(68.0, 148.0), Vector2(346.0, 4.0))
const MENU_CALLSIGN_RECT := Rect2(Vector2(656.0, 112.0), Vector2(480.0, 28.0))
const MENU_LIST_PANEL_RECT := Rect2(Vector2(54.0, 184.0), Vector2(438.0, 430.0))
const MENU_INFO_PANEL_RECT := Rect2(Vector2(536.0, 184.0), Vector2(620.0, 226.0))
const MENU_DESCRIPTION_RECT := Rect2(Vector2(570.0, 212.0), Vector2(552.0, 138.0))
const MENU_STATUS_RECT := Rect2(Vector2(570.0, 354.0), Vector2(552.0, 42.0))
const MENU_TELEMETRY_RECT := Rect2(Vector2(540.0, 438.0), Vector2(604.0, 26.0))
const MENU_HELP_RECT := Rect2(Vector2(64.0, 656.0), Vector2(980.0, 28.0))
const MENU_BUTTON_ORIGIN := Vector2(82.0, 204.0)
const MENU_BUTTON_SIZE := Vector2(382.0, 44.0)
const MENU_BUTTON_ROW_GAP := 12.0
const MENU_AI_SEAT_PANEL_RECT := Rect2(Vector2(536.0, 466.0), Vector2(620.0, 114.0))
const MENU_AI_SEAT_LABEL_RECT := Rect2(Vector2(566.0, 476.0), Vector2(560.0, 24.0))
const MENU_AI_SEAT_ORIGIN := Vector2(566.0, 512.0)
const MENU_AI_SEAT_SIZE := Vector2(170.0, 48.0)
const MENU_AI_SEAT_GAP := Vector2(20.0, 0.0)

const PAGE_OPTIONS_RECT := Rect2(Vector2(952.0, 72.0), Vector2(246.0, 228.0))
const PAGE_OPTIONS_ACCENT_RECT := Rect2(Vector2(16.0, 42.0), Vector2(214.0, 2.0))
const PAGE_OPTIONS_TITLE_RECT := Rect2(Vector2(16.0, 12.0), Vector2(214.0, 26.0))
const PAGE_OPTIONS_BUTTON_ORIGIN := Vector2(18.0, 56.0)
const PAGE_OPTIONS_BUTTON_SIZE := Vector2(210.0, 28.0)
const PAGE_OPTIONS_BUTTON_ROW_GAP := 4.0

const BATTLE_RUNTIME_OPTIONS_RECT := Rect2(Vector2(856.0, 252.0), Vector2(330.0, 340.0))
const BATTLE_RUNTIME_TITLE_RECT := Rect2(Vector2(18.0, 12.0), Vector2(294.0, 28.0))
const BATTLE_RUNTIME_BUTTON_ORIGIN := Vector2(24.0, 52.0)
const BATTLE_RUNTIME_BUTTON_SIZE := Vector2(282.0, 28.0)
const BATTLE_RUNTIME_BUTTON_ROW_GAP := 6.0

const FORMAT_SELECT_PANEL_SIZE := Vector2(708.0, 360.0)
const FORMAT_SELECT_ACCENT_RECT := Rect2(Vector2(40.0, 64.0), Vector2(628.0, 3.0))
const FORMAT_SELECT_TITLE_RECT := Rect2(Vector2(40.0, 18.0), Vector2(628.0, 42.0))
const FORMAT_SELECT_HINT_RECT := Rect2(Vector2(40.0, 76.0), Vector2(628.0, 44.0))
const FORMAT_SELECT_BUTTON_ORIGIN := Vector2(74.0, 138.0)
const FORMAT_SELECT_BUTTON_SIZE := Vector2(560.0, 54.0)
const FORMAT_SELECT_BUTTON_ROW_GAP := 12.0

const LOADING_PANEL_SIZE := Vector2(588.0, 172.0)
const LOADING_TITLE_RECT := Rect2(Vector2(34.0, 28.0), Vector2(520.0, 34.0))
const LOADING_STAGE_RECT := Rect2(Vector2(46.0, 72.0), Vector2(496.0, 28.0))
const LOADING_PROGRESS_RECT := Rect2(Vector2(78.0, 116.0), Vector2(432.0, 18.0))
const LOADING_PERCENT_RECT := Rect2(Vector2(78.0, 140.0), Vector2(432.0, 20.0))

const SETTINGS_TITLE_RECT := Rect2(Vector2(72.0, 42.0), Vector2(480.0, 44.0))
const SETTINGS_OPTIONS_BUTTON_RECT := Rect2(Vector2(1028.0, 54.0), Vector2(152.0, 36.0))
const SETTINGS_CATEGORY_ORIGIN := Vector2(72.0, 100.0)
const SETTINGS_CATEGORY_SIZE := Vector2(164.0, 34.0)
const SETTINGS_CATEGORY_GAP := Vector2(12.0, 0.0)
const SETTINGS_SCROLL_RECT := Rect2(Vector2(72.0, 148.0), Vector2(1088.0, 472.0))
const SETTINGS_STATUS_RECT := Rect2(Vector2(92.0, 632.0), Vector2(820.0, 44.0))
const SETTINGS_RESET_BUTTON_RECT := Rect2(Vector2(932.0, 632.0), Vector2(228.0, 38.0))
const SETTINGS_HELP_RECT := Rect2(Vector2(92.0, 682.0), Vector2(940.0, 24.0))

const SCOUT_TITLE_RECT := Rect2(Vector2(54.0, 28.0), Vector2(480.0, 46.0))
const SCOUT_TIMER_RECT := Rect2(Vector2(890.0, 22.0), Vector2(300.0, 28.0))
const SCOUT_START_BUTTON_RECT := Rect2(Vector2(874.0, 64.0), Vector2(142.0, 24.0))
const SCOUT_OPTIONS_BUTTON_RECT := Rect2(Vector2(1030.0, 64.0), Vector2(148.0, 24.0))
const SCOUT_HINT_RECT := Rect2(Vector2(64.0, 78.0), Vector2(760.0, 22.0))


static func left_sidebar_rect() -> Rect2:
	return LEFT_SIDEBAR_RECT


static func right_sidebar_rect() -> Rect2:
	return RIGHT_SIDEBAR_RECT


static func main_board_rect() -> Rect2:
	return MAIN_BOARD_RECT


static func top_dock_rect() -> Rect2:
	return TOP_DOCK_RECT


static func bottom_bar_rect() -> Rect2:
	return BOTTOM_BAR_RECT


static func modal_rect(rect_size: Vector2, offset := Vector2.ZERO) -> Rect2:
	var position := (DESIGN_SIZE - rect_size) * 0.5 + Vector2(0.0, MODAL_Y_OFFSET) + offset
	return Rect2(position, rect_size)


static func local_rect(rect_size: Vector2) -> Rect2:
	return Rect2(Vector2.ZERO, rect_size)


static func design_scale(viewport_size: Vector2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)


static func design_offset(viewport_size: Vector2) -> Vector2:
	var scale := design_scale(viewport_size)
	return (viewport_size - DESIGN_SIZE * scale) * 0.5


static func to_screen_rect(rect: Rect2, viewport_size: Vector2 = DESIGN_SIZE) -> Rect2:
	var scale := design_scale(viewport_size)
	return Rect2(design_offset(viewport_size) + rect.position * scale, rect.size * scale)


static func to_local_rect(rect: Rect2, viewport_size: Vector2 = DESIGN_SIZE) -> Rect2:
	var scale := design_scale(viewport_size)
	return Rect2(rect.position * scale, rect.size * scale)


static func page_options_rect() -> Rect2:
	return PAGE_OPTIONS_RECT


static func battle_runtime_options_rect() -> Rect2:
	return BATTLE_RUNTIME_OPTIONS_RECT


static func row_rect(origin: Vector2, item_size: Vector2, index: int, gap_y: float = 0.0) -> Rect2:
	var y := origin.y + float(index) * (item_size.y + gap_y)
	return Rect2(Vector2(origin.x, y), item_size)


static func grid_rect(origin: Vector2, item_size: Vector2, index: int, columns: int, gap_x: float = 0.0, gap_y: float = 0.0) -> Rect2:
	var safe_columns := maxi(1, columns)
	var column := index % safe_columns
	var row := floori(float(index) / float(safe_columns))
	var position := origin + Vector2(float(column) * (item_size.x + gap_x), float(row) * (item_size.y + gap_y))
	return Rect2(position, item_size)


static func main_menu_header_rect() -> Rect2:
	return MENU_HEADER_RECT


static func main_menu_title_rect() -> Rect2:
	return MENU_TITLE_RECT


static func main_menu_subtitle_rect() -> Rect2:
	return MENU_SUBTITLE_RECT


static func main_menu_accent_rect() -> Rect2:
	return MENU_ACCENT_RECT


static func main_menu_callsign_rect() -> Rect2:
	return MENU_CALLSIGN_RECT


static func main_menu_list_panel_rect() -> Rect2:
	return MENU_LIST_PANEL_RECT


static func main_menu_info_panel_rect() -> Rect2:
	return MENU_INFO_PANEL_RECT


static func main_menu_description_rect() -> Rect2:
	return MENU_DESCRIPTION_RECT


static func main_menu_status_rect() -> Rect2:
	return MENU_STATUS_RECT


static func main_menu_telemetry_rect() -> Rect2:
	return MENU_TELEMETRY_RECT


static func main_menu_help_rect() -> Rect2:
	return MENU_HELP_RECT


static func main_menu_button_rect(index: int) -> Rect2:
	return row_rect(MENU_BUTTON_ORIGIN, MENU_BUTTON_SIZE, index, MENU_BUTTON_ROW_GAP)


static func main_menu_ai_seat_panel_rect() -> Rect2:
	return MENU_AI_SEAT_PANEL_RECT


static func main_menu_ai_seat_label_rect() -> Rect2:
	return MENU_AI_SEAT_LABEL_RECT


static func main_menu_ai_seat_button_rect(index: int) -> Rect2:
	return grid_rect(MENU_AI_SEAT_ORIGIN, MENU_AI_SEAT_SIZE, index, 3, MENU_AI_SEAT_GAP.x, MENU_AI_SEAT_GAP.y)


static func page_options_accent_rect() -> Rect2:
	return PAGE_OPTIONS_ACCENT_RECT


static func page_options_title_rect() -> Rect2:
	return PAGE_OPTIONS_TITLE_RECT


static func page_options_button_rect(index: int) -> Rect2:
	return row_rect(PAGE_OPTIONS_BUTTON_ORIGIN, PAGE_OPTIONS_BUTTON_SIZE, index, PAGE_OPTIONS_BUTTON_ROW_GAP)


static func battle_runtime_title_rect() -> Rect2:
	return BATTLE_RUNTIME_TITLE_RECT


static func battle_runtime_button_rect(index: int) -> Rect2:
	return row_rect(BATTLE_RUNTIME_BUTTON_ORIGIN, BATTLE_RUNTIME_BUTTON_SIZE, index, BATTLE_RUNTIME_BUTTON_ROW_GAP)


static func format_select_panel_rect() -> Rect2:
	return modal_rect(FORMAT_SELECT_PANEL_SIZE, Vector2.ZERO)


static func format_select_accent_rect() -> Rect2:
	return FORMAT_SELECT_ACCENT_RECT


static func format_select_title_rect() -> Rect2:
	return FORMAT_SELECT_TITLE_RECT


static func format_select_hint_rect() -> Rect2:
	return FORMAT_SELECT_HINT_RECT


static func format_select_button_rect(index: int) -> Rect2:
	return row_rect(FORMAT_SELECT_BUTTON_ORIGIN, FORMAT_SELECT_BUTTON_SIZE, index, FORMAT_SELECT_BUTTON_ROW_GAP)


static func loading_panel_rect() -> Rect2:
	return modal_rect(LOADING_PANEL_SIZE, Vector2.ZERO)


static func loading_title_rect() -> Rect2:
	return LOADING_TITLE_RECT


static func loading_stage_rect() -> Rect2:
	return LOADING_STAGE_RECT


static func loading_progress_rect() -> Rect2:
	return LOADING_PROGRESS_RECT


static func loading_percent_rect() -> Rect2:
	return LOADING_PERCENT_RECT


static func settings_title_rect() -> Rect2:
	return SETTINGS_TITLE_RECT


static func settings_options_button_rect() -> Rect2:
	return SETTINGS_OPTIONS_BUTTON_RECT


static func settings_category_button_rect(index: int) -> Rect2:
	return grid_rect(SETTINGS_CATEGORY_ORIGIN, SETTINGS_CATEGORY_SIZE, index, 6, SETTINGS_CATEGORY_GAP.x, SETTINGS_CATEGORY_GAP.y)


static func settings_scroll_rect() -> Rect2:
	return SETTINGS_SCROLL_RECT


static func settings_status_rect() -> Rect2:
	return SETTINGS_STATUS_RECT


static func settings_reset_button_rect() -> Rect2:
	return SETTINGS_RESET_BUTTON_RECT


static func settings_help_rect() -> Rect2:
	return SETTINGS_HELP_RECT


static func scout_title_rect() -> Rect2:
	return SCOUT_TITLE_RECT


static func scout_timer_rect() -> Rect2:
	return SCOUT_TIMER_RECT


static func scout_start_button_rect() -> Rect2:
	return SCOUT_START_BUTTON_RECT


static func scout_options_button_rect() -> Rect2:
	return SCOUT_OPTIONS_BUTTON_RECT


static func scout_hint_rect() -> Rect2:
	return SCOUT_HINT_RECT
