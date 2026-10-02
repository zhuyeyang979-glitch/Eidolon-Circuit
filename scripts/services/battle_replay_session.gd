extends RefCounted
class_name BattleReplaySession

const ReplayFiles = preload("res://scripts/services/battle_replay_file_service.gd")

var mode := "off"
var start_payload: Dictionary = {}
var setup: Dictionary = {}
var input_frames: Array = []
var cursor := 0
var expected_final: Dictionary = {}
var error := ""
var saved_document: Dictionary = {}


func reset() -> void:
    mode = "off"
    start_payload.clear()
    setup.clear()
    input_frames.clear()
    cursor = 0
    expected_final.clear()
    error = ""
    saved_document.clear()


func begin_capture(start: Dictionary, opening_setup: Dictionary) -> void:
    reset()
    mode = "capture"
    start_payload = start.duplicate(true)
    setup = opening_setup.duplicate(true)


func capture_opening(checkpoint_digest: String, match_seconds: float) -> void:
    if mode != "capture" or not input_frames.is_empty():
        return
    setup["initial_checkpoint_digest"] = checkpoint_digest
    setup["match_seconds"] = match_seconds


func append_step(serialized_frame: String) -> void:
    if mode == "capture":
        input_frames.append(serialized_frame)


func begin_playback(payload: Dictionary) -> void:
    reset()
    mode = "playback"
    start_payload = Dictionary(payload.get("start", {})).duplicate(true)
    setup = Dictionary(payload.get("setup", {})).duplicate(true)
    input_frames = Array(payload.get("input_frames", [])).duplicate(true)
    expected_final = Dictionary(payload.get("final", {})).duplicate(true)


func take_playback_frame(input_service) -> Dictionary:
    if mode != "playback" or cursor >= input_frames.size():
        error = "Replay input ended before the battle result."
        return {}
    var frame: Dictionary = input_service.deserialize_input_frame(String(input_frames[cursor]))
    cursor += 1
    return frame


func complete(contact_complete: bool, checkpoint_digest: String, winner: int, reason: String) -> bool:
    if mode != "playback":
        error = "Replay was not active."
    elif cursor != input_frames.size() or not contact_complete:
        error = "Replay events ended at the wrong simulation step."
    elif checkpoint_digest != String(expected_final.get("checkpoint_digest", "")) or winner != int(expected_final.get("winner", 0)) or reason != String(expected_final.get("reason", "")):
        error = "Replay result differs from the saved match."
    return error == ""


func build_document(contact_tape: Dictionary, final_state: Dictionary) -> Dictionary:
    if mode != "capture":
        return {}
    if saved_document.is_empty():
        saved_document = {
            "schema_version": ReplayFiles.SCHEMA_VERSION,
            "ruleset_id": ReplayFiles.RULESET_ID,
            "start": start_payload.duplicate(true),
            "setup": setup.duplicate(true),
            "input_frames": input_frames.duplicate(true),
            "contact_tape": contact_tape.duplicate(true),
            "final": final_state.duplicate(true),
        }
    return saved_document.duplicate(true)
