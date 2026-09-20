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

    await _test_memory_and_event_choices()
    await _test_reduced_world_clutter()
    _test_event_relic_catalog()

    GameState.data = snapshot
    GameState.save()

    if failures.is_empty():
        print("[V1.18 EVENTS 2.0] expedition memory, branching consequences and pacing passed")
    _finish()

func _fresh_world() -> GameWorld:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    return world

func _test_memory_and_event_choices() -> void:
    var world: GameWorld = _fresh_world()
    await _wait_frames(8)

    if world.expedition_memory == null:
        _fail("ExpeditionMemoryDirector was not attached")
        world.queue_free()
        return

    world.set_process(false)
    world.dynamic_world.set_process(false)
    world.field_objectives.set_process(false)
    world.biome_events.set_process(false)
    world.activity_director.set_process(false)

    world.dynamic_world._start_event("caravan_defense")
    if str(world.dynamic_world.active_event.get("type","")) != "caravan_defense":
        _fail("Caravan major event did not start")
    else:
        world.dynamic_world.active_event["stage"] = "choice"
        world.dynamic_world._on_hud_action("event:caravan_take")
        if not world.expedition_memory.has_flag("caravan_taken"):
            _fail("Taking caravan cargo did not create a lasting consequence")
        var extra: int = world.expedition_memory.consume_night_spawn_delta(1)
        if extra < 4:
            _fail("Caravan theft did not strengthen the next night")

    world.encounter_orchestrator.cooldown = 0.0
    world.dynamic_world._start_event("elite_hunt")
    var thorn_before: int = world.player.thorn_ring_level
    world.dynamic_world._complete_event()
    if world.player.thorn_ring_level <= thorn_before:
        _fail("Named forest hunt did not grant its visible run relic")

    var summary: Dictionary = world.expedition_memory.result_summary()
    var moments: Array = summary.get("moments", [])
    if moments.size() < 2:
        _fail("Expedition memory did not preserve major run moments")
    if int(summary.get("choices",0)) < 1:
        _fail("Expedition memory did not count meaningful choices")

    world.queue_free()
    await _wait_frames(5)

func _test_reduced_world_clutter() -> void:
    var world: GameWorld = _fresh_world()
    await _wait_frames(8)

    if world.activity_director == null:
        _fail("WorldActivityDirector missing")
    else:
        var count: int = world.activity_director.activities.size()
        if count > 5:
            _fail("Events 2.0 still spawns too many initial map activities")
        if count < 4:
            _fail("Events 2.0 removed too much exploration content")

    if world.field_objectives == null:
        _fail("FieldObjectiveDirector missing")
    else:
        world.field_objectives.started_waves[0] = true
        world.field_objectives.started_waves[1] = true
        world.wave = 2
        world.field_objectives.start_delay = -1.0
        world.field_objectives._process(1.0)
        if not world.field_objectives.active.is_empty():
            _fail("Field objectives still stack onto the final preparation day")

    world.queue_free()
    await _wait_frames(5)

func _test_event_relic_catalog() -> void:
    var forest: Dictionary = GameRules.event_relic_for_biome(0)
    var frost: Dictionary = GameRules.event_relic_for_biome(1)
    var ash: Dictionary = GameRules.event_relic_for_biome(2)
    if str(forest.get("id","")) != "thorn_ring":
        _fail("Forest named hunt relic is not deterministic")
    if str(frost.get("id","")) != "frost_aura":
        _fail("Frost named hunt relic is not deterministic")
    if str(ash.get("id","")) != "fire_orb":
        _fail("Ash named hunt relic is not deterministic")
    if GameRules.named_hunt_name(0).strip_edges().is_empty():
        _fail("Named hunt has no identity")

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.18 EVENTS 2.0] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.18 EVENTS 2.0] %s" % failure)
    get_tree().quit(1)
