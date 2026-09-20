extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")
const ART_PATHS: Array[String] = [
    "res://assets/art/forgotten_forest/wanderer.webp",
    "res://assets/art/forgotten_forest/root_husk.webp",
    "res://assets/art/forgotten_forest/briar_hound.webp",
    "res://assets/art/forgotten_forest/ironroot_ravager.webp",
    "res://assets/art/forgotten_forest/hollow_seer.webp",
    "res://assets/art/forgotten_forest/oathstone_bulwark.webp",
    "res://assets/art/forgotten_forest/forest_guardian.webp",
    "res://assets/art/forgotten_forest/last_hearth.webp",
    "res://assets/art/forgotten_forest/ancient_sentinel_tree.webp",
    "res://assets/art/forgotten_forest/harvest_tree.webp",
    "res://assets/art/forgotten_forest/stone_deposit.webp",
    "res://assets/art/forgotten_forest/ore_deposit.webp"
]

var failures: Array[String] = []
var snapshot: Dictionary = {}

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    snapshot = GameState.data.duplicate(true)
    GameState.data = GameState.defaults()
    GameState.data["coach_complete"] = true
    GameState.data["tutorial_replay_pending"] = false

    _test_art_imports()
    await _test_runtime_contracts()

    GameState.data = snapshot
    GameState.save()
    if failures.is_empty():
        print("[V1.22 FOREST ART] 12 production assets and runtime presentation contracts passed")
    _finish()

func _test_art_imports() -> void:
    for path: String in ART_PATHS:
        if not ResourceLoader.exists(path):
            _fail("Production art is missing: " + path)
            continue
        var texture: Texture2D = load(path) as Texture2D
        if texture == null:
            _fail("Production art failed to import: " + path)
        elif texture.get_width() < 250 or texture.get_height() < 250:
            _fail("Production art resolution collapsed: " + path)

func _test_runtime_contracts() -> void:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    await _wait_frames(8)
    _pause_world(world)

    var player_profile: Dictionary = world.player.visual_identity_profile()
    if int(player_profile.get("version", 0)) < 3 or not bool(player_profile.get("production_art", false)):
        _fail("Wanderer is not using the production-art contract")

    for kind: String in ["normal", "runner", "brute", "stalker", "guardian", "boss"]:
        var enemy := AxEnemy.new()
        add_child(enemy)
        enemy.configure(kind, 1.0, 3, Color("765f78"), kind == "boss", 0)
        var signature: Dictionary = enemy.visual_role_signature()
        if int(signature.get("version", 0)) < 3 or not bool(signature.get("production_art", false)):
            _fail("Forest enemy has no production-art contract: " + kind)
        enemy.queue_free()

    if world.resources.is_empty():
        _fail("Forest resources were not generated")
    else:
        var first_resource: ResourceSpot = world.resources[0] as ResourceSpot
        var resource_profile: Dictionary = first_resource.visual_identity_profile()
        if int(resource_profile.get("version", 0)) < 3 or not bool(resource_profile.get("production_art", false)):
            _fail("Forest resources are not using production art")

    var ancient_tree_found: bool = false
    for landmark: WorldLandmark in world.world_generator.landmark_nodes:
        if landmark.kind == "ancient_tree":
            ancient_tree_found = true
            if int(landmark.visual_identity_profile().get("version", 0)) < 3:
                _fail("Ancient sentinel tree still uses the old visual contract")
            break
    if not ancient_tree_found:
        _fail("Ancient sentinel tree was not generated")

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
    print("[V1.22 FOREST ART] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.22 FOREST ART] %s" % failure)
    get_tree().quit(1)
