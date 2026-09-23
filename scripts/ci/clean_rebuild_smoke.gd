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
        if hero.clean_front == null or hero.clean_side == null or hero.clean_back == null:
            _fail("Hero directional presentation is incomplete")
        hero.clean_facing = Vector2.UP
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
