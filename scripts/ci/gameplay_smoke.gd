extends SceneTree

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    await process_frame
    _test_biome_rules()

    var director: Node = root.get_node_or_null("RunDirector")
    if director == null:
        _fail("RunDirector autoload is missing")
    else:
        print("[GAMEPLAY] RunDirector autoload present")

    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["tutorial_complete"] = true
    GameState.data["coach_complete"] = true

    for biome_index: int in range(GameRules.BIOMES.size()):
        await _test_biome_runtime(biome_index)

    if failures.is_empty():
        print("[GAMEPLAY] AXEHOLD runtime mechanics validation passed")
        quit(0)
        return

    for failure: String in failures:
        push_error("[GAMEPLAY] %s" % failure)
    quit(1)

func _test_biome_rules() -> void:
    if GameRules.BIOMES.size() != 3:
        _fail("Expected exactly 3 release biomes")
        return

    for biome_index: int in range(GameRules.BIOMES.size()):
        var biome: Dictionary = GameRules.biome(biome_index)
        for required_key: String in ["id", "name", "difficulty", "boss_name", "enemy_weights", "night_speed"]:
            if not biome.has(required_key):
                _fail("Biome %d missing key %s" % [biome_index, required_key])
        var weights: Dictionary = biome.get("enemy_weights", {})
        var total: float = float(weights.get("normal", 0.0)) + float(weights.get("runner", 0.0)) + float(weights.get("brute", 0.0))
        if absf(total - 1.0) > 0.001:
            _fail("Biome %d enemy weights do not sum to 1.0" % biome_index)

    if float(GameRules.biome(1).get("night_speed", 1.0)) >= 1.0:
        _fail("Frost biome should slow the hero at night")
    if float(GameRules.biome(2).get("enemy_weights", {}).get("brute", 0.0)) <= float(GameRules.biome(0).get("enemy_weights", {}).get("brute", 0.0)):
        _fail("Ashlands should bias toward brutes")

func _test_biome_runtime(biome_index: int) -> void:
    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Cannot instantiate GameWorld for biome %d" % biome_index)
        return

    game.configure(biome_index)
    root.add_child(game)
    current_scene = game
    await _wait_frames(5)

    if game.player == null or game.hud == null:
        _fail("Biome %d did not initialize player/HUD" % biome_index)
        await _cleanup_game(game)
        return

    var fx_found: bool = false
    for child: Node in game.get_children():
        if child is BiomeFX:
            fx_found = true
            break
    if not fx_found:
        _fail("Biome %d did not attach BiomeFX" % biome_index)

    var day_speed: float = game.player.move_speed
    game.call("_start_night")
    await _wait_frames(4)

    if biome_index == 1:
        if game.player.move_speed >= day_speed * 0.97:
            _fail("Frost biome night slow was not applied")
    else:
        if absf(game.player.move_speed - day_speed) > day_speed * 0.03:
            _fail("Biome %d unexpectedly changed night movement speed" % biome_index)

    game.call("_spawn_enemy", true)
    await _wait_frames(5)
    if game.boss_ref == null or not is_instance_valid(game.boss_ref):
        _fail("Biome %d boss failed to spawn" % biome_index)
    else:
        if biome_index == 1:
            if game.boss_ref.special_cooldown < 900.0 or game.boss_ref.charge_cooldown < 900.0:
                _fail("Frost boss default attacks were not replaced by frost-wave pattern")
        elif biome_index == 2:
            if game.boss_ref.special_cooldown < 900.0:
                _fail("Ash boss default area attack was not replaced by eruption pattern")

    var damage_before: float = game.player.damage
    game.hud.action_requested.emit("doctrine:hunt")
    await _wait_frames(2)
    if game.player.damage <= damage_before:
        _fail("Dawn Hunt doctrine did not increase hero damage in biome %d" % biome_index)

    print("[GAMEPLAY] biome %d runtime OK" % biome_index)
    await _cleanup_game(game)

func _cleanup_game(game: GameWorld) -> void:
    if current_scene == game:
        current_scene = null
    if is_instance_valid(game):
        game.queue_free()
    await _wait_frames(4)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[GAMEPLAY] FAIL: ", message)
