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

    await _test_encounter_attention_budget()
    await _test_transparent_buildcraft_and_hud_queue()

    GameState.data = snapshot
    GameState.save()

    if failures.is_empty():
        print("[V1.20 COHERENCE] encounter arbitration, transparent choices and HUD queue passed")
    _finish()

func _fresh_world() -> GameWorld:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    return world

func _pause_directors(world: GameWorld) -> void:
    world.set_process(false)
    world.dynamic_world.set_process(false)
    world.field_objectives.set_process(false)
    world.biome_events.set_process(false)
    world.activity_director.set_process(false)

func _test_encounter_attention_budget() -> void:
    var world: GameWorld = _fresh_world()
    await _wait_frames(8)
    _pause_directors(world)

    if world.encounter_orchestrator == null:
        _fail("EncounterOrchestrator was not attached")
        world.queue_free()
        return

    var orchestrator: EncounterOrchestrator = world.encounter_orchestrator
    orchestrator.cooldown = 0.0
    if not world.field_objectives._start_kind("survey", 0):
        _fail("Field objective could not acquire the encounter slot")
    if world.dynamic_world._start_event("caravan_defense"):
        _fail("Major event overlapped an active field objective")

    world.field_objectives._clear("resolved")
    if orchestrator.cooldown <= 0.0:
        _fail("Encounter completion did not create breathing room")
    if world.dynamic_world._start_event("caravan_defense"):
        _fail("Major event ignored the post-encounter cooldown")

    orchestrator.cooldown = 0.0
    if not world.dynamic_world._start_event("caravan_defense"):
        _fail("Major event did not start after the slot became available")
    elif orchestrator.active_owner() != str(world.dynamic_world.active_event.get("id", "")):
        _fail("Encounter owner and active event lost synchronization")
    world.dynamic_world._clear_active_event("resolved")

    var summary: Dictionary = orchestrator.result_summary()
    if int(summary.get("completed_slots", 0)) < 2:
        _fail("Encounter history did not preserve resolved slots")
    if int(summary.get("denied_requests", 0)) < 2:
        _fail("Encounter arbitration did not record denied overlaps")

    world.queue_free()
    await _wait_frames(4)

func _test_transparent_buildcraft_and_hud_queue() -> void:
    var world: GameWorld = _fresh_world()
    await _wait_frames(8)
    _pause_directors(world)

    var damage_before: float = world.player.damage
    var hp_before: float = world.player.max_hp
    var capacity_before: int = world.player.capacity
    var result: Dictionary = world.buildcraft.apply_choice("bag", "epic", "coherence_test")
    if world.player.capacity != capacity_before + 8:
        _fail("Visible Bag effect was not applied exactly")
    if not is_equal_approx(world.player.damage, damage_before) or not is_equal_approx(world.player.max_hp, hp_before):
        _fail("Rarity still applies an unrelated hidden combat bonus")
    if bool(result.get("hidden_stat_bonus", false)):
        _fail("Buildcraft result reports a hidden rarity bonus")

    world.player.apply_perk("damage")
    world.player.apply_perk("damage")
    var preview: String = world.buildcraft.choice_text({
        "id":"fire_orb",
        "name":"Огненная сфера",
        "desc":"Вокруг героя вращается огненная сфера",
        "rarity":"rare"
    })
    if preview.find("ЭФФЕКТ:") < 0 or preview.find("КОРОНА ПЕПЛА") < 0:
        _fail("Buildcraft card does not preview its exact effect and imminent evolution")

    # Isolate the queue from the expedition's startup announcement.
    world.hud.banner_queue.clear()
    world.hud.banner_running = false
    world.hud.banner_current_text = ""
    world.hud.show_banner("АКТИВНО", Color.WHITE, 0)
    world.hud.show_banner("НИЗКИЙ", Color.WHITE, 1)
    world.hud.show_banner("КРИТИЧЕСКИЙ", Color.WHITE, 9)
    world.hud.show_banner("КРИТИЧЕСКИЙ", Color.WHITE, 9)
    if world.hud.banner_queue.size() != 2:
        _fail("HUD banner queue did not deduplicate messages")
    elif str(world.hud.banner_queue[0].get("text", "")) != "КРИТИЧЕСКИЙ":
        _fail("HUD banner queue did not prioritize critical information")

    world.hud.set_status("ВАЖНО", 10, 3.0)
    world.hud.set_status("ФОНОВОЕ", 0, 3.0)
    if world.hud.status_label.text != "ВАЖНО":
        _fail("Low-priority toast replaced critical status text")

    world.queue_free()
    await _wait_frames(4)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.20 COHERENCE] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.20 COHERENCE] %s" % failure)
    get_tree().quit(1)
