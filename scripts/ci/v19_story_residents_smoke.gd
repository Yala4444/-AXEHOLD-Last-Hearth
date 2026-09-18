extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")
const AppScene: PackedScene = preload("res://scenes/app.tscn")
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

    _reset_story_state()
    _test_resident_rules()
    _test_chapter_transition()
    await _test_resident_runtime()
    await _test_camp_and_chronicle_ui()

    if failures.is_empty():
        print("[V1.9 STORY] chapter transition, Chronicle and resident chains passed")
    _finish()

func _reset_story_state() -> void:
    GameState.data["boss_relics"] = [false, false, false]
    GameState.data["story_state"] = {
        "chapter":1,
        "chapter1_ready_notified":false,
        "chapter1_seen":false,
        "chapter1_claimed":false
    }
    GameState.data["residents"] = {
        "mira":{"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0},
        "thorn":{"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0}
    }
    GameState.data["quest_state"] = {"date":"", "active":[], "used_ids":[], "claimed_today":0, "archive":0}
    GameState.save()

func _test_resident_rules() -> void:
    if ResidentRules.chain_size("mira") != 5:
        _fail("Mira should have five resident quests in v1.9")
    if ResidentRules.chain_size("thorn") != 4:
        _fail("Thorn should have four resident quests in v1.9")
    if ResidentRules.role_for("mira").is_empty() or ResidentRules.role_for("thorn").is_empty():
        _fail("Residents are missing readable camp roles")

func _test_chapter_transition() -> void:
    var shards_before: int = int(GameState.data.get("shards", 0))
    if GameState.chapter_one_ready():
        _fail("Chapter I became ready without all relics")

    GameState.data["boss_relics"] = [true, true, true]
    if not GameState.chapter_one_ready():
        _fail("Three relics did not unlock Chapter I finale")
        return

    var result: Dictionary = GameState.claim_chapter_one()
    if not bool(result.get("ok", false)):
        _fail("Ready Chapter I finale could not be claimed")
        return
    if not GameState.chapter_one_complete() or GameState.current_chapter() != 2:
        _fail("Chapter completion did not advance story to Chapter II")
    if int(GameState.data.get("shards", 0)) != shards_before + 2:
        _fail("Chapter I finale did not grant exactly two shards")

    var duplicate: Dictionary = GameState.claim_chapter_one()
    if bool(duplicate.get("ok", false)):
        _fail("Chapter I finale reward can be claimed twice")
    if int(GameState.data.get("shards", 0)) != shards_before + 2:
        _fail("Duplicate Chapter I claim changed shard balance")

func _test_resident_runtime() -> void:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(8)
    world.paused_local = true

    if world.activity_director == null:
        _fail("Activity Director missing in resident integration test")
        world.queue_free()
        await _wait_frames(2)
        return

    var guaranteed_scout: bool = false
    var guaranteed_tower: bool = false
    for activity: WorldActivity in world.activity_director.activities:
        if not is_instance_valid(activity):
            continue
        if activity.activity_type == "wounded_scout":
            guaranteed_scout = true
        elif activity.activity_type == "broken_tower":
            guaranteed_tower = true
    if not guaranteed_scout:
        _fail("Locked Mira no longer guarantees a rescue opportunity")
    if not guaranteed_tower:
        _fail("Locked Thorn no longer guarantees a tower signal opportunity")

    var scout := WorldActivity.new()
    world.add_child(scout)
    scout.configure("wounded_scout", 0)
    world.activity_director._grant_activity_reward(scout)

    var residents: Dictionary = GameState.data.get("residents", {})
    if not bool((residents.get("mira", {}) as Dictionary).get("unlocked", false)):
        _fail("Wounded Scout did not unlock Mira")

    QuestDirector.record("signal_fire", 2, {"biome":0})
    var mira_quest: Dictionary = QuestDirector.resident_quest_state("mira")
    if not bool(mira_quest.get("ready", false)):
        _fail("Mira quest chain did not react to field events")
    var mira_claim: Dictionary = QuestDirector.claim_resident("mira")
    if not bool(mira_claim.get("ok", false)):
        _fail("Mira quest reward could not be claimed")

    var tower := WorldActivity.new()
    world.add_child(tower)
    tower.configure("broken_tower", 0)
    world.activity_director._grant_activity_reward(tower)

    residents = GameState.data.get("residents", {})
    var thorn: Dictionary = residents.get("thorn", {})
    if not bool(thorn.get("unlocked", false)):
        _fail("Repairing a Broken Tower did not unlock Thorn")
    var thorn_quest: Dictionary = QuestDirector.resident_quest_state("thorn")
    if int(thorn_quest.get("progress", 0)) != 1:
        _fail("The tower that summoned Thorn did not count toward his first quest")

    QuestDirector.record("tower_repaired", 1, {"biome":0})
    thorn_quest = QuestDirector.resident_quest_state("thorn")
    if not bool(thorn_quest.get("ready", false)):
        _fail("Thorn's first quest did not become ready after two repairs")
    var thorn_claim: Dictionary = QuestDirector.claim_resident("thorn")
    if not bool(thorn_claim.get("ok", false)):
        _fail("Thorn quest reward could not be claimed")

    QuestDirector.record("mechanism_part", 4, {"biome":0})
    thorn_quest = QuestDirector.resident_quest_state("thorn")
    if not bool(thorn_quest.get("ready", false)):
        _fail("Thorn mechanism-part quest did not track rare parts")

    world.queue_free()
    await _wait_frames(3)

func _test_camp_and_chronicle_ui() -> void:
    var camp: CampView = CampScene.instantiate() as CampView
    add_child(camp)
    await _wait_frames(2)
    if not camp.action_buttons.has("chronicle"):
        _fail("Living Camp has no Chronicle hotspot")
    var signature: Dictionary = camp.progress_signature()
    if int(signature.get("chapter", 0)) != 2:
        _fail("Living Camp does not reflect completed Chapter I")
    camp.queue_free()
    await _wait_frames(2)

    var app: Node = AppScene.instantiate()
    add_child(app)
    await _wait_frames(5)
    if not app.has_method("_show_chronicle"):
        _fail("Camp UI has no Chronicle screen")
    else:
        app.call("_show_chronicle")
        await _wait_frames(3)
        var body_variant: Variant = app.get("body")
        if not (body_variant is Control):
            _fail("Chronicle screen did not keep a valid UI body")
        else:
            var body: Control = body_variant as Control
            if body.get_child_count() < 6:
                _fail("Chronicle screen rendered too little story content")
    app.queue_free()
    await _wait_frames(3)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.9 STORY] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.9 STORY] %s" % failure)
    get_tree().quit(1)
