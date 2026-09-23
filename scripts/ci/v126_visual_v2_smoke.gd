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
    if not ResourceLoader.exists(AxPlayer.VISUAL_V2_SPEAR_PATH):
        _fail("Missing Root Spear asset")
    for frame_id: String in AxPlayer.VISUAL_V2_FRAME_PATHS:
        if not ResourceLoader.exists(str(AxPlayer.VISUAL_V2_FRAME_PATHS[frame_id])):
            _fail("Missing coherent hero frame: " + frame_id)
    if not ResourceLoader.exists(AxPlayer.VISUAL_V2_HERO_PATH):
        _fail("Missing production hero asset")
    for enemy_role: String in AxEnemy.VISUAL_GATE_WALK_PATHS:
        var enemy_walk_path: String = str(AxEnemy.VISUAL_GATE_WALK_PATHS[enemy_role])
        if not ResourceLoader.exists(enemy_walk_path):
            _fail("Missing Visual Gate enemy walk strip: " + enemy_role)

    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    await _wait_frames(8)
    world.set_process(false)

    if not world.visual_v2_enabled:
        _fail("Full expedition did not receive the visual preview flag")
    if world.player == null or not world.player.visual_v2_enabled:
        _fail("Player production-art animation is not enabled")
    elif world.player.visual_v2_tools.size() != 4:
        _fail("Preview must load the four available weapon-family assets")
    elif world.player.visual_v2_frames.size() != 6:
        _fail("Production hero must load all six coherent animation frames")
    elif world.player.visual_v2_side_walk.size() != 6:
        _fail("VG-2 side walk must use six coherent stride frames")
    elif world.player.visual_v2_frame_layouts.size() < 15:
        _fail("VG-2 did not build normalized frame layouts")
    elif world.player.weapon_style != "axes":
        _fail("Preview changed the equipped weapon profile")
    elif int(world.player.call("_visual_v2_orbit_count")) != world.player.axes:
        _fail("Visible orbit does not match the equipped weapon count")
    elif world.player.visual_v2_hero == null:
        _fail("Production hero texture failed to load")
    if world.visual_gate_fx == null or not is_instance_valid(world.visual_gate_fx):
        _fail("Visual Gate FX layer was not created for preview run")
    if not ResourceLoader.exists(GameWorld.VISUAL_GATE_HEARTH_ART_PATH):
        _fail("Visual Gate hearth animation asset is missing")
    else:
        var hearth_texture := ResourceLoader.load(GameWorld.VISUAL_GATE_HEARTH_ART_PATH) as Texture2D
        if hearth_texture == null or hearth_texture.get_width() < GameWorld.VISUAL_GATE_HEARTH_FRAMES:
            _fail("Visual Gate hearth animation asset is invalid")

    var preview_enemy := AxEnemy.new()
    preview_enemy.configure("runner", 1.0, 1, Color.WHITE, false, 0)
    preview_enemy.set_visual_gate(true)
    if not preview_enemy.visual_gate_enabled:
        _fail("Visual Gate enemy styling was not enabled")
    preview_enemy.queue_free()
    for layout_key: String in world.player.visual_v2_frame_layouts:
        var layout: Dictionary = world.player.visual_v2_frame_layouts[layout_key]
        if absf(float(layout.get("target_height", 0.0)) - AxPlayer.VISUAL_V2_TARGET_HEIGHT) > 0.01:
            _fail("VG-2 frame escaped the canonical body height: " + layout_key)
            break
        if absf(float(layout.get("foot_y", 0.0)) - AxPlayer.VISUAL_V2_FOOT_Y) > 0.01:
            _fail("VG-2 frame escaped the canonical foot baseline: " + layout_key)
            break

    world.queue_free()
    await _wait_frames(3)

    GameState.visual_preview_v2 = false
    var baseline: GameWorld = GameScene.instantiate() as GameWorld
    baseline.configure(0, 1, "expedition")
    add_child(baseline)
    await _wait_frames(6)
    baseline.set_process(false)
    if baseline.visual_v2_enabled:
        _fail("Stable expedition accidentally inherited Visual Gate mode")
    if baseline.visual_gate_fx != null and is_instance_valid(baseline.visual_gate_fx):
        _fail("Stable expedition created Visual Gate FX")
    baseline.queue_free()
    await _wait_frames(3)

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
