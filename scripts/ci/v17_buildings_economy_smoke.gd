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

    _test_blueprint_economy()
    await _test_level_two_buildings()
    _test_building_rules()

    if failures.is_empty():
        print("[V1.7 BUILDINGS] blueprints, parts, branches and economy passed")
    _finish()

func _test_blueprint_economy() -> void:
    GameState.data["coins"] = 2000
    GameState.data["shards"] = 10
    GameState.data["biome_mastery"] = [3, 1, 0]
    GameState.data["building_projects"] = {"wall":false, "forge":false, "turret":false, "shrine":false}

    var before_coins: int = int(GameState.data["coins"])
    var before_shards: int = int(GameState.data["shards"])
    var spec: Dictionary = BuildingRules.project_spec("wall")
    if not GameState.buy_building_project("wall"):
        _fail("Palisade II blueprint could not be purchased")
        return

    if not GameState.has_building_project("wall"):
        _fail("Purchased building blueprint was not persisted")
    if int(GameState.data["coins"]) != before_coins - int(spec.get("coins", 0)):
        _fail("Building blueprint did not spend coins correctly")
    if int(GameState.data["shards"]) != before_shards - int(spec.get("shards", 0)):
        _fail("Building blueprint did not spend shards correctly")

func _test_level_two_buildings() -> void:
    GameState.data["building_projects"] = {"wall":true, "forge":true, "turret":true, "shrine":true}
    GameState.save()

    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(7)

    world.storage = {"wood":200, "stone":200, "ore":200, "parts":12}

    var wall: BuildPad = _find_pad(world, "wall")
    var forge: BuildPad = _find_pad(world, "forge")
    var turret: BuildPad = _find_pad(world, "turret")
    var shrine: BuildPad = _find_pad(world, "shrine")
    if wall == null or forge == null or turret == null or shrine == null:
        _fail("One or more building pads are missing")
        world.queue_free()
        return

    world._complete_build(wall)
    var base_before: float = world.base_max_hp
    world.pending_upgrade_pad = wall
    world._apply_build_upgrade("wall", "spikes")
    if wall.level != 2 or wall.upgrade_branch != "spikes":
        _fail("Palisade did not reach Level II")
    if world.wall_spike_dps <= 0.0 or world.base_max_hp <= base_before:
        _fail("Palisade Spikes branch did not change gameplay values")

    world._complete_build(forge)
    var radius_before: float = world.player.orbit_radius
    world.pending_upgrade_pad = forge
    world._apply_build_upgrade("forge", "reach")
    if world.player.orbit_radius <= radius_before or world.player.crit_chance <= 0.05:
        _fail("Forge Arc Workshop branch did not improve reach/crit")

    world._complete_build(turret)
    var parts_before_turret: int = int(world.storage.get("parts", 0))
    world.pending_upgrade_pad = turret
    world._apply_build_upgrade("turret", "repeater")
    if turret.level != 2 or world.turret_global_fire_mult >= 0.8:
        _fail("Tower Repeater branch did not improve firing cadence")
    if int(world.storage.get("parts", 0)) >= parts_before_turret:
        _fail("Level-II Tower did not consume mechanism parts")

    world._complete_build(shrine)
    world.pending_upgrade_pad = shrine
    world._apply_build_upgrade("shrine", "ward")
    if not world.shrine_ward_active or world.shrine_regen_multiplier <= 1.0:
        _fail("Shrine Ward branch did not activate its effects")

    var parts_before_reward: int = int(world.storage.get("parts", 0))
    world.add_mechanism_parts(1)
    if int(world.storage.get("parts", 0)) != parts_before_reward + 1:
        _fail("Mechanism Part reward did not enter stockpile")

    world._refresh_hud()
    if world.hud.storage_part_label == null or world.hud.storage_part_label.text != str(int(world.storage.get("parts", 0))):
        _fail("Mechanism Parts are not represented in the HUD")

    var result_snapshot: Dictionary = {}
    world.run_finished.connect(func(result: Dictionary) -> void:
        result_snapshot = result.duplicate(true)
    )
    world.storage["parts"] = 3
    world._finish_run(false)
    await _wait_frames(2)
    if int(result_snapshot.get("parts_bonus", -1)) != 24:
        _fail("Unused mechanism parts did not convert to coins at 8 each")

    world.queue_free()
    await _wait_frames(3)

func _test_building_rules() -> void:
    for build_type: String in ["wall", "forge", "turret", "shrine"]:
        var branches: Array[Dictionary] = BuildingRules.branches(build_type)
        if branches.size() != 2:
            _fail("Building does not expose exactly two Level-II branches: " + build_type)
        var cost: Dictionary = BuildingRules.upgrade_cost(build_type)
        if int(cost.get("parts", 0)) <= 0:
            _fail("Level-II building does not require mechanism parts: " + build_type)

func _find_pad(world: GameWorld, kind: String) -> BuildPad:
    for pad: BuildPad in world.pads:
        if is_instance_valid(pad) and pad.build_type == kind:
            return pad
    return null

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.7 BUILDINGS] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.7 BUILDINGS] %s" % failure)
    get_tree().quit(1)
