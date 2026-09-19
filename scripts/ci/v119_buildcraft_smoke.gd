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
    GameState.data["tutorial_replay_pending"] = false

    _test_rule_catalog()
    await _test_live_buildcraft()
    await _test_legendary_survival()

    GameState.data = snapshot
    GameState.save()

    if failures.is_empty():
        print("[V1.19 BUILDCRAFT] rarities, family evolution, legendary rules and result snapshot passed")
    _finish()

func _test_rule_catalog() -> void:
    for family: String in ["flame","steel","frost","guardian","hunt","roots"]:
        var evolution: Dictionary = GameRules.evolution_for_family(family)
        if evolution.is_empty():
            _fail("Missing build evolution for family: " + family)
    if GameRules.LEGENDARY_PERKS.size() < 6:
        _fail("Legendary perk catalog is too small")
    if GameRules.perk_family("fire_orb") != "flame":
        _fail("Fire Orb lost its Buildcraft family")
    if GameRules.perk_family("hammer_force") != "frost":
        _fail("Weapon perks are not participating in Buildcraft families")

func _fresh_world() -> GameWorld:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    return world

func _test_live_buildcraft() -> void:
    var world: GameWorld = _fresh_world()
    await _wait_frames(8)

    if world.buildcraft == null:
        _fail("BuildcraftDirector was not attached to GameWorld")
        world.queue_free()
        return

    world.set_process(false)
    if world.dynamic_world != null:
        world.dynamic_world.set_process(false)
    if world.field_objectives != null:
        world.field_objectives.set_process(false)
    if world.biome_events != null:
        world.biome_events.set_process(false)
    if world.activity_director != null:
        world.activity_director.set_process(false)

    var choices: Array[Dictionary] = world.buildcraft.roll_choices(3, 5)
    if choices.size() != 3:
        _fail("Buildcraft did not produce three level-up choices")
    var ids: Dictionary = {}
    for choice: Dictionary in choices:
        var perk_id: String = str(choice.get("id",""))
        ids[perk_id] = true
        if not choice.has("rarity"):
            _fail("Buildcraft choice has no rarity")
    if ids.size() != choices.size():
        _fail("Buildcraft level-up choices contain duplicates")

    world.player.apply_perk("damage")
    world.player.apply_perk("damage")
    if world.player.has_evolution("flame"):
        _fail("Family evolved before reaching 3/3")
    world.player.apply_perk("fire_orb")
    if not world.player.has_evolution("flame"):
        _fail("Flame family did not evolve at 3/3")
    if world.player.fire_orb_level < 3:
        _fail("Inferno evolution did not transform the visible Fire Orb relic")

    var summary: Dictionary = world.buildcraft.result_summary()
    var evolutions: Array = summary.get("evolutions", [])
    if evolutions.is_empty():
        _fail("Buildcraft result summary lost run evolutions")
    if str(summary.get("top_family","")) != "flame":
        _fail("Buildcraft result identity lost the dominant family")

    world.queue_free()
    await _wait_frames(4)

func _test_legendary_survival() -> void:
    var world: GameWorld = _fresh_world()
    await _wait_frames(8)
    world.set_process(false)

    world.player.apply_perk("phoenix_oath")
    if world.player.phoenix_charges != 1:
        _fail("Last Spark legendary did not grant a Phoenix charge")
    world.player.damage_grace_time = 0.0
    world.player.hp = 5.0
    world.player.take_damage(9999.0)
    if world.player.hp <= 0.0:
        _fail("Last Spark did not prevent lethal damage")
    if world.player.phoenix_charges != 0:
        _fail("Last Spark was not consumed after lethal damage")

    world.player.apply_perk("blood_moon")
    if world.player.crit_multiplier <= 2.0:
        _fail("Red Hunt legendary did not increase critical damage")

    var snapshot_data: Dictionary = world.player.buildcraft_snapshot()
    var legendaries: Array = snapshot_data.get("legendaries", [])
    if legendaries.size() < 2:
        _fail("Legendary rules were not preserved in the build snapshot")

    world.queue_free()
    await _wait_frames(4)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.19 BUILDCRAFT] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.19 BUILDCRAFT] %s" % failure)
    get_tree().quit(1)
