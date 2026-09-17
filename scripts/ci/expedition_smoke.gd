extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    await get_tree().process_frame
    _prepare_state()

    var director: Node = get_tree().root.get_node_or_null("ExpeditionDirector")
    if director == null:
        _fail("ExpeditionDirector autoload is missing")
        _finish()
        return

    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Cannot instantiate GameWorld")
        _finish()
        return

    game.configure(0)
    get_tree().root.add_child(game)
    get_tree().current_scene = game
    await _wait_frames(8)

    if game.player == null or game.hud == null:
        _fail("GameWorld did not initialize player/HUD")
        await _cleanup_game(game)
        _finish()
        return

    if director.get("world") != game:
        await _wait_frames(6)
    if director.get("world") != game:
        _fail("ExpeditionDirector did not attach to GameWorld")

    game.hud.hide_modal()
    game.phase = "night"
    game.wave = 1
    game.spawn_left = 99
    game.spawn_timer = 99.0

    _test_elite_enemy(game, director)
    await _wait_frames(2)
    _test_axes_signature(game, director)
    await _wait_frames(2)
    _test_hammer_signature(game, director)
    await _wait_frames(2)
    _test_twin_blades_signature(game, director)
    await _wait_frames(2)
    _test_risk_reward_choice(game, director)

    await _cleanup_game(game)
    _finish()

func _prepare_state() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["tutorial_complete"] = true
    GameState.data["coach_complete"] = true
    GameState.data["weapons_owned"] = ["axes", "spear", "hammer", "twin_blades"]
    GameState.data["selected_weapon"] = "axes"

func _spawn_test_enemy(game: GameWorld, offset: Vector2) -> AxEnemy:
    game.call("_spawn_enemy", false)
    if game.enemies.is_empty():
        _fail("GameWorld failed to spawn an enemy")
        return null
    var enemy: AxEnemy = game.enemies[game.enemies.size() - 1]
    enemy.global_position = game.player.global_position + offset
    enemy.clear_target()
    return enemy

func _test_elite_enemy(game: GameWorld, director: Node) -> void:
    var enemy: AxEnemy = _spawn_test_enemy(game, Vector2(54.0, 0.0))
    if enemy == null:
        return
    var hp_before: float = enemy.max_hp
    var promoted: bool = bool(director.call("make_elite", enemy))
    if not promoted:
        _fail("ExpeditionDirector failed to promote a normal enemy to elite")
        return
    if not bool(enemy.get_meta("expedition_elite", false)):
        _fail("Elite metadata was not set")
    if enemy.max_hp <= hp_before:
        _fail("Elite enemy did not receive extra HP")

    var elite_kills_before: int = int(director.get("elite_kills"))
    enemy.take_damage(enemy.hp + 9999.0)
    await _wait_frames(24)
    if int(director.get("elite_kills")) <= elite_kills_before:
        _fail("Elite kill bonus hook did not fire")
    else:
        print("[EXPEDITION] elite enemy reward hook OK")

func _test_axes_signature(game: GameWorld, director: Node) -> void:
    var enemy: AxEnemy = _spawn_test_enemy(game, Vector2(62.0, 0.0))
    if enemy == null:
        return
    game.player.apply_weapon_profile("axes")
    var hp_before: float = enemy.hp
    var fired: bool = bool(director.call("trigger_signature_now"))
    if not fired or enemy.hp >= hp_before:
        _fail("Axes signature did not damage a nearby enemy")
    else:
        print("[EXPEDITION] axes signature OK")

func _test_hammer_signature(game: GameWorld, director: Node) -> void:
    var enemy: AxEnemy = _spawn_test_enemy(game, Vector2(66.0, 0.0))
    if enemy == null:
        return
    game.player.apply_weapon_profile("hammer")
    var hp_before: float = enemy.hp
    var fired: bool = bool(director.call("trigger_signature_now"))
    if not fired or enemy.hp >= hp_before:
        _fail("Hammer signature did not damage a nearby enemy")
    if not enemy.has_meta("expedition_slow_time"):
        _fail("Hammer signature did not apply its slow")
    else:
        print("[EXPEDITION] hammer signature + slow OK")

func _test_twin_blades_signature(game: GameWorld, director: Node) -> void:
    var enemy: AxEnemy = _spawn_test_enemy(game, Vector2(58.0, 0.0))
    if enemy == null:
        return
    game.player.apply_weapon_profile("twin_blades")
    var shield_before: int = game.player.shield_hits
    var hp_before: float = enemy.hp
    var fired: bool = bool(director.call("trigger_signature_now"))
    if not fired or enemy.hp >= hp_before:
        _fail("Twin blades signature did not damage a nearby enemy")
    if game.player.shield_hits <= shield_before:
        _fail("Twin blades signature did not grant a shield charge")
    else:
        print("[EXPEDITION] twin blades signature + shield OK")

func _test_risk_reward_choice(game: GameWorld, director: Node) -> void:
    game.phase = "day"
    game.hud.hide_modal()
    var coins_before: int = game.run_coins
    var elite_chance_before: float = float(director.get("elite_bonus_chance"))
    var applied: bool = bool(director.call("apply_event_action", "event:chest_open"))
    if not applied:
        _fail("Risk/reward event action was rejected")
        return
    if game.run_coins < coins_before + 26:
        _fail("Risk/reward chest did not grant its coin reward")
    if float(director.get("elite_bonus_chance")) <= elite_chance_before:
        _fail("Risk/reward chest did not increase elite risk")
    else:
        print("[EXPEDITION] risk/reward choice OK")

func _cleanup_game(game: GameWorld) -> void:
    if get_tree().current_scene == game:
        get_tree().current_scene = self
    if is_instance_valid(game):
        game.queue_free()
    await _wait_frames(6)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _finish() -> void:
    if failures.is_empty():
        print("[EXPEDITION] AXEHOLD expedition wow validation passed")
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[EXPEDITION] %s" % failure)
    get_tree().quit(1)

func _fail(message: String) -> void:
    failures.append(message)
    print("[EXPEDITION] FAIL: ", message)
