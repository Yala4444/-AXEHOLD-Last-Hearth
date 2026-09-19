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

    await _test_field_objectives()
    await _test_player_compass_and_weapon_motion()
    _test_new_quest_specs()
    _test_persistent_stats()

    if failures.is_empty():
        print("[V1.15 LIVING] field objectives, compass cues, weapon motion and progression passed")
    _finish()

func _test_field_objectives() -> void:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(8)

    if world.field_objectives == null:
        _fail("FieldObjectiveDirector was not attached to GameWorld")
        world.queue_free()
        return

    world.field_objectives.set_process(false)
    world.dynamic_world.set_process(false)
    world.biome_events.set_process(false)

    world.field_objectives.start_objective_for_test("survey", 0)
    if world.field_objectives.active.is_empty():
        _fail("Survey field objective did not start")
    else:
        var point: Vector2 = world.field_objectives.active.get("point", world.player.global_position)
        if not world.player.field_hint_active:
            _fail("Field objective did not enable the player compass cue")
        world.player.global_position = point
        var required: float = float(world.field_objectives.active.get("required", 1.5))
        world.field_objectives._update_active(required + 0.1)
        await _wait_frames(2)
        if world.field_objectives.completed < 1:
            _fail("Survey field objective did not complete after holding the marker")
        if world.player.field_hint_active:
            _fail("Player compass cue stayed active after field objective completion")

    world.field_objectives.start_objective_for_test("salvage", 1)
    if str(world.field_objectives.active.get("kind", "")) != "salvage":
        _fail("Salvage field objective could not be started deterministically")
    else:
        var salvage_point: Vector2 = world.field_objectives.active.get("point", world.player.global_position)
        world.player.global_position = salvage_point
        var salvage_required: float = float(world.field_objectives.active.get("required", 2.2))
        var parts_before: int = int(world.storage.get("parts", 0))
        world.field_objectives._update_active(salvage_required + 0.1)
        await _wait_frames(2)
        if int(world.storage.get("parts", 0)) <= parts_before:
            _fail("Salvage field objective did not award a mechanism part")

    world.field_objectives.start_objective_for_test("purge", 2)
    if str(world.field_objectives.active.get("kind", "")) != "purge":
        _fail("Purge field objective could not be started")
    elif world.field_objectives._alive_enemies() < 3:
        _fail("Purge field objective did not create a combat pack")

    var summary: Dictionary = world.field_objectives.result_summary()
    if not summary.has("completed") or not summary.has("perfect"):
        _fail("Field objective result summary is incomplete")

    world.queue_free()
    await _wait_frames(5)

func _test_player_compass_and_weapon_motion() -> void:
    var player := AxPlayer.new()
    add_child(player)
    player.setup({"damage":0,"hp":0,"bag":0,"speed":0}, GameRules.skin(0))
    player.apply_weapon_profile("spear")
    player.set_field_target(Vector2(200,0), true, Color("d5a652"))
    if not player.field_hint_active:
        _fail("Player field target state did not activate")
    var angle_before: float = player.angle
    player._physics_process(0.20)
    if player.angle <= angle_before:
        _fail("Weapon orbit angle did not advance")
    player.apply_weapon_profile("hammer")
    var hammer_before: float = player.angle
    player._physics_process(0.20)
    if player.angle <= hammer_before:
        _fail("Hammer orbit angle did not advance")
    player.queue_free()

func _test_new_quest_specs() -> void:
    for quest_id: String in ["field_runner", "clean_field"]:
        if QuestRules.spec(quest_id).is_empty():
            _fail("Missing v1.15 field objective quest: " + quest_id)

func _test_persistent_stats() -> void:
    var before: Dictionary = GameState.field_objective_stats()
    if not before.has("completed") or not before.has("failed") or not before.has("perfect"):
        _fail("Field objective persistent stat schema is incomplete")

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.15 LIVING] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.15 LIVING] %s" % failure)
    get_tree().quit(1)
