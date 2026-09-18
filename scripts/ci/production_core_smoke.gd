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
    GameState.data["tutorial_complete"] = true
    GameState.data["v1_tutorial_complete"] = true
    GameState.data["coach_complete"] = true

    var game: GameWorld = GameScene.instantiate() as GameWorld
    if game == null:
        _fail("Cannot instantiate production GameWorld")
        _finish()
        return

    game.configure(0)
    get_tree().root.add_child(game)
    get_tree().current_scene = game
    await _wait_frames(7)

    var viewport_size: Vector2 = game.get_viewport_rect().size
    if game.world_size.x < viewport_size.x * 2.5 or game.world_size.y < viewport_size.y * 2.5:
        _fail("World did not expand beyond the single-screen prototype")

    if game.camera == null or not is_instance_valid(game.camera):
        _fail("Follow camera missing")
    elif not game.camera.is_current():
        _fail("Follow camera is not current")

    if game.player == null:
        _fail("Player missing")
    else:
        if not game.player.has_movement_bounds:
            _fail("Player is not constrained to expanded world bounds")
        if game.player.home_target.distance_to(game.base_position) > 1.0:
            _fail("Hero return target is not the Last Hearth")

    var tree_distance_total: float = 0.0
    var tree_count: int = 0
    var ore_distance_total: float = 0.0
    var ore_count: int = 0
    for spot: ResourceSpot in game.resources:
        var distance: float = spot.global_position.distance_to(game.base_position)
        if spot.resource_type == "tree":
            tree_distance_total += distance
            tree_count += 1
        elif spot.resource_type == "ore":
            ore_distance_total += distance
            ore_count += 1

    if tree_count == 0 or ore_count == 0:
        _fail("Resource risk zones are missing")
    else:
        var tree_avg: float = tree_distance_total / float(tree_count)
        var ore_avg: float = ore_distance_total / float(ore_count)
        if ore_avg <= tree_avg + 100.0:
            _fail("Ore is not meaningfully farther from Hearth than wood")

    var controls: Node = get_tree().root.get_node_or_null("MobileControls")
    if controls == null:
        _fail("MobileControls missing")
    else:
        controls.call("bind_world", game)
        controls.call("force_visible_for_test", true)
        var touch := Vector2(viewport_size.x * 0.53, viewport_size.y * 0.72)
        controls.call("simulate_touch_for_test", touch)
        var center_before: Vector2 = controls.get("center")
        if center_before.distance_to(touch) > 2.0:
            _fail("Floating joystick did not appear at touch position")

        controls.call("simulate_drag_for_test", touch + Vector2(90.0, 0.0))
        var center_after: Vector2 = controls.get("center")
        var direction: Vector2 = controls.get("direction")
        if center_after.x <= center_before.x + 4.0:
            _fail("Floating joystick base did not drift with the thumb")
        if direction.x < 0.65:
            _fail("Floating joystick did not produce strong analog movement")

        controls.call("release_test_input")
        controls.call("force_visible_for_test", false)
        controls.call("unbind_world", game)

    if game.player != null:
        game.player.inventory = {"wood": game.player.capacity, "stone": 0, "ore": 0}
        game.player.set_home_hint(true)
        if not game.player.home_hint_active:
            _fail("Hero-local return cue failed")

    if failures.is_empty():
        print("[PRODUCTION] large world, camera, risk zones, floating joystick and hero-local bag UX passed")

    if get_tree().current_scene == game:
        get_tree().current_scene = self
    game.queue_free()
    await _wait_frames(4)
    _finish()

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[PRODUCTION] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[PRODUCTION] %s" % failure)
    get_tree().quit(1)
