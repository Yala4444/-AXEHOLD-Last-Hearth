extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")
const CampScene: PackedScene = preload("res://scenes/camp_view.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["tutorial_complete"] = true
    GameState.data["v1_tutorial_complete"] = true
    GameState.data["coach_complete"] = true

    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Cannot instantiate v1.3 GameWorld")
        _finish()
        return

    game.configure(0)
    get_tree().root.add_child(game)
    get_tree().current_scene = game
    await _wait_frames(8)

    var viewport: Vector2 = game.get_viewport_rect().size
    if game.world_size.x < viewport.x * 3.5 or game.world_size.y < viewport.y * 3.5:
        _fail("v1.3 world is not meaningfully larger")

    if game.world_generator == null or game.activity_director == null:
        _fail("WorldGenerator or WorldActivityDirector missing")
    else:
        var counts: Dictionary = {"caravan":0, "chest":0, "nest":0, "altar":0}
        for activity: WorldActivity in game.activity_director.activities:
            if is_instance_valid(activity):
                counts[activity.activity_type] = int(counts.get(activity.activity_type, 0)) + 1
        if int(counts["caravan"]) < 2 or int(counts["chest"]) < 3 or int(counts["nest"]) < 3:
            _fail("Core exploration activities were not populated")

        var threat_before: int = game.activity_director.night_extra_enemies()
        for activity: WorldActivity in game.activity_director.activities:
            if activity.activity_type == "nest" and not activity.finished:
                activity.damage(99999.0)
                break
        var threat_after: int = game.activity_director.night_extra_enemies()
        if threat_after >= threat_before:
            _fail("Destroying a nest did not reduce night threat")

    var tree_avg: float = _average_resource_distance(game, "tree")
    var rock_avg: float = _average_resource_distance(game, "rock")
    var ore_avg: float = _average_resource_distance(game, "ore")
    if not (tree_avg < rock_avg and rock_avg < ore_avg):
        _fail("Resource risk bands are not ordered wood < stone < ore")

    if game.camera == null:
        _fail("Camera missing")
    else:
        if game.camera.limit_left < int(viewport.x * 0.45):
            _fail("Camera can expose the left edge outside the world")
        if game.camera.limit_right > int(game.world_size.x - viewport.x * 0.45):
            _fail("Camera can expose the right edge outside the world")

    game.call("_start_night")
    await _wait_frames(5)
    if game.backdrop == null or not game.backdrop.night:
        _fail("Backdrop did not enter night")

    game.player.global_position = Vector2(game.camera.limit_left + 5, game.camera.limit_top + 5)
    await _wait_frames(4)
    game.call("_start_day")
    await _wait_frames(90)
    if game.backdrop.night:
        _fail("Night backdrop remained active after dawn")

    var biome_fx: BiomeFX = _find_biome_fx(game)
    if biome_fx != null and biome_fx.night_visual_strength() > 0.08:
        _fail("Night viewport overlay did not clear after dawn")

    var camp: CampView = CampScene.instantiate() as CampView
    add_child(camp)
    await _wait_frames(2)
    if camp.custom_minimum_size.y < 430.0 or camp.custom_minimum_size.y > 520.0:
        _fail("Camp home view is outside the v1.4 immersive hub target")
    for key: String in ["forge", "arsenal", "goals", "map"]:
        if not camp.action_buttons.has(key):
            _fail("Camp hotspot missing: " + key)

    if failures.is_empty():
        print("[V1.4] world expansion, activities, night reset and immersive hub passed")

    camp.queue_free()
    if get_tree().current_scene == game:
        get_tree().current_scene = self
    game.queue_free()
    await _wait_frames(4)
    _finish()

func _average_resource_distance(game: GameWorld, kind: String) -> float:
    var total: float = 0.0
    var count: int = 0
    for spot: ResourceSpot in game.resources:
        if is_instance_valid(spot) and spot.resource_type == kind:
            total += spot.global_position.distance_to(game.base_position)
            count += 1
    return total / float(maxi(1, count))

func _find_biome_fx(node: Node) -> BiomeFX:
    for child: Node in node.get_children():
        if child is BiomeFX:
            return child as BiomeFX
    return null

func _wait_frames(count: int) -> void:
    for _i in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.4] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.4] %s" % failure)
    get_tree().quit(1)
