extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")
const PlayerScene: PackedScene = preload("res://scenes/player.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    await get_tree().process_frame
    _test_biome_rules()
    _test_autoloads()
    _prepare_test_state()
    _test_weapon_profiles()
    _test_meta_rewards()

    GameState.data["weapons_owned"] = ["axes"]
    GameState.data["selected_weapon"] = "axes"
    GameState.data["meta_notices"] = []

    for biome_index: int in range(GameRules.BIOMES.size()):
        await _test_biome_runtime(biome_index)

    if failures.is_empty():
        print("[GAMEPLAY] AXEHOLD runtime mechanics validation passed")
        get_tree().quit(0)
        return

    for failure: String in failures:
        push_error("[GAMEPLAY] %s" % failure)
    get_tree().quit(1)

func _test_autoloads() -> void:
    var director: Node = get_tree().root.get_node_or_null("RunDirector")
    if director == null:
        _fail("RunDirector autoload is missing")
    else:
        print("[GAMEPLAY] RunDirector autoload present")

    var meta_director: Node = get_tree().root.get_node_or_null("MetaDirector")
    if meta_director == null:
        _fail("MetaDirector autoload is missing")
    else:
        print("[GAMEPLAY] MetaDirector autoload present")

func _prepare_test_state() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["tutorial_complete"] = true
    GameState.data["coach_complete"] = true
    GameState.data["weapons_owned"] = ["axes", "spear", "hammer", "twin_blades"]
    GameState.data["selected_weapon"] = "axes"
    GameState.data["boss_relics"] = [false, false, false]
    GameState.data["biome_mastery"] = [0, 0, 0]
    GameState.data["biome_wins"] = [0, 0, 0]
    GameState.data["meta_notices"] = []

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
    var ash_weights: Dictionary = GameRules.biome(2).get("enemy_weights", {})
    var forest_weights: Dictionary = GameRules.biome(0).get("enemy_weights", {})
    if float(ash_weights.get("brute", 0.0)) <= float(forest_weights.get("brute", 0.0)):
        _fail("Ashlands should bias toward brutes")

func _test_weapon_profiles() -> void:
    for required_weapon: String in ["axes", "spear", "hammer", "twin_blades"]:
        if not WeaponRules.WEAPONS.has(required_weapon):
            _fail("Weapon profile missing: %s" % required_weapon)

    var player: AxPlayer = PlayerScene.instantiate() as AxPlayer
    if player == null:
        _fail("Cannot instantiate AxPlayer for weapon tests")
        return
    player.setup({"damage":0, "hp":0, "bag":0, "speed":0}, GameRules.skin(0))
    var axes_damage: float = player.damage
    var axes_speed: float = player.move_speed
    var axes_radius: float = player.orbit_radius
    var axes_crit: float = player.crit_chance

    player.apply_weapon_profile("spear")
    if player.orbit_radius <= axes_radius or player.damage >= axes_damage:
        _fail("Spear profile should trade damage for reach")

    player.apply_weapon_profile("hammer")
    if player.damage <= axes_damage or player.move_speed >= axes_speed:
        _fail("Hammer profile should trade speed for damage")

    player.apply_weapon_profile("twin_blades")
    if player.crit_chance <= axes_crit or player.axes < 2:
        _fail("Twin blades should increase crit and use two blades")

    player.free()
    print("[GAMEPLAY] weapon profiles OK")

func _test_meta_rewards() -> void:
    GameState.data["weapons_owned"] = ["axes"]
    GameState.data["selected_weapon"] = "axes"
    GameState.data["boss_relics"] = [false, false, false]
    GameState.data["biome_mastery"] = [0, 0, 0]
    GameState.data["biome_wins"] = [0, 0, 0]
    GameState.data["meta_notices"] = []
    var shards_before: int = int(GameState.data.get("shards", 0))

    GameState.register_run(3, true, 0, 10, 2, 8)
    if not GameState.owns_weapon("spear") or not bool(GameState.data["boss_relics"][0]):
        _fail("Forest victory did not unlock spear and root relic")

    GameState.register_run(3, true, 1, 10, 2, 8)
    if not GameState.owns_weapon("hammer") or not bool(GameState.data["boss_relics"][1]):
        _fail("Frost victory did not unlock hammer and frost relic")

    GameState.register_run(3, true, 2, 10, 2, 8)
    if not GameState.owns_weapon("twin_blades") or not bool(GameState.data["boss_relics"][2]):
        _fail("Ashlands victory did not unlock twin blades and ash relic")

    GameState.register_run(3, true, 0, 10, 2, 8)
    GameState.register_run(3, true, 0, 10, 2, 8)
    if int(GameState.data["biome_mastery"][0]) != 3:
        _fail("Forest mastery did not reach level 3 after three victories")
    if int(GameState.data.get("shards", 0)) < shards_before + 1:
        _fail("Mastery III did not grant its shard reward")
    if not GameState.select_weapon("hammer") or str(GameState.data.get("selected_weapon", "")) != "hammer":
        _fail("Unlocked weapon selection did not persist")

    print("[GAMEPLAY] meta progression rewards OK")

func _test_biome_runtime(biome_index: int) -> void:
    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Cannot instantiate GameWorld for biome %d" % biome_index)
        return

    game.configure(biome_index)
    get_tree().root.add_child(game)
    get_tree().current_scene = game
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
    print("[GAMEPLAY] FAIL: ", message)
