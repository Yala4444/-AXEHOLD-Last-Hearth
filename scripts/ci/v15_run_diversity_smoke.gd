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

    _test_rule_pools()

    var world: GameWorld = GameScene.instantiate() as GameWorld
    if world == null:
        _fail("Cannot instantiate GameWorld for v1.5 diversity test")
        _finish()
        return

    world.configure(0)
    add_child(world)
    await _wait_frames(5)

    if world.run_variation == null:
        _fail("RunVariationDirector missing from live expedition")
    else:
        if world.run_variation.contract.is_empty():
            _fail("Run contract was not selected")
        world.phase_time = 17.0
        world.run_variation._process(0.1)
        if world.run_variation.preview_wave != 1 or world.run_variation.previewed_modifier.is_empty():
            _fail("Night modifier was not previewed before first night")

    var tower: Dictionary = GameRules.build_spec("turret")
    var tower_cost: Dictionary = tower.get("cost", {})
    if int(tower_cost.get("wood", 0)) < 22 or int(tower_cost.get("ore", 0)) < 5:
        _fail("Tower cost no longer enforces an early-run tradeoff")

    world.wave = 1
    world.phase = "day"
    world.phase_time = 40.0
    await _wait_frames(3)
    var found_old_hearth: bool = false
    for activity: WorldActivity in world.activity_director.activities:
        if is_instance_valid(activity) and activity.activity_type == "old_hearth":
            found_old_hearth = true
            break
    if not found_old_hearth:
        _fail("Extinguished Hearth activity did not enter post-night world pool")

    var swarm: Dictionary = {}
    for spec_variant: Variant in GameRules.NIGHT_MODIFIERS:
        var spec: Dictionary = spec_variant
        if str(spec.get("id", "")) == "swarm":
            swarm = spec.duplicate(true)
            break
    if not swarm.is_empty() and world.run_variation != null:
        world.run_variation.current_modifier = swarm
        if world.run_variation.modify_spawn_count(10) <= 10:
            _fail("Swarm modifier did not increase enemy count")

    world.queue_free()
    await _wait_frames(3)

    if failures.is_empty():
        print("[V1.5 DIVERSITY] contracts, night previews, tower tradeoff and world events passed")
    _finish()

func _test_rule_pools() -> void:
    var doctrines: Array[Dictionary] = GameRules.random_doctrines(3)
    if doctrines.size() != 3:
        _fail("Dawn doctrine pool did not return three choices")
    var ids: Dictionary = {}
    for doctrine: Dictionary in doctrines:
        ids[str(doctrine.get("id", ""))] = true
    if ids.size() != doctrines.size():
        _fail("Dawn doctrine pool returned duplicate choices")

    var first_night: Dictionary = GameRules.random_night_modifier(1, 0.0)
    if int(first_night.get("min_wave", 99)) > 1:
        _fail("First night selected an invalid late modifier")

    if GameRules.RUN_CONTRACTS.size() < 6:
        _fail("Run contract pool is too small for meaningful variety")

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.5 DIVERSITY] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.5 DIVERSITY] %s" % failure)
    get_tree().quit(1)
