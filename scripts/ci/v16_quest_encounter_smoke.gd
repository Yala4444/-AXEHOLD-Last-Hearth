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

    await _test_daily_rotation()
    await _test_resident_chain()
    await _test_encounter_pool()

    if failures.is_empty():
        print("[V1.6 QUESTS] daily rotation, resident chain and encounter expansion passed")
    _finish()

func _test_daily_rotation() -> void:
    GameState.data["quest_state"] = {"date":"", "active":[], "used_ids":[], "claimed_today":0, "archive":0}
    QuestDirector.ensure_daily_quests()
    var active: Array[Dictionary] = QuestDirector.active_quests()
    if active.size() != 3:
        _fail("Daily board did not generate exactly three active quests")
        return

    var quest: Dictionary = active[0]
    var event_name: String = str(quest.get("event", ""))
    var goal: int = int(quest.get("goal", 1))
    var context: Dictionary = {}
    var filter_key: String = str(quest.get("filter_key", ""))
    if not filter_key.is_empty():
        context[filter_key] = quest.get("filter_value")

    QuestDirector.record(event_name, goal, context)
    active = QuestDirector.active_quests()
    var ready: bool = false
    var quest_id: String = str(quest.get("id", ""))
    for item: Dictionary in active:
        if str(item.get("id", "")) == quest_id:
            ready = bool(item.get("ready", false))
            break
    if not ready:
        _fail("Daily quest did not reach ready state after matching progress")
        return

    var claims_before: int = QuestDirector.claims_left_today()
    var result: Dictionary = QuestDirector.claim(quest_id)
    if not bool(result.get("ok", false)):
        _fail("Ready daily quest could not be claimed")
        return
    if QuestDirector.claims_left_today() != claims_before - 1:
        _fail("Daily claim budget did not decrement")
    if QuestDirector.active_quests().size() != 3:
        _fail("Claimed quest was not replaced with the next rotating task")

func _test_resident_chain() -> void:
    var residents: Dictionary = GameState.data.get("residents", {})
    residents["mira"] = {"unlocked":true, "trust":0, "quest_step":0, "quest_progress":0}
    GameState.data["residents"] = residents
    GameState.save()

    QuestDirector.record("signal_fire", 2, {"biome":0})
    var quest: Dictionary = QuestDirector.resident_quest_state("mira")
    if not bool(quest.get("ready", false)):
        _fail("Mira resident quest did not react to signal fires")
        return

    var result: Dictionary = QuestDirector.claim_resident("mira")
    if not bool(result.get("ok", false)):
        _fail("Mira resident quest could not be claimed")
        return
    residents = GameState.data.get("residents", {})
    var mira: Dictionary = residents.get("mira", {})
    if int(mira.get("trust", 0)) != 1 or int(mira.get("quest_step", 0)) != 1:
        _fail("Resident trust/quest step did not advance")

func _test_encounter_pool() -> void:
    var expected: Array[String] = [
        "rare_ore", "broken_tower", "wind_shrine", "wanderer_grave",
        "signal_fire", "infected_cache", "memory_rift", "wounded_scout"
    ]
    for kind: String in expected:
        var activity := WorldActivity.new()
        add_child(activity)
        activity.configure(kind, 0)
        if activity._title().is_empty():
            _fail("Encounter has no readable title: " + kind)
        activity.queue_free()
    await _wait_frames(2)

    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(8)

    if world.activity_director == null:
        _fail("Activity Director missing")
    else:
        if world.activity_director.activities.size() < 7:
            _fail("Activity Director 2.0 populated too few encounters")
        var unique: Dictionary = {}
        var new_count: int = 0
        for activity: WorldActivity in world.activity_director.activities:
            if not is_instance_valid(activity):
                continue
            unique[activity.activity_type] = true
            if expected.has(activity.activity_type):
                new_count += 1
        if unique.size() < 5:
            _fail("Run encounter mix is not diverse enough")
        if new_count < 1:
            _fail("Expanded encounter pool did not place any new activity")

        var residents: Dictionary = GameState.data.get("residents", {})
        residents["mira"] = {"unlocked":false, "trust":0, "quest_step":0, "quest_progress":0}
        GameState.data["residents"] = residents

        var scout := WorldActivity.new()
        world.add_child(scout)
        scout.configure("wounded_scout", 0)
        world.activity_director._grant_activity_reward(scout)
        residents = GameState.data.get("residents", {})
        if not bool((residents.get("mira", {}) as Dictionary).get("unlocked", false)):
            _fail("Wounded scout encounter did not unlock Mira")

    world.queue_free()
    await _wait_frames(3)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.6 QUESTS] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.6 QUESTS] %s" % failure)
    get_tree().quit(1)
