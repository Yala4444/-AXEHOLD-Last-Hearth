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

    _reset_contract_state()
    _test_contract_board()
    _test_camp_growth()
    _test_resident_bonuses()
    await _test_run_contract_integration()
    await _test_contract_ui()

    if failures.is_empty():
        print("[V1.11 CAMP] contract board, renown, residents and living camp growth passed")
    _finish()

func _reset_contract_state() -> void:
    GameState.data["camp_renown"] = 0
    GameState.data["biome_mastery"] = [0, 0, 0]
    GameState.data["contract_state"] = {
        "date":"",
        "offers":[],
        "selected":"",
        "completed_today":[],
        "completed_total":0
    }
    GameState.data["residents"] = {
        "mira":{"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0},
        "thorn":{"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0}
    }
    GameState.ensure_contract_board()
    GameState.save()

func _test_contract_board() -> void:
    var offers: Array[String] = GameState.contract_offers()
    if offers.size() != 3:
        _fail("Contract board did not generate exactly three offers")
        return
    var unique: Dictionary = {}
    for contract_id: String in offers:
        unique[contract_id] = true
        if GameRules.contract_by_id(contract_id).is_empty():
            _fail("Contract board contains unknown contract: " + contract_id)
    if unique.size() != 3:
        _fail("Contract board generated duplicate offers")

    var selected: String = offers[1]
    if not GameState.select_contract(selected):
        _fail("Available contract could not be selected")
    if GameState.selected_contract_id() != selected:
        _fail("Selected contract was not persisted")

    var renown_before: int = GameState.camp_renown()
    var result: Dictionary = GameState.complete_contract_meta(selected)
    var expected: int = GameRules.contract_renown(selected)
    if not bool(result.get("ok", false)):
        _fail("Selected contract meta completion failed")
    if GameState.camp_renown() != renown_before + expected:
        _fail("Contract did not award expected camp renown")
    var duplicate: Dictionary = GameState.complete_contract_meta(selected)
    if bool(duplicate.get("ok", false)):
        _fail("Daily contract renown can be claimed twice")
    if GameState.camp_renown() != renown_before + expected:
        _fail("Duplicate contract completion changed renown")

func _test_camp_growth() -> void:
    GameState.data["biome_mastery"] = [0, 0, 0]
    GameState.data["camp_renown"] = 0
    if GameState.camp_level() != 1:
        _fail("Fresh camp should be Level 1")

    GameState.data["camp_renown"] = 3
    if GameState.camp_level() != 2:
        _fail("Renown 3 should unlock camp Level 2")
    GameState.data["camp_renown"] = 8
    if GameState.camp_level() != 3:
        _fail("Renown 8 should unlock camp Level 3")
    GameState.data["camp_renown"] = 15
    if GameState.camp_level() != 4:
        _fail("Renown 15 should unlock camp Level 4")
    GameState.data["camp_renown"] = 25
    if GameState.camp_level() != 5:
        _fail("Renown 25 should unlock camp Level 5")

func _test_resident_bonuses() -> void:
    GameState.data["residents"] = {
        "mira":{"unlocked":true,"trust":5,"quest_step":5,"quest_progress":0},
        "thorn":{"unlocked":true,"trust":4,"quest_step":4,"quest_progress":0}
    }
    var bonuses: Dictionary = GameState.expedition_resident_bonuses()
    if float(bonuses.get("move_mult", 1.0)) < 1.049:
        _fail("Mira max trust does not improve expedition movement")
    if float(bonuses.get("preview_bonus", 0.0)) < 5.9:
        _fail("Mira max trust does not provide earlier night preview")
    if int(bonuses.get("starting_parts", 0)) != 2:
        _fail("Thorn max trust should provide two starting parts")
    if float(bonuses.get("tower_damage_mult", 1.0)) <= 1.0:
        _fail("Thorn max trust should improve Tower damage")

func _test_run_contract_integration() -> void:
    var state: Dictionary = GameState.data.get("contract_state", {})
    state["date"] = Time.get_date_string_from_system()
    state["offers"] = ["outer_reach", "nest_hunter", "hearthkeeper"]
    state["selected"] = "outer_reach"
    state["completed_today"] = []
    GameState.data["contract_state"] = state
    GameState.data["camp_renown"] = 0
    GameState.data["biome_mastery"] = [0, 0, 0]
    GameState.save()

    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(8)
    world.paused_local = true

    if world.run_variation == null:
        _fail("RunVariationDirector missing")
    else:
        if str(world.run_variation.contract.get("id", "")) != "outer_reach":
            _fail("Expedition did not use selected board contract")
        if not world.run_variation.contract_from_board:
            _fail("Selected contract was not marked as board contract")

        var before: int = GameState.camp_renown()
        world.run_variation._complete_contract()
        var expected: int = GameRules.contract_renown("outer_reach")
        if GameState.camp_renown() != before + expected:
            _fail("In-run contract completion did not award renown")
        var snapshot: Dictionary = world.run_variation.contract_result()
        if not bool(snapshot.get("completed", false)) or int(snapshot.get("renown", 0)) != expected:
            _fail("Contract result snapshot lost completion or renown")

    if int(world.storage.get("parts", 0)) < 2:
        _fail("Thorn starting-part bonus did not enter expedition storage")
    if world.player.move_speed <= world.player.base_meta_speed:
        _fail("Mira trust bonus did not affect expedition player speed")

    world.queue_free()
    await _wait_frames(3)

func _test_contract_ui() -> void:
    var camp: CampView = CampScene.instantiate() as CampView
    add_child(camp)
    await _wait_frames(2)
    if not camp.action_buttons.has("contracts"):
        _fail("Living Camp has no Contracts hotspot")
    var signature: Dictionary = camp.progress_signature()
    if not signature.has("camp_level") or not signature.has("renown"):
        _fail("Camp progress signature lacks v1.11 growth state")
    camp.queue_free()
    await _wait_frames(2)

    var app: Node = AppScene.instantiate()
    add_child(app)
    await _wait_frames(5)
    if not app.has_method("_show_contracts"):
        _fail("Camp UI has no contract board screen")
    else:
        app.call("_show_contracts")
        await _wait_frames(3)
        var body_variant: Variant = app.get("body")
        if not (body_variant is Control):
            _fail("Contract screen did not keep a valid UI body")
        else:
            var body: Control = body_variant as Control
            if body.get_child_count() < 7:
                _fail("Contract screen rendered too little content")
    app.queue_free()
    await _wait_frames(3)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.11 CAMP] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.11 CAMP] %s" % failure)
    get_tree().quit(1)
