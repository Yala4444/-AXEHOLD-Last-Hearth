extends Node

const CampScene: PackedScene = preload("res://scenes/camp_view.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    await get_tree().process_frame
    var camp: CampView = CampScene.instantiate() as CampView
    if camp == null:
        _fail("Cannot instantiate CampView")
        _finish()
        return

    add_child(camp)
    await get_tree().process_frame

    _set_progress([0, 0, 0], [false, false, false], ["axes"], "axes", 0)
    camp.refresh()
    await get_tree().process_frame
    var base: Dictionary = camp.progress_signature()
    if str(base.get("title", "")) != "Последний Очаг":
        _fail("Base camp title is incorrect")
    if bool(base.get("forge", true)):
        _fail("Forge should not be built in untouched camp")
    if bool(base.get("arsenal", true)):
        _fail("Arsenal should be hidden with one weapon")
    if int(base.get("residents", -1)) != 0:
        _fail("Untouched camp should have no residents")

    _set_progress([1, 1, 0], [true, true, false], ["axes", "spear", "hammer"], "hammer", 2)
    camp.refresh()
    await get_tree().process_frame
    var living: Dictionary = camp.progress_signature()
    if str(living.get("title", "")) != "Живой Лагерь":
        _fail("Living camp title was not reached at mastery 2")
    if int(living.get("relic_count", 0)) != 2:
        _fail("Living camp should display two relics")
    if not bool(living.get("forge", false)) or not bool(living.get("arsenal", false)):
        _fail("Living camp should show forge and arsenal")
    if str(living.get("weapon", "")) != "hammer":
        _fail("Camp weapon rack did not reflect selected weapon")

    _set_progress([3, 3, 3], [true, true, true], ["axes", "spear", "hammer", "twin_blades"], "twin_blades", 9)
    camp.refresh()
    await get_tree().process_frame
    var fortress: Dictionary = camp.progress_signature()
    if str(fortress.get("title", "")) != "Крепость Последнего Огня":
        _fail("Fortress title was not reached at mastery 9")
    if not bool(fortress.get("watchtower", false)) or not bool(fortress.get("stronghold", false)):
        _fail("Fortress visuals did not unlock at mastery 9")
    if int(fortress.get("residents", 0)) < 6:
        _fail("Fortress should visibly populate with residents")
    if int(fortress.get("relic_count", 0)) != 3:
        _fail("Fortress should display all three guardian relics")

    var arsenal_button: Button = camp.action_buttons.get("arsenal") as Button
    if arsenal_button == null or not arsenal_button.visible:
        _fail("Arsenal hotspot should be visible once multiple weapons are owned")

    print("[CAMP] living camp progression OK")
    camp.queue_free()
    await get_tree().process_frame
    _finish()

func _set_progress(mastery: Array, relic_values: Array, owned: Array, weapon: String, win_count: int) -> void:
    GameState.data["biome_mastery"] = mastery.duplicate(true)
    GameState.data["boss_relics"] = relic_values.duplicate(true)
    GameState.data["weapons_owned"] = owned.duplicate(true)
    GameState.data["selected_weapon"] = weapon
    GameState.data["wins"] = win_count

func _finish() -> void:
    if failures.is_empty():
        print("[CAMP] AXEHOLD living camp validation passed")
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[CAMP] %s" % failure)
    get_tree().quit(1)

func _fail(message: String) -> void:
    failures.append(message)
    print("[CAMP] FAIL: ", message)
