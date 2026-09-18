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
    GameState.data["dynamic_world_stats"] = {
        "events":0,"failures":0,"elites":0,"rescues":0,"chains":0
    }

    _test_elite_profiles()
    _test_dynamic_quest_specs()
    await _test_dynamic_runtime()

    if failures.is_empty():
        print("[V1.12 WORLD] elites, daytime combat and dynamic event chains passed")
    _finish()

func _test_elite_profiles() -> void:
    var baseline := AxEnemy.new()
    add_child(baseline)
    baseline.configure("brute", 1.0, 1, Color("76586c"), false, 0)
    var base_hp: float = baseline.max_hp
    var base_damage: float = baseline.contact_damage
    baseline.queue_free()

    var armored := AxEnemy.new()
    add_child(armored)
    armored.configure("brute", 1.0, 1, Color("76586c"), false, 0)
    armored.configure_elite("armored")
    if not armored.elite or armored.elite_title != "ЗАКОВАННЫЙ":
        _fail("Armored elite identity was not applied")
    if armored.max_hp <= base_hp or armored.armor <= 0.25:
        _fail("Armored elite did not become tougher")
    armored.queue_free()

    var warlord := AxEnemy.new()
    add_child(warlord)
    warlord.configure("guardian", 1.0, 1, Color("76586c"), false, 0)
    warlord.configure_elite("warlord")
    if warlord.max_hp <= base_hp or warlord.contact_damage <= base_damage:
        _fail("Warlord elite lacks mini-boss scaling")
    if warlord.charge_cooldown > 5.0:
        _fail("Warlord charge cadence was not enabled")
    warlord.queue_free()

func _test_dynamic_quest_specs() -> void:
    for quest_id: String in ["elite_hunter", "field_rescue", "event_runner", "follow_the_clue"]:
        if QuestRules.spec(quest_id).is_empty():
            _fail("Missing v1.12 quest: " + quest_id)

func _test_dynamic_runtime() -> void:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(8)
    world.paused_local = true

    if world.dynamic_world == null:
        _fail("DynamicWorldDirector was not attached to GameWorld")
        world.queue_free()
        return
    world.dynamic_world.set_process(false)

    var anchor := world.player.global_position + Vector2(180, 0)
    var day_enemy: AxEnemy = world.spawn_event_enemy("normal", anchor + Vector2(40, 0), "", "test", anchor, "attack_anchor")
    world._update_day_enemies(0.05)
    if not day_enemy.has_target:
        _fail("Daytime event enemy did not receive an AI target")
    day_enemy.take_damage(99999.0)
    await _wait_frames(3)

    world.dynamic_world._start_event("caravan_defense")
    if str(world.dynamic_world.active_event.get("type", "")) != "caravan_defense":
        _fail("Caravan defense event failed to start")
    var caravan_enemies: Array = world.dynamic_world.active_event.get("enemies", []).duplicate()
    if caravan_enemies.size() < 3:
        _fail("Caravan defense spawned too few attackers")
    for enemy_variant: Variant in caravan_enemies:
        var enemy: AxEnemy = enemy_variant as AxEnemy
        if enemy != null and is_instance_valid(enemy):
            enemy.take_damage(99999.0)
    await _wait_frames(4)
    world.dynamic_world._update_active_event(0.1)
    if str(world.dynamic_world.active_event.get("type", "")) != "trail_cache":
        _fail("Saved caravan did not open a chained trail cache")

    if not world.dynamic_world.active_event.is_empty():
        var cache_point: Vector2 = world.dynamic_world.active_event.get("point", world.player.global_position)
        world.player.global_position = cache_point
        world.dynamic_world._update_active_event(0.9)
    if world.dynamic_world.chains_completed != 1:
        _fail("Trail cache chain could not be completed")
    if not world.dynamic_world.active_event.is_empty():
        _fail("Trail cache stayed active after completion")

    world.dynamic_world._start_event("survivor_rescue")
    var rescue_enemies: Array = world.dynamic_world.active_event.get("enemies", []).duplicate()
    for enemy_variant: Variant in rescue_enemies:
        var enemy: AxEnemy = enemy_variant as AxEnemy
        if enemy != null and is_instance_valid(enemy):
            enemy.take_damage(99999.0)
    await _wait_frames(4)
    world.dynamic_world._update_active_event(0.1)
    if str(world.dynamic_world.active_event.get("stage", "")) != "secure":
        _fail("Rescue event did not require the player to secure the survivor after combat")
    if not world.dynamic_world.active_event.is_empty():
        var rescue_point: Vector2 = world.dynamic_world.active_event.get("point", world.player.global_position)
        world.player.global_position = rescue_point
        world.dynamic_world._update_active_event(1.3)
    if world.dynamic_world.rescues_completed != 1:
        _fail("Survivor rescue did not complete")

    world.dynamic_world._start_event("elite_hunt")
    var hunt_enemies: Array = world.dynamic_world.active_event.get("enemies", [])
    var found_elite: bool = false
    for enemy_variant: Variant in hunt_enemies:
        var enemy: AxEnemy = enemy_variant as AxEnemy
        if enemy != null and is_instance_valid(enemy) and enemy.elite:
            found_elite = true
            enemy.take_damage(99999.0)
    if not found_elite:
        _fail("Elite Hunt did not spawn an elite target")
    await _wait_frames(4)
    world.dynamic_world._update_active_event(0.1)
    if world.dynamic_world.elites_killed < 2:
        _fail("Elite kill accounting did not include rescue/hunt elites")

    world.dynamic_world._start_event("ambush")
    world.dynamic_world.active_event["time"] = 0.01
    world.dynamic_world._update_active_event(0.2)
    if world.dynamic_world.events_failed < 1:
        _fail("Timed dynamic event could not fail")
    if not world.dynamic_world.active_event.is_empty():
        _fail("Failed event did not clear its active state")

    var summary: Dictionary = world.dynamic_world.result_summary()
    if int(summary.get("completed", 0)) < 3:
        _fail("Dynamic event result summary lost completed events")
    if int(summary.get("chains", 0)) != 1 or int(summary.get("rescues", 0)) != 1:
        _fail("Dynamic event result summary lost chain/rescue detail")

    var saved_stats: Dictionary = GameState.dynamic_world_stats()
    if int(saved_stats.get("events", 0)) < 3 or int(saved_stats.get("elites", 0)) < 2:
        _fail("Dynamic world statistics were not persisted")

    world.queue_free()
    await _wait_frames(4)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.12 WORLD] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.12 WORLD] %s" % failure)
    get_tree().quit(1)
