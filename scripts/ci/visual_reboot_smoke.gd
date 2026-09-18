extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["tutorial_complete"] = true
    GameState.data["v1_tutorial_complete"] = true
    GameState.data["coach_complete"] = true

    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Cannot instantiate GameWorld")
        _finish()
        return

    game.configure(0)
    get_tree().root.add_child(game)
    get_tree().current_scene = game
    await _wait_frames(5)

    if game.core_fx == null or not is_instance_valid(game.core_fx):
        _fail("CoreFX presentation layer missing")

    if game.hud == null:
        _fail("HUD missing")
    else:
        if game.hud.build_panel.size.x > 210.0:
            _fail("Build context panel regressed to oversized prototype UI")
        if game.hud.backpack_label == null or not game.hud.backpack_label.text.contains("РЮКЗАК"):
            _fail("Compact backpack HUD missing")
        if game.hud.storage_label == null or not game.hud.storage_label.text.contains("СКЛАД"):
            _fail("Compact hearth storage HUD missing")
        if _contains_button_text(game.hud.root, "ВЫХОД"):
            _fail("Persistent EXIT button returned to gameplay HUD")

    var wall: BuildPad = null
    for pad: BuildPad in game.pads:
        if pad.build_type == "wall":
            wall = pad
            break
    if wall == null:
        _fail("Palisade blueprint missing")
    else:
        wall.set_context_state(true, true)
        if not wall.affordable or not wall.focused:
            _fail("In-world blueprint focus/affordability state missing")

    if game.phase != "day" or game.wave != 0:
        _fail("Fresh visual slice must start in clean day zero")

    if failures.is_empty():
        print("[VISUAL] compact HUD, CoreFX and world-blueprint validation passed")

    if get_tree().current_scene == game:
        get_tree().current_scene = self
    game.queue_free()
    await _wait_frames(3)
    _finish()

func _contains_button_text(node: Node, text_value: String) -> bool:
    if node is Button and (node as Button).text == text_value:
        return true
    for child: Node in node.get_children():
        if _contains_button_text(child, text_value):
            return true
    return false

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[VISUAL] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[VISUAL] %s" % failure)
    get_tree().quit(1)
