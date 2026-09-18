extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    _prepare_state()
    _test_chapter_one_finale()
    _test_frontier_assignment_delivery()
    _test_assignment_deadline()
    _test_thorn_chain_and_support()
    await _test_world_guarantees()
    await _test_map_frontier_node()

    if failures.is_empty():
        print("[V1.9 LIVING WORLD] finale, frontier assignments, Thorn and support passed")
    _finish()

func _prepare_state() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["boss_relics"] = [true, true, true]
    GameState.data["story_state"] = {"chapter1_complete":false, "frontier_signal":false}
    GameState.data["frontier_state"] = {
        "selected_assignment":"",
        "assignment_progress":0,
        "assignment_ready":false,
        "assignment_failed":false,
        "assignments_completed":0,
        "assignment_history":{},
        "selected_support":""
    }
    GameState.data["residents"] = {
        "mira":{"unlocked":true,"trust":1,"quest_step":0,"quest_progress":0},
        "thorn":{"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0}
    }
    GameState._sync_chapter_one_from_relics(false)
    GameState.save()

func _test_chapter_one_finale() -> void:
    if not GameState.chapter_one_complete():
        _fail("Three relics did not complete Chapter I")
    if not GameState.frontier_signal_unlocked():
        _fail("Chapter I completion did not unlock the Frontier Signal")

func _test_frontier_assignment_delivery() -> void:
    if not GameState.select_frontier_assignment("beacon"):
        _fail("Frontier assignment could not be selected")
        return
    var assignment: Dictionary = QuestDirector.begin_frontier_assignment_run()
    if str(assignment.get("id", "")) != "beacon":
        _fail("Selected frontier assignment did not begin")
        return

    QuestDirector.record("signal_fire", 1, {"wave":0,"biome":0})
    QuestDirector.record("signal_fire", 1, {"wave":1,"biome":0})
    var ready: Dictionary = QuestDirector.frontier_assignment_state()
    if not bool(ready.get("ready", false)):
        _fail("Frontier objective did not become ready at goal")
        return

    var coins_before: int = int(GameState.data.get("coins", 0))
    var away: Dictionary = QuestDirector.try_complete_frontier_assignment_at_hearth(false, "day")
    if bool(away.get("ok", false)):
        _fail("Frontier objective delivered while away from Hearth")

    var delivered: Dictionary = QuestDirector.try_complete_frontier_assignment_at_hearth(true, "day")
    if not bool(delivered.get("ok", false)):
        _fail("Ready frontier assignment could not be delivered at Hearth")
    if int(GameState.data.get("coins", 0)) <= coins_before:
        _fail("Frontier assignment reward was not paid")
    if int((GameState.data.get("frontier_state", {}) as Dictionary).get("assignments_completed", 0)) != 1:
        _fail("Frontier completion count did not advance")
    if not GameState.frontier_assignment_id().is_empty():
        _fail("Delivered frontier assignment did not clear")

func _test_assignment_deadline() -> void:
    GameState.select_frontier_assignment("purge")
    QuestDirector.begin_frontier_assignment_run()
    if not QuestDirector.tick_frontier_assignment(2):
        _fail("Frontier assignment did not fail after its second-night deadline")
    var state: Dictionary = QuestDirector.frontier_assignment_state()
    if not bool(state.get("failed", false)):
        _fail("Failed frontier assignment state was not persisted")
    QuestDirector.end_frontier_assignment_run()
    if not GameState.frontier_assignment_id().is_empty():
        _fail("Failed frontier assignment did not clear after run end")

func _test_thorn_chain_and_support() -> void:
    var residents: Dictionary = GameState.data.get("residents", {})
    residents["thorn"] = {"unlocked":true,"trust":0,"quest_step":0,"quest_progress":0}
    GameState.data["residents"] = residents
    GameState.save()

    QuestDirector.record("mechanism_part", 4, {"wave":0,"biome":0})
    var thorn_quest: Dictionary = QuestDirector.resident_quest_state("thorn")
    if not bool(thorn_quest.get("ready", false)):
        _fail("Thorn's first quest did not react to Mechanism Parts")
        return
    var claim: Dictionary = QuestDirector.claim_resident("thorn")
    if not bool(claim.get("ok", false)):
        _fail("Thorn's first resident quest could not be claimed")
        return
    if not GameState.support_available("thorn_kit"):
        _fail("Thorn support did not unlock at Trust I")
    if not GameState.support_available("mira_route"):
        _fail("Mira support should be available at Trust I")
    if not GameState.select_run_support("thorn_kit"):
        _fail("Thorn support could not be armed")

func _test_world_guarantees() -> void:
    GameState.select_frontier_assignment("beacon")
    var residents: Dictionary = GameState.data.get("residents", {})
    residents["thorn"] = {"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0}
    GameState.data["residents"] = residents

    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(8)

    var signal_count: int = 0
    var engineer_count: int = 0
    for activity: WorldActivity in world.activity_director.activities:
        if not is_instance_valid(activity):
            continue
        if activity.activity_type == "signal_fire":
            signal_count += 1
        elif activity.activity_type == "stranded_engineer":
            engineer_count += 1

    if signal_count < 2:
        _fail("Beacon assignment did not guarantee two Signal Fires")
    if engineer_count < 1:
        _fail("Post-Chapter-I world did not spawn Thorn rescue encounter")

    if int(world.storage.get("parts", 0)) != 1:
        _fail("Armed Thorn support did not grant one starting Mechanism Part")
    if not GameState.selected_run_support().is_empty():
        _fail("Resident support was not consumed at expedition start")

    # Resolve the engineer directly to verify permanent resident unlock.
    for activity: WorldActivity in world.activity_director.activities:
        if is_instance_valid(activity) and activity.activity_type == "stranded_engineer":
            world.activity_director._grant_activity_reward(activity)
            break
    residents = GameState.data.get("residents", {})
    if not bool((residents.get("thorn", {}) as Dictionary).get("unlocked", false)):
        _fail("Stranded Engineer encounter did not unlock Thorn")

    world.queue_free()
    await _wait_frames(4)
    GameState.clear_frontier_assignment()

func _test_map_frontier_node() -> void:
    var map := WorldMapView.new()
    add_child(map)
    map.custom_minimum_size = Vector2(360, 455)
    map.size = Vector2(360, 455)
    await _wait_frames(3)
    if map.node_buttons.size() != 4:
        _fail("World Map does not expose the fourth Frontier node")
    elif map.node_buttons[3].disabled:
        _fail("Frontier node remained locked after Chapter I completion")
    map.queue_free()
    await _wait_frames(2)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.9 LIVING WORLD] FAIL: ", message)

func _finish() -> void:
    GameState.clear_frontier_assignment()
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.9 LIVING WORLD] %s" % failure)
    get_tree().quit(1)
