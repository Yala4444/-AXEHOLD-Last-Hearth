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
    GameState.data["tutorial_complete"] = true
    GameState.visual_preview_v2 = true

    for path: String in AxPlayer.VISUAL_V2_TOOL_PATHS:
        if not ResourceLoader.exists(path):
            _fail("Missing orbit tool asset: " + path)
    if not ResourceLoader.exists(AxPlayer.VISUAL_V2_SPEAR_PATH):
        _fail("Missing Root Spear asset")
    for frame_id: String in AxPlayer.VISUAL_V2_FRAME_PATHS:
        if not ResourceLoader.exists(str(AxPlayer.VISUAL_V2_FRAME_PATHS[frame_id])):
            _fail("Missing coherent hero frame: " + frame_id)
    for idle_id: String in AxPlayer.VISUAL_V2_IDLE_PATHS:
        if not ResourceLoader.exists(str(AxPlayer.VISUAL_V2_IDLE_PATHS[idle_id])):
            _fail("Missing neutral production idle frame: " + idle_id)
    if not ResourceLoader.exists(ResourceSpot.PRODUCTION_TREE_STRIP_PATH):
        _fail("Missing painted production tree damage strip")
    if not ResourceLoader.exists(AxPlayer.VISUAL_V2_HERO_PATH):
        _fail("Missing production hero asset")
    for enemy_role: String in AxEnemy.VISUAL_GATE_WALK_PATHS:
        var enemy_walk_path: String = str(AxEnemy.VISUAL_GATE_WALK_PATHS[enemy_role])
        if not ResourceLoader.exists(enemy_walk_path):
            _fail("Missing Visual Gate enemy walk strip: " + enemy_role)
    if not ResourceLoader.exists(WorldActivity.RARE_ORE_ART_PATH):
        _fail("Missing painted rare-ore asset")

    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 1, "expedition")
    add_child(world)
    await _wait_frames(8)
    world.set_process(false)

    if not world.visual_v2_enabled:
        _fail("Full expedition did not receive the visual preview flag")
    if world.player == null or not world.player.visual_v2_enabled:
        _fail("Player production-art animation is not enabled")
    elif world.player.visual_v2_tools.size() != 4:
        _fail("Preview must load the four available weapon-family assets")
    elif world.player.visual_v2_frames.size() != 6:
        _fail("Production hero must load all six coherent animation frames")
    elif world.player.visual_v2_side_walk.size() != 6:
        _fail("VG-2 side walk must use six coherent stride frames")
    elif world.player.visual_v2_idle_frames.size() != 2:
        _fail("Master P0 must load dedicated front/side neutral idle art")
    elif world.player.visual_v2_frame_layouts.size() < 17:
        _fail("Master P0 did not normalize walk + idle frame layouts")
    elif world.player.movement_acceleration < 1400.0 or world.player.movement_deceleration < 1700.0:
        _fail("Master P0 movement responsiveness regressed to the sluggish tuning")
    elif world.player.weapon_style != "axes":
        _fail("Preview changed the equipped weapon profile")
    elif int(world.player.call("_visual_v2_orbit_count")) != world.player.axes:
        _fail("Visible orbit does not match the equipped weapon count")
    elif world.player.visual_v2_hero == null:
        _fail("Production hero texture failed to load")
    if world.visual_gate_fx == null or not is_instance_valid(world.visual_gate_fx):
        _fail("Visual Gate FX layer was not created for preview run")
    if world.hud == null or not world.hud.visual_gate_enabled:
        _fail("Visual Gate release HUD was not enabled")
    if world.camera == null or world.camera.position_smoothing_speed < 7.0:
        _fail("Visual Gate camera polish was not enabled")
    else:
        world.phase = "day"
        world.phase_time = 4.0
        world.visual_gate_fx._process(1.0)
        if world.visual_gate_fx.dusk_mix <= 0.05:
            _fail("Visual Gate dusk transition did not engage before night")
        world.phase = "night"
        world.visual_gate_fx._process(1.0)
        if world.visual_gate_fx.night_mix <= 0.05:
            _fail("Visual Gate night grade did not engage")
    if world.world_generator != null:
        for landmark: WorldLandmark in world.world_generator.landmark_nodes:
            if not is_instance_valid(landmark):
                continue
            if landmark.kind == "ancient_tree":
                _fail("Production forest spawned the boss-like ancient sentinel as scenery")
                break
            if landmark.kind == "firepit":
                _fail("Production forest spawned an inert dead firepit landmark")
                break
            if not landmark.visual_gate_enabled:
                _fail("Production landmark missed Master P1 grounding mode")
                break

    for pad: BuildPad in world.pads:
        if is_instance_valid(pad) and not pad.visual_gate_enabled:
            _fail("Production camp build pad missed Master P4 styling")
            break

    if world.activity_director != null:
        if world.activity_director.activities.size() > 4:
            _fail("Production forest spawned too many map activities")
        for activity: WorldActivity in world.activity_director.activities:
            if is_instance_valid(activity) and activity.activity_type in ["altar", "old_hearth", "signal_fire"]:
                _fail("Production forest spawned a retired fake-objective activity: " + activity.activity_type)
                break

    # A buildcraft/evolution choice is a true pause. Held joystick input must
    # be cancelled and actor physics must stop until the player makes a choice.
    world.player.set_move_input(Vector2.RIGHT)
    world.player.velocity = Vector2(64.0, 0.0)
    world._show_perks(world.player.level + 1)
    await _wait_frames(2)
    if not world.modal_gameplay_paused:
        _fail("Buildcraft modal did not pause gameplay")
    if world.player.is_physics_processing():
        _fail("Hero physics continued during buildcraft choice")
    if world.player.move_input.length_squared() > 0.0001 or world.player.velocity.length_squared() > 0.0001:
        _fail("Held joystick movement survived buildcraft modal")
    if not world.hud.modal_open():
        _fail("Buildcraft modal failed to open during pause test")
    world.hud.hide_modal()
    world._resume_gameplay_after_modal()
    if not world.player.is_physics_processing():
        _fail("Hero physics did not resume after modal choice")

    # Standing still must be a stable idle draw, not a live walk cycle.
    world.player.velocity = Vector2.ZERO
    world.player.walk_clock = 1.73
    world.player.queue_redraw()
    await _wait_frames(2)
    if world.player.velocity.length_squared() > 0.0001:
        _fail("Visual Gate idle test unexpectedly moved the hero")
    var side_idle := world.player.visual_v2_idle_frames.get("side") as Texture2D
    var frozen_walk := world.player.visual_v2_side_walk[3] if world.player.visual_v2_side_walk.size() >= 4 else null
    if side_idle == null:
        _fail("Master P0 side idle texture failed to load")
    elif side_idle == frozen_walk:
        _fail("Master P0 idle fell back to the old frozen walk frame")

    var damage_preview := ResourceSpot.new()
    world.add_child(damage_preview)
    damage_preview.configure("tree", 0, 0)
    damage_preview.set_visual_gate(true)
    if damage_preview.radius < 19.5:
        _fail("Master P2 production tree returned to prototype scale")
    if damage_preview.damage_stage() != 0:
        _fail("Fresh production resource starts damaged")
    damage_preview.hp = damage_preview.max_hp * 0.60
    if damage_preview.damage_stage() != 1:
        _fail("Production resource did not enter damaged stage")
    damage_preview.hp = damage_preview.max_hp * 0.25
    if damage_preview.damage_stage() != 2:
        _fail("Production resource did not enter severe damage stage")
    var harvest_streaks_before: int = world.core_fx.streaks.size() if world.core_fx != null else 0
    if world.core_fx != null:
        world.core_fx.resource_hit("wood", world.player.global_position + Vector2(18, 0), Vector2.RIGHT)
        if world.core_fx.streaks.size() <= harvest_streaks_before:
            _fail("Production harvest impact did not create readable contact feedback")
    damage_preview.queue_free()

    var rare_preview := WorldActivity.new()
    world.add_child(rare_preview)
    rare_preview.configure("rare_ore", 0)
    rare_preview.set_visual_gate(true)
    if not rare_preview.visual_gate_enabled:
        _fail("Rare ore did not inherit Visual Gate styling")
    rare_preview.queue_free()

    if world.core_fx == null or not world.core_fx.visual_gate_enabled:
        _fail("Visual Gate combat FX was not enabled")
    else:
        var streaks_before: int = world.core_fx.streaks.size()
        world.core_fx.enemy_hit(world.player.global_position + Vector2(22, 0), false, Vector2.RIGHT, "axes")
        if world.core_fx.streaks.size() <= streaks_before:
            _fail("Visual Gate weapon impact did not create a streak")
    if not ResourceLoader.exists(GameWorld.VISUAL_GATE_HEARTH_ART_PATH):
        _fail("Visual Gate hearth animation asset is missing")
    else:
        var hearth_texture := ResourceLoader.load(GameWorld.VISUAL_GATE_HEARTH_ART_PATH) as Texture2D
        if hearth_texture == null or hearth_texture.get_width() < GameWorld.VISUAL_GATE_HEARTH_FRAMES:
            _fail("Visual Gate hearth animation asset is invalid")

    var preview_enemy := AxEnemy.new()
    preview_enemy.configure("runner", 1.0, 1, Color.WHITE, false, 0)
    preview_enemy.set_visual_gate(true)
    if not preview_enemy.visual_gate_enabled:
        _fail("Visual Gate enemy styling was not enabled")
    var runner_profile: Dictionary = preview_enemy.production_visual_profile()
    if float(runner_profile.get("width",0.0)) < 130.0:
        _fail("Master P3 runner silhouette became too small")
    preview_enemy.configure("brute", 1.0, 1, Color.WHITE, false, 0)
    preview_enemy.set_visual_gate(true)
    var brute_profile: Dictionary = preview_enemy.production_visual_profile()
    if float(brute_profile.get("height",0.0)) < 150.0:
        _fail("Master P3 brute lost its heavy role scale")
    preview_enemy.configure("boss", 1.0, 1, Color.WHITE, true, 0)
    preview_enemy.set_visual_gate(true)
    var boss_profile: Dictionary = preview_enemy.production_visual_profile()
    if float(boss_profile.get("height",0.0)) < 250.0:
        _fail("Master P3 boss no longer dominates hero scale")
    preview_enemy.queue_free()

    var built_snapshot: Dictionary = world.built.duplicate(true)
    world.built["wall"] = true
    if world.production_camp_stage() < 1:
        _fail("Master P4 Hearth camp did not visually progress after a build")
    world.built = built_snapshot
    for layout_key: String in world.player.visual_v2_frame_layouts:
        var layout: Dictionary = world.player.visual_v2_frame_layouts[layout_key]
        if absf(float(layout.get("target_height", 0.0)) - AxPlayer.VISUAL_V2_TARGET_HEIGHT) > 0.01:
            _fail("VG-2 frame escaped the canonical body height: " + layout_key)
            break
        if absf(float(layout.get("foot_y", 0.0)) - AxPlayer.VISUAL_V2_FOOT_Y) > 0.01:
            _fail("VG-2 frame escaped the canonical foot baseline: " + layout_key)
            break

    world.queue_free()
    await _wait_frames(3)

    GameState.visual_preview_v2 = false
    var baseline: GameWorld = GameScene.instantiate() as GameWorld
    baseline.configure(0, 1, "expedition")
    add_child(baseline)
    await _wait_frames(6)
    baseline.set_process(false)
    if baseline.visual_v2_enabled:
        _fail("Stable expedition accidentally inherited Visual Gate mode")
    if baseline.visual_gate_fx != null and is_instance_valid(baseline.visual_gate_fx):
        _fail("Stable expedition created Visual Gate FX")
    if baseline.hud != null and baseline.hud.visual_gate_enabled:
        _fail("Stable expedition inherited Visual Gate HUD")
    if baseline.camera != null and absf(baseline.camera.position_smoothing_speed - 6.2) > 0.01:
        _fail("Stable expedition inherited Visual Gate camera tuning")
    if baseline.core_fx != null and baseline.core_fx.visual_gate_enabled:
        _fail("Stable expedition inherited Visual Gate combat FX")
    baseline.queue_free()
    await _wait_frames(3)

    GameState.data = snapshot
    _finish()

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.26 VISUAL V2] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        print("V1.26 VISUAL V2 FULL EXPEDITION SMOKE PASSED")
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.26 VISUAL V2] %s" % failure)
    get_tree().quit(1)
