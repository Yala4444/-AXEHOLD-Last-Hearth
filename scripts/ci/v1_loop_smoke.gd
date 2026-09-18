extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["tutorial_complete"] = true
    GameState.data["v1_tutorial_complete"] = true
    GameState.data["coach_complete"] = true
    GameState.data["weapons_owned"] = ["axes"]
    GameState.data["selected_weapon"] = "axes"

    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Cannot instantiate redesigned GameWorld")
        _finish()
        return

    game.configure(0)
    get_tree().root.add_child(game)
    get_tree().current_scene = game
    await _wait_frames(6)

    if game.player == null or game.hud == null:
        _fail("Redesigned game did not initialize player/HUD")
        await _cleanup(game)
        _finish()
        return

    if game.phase_max < 44.0:
        _fail("Resource-first opening day is too short")
    if game.player.capacity < 24:
        _fail("Starting backpack was not expanded for gathering loop")

    game.player.inventory = {"wood": 9, "stone": 4, "ore": 2}
    game.player.global_position = game.base_position
    game.call("_deposit_and_build", 0.016)
    if int(game.storage["wood"]) != 9 or int(game.storage["stone"]) != 4 or int(game.storage["ore"]) != 2:
        _fail("Backpack did not deposit into visible base storage")
    if game.player.inventory_total() != 0:
        _fail("Backpack was not cleared after deposit")

    game.call("_refresh_hud")
    if not game.hud.backpack_label.text.contains("РЮКЗАК") or not game.hud.storage_label.text.contains("СКЛАД"):
        _fail("HUD does not expose backpack and base storage separately")

    var wall: BuildPad = _pad(game, "wall")
    if wall == null:
        _fail("Palisade blueprint missing")
    else:
        game.storage = {"wood": 20, "stone": 20, "ore": 10}
        game.player.global_position = wall.global_position
        for _i: int in range(5):
            game.call("_deposit_and_build", 0.20)
        if not bool(game.built["wall"]) or not wall.built:
            _fail("Palisade did not complete after visible construction hold")
        if game.base_max_hp <= 270.0:
            _fail("Palisade did not strengthen the hearth")

    var forge: BuildPad = _pad(game, "forge")
    if forge != null:
        var damage_before: float = game.player.damage
        var radius_before: float = game.player.orbit_radius
        game.storage = {"wood": 30, "stone": 30, "ore": 10}
        game.call("_complete_build", forge)
        if game.player.damage <= damage_before or game.player.orbit_radius <= radius_before:
            _fail("Forge does not visibly strengthen weapon power/reach")

    var turret: BuildPad = _pad(game, "turret")
    if turret != null:
        game.storage = {"wood": 30, "stone": 30, "ore": 10}
        game.call("_complete_build", turret)
        game.wave = 1
        game.call("_spawn_enemy", false)
        await _wait_frames(2)
        if not game.enemies.is_empty():
            var target: AxEnemy = game.enemies[0]
            var hp_before: float = target.hp
            game.turret_timer = 0.0
            game.call("_update_turret", 0.1)
            if target.hp >= hp_before or game.turret_shot_time <= 0.0:
                _fail("Tower did not deal damage with visible shot feedback")

    var shrine: BuildPad = _pad(game, "shrine")
    if shrine != null:
        game.storage = {"wood": 30, "stone": 30, "ore": 10}
        game.call("_complete_build", shrine)
        game.base_hp = maxf(1.0, game.base_max_hp - 60.0)
        var hearth_before: float = game.base_hp
        game.phase = "day"
        game.call("_update_building_passives", 1.0)
        if game.base_hp <= hearth_before:
            _fail("Shrine did not regenerate hearth durability")

    if failures.is_empty():
        print("[V1 LOOP] resource -> deposit -> build -> defense validation passed")

    await _cleanup(game)
    _finish()

func _pad(game: GameWorld, kind: String) -> BuildPad:
    for pad: BuildPad in game.pads:
        if pad.build_type == kind:
            return pad
    return null

func _cleanup(game: GameWorld) -> void:
    if get_tree().current_scene == game:
        get_tree().current_scene = self
    if is_instance_valid(game):
        game.queue_free()
    await _wait_frames(4)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1 LOOP] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1 LOOP] %s" % failure)
    get_tree().quit(1)
