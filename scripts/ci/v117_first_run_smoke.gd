extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")
const AppScene: PackedScene = preload("res://scenes/app.tscn")

var failures: Array[String] = []
var snapshot: Dictionary = {}

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    snapshot = GameState.data.duplicate(true)

    _test_tutorial_state()
    _test_threat_relief_rules()
    _test_mobile_safe_progress_labels()
    await _test_mobile_settings_shell()
    await _test_clean_tutorial_world()
    await _test_threat_two_first_night()

    GameState.data = snapshot
    GameState.save()

    if failures.is_empty():
        print("[V1.17 FIRST RUN] onboarding isolation and first-night calibration passed")
    _finish()

func _test_tutorial_state() -> void:
    GameState.data = GameState.defaults()
    if not GameState.tutorial_should_run():
        _fail("Fresh save should enter tutorial")
    GameState.complete_tutorial()
    if GameState.tutorial_should_run():
        _fail("Completed tutorial should not auto-run again")
    GameState.restart_tutorial()
    if not GameState.tutorial_should_run():
        _fail("Replay tutorial flag did not reactivate onboarding")
    if int(GameState.data.get("selected_biome",-1)) != 0 or int(GameState.data.get("selected_threat",-1)) != 1:
        _fail("Replay tutorial did not force Forgotten Forest / Threat I")

func _test_threat_relief_rules() -> void:
    var threat_two: Dictionary = ThreatRules.first_night_relief(2,1)
    if float(threat_two.get("spawn",1.0)) >= 1.0:
        _fail("Threat II first night still has full spawn pressure")
    if float(threat_two.get("base_damage",1.0)) >= 0.90:
        _fail("Threat II first-night Hearth damage relief is too weak")
    var later: Dictionary = ThreatRules.first_night_relief(2,2)
    if absf(float(later.get("spawn",0.0)) - 1.0) > 0.001:
        _fail("Threat II relief leaked into later nights")
    if ThreatRules.readiness_text(2).strip_edges().is_empty():
        _fail("Threat II has no preparation guidance")

func _test_mobile_safe_progress_labels() -> void:
    GameState.data = GameState.defaults()
    var weapon_progress: String = GameState.weapon_mastery_stars("axes")
    if weapon_progress.contains("★") or weapon_progress.contains("☆") or not weapon_progress.ends_with("/5"):
        _fail("Weapon mastery still uses unsupported star glyphs")

    var threat_progress: String = ThreatRules.stars(2)
    if threat_progress != "2/5":
        _fail("Threat mastery is not using numeric mobile-safe progress")

    var legacy_notice: String = UISanitizer.clean_text("Мастерство оружия: Пепельные клинки → ★☆☆☆☆")
    if legacy_notice != "Мастерство оружия: Пепельные клинки — 1/5":
        _fail("Legacy mastery notice sanitizer did not convert star glyphs")

func _test_mobile_settings_shell() -> void:
    GameState.data = GameState.defaults()
    GameState.data["coach_complete"] = true
    var app: Node = AppScene.instantiate()
    add_child(app)
    await _wait_frames(4)
    app.call("_show_settings")
    await _wait_frames(2)
    var frame: Control = app.get("nav_frame") as Control
    if frame == null:
        _fail("Mobile navigation frame missing")
    elif frame.visible:
        _fail("Empty mobile navigation frame remains visible in Settings")
    app.queue_free()
    await _wait_frames(3)

func _test_clean_tutorial_world() -> void:
    GameState.data = GameState.defaults()
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0,1,"expedition")
    add_child(world)
    await _wait_frames(8)

    if not world.tutorial_run:
        _fail("GameWorld did not mark fresh first path as tutorial")
    if world.activity_director == null:
        _fail("Activity director missing")
    elif not world.activity_director.activities.is_empty():
        _fail("Tutorial spawned exploration activities before basics were taught")

    if world.dynamic_world != null:
        world.dynamic_world.event_timer = -1.0
        world.dynamic_world._process(1.0)
        if not world.dynamic_world.active_event.is_empty():
            _fail("Dynamic event leaked into tutorial run")

    if world.field_objectives != null:
        world.field_objectives.start_delay = -1.0
        world.field_objectives._process(1.0)
        if not world.field_objectives.active.is_empty():
            _fail("Field objective leaked into tutorial run")

    if world.biome_events != null:
        world.wave = 1
        world.phase_time = 5.0
        world.biome_events._process(1.0)
        if world.biome_events.active_environment:
            _fail("Biome hazard event leaked into tutorial run")

    world.queue_free()
    await _wait_frames(5)

func _test_threat_two_first_night() -> void:
    GameState.data = GameState.defaults()
    GameState.data["coach_complete"] = true
    GameState.data["selected_biome"] = 0
    GameState.data["selected_threat"] = 2
    GameState.data["threat_unlocked"] = [2,1,1]

    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0,2,"expedition")
    add_child(world)
    await _wait_frames(8)

    if world.tutorial_run:
        _fail("Threat II should never be treated as tutorial")
    world._start_night()
    var raw_count: int = GameRules.wave_count(1,float(world.biome.get("difficulty",1.0)))
    var old_full_pressure: int = int(round(float(raw_count) * float(ThreatRules.spec(2).get("spawn",1.0))))
    if world.spawn_left >= old_full_pressure:
        _fail("Threat II first night was not reduced from v1.16 pressure")

    var enemy := AxEnemy.new()
    add_child(enemy)
    enemy.configure("normal",1.0,1,Color("755b76"),false,0)
    var base_hp: float = enemy.max_hp
    world._apply_threat_to_enemy(enemy,false)
    var full_threat_hp: float = base_hp * float(ThreatRules.spec(2).get("enemy_hp",1.0))
    if enemy.max_hp >= full_threat_hp:
        _fail("Threat II first-night enemy HP did not receive a relief ramp")
    enemy.queue_free()

    world.queue_free()
    await _wait_frames(5)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.17 FIRST RUN] FAIL: ",message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.17 FIRST RUN] %s" % failure)
    get_tree().quit(1)
