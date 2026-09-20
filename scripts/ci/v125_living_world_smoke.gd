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

    await _test_living_world_contract()
    _test_resource_contact_language()
    _test_enemy_silhouettes()

    GameState.data = snapshot
    GameState.save()

    if failures.is_empty():
        print("[V1.25 LIVING WORLD] Hearth growth, direction-aware Wanderer, readable harvesting and silhouettes passed")
    _finish()

func _fresh_world() -> GameWorld:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    return world

func _test_living_world_contract() -> void:
    var world: GameWorld = _fresh_world()
    await _wait_frames(8)

    if world.hearth_growth == null:
        _fail("HearthGrowthDirector was not attached")
        world.queue_free()
        return

    var initial_hp: float = world.base_max_hp
    var initial_radius: float = world.hearth_growth.safe_radius()
    var initial_deposit_radius: float = world.hearth_growth.deposit_radius()

    world.hearth_growth.record_deposit({"wood":20,"stone":0,"ore":0})
    if world.hearth_growth.stage != 1:
        _fail("First physical resource delivery did not grow Ember into Campfire")
    if world.base_max_hp <= initial_hp:
        _fail("Hearth growth did not add its modest gameplay durability effect")
    if world.hearth_growth.safe_radius() <= initial_radius:
        _fail("Hearth warm territory did not expand at stage 1")
    if world.hearth_growth.deposit_radius() <= initial_deposit_radius:
        _fail("Hearth deposit comfort radius did not expand")

    var stage_one_radius: float = world.hearth_growth.safe_radius()
    world.hearth_growth.record_deposit({"wood":20,"stone":10,"ore":0})
    if world.hearth_growth.stage < 2:
        _fail("Second major delivery did not reach Last Hearth stage")
    if world.hearth_growth.safe_radius() <= stage_one_radius:
        _fail("Last Hearth stage did not visibly expand home territory")

    var profile: Dictionary = world.player.visual_identity_profile()
    if not bool(profile.get("direction_aware",false)):
        _fail("Wanderer visual identity is not direction-aware")

    world.player.set_move_input(Vector2(0,-1))
    world.player._physics_process(0.12)
    if world.player.facing_direction.y > -0.35:
        _fail("Wanderer did not turn north when moving north")
    world.player.release_move_input()

    if world.resources.size() >= 70:
        _fail("Living World still starts with excessive resource clutter")

    var tree_points: Array = world.world_generator.clusters.get("tree",[])
    if tree_points.is_empty():
        _fail("World generator has no tree clusters")
    else:
        var nearest_tree_cluster: float = INF
        for p_variant: Variant in tree_points:
            var p: Vector2 = p_variant as Vector2
            nearest_tree_cluster = minf(nearest_tree_cluster,p.distance_to(world.base_position))
        if nearest_tree_cluster > 220.0:
            _fail("First gathering route is no longer spatially self-teaching")

    world.queue_free()
    await _wait_frames(4)

func _test_resource_contact_language() -> void:
    var spot := ResourceSpot.new()
    add_child(spot)
    spot.configure("tree",0,0)
    spot.damage(1.0)
    if spot.harvest_contact <= 0.0:
        _fail("Automatic harvesting does not activate visible contact feedback")
    if int(spot.visual_identity_profile().get("version",0)) < 4:
        _fail("Resource visual identity was not upgraded for Living World")
    spot.queue_free()

func _test_enemy_silhouettes() -> void:
    var expected: Dictionary = {
        "normal":"husk",
        "runner":"low_long_limb",
        "brute":"broad_horned_wedge",
        "stalker":"tall_masked_crescent",
        "guardian":"stone_bulwark"
    }
    var silhouettes: Dictionary = {}
    for kind: String in expected.keys():
        var enemy := AxEnemy.new()
        add_child(enemy)
        enemy.configure(kind,1.0,1,Color("755b76"),false,0)
        var profile: Dictionary = enemy.visual_role_signature()
        var silhouette: String = str(profile.get("silhouette",""))
        silhouettes[silhouette] = true
        if silhouette != str(expected[kind]):
            _fail("Enemy role lost its intended silhouette: " + kind)
        enemy.queue_free()
    if silhouettes.size() != expected.size():
        _fail("Enemy roles are not visually distinct enough by silhouette")

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.25 LIVING WORLD] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.25 LIVING WORLD] %s" % failure)
    get_tree().quit(1)
