extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []
var snapshot: Dictionary = {}

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    snapshot = GameState.data.duplicate(true)
    GameState.data = GameState.defaults()
    GameState.data["coach_complete"] = true
    GameState.data["tutorial_complete"] = true
    GameState.visual_preview_v2 = true

    for path: String in AxPlayer.VISUAL_V2_TOOL_PATHS:
        if not ResourceLoader.exists(path):
            _fail("Missing orbit tool asset: " + path)
    if not ResourceLoader.exists(AxPlayer.VISUAL_V2_HERO_PATH):
        _fail("Missing production hero asset")

    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    await _wait_frames(8)
    world.set_process(false)

    if not world.visual_v2_enabled:
        _fail("Full expedition did not receive the visual preview flag")
    if world.player == null or not world.player.visual_v2_enabled:
        _fail("Player production-art rig is not enabled")
    elif world.player.visual_v2_tools.size() != 4:
        _fail("Preview must load exactly four autonomous tools")
    elif world.player.axes != 4:
        _fail("Preview orbit contract must expose exactly four tools")
    elif world.player.visual_v2_hero == null:
        _fail("Production hero texture failed to load")

    world.queue_free()
    await _wait_frames(3)
    GameState.visual_preview_v2 = false
    GameState.data = snapshot
    _finish()

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.26 VISUAL V2] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        print("V1.26 VISUAL V2 FULL EXPEDITION SMOKE PASSED")
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.26 VISUAL V2] %s" % failure)
    get_tree().quit(1)
