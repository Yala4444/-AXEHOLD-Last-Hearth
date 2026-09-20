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

    await _test_forest_visual_identity()

    GameState.data = snapshot
    GameState.save()
    if failures.is_empty():
        print("[V1.21 VISUAL IDENTITY] Wanderer, enemy roles, Forest Guardian and Forgotten Forest passed")
    _finish()

func _test_forest_visual_identity() -> void:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    await _wait_frames(8)
    _pause_world(world)

    var player_profile: Dictionary = world.player.visual_identity_profile()
    if int(player_profile.get("version", 0)) < 2:
        _fail("Wanderer visual identity contract was not upgraded")
    if str(player_profile.get("silhouette", "")) != "hooded_wanderer":
        _fail("Wanderer lost the hooded silhouette")
    if str(player_profile.get("anchor", "")) != "hearth_rune":
        _fail("Wanderer lost the Last Hearth rune anchor")
    if not bool(player_profile.get("weapon_readable", false)):
        _fail("Wanderer weapon readability contract is missing")

    var silhouettes: Dictionary = {}
    var brute_footprint := Vector2.ZERO
    for kind: String in ["normal", "runner", "brute", "stalker", "guardian"]:
        var enemy := AxEnemy.new()
        add_child(enemy)
        enemy.configure(kind, 1.0, 1, Color("765f78"), false, 0)
        var signature: Dictionary = enemy.visual_role_signature()
        var silhouette: String = str(signature.get("silhouette", ""))
        if silhouette.is_empty() or silhouettes.has(silhouette):
            _fail("Enemy roles do not have unique silhouettes: " + kind)
        silhouettes[silhouette] = true
        var footprint: Vector2 = signature.get("footprint", Vector2.ZERO) as Vector2
        if footprint.x <= 0.0 or footprint.y <= 0.0:
            _fail("Enemy role has no readable footprint: " + kind)
        if kind == "brute":
            brute_footprint = footprint
        enemy.queue_free()

    var boss := AxEnemy.new()
    add_child(boss)
    boss.configure("boss", 1.0, 3, Color("765f78"), true, 0)
    var boss_signature: Dictionary = boss.visual_role_signature()
    var boss_footprint: Vector2 = boss_signature.get("footprint", Vector2.ZERO) as Vector2
    if str(boss_signature.get("silhouette", "")) != "regional_colossus":
        _fail("Forest Guardian lost its regional colossus silhouette")
    if boss_footprint.x <= brute_footprint.x or boss_footprint.y <= brute_footprint.y:
        _fail("Forest Guardian does not read larger than a brute")
    boss.queue_free()

    var backdrop_profile: Dictionary = world.backdrop.visual_identity_profile()
    if int(backdrop_profile.get("version", 0)) < 2:
        _fail("Forgotten Forest backdrop contract was not upgraded")
    if str(backdrop_profile.get("landmark_language", "")) != "folk_ruins":
        _fail("Forgotten Forest lost its dark folk landmark language")

    if world.world_generator.landmark_nodes.size() < 28:
        _fail("Forgotten Forest landmark density is below the v1.21 target")
    var landmark_kinds: Dictionary = {}
    for landmark: WorldLandmark in world.world_generator.landmark_nodes:
        landmark_kinds[landmark.kind] = true
    for required_kind: String in ["ancient_tree", "root_arch", "fallen_totem"]:
        if not landmark_kinds.has(required_kind):
            _fail("Forgotten Forest landmark missing: " + required_kind)

    world.queue_free()
    await _wait_frames(4)

func _pause_world(world: GameWorld) -> void:
    world.set_process(false)
    world.dynamic_world.set_process(false)
    world.field_objectives.set_process(false)
    world.biome_events.set_process(false)
    world.activity_director.set_process(false)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.21 VISUAL IDENTITY] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.21 VISUAL IDENTITY] %s" % failure)
    get_tree().quit(1)
