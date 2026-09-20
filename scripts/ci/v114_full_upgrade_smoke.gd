extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")
const CampScene: PackedScene = preload("res://scenes/camp_view.tscn")
const AppScene: PackedScene = preload("res://scenes/app.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["weapons_owned"] = ["axes", "spear", "hammer", "twin_blades"]
    GameState.data["selected_weapon"] = "spear"

    await _test_world_foundation()
    await _test_app_gameplay_backdrop()
    await _test_camp_affordances()
    _test_new_perks()
    _test_quest_specs()

    if failures.is_empty():
        print("[V1.14 FULL] WebGL fallback, weapon orbit, camp UX, biome events and build perks passed")
    _finish()

func _test_world_foundation() -> void:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(8)

    if world.world_fill_layer == null or world.world_fill == null:
        _fail("Screen-space biome fallback was not installed")
    else:
        if world.world_fill_layer.layer > -50:
            _fail("Biome fallback is not safely behind the world")
        if world.world_fill.color.get_luminance() < 0.08:
            _fail("Biome fallback is effectively black")
        if world.world_fill.size.x < 100.0 or world.world_fill.size.y < 100.0:
            _fail("Biome fallback did not cover the viewport")

    if world.biome_events == null:
        _fail("BiomeEventDirector was not attached")
    else:
        world.biome_events.set_process(false)
        world.biome_events._start_environment_event()
        if not world.biome_events.active_environment:
            _fail("Regional environment event did not start")
        world.biome_events._spawn_environment_hazard()
        if world.biome_events.hazards.is_empty():
            _fail("Regional environment event did not create a telegraphed hazard")
        world.biome_events._finish_environment(true, "")

        world.wave = 2
        world.encounter_orchestrator.cooldown = 0.0
        world.biome_events._start_regional_hunt()
        if world.biome_events.mini_boss == null or not is_instance_valid(world.biome_events.mini_boss):
            _fail("Regional hunt did not create a rare target")
        elif world.biome_events.mini_boss.elite_trait != "root_alpha":
            _fail("Forest regional hunt did not use its biome elite identity")

    world.player.apply_weapon_profile("spear")
    var before_angle: float = world.player.angle
    await _wait_frames(5)
    var after_angle: float = world.player.angle
    if is_equal_approx(before_angle, after_angle):
        _fail("Spear visual orbit angle did not advance")
    if world.player.orbit_radius < 50.0:
        _fail("Spear orbit radius collapsed")

    var summary: Dictionary = world.biome_events.result_summary() if world.biome_events != null else {}
    if not summary.has("completed") or not summary.has("hunts"):
        _fail("Regional event result summary is incomplete")

    world.queue_free()
    await _wait_frames(5)

func _test_app_gameplay_backdrop() -> void:
    var app: Control = AppScene.instantiate() as Control
    add_child(app)
    await _wait_frames(5)

    var menu_background: ColorRect = app.get("menu_background") as ColorRect
    var menu_vignette: ColorRect = app.get("menu_vignette") as ColorRect
    if menu_background == null or menu_vignette == null:
        _fail("Mobile app did not expose menu-only backdrop layers")
    else:
        if not menu_background.visible or not menu_vignette.visible:
            _fail("Menu backdrop should be visible while in camp")

    app.call("_start_game")
    await _wait_frames(8)

    if menu_background != null and menu_background.visible:
        _fail("Menu background remained visible behind gameplay and can leak as a black WebGL quadrant")
    if menu_vignette != null and menu_vignette.visible:
        _fail("Menu vignette remained visible behind gameplay")
    var active_game: GameWorld = app.get("active_game") as GameWorld
    if active_game == null:
        _fail("App did not enter gameplay while testing menu backdrop isolation")
    elif active_game.world_fill == null:
        _fail("Gameplay world has no screen-space biome fill after menu backdrop is hidden")

    if active_game != null:
        active_game.queue_free()
        app.set("active_game", null)
    app.queue_free()
    await _wait_frames(4)

func _test_camp_affordances() -> void:
    var camp: CampView = CampScene.instantiate() as CampView
    add_child(camp)
    camp.size = Vector2(360, 455)
    await _wait_frames(4)

    for key: String in ["forge", "arsenal", "goals", "quests", "contracts", "chronicle", "map"]:
        var button: Button = camp.action_buttons.get(key) as Button
        if button == null:
            _fail("Camp destination missing: " + key)
            continue
        if button.size.x < 60.0 or button.size.y < 44.0:
            _fail("Camp destination is still too small to understand/tap: " + key)
        var label: Label = button.get_node_or_null("ActionLabel") as Label
        if label == null or label.text.strip_edges().is_empty():
            _fail("Camp destination has no visible label: " + key)

    camp.queue_free()
    await _wait_frames(3)

func _test_new_perks() -> void:
    var player := AxPlayer.new()
    add_child(player)
    player.setup({"damage":0,"hp":0,"bag":0,"speed":0}, GameRules.skin(0))

    player.apply_perk("harvest_heal")
    player.apply_perk("hearth_aura")
    player.apply_perk("loaded_pack")
    player.apply_perk("hunter_rhythm")

    if player.harvest_heal_per_node < 2.9:
        _fail("Harvest-heal perk did not alter gameplay state")
    if player.hearth_damage_bonus < 0.34:
        _fail("Hearth aura perk did not alter damage state")
    if player.loaded_pack_damage_bonus < 0.24:
        _fail("Loaded-pack perk did not alter damage state")
    if player.kill_heal_every != 10 or player.kill_heal_amount < 11.9:
        _fail("Hunter rhythm perk did not alter kill reward state")

    player.queue_free()

func _test_quest_specs() -> void:
    for quest_id: String in ["region_master", "regional_hunter"]:
        if QuestRules.spec(quest_id).is_empty():
            _fail("Missing v1.14 regional quest: " + quest_id)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.14 FULL] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.14 FULL] %s" % failure)
    get_tree().quit(1)
