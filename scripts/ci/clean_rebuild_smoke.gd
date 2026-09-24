extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Clean GameWorld did not instantiate")
        _finish()
        return

    game.configure(0,1,"expedition")
    add_child(game)
    await _frames(5)

    if not (game is AXEHOLDCleanWorld):
        _fail("game.tscn is not routed to AXEHOLDCleanWorld")
    if game.player == null or not (game.player is AXEHOLDCleanPlayer):
        _fail("Clean player was not created")
    if game.hud == null:
        _fail("Clean HUD was not created")
    if game.resources.size() < 35:
        _fail("Clean world did not populate enough grounded resources")
    if game.pads.size() != 4:
        _fail("Clean build pads were not created")
    if game.camera == null:
        _fail("Clean camera was not created")

    if game.player is AXEHOLDCleanPlayer:
        var hero := game.player as AXEHOLDCleanPlayer
        if not hero.production_ready:
            _fail("Hero production animation set is incomplete")
        if hero.visual_v2_side_walk.size() < 6 or hero.visual_v2_front_walk.size() < 4 or hero.visual_v2_back_walk.size() < 4:
            _fail("Hero directional walk cycles are incomplete")
        hero.visual_facing_direction = Vector2.UP
        hero.queue_redraw()
        await _frames(2)

    var resource_ok: bool = false
    for spot: ResourceSpot in game.resources:
        if spot is AXEHOLDCleanResource:
            resource_ok = true
            break
    if not resource_ok:
        _fail("Clean resources are not in use")

    game.call("_begin_clean_night")
    await _frames(3)
    if game.phase != "night" or game.wave != 1:
        _fail("Clean day/night transition failed")

    game.call("_spawn_clean_enemy", false)
    await _frames(2)
    var enemy_ok: bool = false
    for enemy: AxEnemy in game.enemies:
        if enemy is AXEHOLDCleanEnemy:
            enemy_ok = true
            break
    if not enemy_ok:
        _fail("Clean enemy runtime did not spawn")

    game.call("_spawn_clean_enemy", true)
    await _frames(2)
    var boss_ok: bool = false
    for enemy: AxEnemy in game.enemies:
        if is_instance_valid(enemy) and enemy.boss:
            boss_ok = true
            break
    if not boss_ok:
        _fail("Clean boss did not spawn")

    game.storage["wood"] = 99
    game.storage["stone"] = 99
    game.storage["ore"] = 99
    var pad: BuildPad = game.pads[0]
    if not pad.can_build(game.storage):
        _fail("Clean build economy is not functional")
    else:
        game.player.global_position = pad.global_position
        game.call("_update_build_loop", 0.016)
        if game.clean_focused_pad != pad:
            _fail("Context build focus did not select the nearby pad")
        if game.hud.context_button == null or not game.hud.context_button.visible:
            _fail("Context mobile build button did not appear")
        game.call("_on_clean_hud_action", "clean_build_" + pad.build_type)
        if not pad.built:
            _fail("Context mobile build action did not construct the pad")

    game.queue_free()
    await _frames(3)
    _finish()

func _frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    push_error("[CLEAN REBUILD] " + message)

func _finish() -> void:
    if failures.is_empty():
        print("[CLEAN REBUILD] AXEHOLD clean runtime passed")
        get_tree().quit(0)
    else:
        print("[CLEAN REBUILD] failures: %d" % failures.size())
        get_tree().quit(1)
