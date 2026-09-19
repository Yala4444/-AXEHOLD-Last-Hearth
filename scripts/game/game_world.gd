class_name GameWorld
extends Node2D

signal run_finished(result: Dictionary)
signal quit_requested
signal enemy_defeated(enemy: AxEnemy)

const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")
const ResourceScene: PackedScene = preload("res://scenes/resource_spot.tscn")
const BuildPadScene: PackedScene = preload("res://scenes/build_pad.tscn")

var biome_index: int = 0
var biome: Dictionary = {}
var threat_level: int = 1
var run_mode: String = "expedition"
var tutorial_run: bool = false
var endless_checkpoint_wave: int = 0
var endless_chest_boosted: bool = false
var relic_thorn_timer: float = 2.5
var relic_spirit_timer: float = 18.0
var player: AxPlayer
var hud: GameHud
var core_fx: CoreFX
var base_position: Vector2 = Vector2.ZERO
var base_hp: float = 270.0
var base_max_hp: float = 270.0
var storage: Dictionary = {"wood": 0, "stone": 0, "ore": 0, "parts": 0}
var built: Dictionary = {"wall": false, "forge": false, "turret": false, "shrine": false}
var pads: Array[BuildPad] = []
var resources: Array[ResourceSpot] = []
var enemies: Array[AxEnemy] = []
var phase: String = "day"
var phase_time: float = 46.0
var phase_max: float = 46.0
var wave: int = 0
var spawn_left: int = 0
var spawn_timer: float = 0.0
var boss_spawned: bool = false
var boss_ref: AxEnemy = null
var run_coins: int = 0
var run_shards: int = 0
var kills: int = 0
var builds: int = 0
var trees_cut: int = 0
var revived: bool = false
var paused_local: bool = false
var finishing: bool = false
var turret_timer: float = 0.0
var turret_shot_time: float = 0.0
var turret_shot_from: Vector2 = Vector2.ZERO
var turret_shot_to: Vector2 = Vector2.ZERO
var boss_warning_active: bool = false
var boss_warning_position: Vector2 = Vector2.ZERO
var boss_warning_time: float = 0.0
var bag_full_announced: bool = false
var deposit_pulse: float = 0.0
var world_size: Vector2 = Vector2(1170, 2532)
var world_rect: Rect2 = Rect2(Vector2.ZERO, world_size)
var camera: Camera2D
var camera_lookahead: Vector2 = Vector2.ZERO
var camera_shake_strength: float = 0.0
var camera_shake_time: float = 0.0
var backdrop: WorldBackdrop
var world_generator: WorldGenerator
var activity_director: WorldActivityDirector
var run_variation: RunVariationDirector
var dynamic_world: DynamicWorldDirector
var biome_events: BiomeEventDirector
var field_objectives: FieldObjectiveDirector
var world_fill_layer: CanvasLayer
var world_fill: ColorRect

var resource_yield_multiplier: float = 1.0
var turret_global_damage_mult: float = 1.0
var turret_global_fire_mult: float = 1.0
var turret_disabled_time: float = 0.0
var wall_damage_multiplier: float = 0.35
var wall_slow_multiplier: float = 0.58
var wall_spike_dps: float = 0.0
var shrine_regen_multiplier: float = 1.0
var shrine_ward_active: bool = false
var pending_upgrade_pad: BuildPad = null

# Weapon Identity runtime state.
var weapon_attack_timer: float = 0.0
var weapon_combo: int = 0
var weapon_combo_timeout: float = 0.0
var weapon_last_hit_count: int = 0

func configure(index: int, selected_threat: int = 1, mode: String = "expedition") -> void:
    biome_index = index
    threat_level = clampi(selected_threat, 1, ThreatRules.MAX_LEVEL)
    run_mode = mode if mode in ["expedition","endless"] else "expedition"
    tutorial_run = run_mode == "expedition" and biome_index == 0 and threat_level == 1 and GameState.tutorial_should_run()

func _ready() -> void:
    core_fx = CoreFX.new()
    add_child(core_fx)
    hud = GameHud.new()
    add_child(hud)
    hud.action_requested.connect(_on_hud_action)
    _start_run()

func _start_run() -> void:
    biome_index = clampi(biome_index, 0, GameRules.BIOMES.size() - 1)
    biome = GameRules.biome(biome_index)
    var viewport_size: Vector2 = get_viewport_rect().size
    world_size = Vector2(
        maxf(1380.0, viewport_size.x * 3.75),
        maxf(2860.0, viewport_size.y * 3.75)
    )
    world_rect = Rect2(Vector2.ZERO, world_size)
    base_position = world_size * 0.5
    _install_screen_fill()

    backdrop = WorldBackdrop.new()
    add_child(backdrop)
    backdrop.setup(world_size, base_position, biome, biome_index)

    world_generator = WorldGenerator.new()
    add_child(world_generator)
    world_generator.setup(self)

    activity_director = WorldActivityDirector.new()
    add_child(activity_director)
    activity_director.setup(self, world_generator)

    run_variation = RunVariationDirector.new()
    add_child(run_variation)
    run_variation.setup(self)

    var threat_spec: Dictionary = ThreatRules.spec(threat_level)
    phase_max = GameRules.day_duration(0) * float(threat_spec.get("day",1.0))
    phase_time = phase_max

    player = PlayerScene.instantiate() as AxPlayer
    add_child(player)
    player.global_position = base_position + Vector2(0, 42)
    var upgrades: Dictionary = GameState.data["upgrades"]
    var skin_index: int = int(GameState.data.get("selected_skin", 0))
    player.setup(upgrades, GameRules.skin(skin_index))
    var relic_bonuses: Dictionary = GameState.relic_forge_bonuses()
    player.damage *= float(relic_bonuses.get("damage_mult",1.0))
    player.max_hp += float(relic_bonuses.get("hp_bonus",0.0))
    player.hp = player.max_hp
    var resident_bonuses: Dictionary = GameState.expedition_resident_bonuses()
    player.move_speed *= float(resident_bonuses.get("move_mult", 1.0))
    storage["parts"] = int(storage.get("parts", 0)) + int(resident_bonuses.get("starting_parts", 0))
    turret_global_damage_mult *= float(resident_bonuses.get("tower_damage_mult", 1.0))
    turret_global_damage_mult *= float(ThreatRules.spec(threat_level).get("tower",1.0))
    player.set_world_bounds(world_rect.grow(-34.0))
    player.set_home_target(base_position)
    _setup_camera()
    player.died.connect(_on_player_died)
    player.damaged.connect(_on_player_damaged)
    player.level_up_requested.connect(_show_perks)

    dynamic_world = DynamicWorldDirector.new()
    add_child(dynamic_world)
    dynamic_world.setup(self)

    biome_events = BiomeEventDirector.new()
    add_child(biome_events)
    biome_events.setup(self)

    field_objectives = FieldObjectiveDirector.new()
    add_child(field_objectives)
    field_objectives.setup(self)

    _create_pads()
    for _i in range(52):
        _spawn_resource("tree")
    for _i in range(20):
        _spawn_resource("rock")
    var initial_ore: int = 12 if biome_index == 2 else 9
    for _i in range(initial_ore):
        _spawn_resource("ore")

    Analytics.event("run_start", {"biome":biome_index,"weapon":player.weapon_id,"threat":threat_level,"mode":run_mode})
    if run_mode == "endless":
        hud.show_banner("ПОСЛЕДНИЙ РУБЕЖ · " + str(biome["name"]).to_upper(), Color("e3b56a"))
        hud.set_run_objective("БЕСКОНЕЧНЫЙ РЕЖИМ · рекорд %d" % int((GameState.data.get("endless_stats",{}) as Dictionary).get("best_wave",0)))
    else:
        hud.show_banner("%s · УГРОЗА %d" % [str(biome["name"]).to_upper(), threat_level])
    var resident_part_bonus: int = int(storage.get("parts", 0))
    if resident_part_bonus > 0:
        hud.set_status("Торн подготовил %d дет. · собирай добычу и возвращайся к Очагу." % resident_part_bonus)
    elif GameState.resident_trust("mira") > 0:
        hud.set_status("Мира отметила маршрут. Собирай добычу и возвращайся к Очагу.")
    else:
        hud.set_status("Собирай добычу и возвращайся к Очагу.")

    var settings: Dictionary = GameState.data["settings"]
    if tutorial_run:
        hud.show_banner("ПЕРВЫЙ ПУТЬ СТРАННИКА", Color("f3d58d"))
        hud.set_run_objective("ОБУЧЕНИЕ · 1/5 · ОСВОЙ ДВИЖЕНИЕ")
        hud.set_status("Проведи пальцем по экрану. Странник движется за твоим жестом.")
    elif bool(settings.get("hints", true)) and not bool(GameState.data.get("v1_tutorial_complete", false)):
        GameState.data["v1_tutorial_complete"] = true
        GameState.save()
        hud.show_banner("РУБИ ДНЁМ. ДЕРЖИ ОБОРОНУ НОЧЬЮ.", Color("f3d58d"))
        hud.set_status("Оружие работает автоматически. Днём добывай ресурсы, ночью защищай Очаг.")
    _refresh_hud()
    queue_redraw()

func _install_screen_fill() -> void:
    # iOS/WebGL occasionally exposes an undrawn world chunk as a black quadrant.
    # This screen-space biome fill lives behind all world CanvasItems, so even if
    # a chunk is culled or briefly misses a frame the player never sees black.
    if world_fill_layer != null and is_instance_valid(world_fill_layer):
        world_fill_layer.queue_free()
    world_fill_layer = CanvasLayer.new()
    world_fill_layer.layer = -100
    add_child(world_fill_layer)
    world_fill = ColorRect.new()
    world_fill_layer.add_child(world_fill)
    world_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var ground_color := Color(str(biome.get("ground", "5e795c")))
    world_fill.color = ground_color.darkened(0.04)
    world_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _update_world_fill(delta: float) -> void:
    if world_fill == null or player == null:
        return
    var top := Color(str(biome.get("sky", "80936c")))
    var bottom := Color(str(biome.get("ground", "5e795c")))
    var world_t: float = clampf(player.global_position.y / maxf(1.0, world_size.y), 0.0, 1.0)
    var target: Color = top.lerp(bottom, 0.30 + world_t * 0.50)
    if phase == "night":
        var night_color := Color("24363b") if biome_index < 2 else Color("432b2c")
        target = target.lerp(night_color, 0.58)
    world_fill.color = world_fill.color.lerp(target, clampf(delta * 2.6, 0.0, 1.0))

func _setup_camera() -> void:
    camera = Camera2D.new()
    player.add_child(camera)
    camera.position = Vector2.ZERO
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.2
    var viewport_size: Vector2 = get_viewport_rect().size
    var half_view: Vector2 = viewport_size * 0.5
    camera.limit_left = int(world_rect.position.x + half_view.x)
    camera.limit_top = int(world_rect.position.y + half_view.y)
    camera.limit_right = int(world_rect.end.x - half_view.x)
    camera.limit_bottom = int(world_rect.end.y - half_view.y)
    camera.limit_smoothed = false
    camera.make_current()

func _update_camera_lookahead(delta: float) -> void:
    if camera == null or player == null:
        return
    var target_offset := Vector2.ZERO
    if player.velocity.length_squared() > 64.0:
        target_offset = player.velocity.normalized() * 24.0
    camera_lookahead = camera_lookahead.lerp(target_offset, clampf(delta * 4.6, 0.0, 1.0))

    camera_shake_time = maxf(0.0, camera_shake_time - delta)
    camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 18.0)
    var shake := Vector2.ZERO
    if camera_shake_time > 0.0 and camera_shake_strength > 0.05:
        var ticks: float = float(Time.get_ticks_msec()) * 0.001
        shake = Vector2(
            sin(ticks * 53.0) + sin(ticks * 89.0) * 0.45,
            cos(ticks * 61.0) + sin(ticks * 97.0) * 0.35
        ) * camera_shake_strength
    camera.position = camera_lookahead + shake

func trigger_camera_shake(strength: float, duration: float = 0.14) -> void:
    camera_shake_strength = maxf(camera_shake_strength, strength)
    camera_shake_time = maxf(camera_shake_time, duration)

func _process(delta: float) -> void:
    deposit_pulse = maxf(0.0, deposit_pulse - delta * 2.8)
    turret_shot_time = maxf(0.0, turret_shot_time - delta * 8.0)
    turret_disabled_time = maxf(0.0, turret_disabled_time - delta)

    if paused_local or finishing or hud.modal_open():
        queue_redraw()
        return

    _harvest(delta)
    _deposit_and_build(delta)
    _maintain_resources()
    _update_building_passives(delta)
    _update_relic_perks(delta)
    _update_camera_lookahead(delta)
    _update_world_fill(delta)
    var bag_ratio: float = float(player.inventory_total()) / float(maxi(1, player.capacity))
    var return_soon: bool = phase == "night" or bag_ratio >= 0.82 or (phase == "day" and phase_time <= 12.0)
    player.set_home_hint(return_soon and player.global_position.distance_to(base_position) > 110.0)

    if phase == "day":
        _update_day_enemies(delta)
        phase_time -= delta
        if phase_time <= 0.0:
            _start_night()
    else:
        _update_night(delta)

    if boss_warning_active:
        boss_warning_time -= delta
        if boss_warning_time <= 0.0:
            boss_warning_active = false

    _refresh_hud()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if finishing or paused_local or hud.modal_open():
        return
    # Touch input is owned by the floating joystick. Mouse remains a desktop fallback.
    if event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
            player.set_target(_screen_to_world(button.position))
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        var motion := event as InputEventMouseMotion
        player.set_target(_screen_to_world(motion.position))

func _screen_to_world(screen_position: Vector2) -> Vector2:
    return get_viewport().get_canvas_transform().affine_inverse() * screen_position

func _create_pads() -> void:
    for spec_variant: Variant in GameRules.BUILD_SPECS:
        var spec: Dictionary = spec_variant
        var pad: BuildPad = BuildPadScene.instantiate() as BuildPad
        add_child(pad)
        var offset: Vector2 = spec.get("offset", Vector2.ZERO)
        var build_cost: Dictionary = spec.get("cost", {})
        pad.global_position = base_position + offset
        pad.configure(
            str(spec.get("id", "wall")),
            str(spec.get("name", "ПОСТРОЙКА")),
            build_cost,
            false,
            str(spec.get("effect", ""))
        )
        pads.append(pad)

func _spawn_resource(kind: String) -> void:
    var spot: ResourceSpot = ResourceScene.instantiate() as ResourceSpot
    add_child(spot)
    spot.global_position = _resource_spawn_position(kind)
    spot.configure(kind, randi() % 3, biome_index)
    resources.append(spot)

func _resource_spawn_position(kind: String) -> Vector2:
    if world_generator != null:
        for _attempt in range(24):
            var point: Vector2 = world_generator.resource_point(kind)
            var blocked: bool = point.distance_to(base_position) < 145.0
            if not blocked:
                for pad: BuildPad in pads:
                    if is_instance_valid(pad) and point.distance_to(pad.global_position) < 58.0:
                        blocked = true
                        break
            if not blocked:
                return point
    return base_position + Vector2(190, 0)

func _maintain_resources() -> void:
    var counts: Dictionary = {"tree": 0, "rock": 0, "ore": 0}
    for spot: ResourceSpot in resources:
        if is_instance_valid(spot):
            counts[spot.resource_type] = int(counts.get(spot.resource_type, 0)) + 1
    while int(counts["tree"]) < 38:
        _spawn_resource("tree")
        counts["tree"] = int(counts["tree"]) + 1
    while int(counts["rock"]) < 15:
        _spawn_resource("rock")
        counts["rock"] = int(counts["rock"]) + 1
    var ore_target: int = 9 if biome_index == 2 else 7
    while int(counts["ore"]) < ore_target:
        _spawn_resource("ore")
        counts["ore"] = int(counts["ore"]) + 1

func _harvest(delta: float) -> void:
    if player.inventory_total() >= player.capacity:
        if not bag_full_announced:
            bag_full_announced = true
            hud.show_banner("РЮКЗАК ПОЛОН", Color("f1d38b"))
            hud.set_status("Вернись к Очагу и разгрузи добычу.")
        return

    bag_full_announced = false
    var reach: float = player.orbit_radius + player.axes * 4.0
    var candidates: Array[Dictionary] = []

    for spot: ResourceSpot in resources:
        if not is_instance_valid(spot):
            continue
        var distance: float = player.global_position.distance_to(spot.global_position)
        if distance <= reach + spot.radius:
            candidates.append({"spot":spot, "distance":distance})

    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))
    )

    var target_limit: int = candidates.size()
    if player.weapon_style == "spear":
        target_limit = mini(1, candidates.size())
    elif player.weapon_style == "twin_blades":
        target_limit = mini(2, candidates.size())

    var removed: Array[ResourceSpot] = []
    for i: int in range(target_limit):
        var spot: ResourceSpot = candidates[i].get("spot") as ResourceSpot
        if spot == null or not is_instance_valid(spot):
            continue

        var harvest_damage: float = player.damage * delta * GameRules.harvest_multiplier(spot.resource_type) * WeaponRules.mechanic_value(player.weapon_id, "harvest_mult", 1.0)
        if spot.damage(harvest_damage):
            var kind: String = "wood" if spot.resource_type == "tree" else ("stone" if spot.resource_type == "rock" else "ore")
            var amount: int = maxi(1, int(round(
                float(GameRules.resource_yield(spot.resource_type, biome_index)) * resource_yield_multiplier
            )))
            var actual: int = player.add_resource(kind, amount)
            if spot.resource_type == "tree":
                trees_cut += 1
                GameState.mission_add("trees")
            player.gain_xp(2)
            if actual > 0:
                if player.harvest_heal_per_node > 0.0:
                    player.heal(player.harvest_heal_per_node)
                QuestDirector.record("harvest_" + kind, actual, {"biome":biome_index})
                var resource_name: String = "дерево" if kind == "wood" else ("камень" if kind == "stone" else "руда")
                hud.set_status("+%d %s в рюкзак" % [actual, resource_name])
                if core_fx != null:
                    core_fx.harvest(kind, spot.global_position, actual, player.global_position)
            removed.append(spot)

    for spot: ResourceSpot in removed:
        resources.erase(spot)
        spot.queue_free()

func _deposit_and_build(delta: float) -> void:
    if player.global_position.distance_to(base_position) < 68.0 and player.inventory_total() > 0:
        var inv: Dictionary = player.clear_inventory()
        for key: String in ["wood", "stone", "ore"]:
            storage[key] = int(storage.get(key, 0)) + int(inv.get(key, 0))
        deposit_pulse = 1.0
        bag_full_announced = false
        hud.show_banner("ДОБЫЧА НА СКЛАДЕ", Color("d9c17e"))
        hud.set_status("Д +%d  К +%d  Р +%d" % [int(inv["wood"]), int(inv["stone"]), int(inv["ore"])])
        Feedback.play("level", 5)
        if core_fx != null:
            core_fx.deposit(inv, player.global_position, base_position + Vector2(39, 20))

    var nearest: BuildPad = null
    var nearest_distance: float = INF

    for pad: BuildPad in pads:
        if not is_instance_valid(pad):
            continue

        var distance: float = player.global_position.distance_to(pad.global_position)
        if distance < nearest_distance:
            nearest = pad
            nearest_distance = distance

        if not pad.built:
            pad.set_context_state(pad.can_build(storage), distance <= 92.0)
            if distance <= 38.0 and pad.can_build(storage):
                if pad.advance_construction(delta):
                    _complete_build(pad)
            elif distance > 45.0:
                pad.reset_construction()
            continue

        var upgrade_unlocked: bool = GameState.has_building_project(pad.build_type)
        var can_upgrade_now: bool = upgrade_unlocked and pad.level == 1 and pad.can_upgrade(storage, int(storage.get("parts", 0)))
        pad.set_context_state(can_upgrade_now, distance <= 92.0)

        if pad.level == 1 and upgrade_unlocked and phase == "day" and pending_upgrade_pad == null:
            if distance <= 38.0 and can_upgrade_now:
                if pad.advance_upgrade(delta):
                    _show_build_upgrade_choices(pad)
            elif distance > 45.0:
                pad.reset_upgrade()
        elif pad.level == 1 and distance > 45.0:
            pad.reset_upgrade()

    if nearest != null and nearest_distance <= 92.0:
        if not nearest.built:
            hud.set_build_context(
                nearest.label,
                nearest.effect,
                nearest.cost,
                storage,
                nearest.can_build(storage),
                nearest.construction_progress
            )
        elif nearest.level == 1 and GameState.has_building_project(nearest.build_type):
            var upgrade_cost: Dictionary = BuildingRules.upgrade_cost(nearest.build_type)
            var ready: bool = nearest.can_upgrade(storage, int(storage.get("parts", 0)))
            var branch_names: Array[String] = []
            for branch: Dictionary in BuildingRules.branches(nearest.build_type):
                branch_names.append(str(branch.get("name", "ВЕТКА")))
            hud.set_build_context(
                nearest.label + " I → II",
                "Выбор: " + " / ".join(PackedStringArray(branch_names)),
                upgrade_cost,
                storage,
                ready,
                nearest.upgrade_progress,
                int(upgrade_cost.get("parts", 0)),
                int(storage.get("parts", 0))
            )
        elif nearest.level == 1:
            hud.set_built_context(nearest.label + " I", nearest.effect + " · Ур. II открывается чертежом в Кузнице лагеря")
        else:
            hud.set_built_context(
                nearest.label + " II · " + BuildingRules.branch_title(nearest.build_type, nearest.upgrade_branch),
                BuildingRules.branch_effect(nearest.build_type, nearest.upgrade_branch)
            )
    else:
        hud.hide_build_context()

func add_mechanism_parts(amount: int, source: Vector2 = Vector2.ZERO) -> void:
    if amount <= 0:
        return
    storage["parts"] = int(storage.get("parts", 0)) + amount
    QuestDirector.record("mechanism_part", amount, {"biome":biome_index,"wave":wave})
    hud.show_banner("+%d ДЕТАЛЬ" % amount if amount == 1 else "+%d ДЕТАЛИ" % amount, Color("c7d0cf"))
    hud.set_status("Редкая деталь хранится отдельно и нужна для построек II.")
    if core_fx != null and source != Vector2.ZERO:
        core_fx.enemy_hit(source, false)
    Feedback.play("level", 4)

func _show_build_upgrade_choices(pad: BuildPad) -> void:
    if pad == null or not is_instance_valid(pad) or pad.level != 1:
        return
    pending_upgrade_pad = pad
    var buttons: Array = []
    for branch: Dictionary in BuildingRules.branches(pad.build_type):
        buttons.append({
            "text":"%s — %s" % [str(branch.get("name", "ВЕТКА")), str(branch.get("desc", ""))],
            "action":"build_upgrade:%s:%s" % [pad.build_type, str(branch.get("id", ""))]
        })
    buttons.append({"text":"ПОКА НЕ УЛУЧШАТЬ","action":"build_upgrade:cancel"})
    hud.show_modal(
        "",
        pad.label + " · УРОВЕНЬ II",
        "Редкая деталь позволяет специализировать постройку. Выбор действует до конца экспедиции.",
        buttons
    )

func _apply_build_upgrade(build_type: String, branch_id: String) -> void:
    if pending_upgrade_pad == null or not is_instance_valid(pending_upgrade_pad):
        hud.hide_modal()
        pending_upgrade_pad = null
        return
    var pad: BuildPad = pending_upgrade_pad
    if pad.build_type != build_type or pad.level != 1:
        hud.hide_modal()
        pending_upgrade_pad = null
        return

    var upgrade_cost: Dictionary = BuildingRules.upgrade_cost(build_type)
    if not pad.can_upgrade(storage, int(storage.get("parts", 0))):
        hud.hide_modal()
        pending_upgrade_pad = null
        hud.set_status("Ресурсов для улучшения уже не хватает.")
        return

    for key: String in ["wood", "stone", "ore"]:
        storage[key] = int(storage.get(key, 0)) - int(upgrade_cost.get(key, 0))
    storage["parts"] = int(storage.get("parts", 0)) - int(upgrade_cost.get("parts", 0))

    pad.apply_upgrade(branch_id)
    _apply_building_branch_effect(build_type, branch_id)
    builds += 1
    QuestDirector.record("build_upgrade", 1, {"type":build_type, "branch":branch_id, "biome":biome_index})
    Analytics.event("building_upgraded", {"type":build_type, "branch":branch_id, "wave":wave, "biome":biome_index})
    hud.hide_modal()
    pending_upgrade_pad = null
    hud.show_banner("%s II · %s" % [pad.label, BuildingRules.branch_title(build_type, branch_id)], Color("f3d58d"))
    hud.set_status(BuildingRules.branch_effect(build_type, branch_id))
    Feedback.play("level", 16)
    if core_fx != null:
        core_fx.build_complete(pad.global_position, pad.label + " II")

func _apply_building_branch_effect(build_type: String, branch_id: String) -> void:
    match branch_id:
        "bastion":
            base_max_hp += 140.0
            base_hp = minf(base_max_hp, base_hp + 140.0)
            wall_damage_multiplier = 0.22
            wall_slow_multiplier = 0.42
        "spikes":
            base_max_hp += 80.0
            base_hp = minf(base_max_hp, base_hp + 80.0)
            wall_damage_multiplier = 0.30
            wall_slow_multiplier = 0.48
            wall_spike_dps = 9.0
        "temper":
            player.damage *= 1.22
        "reach":
            player.orbit_radius += 12.0
            player.crit_chance = minf(0.65, player.crit_chance + 0.04)
        "ballista":
            turret_global_damage_mult *= 1.75
            turret_global_fire_mult *= 1.28
        "repeater":
            turret_global_damage_mult *= 0.88
            turret_global_fire_mult *= 0.58
        "renewal":
            shrine_regen_multiplier *= 2.0
        "ward":
            shrine_regen_multiplier *= 1.35
            shrine_ward_active = true
            player.shield_hits = mini(5, player.shield_hits + 2)

func _complete_build(pad: BuildPad) -> void:
    if pad.built or not pad.can_build(storage):
        return
    pad.consume(storage)
    built[pad.build_type] = true
    builds += 1
    GameState.mission_add("builds")
    QuestDirector.record("build_structure", 1, {"type":pad.build_type, "biome":biome_index})
    player.gain_xp(7)

    match pad.build_type:
        "wall":
            base_max_hp += 160.0
            base_hp = minf(base_max_hp, base_hp + 160.0)
        "forge":
            player.damage *= 1.30
            player.orbit_radius += 6.0
        "shrine":
            player.max_hp += 30.0
            player.hp = minf(player.max_hp, player.hp + 30.0)
            base_hp = minf(base_max_hp, base_hp + 55.0)
        "turret":
            turret_timer = 0.15

    hud.show_banner(pad.label + " ГОТОВ", Color("f4d486"))
    hud.set_status(pad.effect)
    Feedback.play("level", 12)
    if core_fx != null:
        core_fx.build_complete(pad.global_position, pad.label)

func _update_building_passives(delta: float) -> void:
    if bool(built["shrine"]):
        player.heal(delta * (0.75 if phase == "day" else 0.35) * shrine_regen_multiplier)
        var base_regen: float = (0.85 if phase == "day" else 0.22) * shrine_regen_multiplier
        base_hp = minf(base_max_hp, base_hp + delta * base_regen)

func _start_night() -> void:
    phase = "night"
    if backdrop != null:
        backdrop.set_night(true)
    wave += 1

    var base_spawn_count: int = GameRules.wave_count(wave, float(biome["difficulty"]))
    if run_variation != null:
        run_variation.prepare_night(wave)
        base_spawn_count = run_variation.modify_spawn_count(base_spawn_count)
    var first_night_relief: Dictionary = ThreatRules.first_night_relief(threat_level, wave)
    base_spawn_count = int(round(
        float(base_spawn_count)
        * float(ThreatRules.spec(threat_level).get("spawn",1.0))
        * float(first_night_relief.get("spawn",1.0))
    ))
    if tutorial_run and wave == 1:
        base_spawn_count = mini(base_spawn_count, 7)
    if run_mode == "endless":
        base_spawn_count = int(round(float(base_spawn_count) * ThreatRules.endless_spawn_multiplier(wave)))
    spawn_left = maxi(1, base_spawn_count)

    if activity_director != null:
        var nest_extra: int = activity_director.night_extra_enemies()
        spawn_left += nest_extra
        if nest_extra > 0:
            hud.set_status("%d активных гнёзд усиливают эту ночь." % activity_director.unresolved_nests())
    spawn_timer = 0.1
    boss_spawned = false
    hud.hide_build_context()
    if tutorial_run and wave == 1:
        hud.show_banner("ПЕРВАЯ НОЧЬ · ЗАЩИТИ ОЧАГ", Color("f2d98b"))
        hud.set_run_objective("ОБУЧЕНИЕ · 5/5 · НЕ ДАЙ ТЬМЕ ДОЙТИ ДО ОЧАГА")
    else:
        hud.show_banner("НОЧЬ %d" % wave, Color("d9e7ff"))
    if core_fx != null:
        core_fx.hearth_flare(base_position, true)
    trigger_camera_shake(2.6, 0.22)
    var active_count: int = 0
    for value: Variant in built.values():
        if bool(value):
            active_count += 1
    if player.global_position.distance_to(base_position) > 170.0:
        hud.set_status("ОЧАГ ПОД УГРОЗОЙ — ВЕРНИСЬ К БАЗЕ")
    else:
        hud.set_status("Защищай Очаг • активных построек: %d" % active_count)
    Analytics.event("wave_start", {"wave": wave, "biome": biome_index})

func _start_day() -> void:
    QuestDirector.record("night_survive", 1, {"biome":biome_index,"wave":wave})
    phase = "day"
    if backdrop != null:
        backdrop.set_night(false)
    phase_max = GameRules.day_duration(wave) * float(ThreatRules.spec(threat_level).get("day",1.0))
    if run_mode == "endless":
        phase_max *= maxf(0.72, 1.0 - float(maxi(0,wave-1))*0.015)
    phase_time = phase_max
    player.heal(18.0 + (10.0 * shrine_regen_multiplier if bool(built["shrine"]) else 0.0))
    if shrine_ward_active:
        player.shield_hits = mini(5, player.shield_hits + 1)
        hud.set_status("Оберег Святилища восстановил 1 защитный заряд.")
    run_coins += 5 + wave * 3
    hud.show_banner("РАССВЕТ • СНОВА ЗА РЕСУРСАМИ", Color("fff0b4"))
    if core_fx != null:
        core_fx.hearth_flare(base_position, false)
    hud.set_status("Укрепи слабое место лагеря до следующей ночи.")

func _spawn_enemy(is_boss: bool = false, forced_kind: String = "") -> void:
    var enemy: AxEnemy = EnemyScene.instantiate() as AxEnemy
    add_child(enemy)
    enemy.global_position = _edge_position()
    var kind: String = "boss" if is_boss else (forced_kind if not forced_kind.is_empty() else GameRules.enemy_type_for_biome(biome_index))
    if run_variation != null:
        kind = run_variation.pick_enemy_kind(kind, is_boss)
    enemy.configure(kind, float(biome["difficulty"]), wave, Color(str(biome["enemy"])), is_boss, biome_index)
    if run_variation != null:
        run_variation.tune_enemy(enemy)
    _apply_threat_to_enemy(enemy, is_boss)
    if biome_events != null:
        biome_events.apply_enemy_behavior(enemy)
    if is_boss:
        enemy.max_hp *= (1.0 + biome_index * 0.28) * float(ThreatRules.spec(threat_level).get("boss_hp",1.0))
        if run_mode == "endless":
            enemy.max_hp *= 1.0 + floor(float(wave)/5.0)*0.22
        enemy.hp = enemy.max_hp
        boss_ref = enemy
        hud.show_banner(str(biome.get("boss_name", "ХРАНИТЕЛЬ")).to_upper(), Color("ffb66a"))
        if core_fx != null:
            core_fx.boss_arrival(enemy.global_position, biome_index)
        trigger_camera_shake(6.0, 0.38)
    enemy.killed.connect(_on_enemy_killed)
    enemies.append(enemy)

func spawn_event_enemy(kind: String, position: Vector2, elite_trait: String = "", event_id: String = "", anchor: Vector2 = Vector2.ZERO, behavior: String = "hunt") -> AxEnemy:
    var enemy: AxEnemy = EnemyScene.instantiate() as AxEnemy
    add_child(enemy)
    var safe_rect: Rect2 = world_rect.grow(-28.0)
    position.x = clampf(position.x, safe_rect.position.x, safe_rect.end.x)
    position.y = clampf(position.y, safe_rect.position.y, safe_rect.end.y)
    enemy.global_position = position
    enemy.configure(kind, float(biome["difficulty"]) * (1.0 + float(wave) * 0.06), wave, Color(str(biome["enemy"])), false, biome_index)
    _apply_threat_to_enemy(enemy, false)
    if not elite_trait.is_empty():
        enemy.configure_elite(elite_trait)
    if biome_events != null:
        biome_events.apply_enemy_behavior(enemy)
    enemy.set_meta("dynamic_event_id", event_id)
    enemy.set_meta("day_anchor", anchor)
    enemy.set_meta("day_behavior", behavior)
    enemy.killed.connect(_on_enemy_killed)
    enemies.append(enemy)
    return enemy

func _edge_position() -> Vector2:
    var angle: float = randf_range(0.0, TAU)
    var radius: float = randf_range(330.0, 430.0)
    var point: Vector2 = base_position + Vector2(cos(angle), sin(angle)) * radius
    var safe_rect: Rect2 = world_rect.grow(-30.0)
    point.x = clampf(point.x, safe_rect.position.x, safe_rect.end.x)
    point.y = clampf(point.y, safe_rect.position.y, safe_rect.end.y)
    return point

func _update_day_enemies(delta: float) -> void:
    if enemies.is_empty():
        return

    var enemy_snapshot: Array[AxEnemy] = enemies.duplicate()
    _resolve_player_weapon(enemy_snapshot, delta)

    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy) or enemy.dying:
            continue

        if biome_events != null:
            biome_events.update_enemy_behavior(enemy)

        var player_distance: float = enemy.global_position.distance_to(player.global_position)
        var behavior: String = str(enemy.get_meta("day_behavior", "hunt"))
        var target: Vector2 = player.global_position
        if behavior == "attack_anchor" and player_distance >= 128.0:
            var anchor_variant: Variant = enemy.get_meta("day_anchor", player.global_position)
            if anchor_variant is Vector2:
                target = anchor_variant
        enemy.set_target_position(target)

        enemy.hit_cooldown = maxf(0.0, enemy.hit_cooldown - delta)
        var contact_distance: float = 27.0 if enemy.elite else 23.0
        if enemy.hit_cooldown <= 0.0 and player_distance < contact_distance:
            player.take_damage(enemy.contact_damage)
            if biome_events != null:
                biome_events.on_enemy_contact(enemy)
            enemy.hit_cooldown = 0.78

    _update_turret(delta)

func _update_night(delta: float) -> void:
    spawn_timer -= delta
    if spawn_left > 0 and spawn_timer <= 0.0:
        var interval_mult: float = run_variation.spawn_interval_multiplier() if run_variation != null else 1.0
        interval_mult *= float(ThreatRules.first_night_relief(threat_level, wave).get("interval",1.0))
        if tutorial_run and wave == 1:
            interval_mult *= 1.16
        spawn_timer = maxf(0.42, (1.55 - wave * 0.12) * interval_mult)
        _spawn_enemy()
        spawn_left -= 1
    var should_spawn_boss: bool = (run_mode == "endless" and ThreatRules.endless_is_boss_wave(wave)) or (run_mode != "endless" and wave == 3)
    if should_spawn_boss and not boss_spawned and spawn_left <= 3:
        boss_spawned = true
        _spawn_enemy(true)

    var enemy_snapshot: Array[AxEnemy] = enemies.duplicate()
    _resolve_player_weapon(enemy_snapshot, delta)

    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy) or enemy.dying:
            continue

        _update_boss_special(enemy, delta)
        if biome_events != null:
            biome_events.update_enemy_behavior(enemy)

        var dist_to_base: float = enemy.global_position.distance_to(base_position)
        enemy.movement_multiplier = wall_slow_multiplier if bool(built["wall"]) and dist_to_base < 102.0 else 1.0
        if wall_spike_dps > 0.0 and dist_to_base < 96.0 and not enemy.dying:
            enemy.take_damage(wall_spike_dps * delta)

        if enemy.windup > 0.0:
            enemy.clear_target()
        else:
            var player_distance: float = enemy.global_position.distance_to(player.global_position)
            var target: Vector2 = player.global_position if player_distance < 125.0 else base_position

            # Stalkers are the natural answer to passive tower play: if the hero
            # ignores them, they dive the tower and disable it temporarily.
            if enemy.enemy_type == "stalker" and bool(built["turret"]) and turret_disabled_time <= 0.0 and player_distance >= 82.0:
                target = _pad_position("turret")
            enemy.set_target_position(target)

        if enemy.enemy_type == "stalker" and bool(built["turret"]) and turret_disabled_time <= 0.0:
            if enemy.global_position.distance_to(_pad_position("turret")) < 30.0:
                turret_disabled_time = 4.5
                enemy.surge_cooldown = 1.6
                hud.show_banner("БАШНЯ ОГЛУШЕНА", Color("d7a1bd"))
                hud.set_status("Сталкер добрался до Башни. Она не стреляет несколько секунд.")
                Feedback.play("danger", 10)

        enemy.hit_cooldown = maxf(0.0, enemy.hit_cooldown - delta)
        if enemy.hit_cooldown <= 0.0:
            var player_contact: float = 34.0 if enemy.boss else 23.0
            if enemy.global_position.distance_to(player.global_position) < player_contact:
                player.take_damage(enemy.contact_damage)
                if biome_events != null:
                    biome_events.on_enemy_contact(enemy)
                enemy.hit_cooldown = 0.78
            elif dist_to_base < 53.0:
                var wall_multiplier: float = wall_damage_multiplier if bool(built["wall"]) else 1.0
                var night_damage_mult: float = run_variation.base_damage_multiplier() if run_variation != null else 1.0
                var base_relief: float = float(ThreatRules.first_night_relief(threat_level, wave).get("base_damage",1.0))
                if tutorial_run and wave == 1:
                    base_relief *= 0.72
                var amount: float = enemy.contact_damage * wall_multiplier * night_damage_mult * base_relief
                base_hp -= amount
                if core_fx != null:
                    core_fx.hearth_hit(base_position)
                enemy.hit_cooldown = 0.88

    _update_turret(delta)

    if base_hp <= 0.0:
        _finish_run(false)
        return

    var objective_blocks_end: bool = run_variation != null and run_variation.blocks_night_end()
    if spawn_left == 0 and enemies.is_empty() and not objective_blocks_end:
        if run_variation != null:
            run_variation.on_night_completed(wave)
        if run_mode == "endless":
            if ThreatRules.endless_is_boss_wave(wave):
                _show_endless_checkpoint()
            else:
                _start_day()
        elif wave >= 3:
            _finish_run(true)
        else:
            _start_day()

func _resolve_player_weapon(enemy_snapshot: Array[AxEnemy], delta: float) -> void:
    weapon_last_hit_count = 0
    weapon_attack_timer = maxf(0.0, weapon_attack_timer - delta)

    if player.weapon_style == "twin_blades":
        weapon_combo_timeout = maxf(0.0, weapon_combo_timeout - delta)
        if weapon_combo_timeout <= 0.0 and weapon_combo > 0:
            weapon_combo = 0
            player.set_weapon_combo_visual(0)
    elif weapon_combo > 0:
        weapon_combo = 0
        weapon_combo_timeout = 0.0
        player.set_weapon_combo_visual(0)

    match player.weapon_style:
        "spear":
            _weapon_spear(enemy_snapshot)
        "hammer":
            _weapon_hammer(enemy_snapshot)
        "twin_blades":
            _weapon_twin_blades(enemy_snapshot)
        _:
            _weapon_axes(enemy_snapshot, delta)

func _weapon_axes(enemy_snapshot: Array[AxEnemy], delta: float) -> void:
    var reach: float = player.orbit_radius + player.axes * 4.0
    var damage_factor: float = WeaponRules.mechanic_value(player.weapon_id, "damage_factor", 1.30) * player.axes_dps_bonus

    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        var enemy_radius: float = 24.0 if enemy.boss else 12.0
        if player.global_position.distance_to(enemy.global_position) > reach + enemy_radius:
            continue
        var critical: bool = _deal_weapon_damage(enemy, player.damage * delta * damage_factor)
        weapon_last_hit_count += 1
        if core_fx != null and randf() < delta * 5.5:
            core_fx.enemy_hit(enemy.global_position, critical)

func _weapon_spear(enemy_snapshot: Array[AxEnemy]) -> void:
    if weapon_attack_timer > 0.0:
        return

    var attack_range: float = WeaponRules.mechanic_value(player.weapon_id, "attack_range", 116.0)
    var primary: AxEnemy = null
    var nearest_distance: float = INF
    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        var distance: float = player.global_position.distance_to(enemy.global_position)
        if distance <= attack_range + (24.0 if enemy.boss else 12.0) and distance < nearest_distance:
            nearest_distance = distance
            primary = enemy
    if primary == null:
        return

    var direction: Vector2 = player.global_position.direction_to(primary.global_position)
    if direction.length_squared() < 0.01:
        direction = Vector2(player.facing_x, 0.0)
    direction = direction.normalized()

    weapon_attack_timer = WeaponRules.mechanic_value(player.weapon_id, "attack_cooldown", 0.66) * player.weapon_cooldown_mult
    player.trigger_weapon_action(direction, 0.22)

    var width: float = WeaponRules.mechanic_value(player.weapon_id, "attack_width", 16.0)
    var max_targets: int = WeaponRules.mechanic_int(player.weapon_id, "pierce", 3) + player.spear_pierce_bonus
    var candidates: Array[Dictionary] = []

    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        var offset: Vector2 = enemy.global_position - player.global_position
        var along: float = offset.dot(direction)
        if along < -6.0 or along > attack_range + (24.0 if enemy.boss else 12.0):
            continue
        var perpendicular: float = absf(offset.cross(direction))
        var enemy_radius: float = 24.0 if enemy.boss else 12.0
        if perpendicular <= width + enemy_radius:
            candidates.append({"enemy":enemy, "along":along})

    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a.get("along", 0.0)) < float(b.get("along", 0.0))
    )

    var damage_factor: float = WeaponRules.mechanic_value(player.weapon_id, "damage_factor", 1.08) * player.spear_damage_bonus
    for i: int in range(mini(max_targets, candidates.size())):
        var enemy: AxEnemy = candidates[i].get("enemy") as AxEnemy
        if enemy == null or enemy.dying:
            continue
        var critical: bool = _deal_weapon_damage(enemy, player.damage * damage_factor)
        weapon_last_hit_count += 1
        if core_fx != null:
            core_fx.enemy_hit(enemy.global_position, critical)

    if core_fx != null:
        core_fx.spear_thrust(player.global_position + direction * 10.0, player.global_position + direction * attack_range)
    Feedback.play("spear", 5)

func _weapon_hammer(enemy_snapshot: Array[AxEnemy]) -> void:
    if weapon_attack_timer > 0.0:
        return

    var radius: float = WeaponRules.mechanic_value(player.weapon_id, "attack_range", 62.0) + player.hammer_radius_bonus
    var nearest: AxEnemy = null
    var nearest_distance: float = INF
    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        var distance: float = player.global_position.distance_to(enemy.global_position)
        if distance <= radius + (24.0 if enemy.boss else 12.0) and distance < nearest_distance:
            nearest = enemy
            nearest_distance = distance
    if nearest == null:
        return

    weapon_attack_timer = WeaponRules.mechanic_value(player.weapon_id, "attack_cooldown", 0.98) * player.weapon_cooldown_mult
    var slam_direction: Vector2 = player.global_position.direction_to(nearest.global_position)
    player.trigger_weapon_action(slam_direction, 0.34)

    var damage_factor: float = WeaponRules.mechanic_value(player.weapon_id, "damage_factor", 0.92) * player.hammer_damage_bonus
    var knockback: float = WeaponRules.mechanic_value(player.weapon_id, "knockback", 18.0)

    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        var enemy_radius: float = 24.0 if enemy.boss else 12.0
        if player.global_position.distance_to(enemy.global_position) > radius + enemy_radius:
            continue
        var critical: bool = _deal_weapon_damage(enemy, player.damage * damage_factor)
        weapon_last_hit_count += 1

        if not enemy.dying:
            var push_direction: Vector2 = player.global_position.direction_to(enemy.global_position)
            var push_amount: float = knockback * (0.45 if enemy.boss else 1.0)
            enemy.global_position += push_direction * push_amount
            enemy.global_position.x = clampf(enemy.global_position.x, world_rect.position.x + 24.0, world_rect.end.x - 24.0)
            enemy.global_position.y = clampf(enemy.global_position.y, world_rect.position.y + 24.0, world_rect.end.y - 24.0)
        if core_fx != null:
            core_fx.enemy_hit(enemy.global_position, critical)

    if core_fx != null:
        core_fx.hammer_slam(player.global_position, radius)
    trigger_camera_shake(3.2, 0.12)
    Feedback.play("hammer", 11)

func _weapon_twin_blades(enemy_snapshot: Array[AxEnemy]) -> void:
    if weapon_attack_timer > 0.0:
        return

    var attack_range: float = WeaponRules.mechanic_value(player.weapon_id, "attack_range", 50.0)
    var max_targets: int = WeaponRules.mechanic_int(player.weapon_id, "targets", 2)
    var chosen: Array[AxEnemy] = []

    for _slot: int in range(max_targets):
        var nearest: AxEnemy = null
        var nearest_distance: float = INF
        for enemy: AxEnemy in enemy_snapshot:
            if not is_instance_valid(enemy) or enemy.dying or chosen.has(enemy):
                continue
            var enemy_radius: float = 24.0 if enemy.boss else 12.0
            var distance: float = player.global_position.distance_to(enemy.global_position)
            if distance <= attack_range + enemy_radius and distance < nearest_distance:
                nearest = enemy
                nearest_distance = distance
        if nearest != null:
            chosen.append(nearest)

    if chosen.is_empty():
        return

    weapon_attack_timer = WeaponRules.mechanic_value(player.weapon_id, "attack_cooldown", 0.20) * player.weapon_cooldown_mult
    var combo_cap: int = WeaponRules.mechanic_int(player.weapon_id, "combo_cap", 6) + player.blades_combo_cap_bonus
    var combo_step: float = WeaponRules.mechanic_value(player.weapon_id, "combo_step", 0.06) + player.blades_combo_step_bonus
    var combo_multiplier: float = 1.0 + float(weapon_combo) * combo_step
    var damage_factor: float = WeaponRules.mechanic_value(player.weapon_id, "damage_factor", 0.30) * combo_multiplier

    var primary_direction: Vector2 = player.global_position.direction_to(chosen[0].global_position)
    player.trigger_weapon_action(primary_direction, 0.12)

    for enemy: AxEnemy in chosen:
        var critical: bool = _deal_weapon_damage(enemy, player.damage * damage_factor)
        weapon_last_hit_count += 1
        if core_fx != null:
            core_fx.enemy_hit(enemy.global_position, critical)

    weapon_combo = mini(combo_cap, weapon_combo + 1)
    weapon_combo_timeout = 0.86 + player.blades_combo_timeout_bonus
    player.set_weapon_combo_visual(weapon_combo)
    if core_fx != null:
        core_fx.blade_flurry(player.global_position, primary_direction, weapon_combo)
    Feedback.play("blades", 3)

func _deal_weapon_damage(enemy: AxEnemy, raw_damage: float) -> bool:
    var critical: bool = randf() < player.crit_chance
    var tactical_mult: float = 1.0
    if player.hearth_damage_bonus > 0.0 and player.global_position.distance_to(base_position) <= 190.0:
        tactical_mult += player.hearth_damage_bonus
    var bag_ratio: float = float(player.inventory_total()) / float(maxi(1, player.capacity))
    if player.loaded_pack_damage_bonus > 0.0 and bag_ratio >= 0.75:
        tactical_mult += player.loaded_pack_damage_bonus
    var amount: float = raw_damage * tactical_mult * (2.0 if critical else 1.0)
    enemy.take_damage(amount)
    return critical

func weapon_identity_snapshot() -> Dictionary:
    return {
        "style": player.weapon_style if player != null else "",
        "timer": weapon_attack_timer,
        "combo": weapon_combo,
        "last_hits": weapon_last_hit_count
    }

func _update_turret(delta: float) -> void:
    if not bool(built["turret"]) or enemies.is_empty() or turret_disabled_time > 0.0:
        return
    turret_timer -= delta
    if turret_timer > 0.0:
        return

    var variation_fire_mult: float = run_variation.turret_fire_multiplier() if run_variation != null else 1.0
    turret_timer = maxf(0.48, (0.78 - wave * 0.03) * turret_global_fire_mult * variation_fire_mult)
    var nearest: AxEnemy = null
    var best: float = INF
    for enemy: AxEnemy in enemies:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        var distance_to_base: float = enemy.global_position.distance_to(base_position)
        if distance_to_base < best:
            best = distance_to_base
            nearest = enemy

    if nearest != null:
        turret_shot_from = _pad_position("turret")
        turret_shot_to = nearest.global_position
        turret_shot_time = 1.0
        var variation_damage_mult: float = run_variation.turret_damage_multiplier() if run_variation != null else 1.0
        nearest.take_damage((20.0 + wave * 3.0) * turret_global_damage_mult * variation_damage_mult)
        if core_fx != null:
            core_fx.turret_hit(nearest.global_position)
        Feedback.play("hit", 2)

func _pad_position(kind: String) -> Vector2:
    for pad: BuildPad in pads:
        if pad.build_type == kind:
            return pad.global_position
    return base_position

func _update_boss_special(enemy: AxEnemy, delta: float) -> void:
    if not enemy.boss:
        return
    enemy.special_cooldown -= delta
    if enemy.windup > 0.0:
        enemy.windup -= delta
        if enemy.windup <= 0.0 and enemy.mark_active:
            if player.global_position.distance_to(enemy.mark_position) < 64.0:
                player.take_damage(24.0 * float(biome["difficulty"]))
            enemy.mark_active = false
            boss_warning_active = false
        return
    if enemy.special_cooldown <= 0.0:
        enemy.special_cooldown = 3.1
        enemy.windup = 0.85
        enemy.mark_position = player.global_position
        enemy.mark_active = true
        boss_warning_position = enemy.mark_position
        boss_warning_time = 0.85
        boss_warning_active = true

func spawn_reinforcement(kind: String = "") -> void:
    if phase != "night" or finishing:
        return
    _spawn_enemy(false, kind)

func _on_enemy_killed(enemy: AxEnemy) -> void:
    if not enemies.has(enemy):
        return
    enemies.erase(enemy)
    if core_fx != null:
        core_fx.enemy_down(enemy.global_position, enemy.enemy_type, enemy.boss, biome_index, enemy.elite)
    if enemy.boss:
        trigger_camera_shake(7.0, 0.34)
    elif enemy.elite:
        trigger_camera_shake(3.4, 0.16)
        if enemy.elite_trait == "volatile":
            if player.global_position.distance_to(enemy.global_position) < 58.0:
                player.take_damage(10.0 * float(biome["difficulty"]))
            if core_fx != null:
                core_fx.hammer_slam(enemy.global_position, 54.0)
    kills += 1
    if player.kill_heal_every > 0 and kills % player.kill_heal_every == 0:
        player.heal(player.kill_heal_amount)
        hud.show_banner("РИТМ ОХОТЫ", Color("a8d0b1"))
        hud.set_status("+%d HP за серию убийств." % int(player.kill_heal_amount))
    if biome_events != null:
        biome_events.on_enemy_defeated(enemy)
    GameState.mission_add("kills")
    QuestDirector.record("kill_enemy", 1, {"enemy":enemy.enemy_type, "biome":biome_index})
    if enemy.elite and not enemy.boss:
        QuestDirector.record("elite_kill", 1, {"enemy":enemy.enemy_type, "trait":enemy.elite_trait, "biome":biome_index})
    var reward: int = 25 if enemy.boss else (3 if enemy.enemy_type == "brute" or enemy.enemy_type == "guardian" else 1)
    if enemy.elite and not enemy.boss:
        reward += 8
    if not enemy.boss and run_variation != null:
        reward = maxi(1, int(round(float(reward) * run_variation.reward_multiplier())))
    run_coins += reward
    var xp_reward: int = 20 if enemy.boss else (6 if enemy.enemy_type == "brute" or enemy.enemy_type == "guardian" else 4)
    if enemy.elite and not enemy.boss:
        xp_reward += 7
    player.gain_xp(xp_reward)
    if enemy.enemy_type == "guardian" and not enemy.boss:
        add_mechanism_parts(1, enemy.global_position)
    elif enemy.elite and not enemy.boss:
        add_mechanism_parts(1, enemy.global_position)
    if enemy.boss:
        add_mechanism_parts(2, enemy.global_position)
        if run_mode == "endless":
            run_shards += 1
        else:
            run_shards = int(biome["reward"])
        boss_ref = null
        hud.hide_boss()
    enemy_defeated.emit(enemy)
    enemy.queue_free()

func _apply_threat_to_enemy(enemy: AxEnemy, is_boss: bool) -> void:
    if enemy == null or not is_instance_valid(enemy):
        return
    var spec: Dictionary = ThreatRules.spec(threat_level)
    var relief: Dictionary = ThreatRules.first_night_relief(threat_level, wave)
    enemy.max_hp *= float(spec.get("enemy_hp",1.0)) * float(relief.get("hp",1.0))
    enemy.hp = enemy.max_hp
    enemy.contact_damage *= float(spec.get("enemy_damage",1.0)) * float(relief.get("damage",1.0))
    enemy.move_speed *= float(spec.get("enemy_speed",1.0))
    if tutorial_run and wave == 1:
        enemy.max_hp *= 0.88
        enemy.hp = enemy.max_hp
        enemy.contact_damage *= 0.80

    if run_mode == "endless":
        enemy.max_hp *= ThreatRules.endless_enemy_hp(wave)
        enemy.hp = enemy.max_hp
        enemy.contact_damage *= ThreatRules.endless_enemy_damage(wave)
        enemy.move_speed *= ThreatRules.endless_enemy_speed(wave)

    if not is_boss and threat_level >= 3 and not enemy.elite and randf() < 0.055 * float(threat_level - 2):
        var traits: Array[String] = ["swift","armored","vampiric"]
        enemy.configure_elite(traits[randi() % traits.size()])

func _update_relic_perks(delta: float) -> void:
    if player == null:
        return

    if player.fire_orb_level > 0:
        var fire_radius: float = 58.0 + float(player.fire_orb_level) * 5.0
        for enemy: AxEnemy in enemies:
            if is_instance_valid(enemy) and not enemy.dying and player.global_position.distance_to(enemy.global_position) <= fire_radius:
                enemy.take_damage(player.damage * delta * (0.10 + 0.05 * float(player.fire_orb_level)))

    if player.frost_aura_level > 0:
        var frost_radius: float = 66.0 + float(player.frost_aura_level) * 8.0
        for enemy: AxEnemy in enemies:
            if is_instance_valid(enemy) and not enemy.dying:
                if player.global_position.distance_to(enemy.global_position) <= frost_radius:
                    enemy.behavior_speed_multiplier = minf(enemy.behavior_speed_multiplier, 0.80 - 0.07 * float(player.frost_aura_level - 1))
                else:
                    enemy.behavior_speed_multiplier = move_toward(enemy.behavior_speed_multiplier, 1.0, delta * 1.8)

    if player.thorn_ring_level > 0:
        relic_thorn_timer -= delta
        if relic_thorn_timer <= 0.0:
            relic_thorn_timer = maxf(2.4, 4.2 - float(player.thorn_ring_level) * 0.45)
            var radius: float = 92.0 + float(player.thorn_ring_level) * 8.0
            for enemy: AxEnemy in enemies.duplicate():
                if is_instance_valid(enemy) and not enemy.dying and player.global_position.distance_to(enemy.global_position) <= radius:
                    enemy.take_damage(player.damage * (0.65 + 0.22 * float(player.thorn_ring_level)))
                    if core_fx != null:
                        core_fx.enemy_hit(enemy.global_position, false)
            trigger_camera_shake(1.2,0.08)

    if player.guardian_spirit_level > 0:
        relic_spirit_timer -= delta
        if relic_spirit_timer <= 0.0:
            relic_spirit_timer = maxf(11.0, 22.0 - float(player.guardian_spirit_level) * 3.0)
            player.shield_hits = mini(5, player.shield_hits + 1)
            hud.set_status("Дух Хранителя восстановил защитный заряд.")

func _endless_relic_choices(boosted: bool) -> Array[String]:
    var relics: Array[String] = ["fire_orb","frost_aura","thorn_ring","guardian_spirit"]
    relics.shuffle()
    if boosted:
        return relics.slice(0,3)

    var pool: Array[String] = ["damage","crit","speed","hp","shield","orbit","fire_orb","frost_aura","thorn_ring","guardian_spirit"]
    pool.shuffle()
    var choices: Array[String] = []
    for id: String in pool:
        if not choices.has(id):
            choices.append(id)
        if choices.size() >= 3:
            break
    return choices

func _show_endless_checkpoint(boosted: bool = false) -> void:
    endless_checkpoint_wave = wave
    endless_chest_boosted = boosted
    var buttons: Array = []
    for perk_id: String in _endless_relic_choices(boosted):
        var spec: Dictionary = {}
        for perk_variant: Variant in GameRules.PERKS:
            var perk: Dictionary = perk_variant
            if str(perk.get("id","")) == perk_id:
                spec = perk
                break
        buttons.append({
            "text":"%s\n%s" % [str(spec.get("name",perk_id)),str(spec.get("desc",""))],
            "action":"endless_relic:" + perk_id
        })

    if not boosted:
        buttons.append({"text":"УЛУЧШИТЬ СУНДУК · РЕКЛАМА","action":"endless_chest_ad"})
    buttons.append({"text":"ЗАБРАТЬ НАГРАДУ И ВЕРНУТЬСЯ","action":"endless_cashout"})
    hud.show_modal("", "СУНДУК НОЧИ %d" % wave, "Хранитель пал. Выбери силу и продолжай или зафиксируй рекорд.", buttons)

func _on_endless_chest_ad(_placement: String) -> void:
    hud.hide_modal()
    _show_endless_checkpoint(true)

func _show_perks(level: int) -> void:
    var buttons: Array = []
    var choices: Array = GameRules.random_perks(3, player.weapon_id)
    for perk_variant: Variant in choices:
        var perk: Dictionary = perk_variant
        buttons.append({
            "text": "%s\n%s" % [str(perk.get("name", "УСИЛЕНИЕ")), str(perk.get("desc", ""))],
            "action": "perk:" + str(perk.get("id", ""))
        })
    hud.show_modal("", "УРОВЕНЬ %d" % level, "Выбери усиление на этот забег.", buttons)

func _on_player_died() -> void:
    if finishing:
        return
    finishing = true
    var buttons: Array = []
    if not revived:
        buttons.append({"text": "ВОСКРЕСНУТЬ С 50% HP", "action": "revive"})
    buttons.append({"text": "ЗАВЕРШИТЬ ЭКСПЕДИЦИЮ", "action": "end"})
    var text: String = "Одно рекламное воскрешение доступно на забег." if not revived else "Второго воскрешения нет."
    hud.show_modal("", "ГЕРОЙ ПАЛ", text, buttons)

func _on_player_damaged(_amount: float, blocked: bool) -> void:
    hud.damage_feedback(blocked)
    if not blocked:
        trigger_camera_shake(2.2, 0.10)
        if core_fx != null:
            core_fx.player_hit(player.global_position)
    hud.set_status("Щит поглотил удар." if blocked else "Герой получил урон.")

func _finish_run(won: bool) -> void:
    if finishing and player.hp > 0.0:
        return
    finishing = true
    if run_variation != null:
        run_variation.on_run_finished(won)
    var unused_parts: int = int(storage.get("parts", 0))
    var base_reward: int = 22 + wave * 15 + run_coins + builds * 4 + unused_parts * 8
    var reward_mult: float = ThreatRules.reward_multiplier(threat_level)
    if run_mode == "endless":
        reward_mult *= ThreatRules.endless_reward_multiplier(wave)
    reward_mult *= float(GameState.relic_forge_bonuses().get("coin_mult",1.0))
    var reward: int = int(round(float(base_reward) * reward_mult))
    var progress_reward: Dictionary = GameState.register_run(wave, won, biome_index, kills, builds, trees_cut, threat_level, run_mode, reward)
    if run_mode != "endless" and won:
        reward += int(progress_reward.get("coins",0))
        run_shards += int(progress_reward.get("shards",0))
        QuestDirector.record("run_win", 1, {"biome":biome_index, "wave":wave,"threat":threat_level})
        QuestDirector.record("threat_clear",1,{"biome":biome_index,"threat":threat_level})
    elif run_mode == "endless":
        QuestDirector.record("endless_wave",wave,{"biome":biome_index})
    Analytics.event("run_end", {"won":won,"wave":wave,"biome":biome_index,"kills":kills,"parts_unused":unused_parts,"weapon":player.weapon_id,"threat":threat_level,"mode":run_mode})
    var earned_shards: int = run_shards if (won or run_mode == "endless") else 0
    run_finished.emit({
        "won": won,
        "biome": biome_index,
        "wave": wave,
        "coins": reward,
        "shards": earned_shards,
        "run_mode":run_mode,
        "threat":threat_level,
        "first_clear":bool(progress_reward.get("first",false)),
        "new_record":bool(progress_reward.get("new_record",false)),
        "kills": kills,
        "parts_unused": unused_parts,
        "parts_bonus": unused_parts * 8,
        "contract": run_variation.contract_result() if run_variation != null else {},
        "dynamic_world": dynamic_world.result_summary() if dynamic_world != null else {},
        "biome_events": biome_events.result_summary() if biome_events != null else {},
        "field_objectives": field_objectives.result_summary() if field_objectives != null else {}
    })

func _refresh_hud() -> void:
    if player == null:
        return
    hud.update_stats(
        player.hp,
        base_hp,
        player.inventory_total(),
        player.capacity,
        wave,
        phase,
        phase_time,
        player.xp,
        player.next_xp,
        player.level,
        storage,
        spawn_left + enemies.size(),
        player.inventory
    )
    if boss_ref != null and is_instance_valid(boss_ref):
        hud.show_boss(str(biome.get("boss_name", "Хранитель")), boss_ref.hp, boss_ref.max_hp)
    else:
        hud.hide_boss()

func _on_hud_action(action: String) -> void:
    if action == "close":
        hud.hide_modal()
    elif action == "pause":
        paused_local = true
        hud.show_modal("", "ПАУЗА", "Текущий забег не сохраняется после выхода.", [
            {"text": "ПРОДОЛЖИТЬ", "action": "resume"},
            {"text": "В ЛАГЕРЬ", "action": "quit"}
        ])
    elif action == "resume":
        paused_local = false
        hud.hide_modal()
    elif action == "quit":
        paused_local = false
        hud.hide_modal()
        quit_requested.emit()
    elif action == "end":
        hud.hide_modal()
        _finish_run(false)
    elif action == "revive":
        AdService.rewarded_completed.connect(_on_revive_ad, CONNECT_ONE_SHOT)
        AdService.show_rewarded("revive")
    elif action == "endless_cashout":
        hud.hide_modal()
        _finish_run(true)
    elif action == "endless_chest_ad":
        AdService.rewarded_completed.connect(_on_endless_chest_ad, CONNECT_ONE_SHOT)
        AdService.show_rewarded("endless_chest")
    elif action.begins_with("endless_relic:"):
        var relic_id: String = action.trim_prefix("endless_relic:")
        player.apply_perk(relic_id)
        hud.hide_modal()
        endless_chest_boosted = false
        _start_day()
    elif action == "build_upgrade:cancel":
        if pending_upgrade_pad != null and is_instance_valid(pending_upgrade_pad):
            pending_upgrade_pad.reset_upgrade()
        pending_upgrade_pad = null
        hud.hide_modal()
    elif action.begins_with("build_upgrade:"):
        var parts: PackedStringArray = action.split(":")
        if parts.size() >= 3:
            _apply_build_upgrade(parts[1], parts[2])
    elif action.begins_with("perk:"):
        player.apply_perk(action.trim_prefix("perk:"))
        hud.hide_modal()

func _on_revive_ad(_placement: String) -> void:
    revived = true
    finishing = false
    player.hp = player.max_hp * 0.5
    hud.hide_modal()
    hud.set_status("Воскрешение использовано.")

func _draw() -> void:
    var night: bool = phase == "night"
    _draw_hearth(night)

    if bool(built["wall"]):
        _draw_palisade()

    if deposit_pulse > 0.0:
        var radius: float = 66.0 + (1.0 - deposit_pulse) * 30.0
        draw_arc(base_position, radius, 0.0, TAU, 40, Color(0.94, 0.76, 0.36, deposit_pulse * 0.54), 2.5)

    var ratio: float = clampf(base_hp / maxf(1.0, base_max_hp), 0.0, 1.0)
    draw_rect(Rect2(base_position + Vector2(-45, -76), Vector2(90, 5)), Color(0.07, 0.08, 0.07, 0.34))
    draw_rect(Rect2(base_position + Vector2(-45, -76), Vector2(90 * ratio, 5)), Color("83b06e"))

    if turret_shot_time > 0.0:
        draw_line(turret_shot_from, turret_shot_to, Color(1.0, 0.83, 0.38, 0.58 + turret_shot_time * 0.32), 2.5)
        draw_rect(Rect2(turret_shot_to - Vector2(3, 3), Vector2(6, 6)), Color("ffe7a0"))

    if boss_warning_active:
        draw_circle(boss_warning_position, 62.0, Color(0.84, 0.27, 0.27, 0.09))
        draw_arc(boss_warning_position, 62.0, 0.0, TAU, 36, Color(0.92, 0.38, 0.34, 0.72), 2.5)

func _draw_ground_detail(size: Vector2, night: bool) -> void:
    var tuft: Color = Color(0.18, 0.32, 0.18, 0.16) if not night else Color(0.05, 0.10, 0.10, 0.16)
    var patch: Color = Color(0.12, 0.24, 0.14, 0.08) if not night else Color(0.04, 0.08, 0.09, 0.09)

    for i: int in range(210):
        var px: float = floor(fmod(float(i * 73 + 31), size.x) / 4.0) * 4.0
        var py: float = floor(fmod(float(i * 47 + 149), size.y) / 4.0) * 4.0
        if Vector2(px, py).distance_to(base_position) < 88.0:
            continue
        if i % 3 == 0:
            draw_rect(Rect2(px, py, 12, 4), patch)
        else:
            draw_rect(Rect2(px, py, 3, 7), tuft)
            draw_rect(Rect2(px + 4, py + 2, 2, 5), Color(tuft, tuft.a * 0.75))

    # Darker forest edges create depth and keep the eye on the Hearth.
    var edge: Color = Color(0.04, 0.09, 0.06, 0.12) if not night else Color(0.01, 0.03, 0.04, 0.22)
    for i: int in range(5):
        var alpha: float = edge.a * (1.0 - float(i) * 0.14)
        var c: Color = Color(edge.r, edge.g, edge.b, alpha)
        draw_rect(Rect2(i * 7.0, 0, 7.0, size.y), c)
        draw_rect(Rect2(size.x - (i + 1) * 7.0, 0, 7.0, size.y), c)

func _draw_clearing(night: bool) -> void:
    var clearing: Color = Color(0.66, 0.75, 0.45, 0.24) if not night else Color(0.39, 0.46, 0.32, 0.20)
    draw_circle(base_position, 95.0, clearing)

    # A worn path from the lower screen to the Last Hearth.
    var path: Color = Color(0.54, 0.48, 0.31, 0.20) if not night else Color(0.29, 0.27, 0.22, 0.16)
    var bottom_y: float = minf(world_rect.end.y, base_position.y + 430.0)
    var points := PackedVector2Array([
        Vector2(base_position.x - 19, base_position.y + 28),
        Vector2(base_position.x + 20, base_position.y + 28),
        Vector2(base_position.x + 35, bottom_y),
        Vector2(base_position.x - 38, bottom_y)
    ])
    draw_colored_polygon(points, path)
    for i: int in range(6):
        var y: float = base_position.y + 58.0 + float(i) * 43.0
        draw_rect(Rect2(base_position.x - 11 + float((i % 2) * 4), y, 20, 3), Color(0.36, 0.31, 0.21, 0.12))

func _draw_hearth(night: bool) -> void:
    var glow_strength: float = 0.11 if not night else 0.24
    draw_circle(base_position, 148.0, Color(1.0, 0.55, 0.18, glow_strength * 0.16))
    draw_circle(base_position, 104.0, Color(1.0, 0.52, 0.16, glow_strength * 0.22))
    draw_circle(base_position, 64.0, Color(1.0, 0.55, 0.18, glow_strength))
    draw_circle(base_position, 38.0, Color(1.0, 0.45, 0.12, glow_strength * 0.78))

    # Stone fire ring.
    for i: int in range(10):
        var angle: float = TAU * float(i) / 10.0
        var stone_pos: Vector2 = base_position + Vector2(cos(angle), sin(angle)) * 22.0
        var stone_color: Color = Color("73756b") if i % 2 == 0 else Color("85867a")
        draw_rect(Rect2(stone_pos - Vector2(4, 3), Vector2(8, 6)), Color("464941"))
        draw_rect(Rect2(stone_pos - Vector2(3, 3), Vector2(6, 5)), stone_color)

    # Crossed logs.
    draw_line(base_position + Vector2(-11, 8), base_position + Vector2(10, -5), Color("54331f"), 5.0)
    draw_line(base_position + Vector2(11, 8), base_position + Vector2(-9, -5), Color("6a4226"), 5.0)

    var flicker: float = (sin(Time.get_ticks_msec() * 0.010) + 1.0) * 0.5
    var flame := PackedVector2Array([
        base_position + Vector2(-8, 5),
        base_position + Vector2(-4, -13 - flicker * 3.0),
        base_position + Vector2(0, -6),
        base_position + Vector2(5, -20 + flicker * 2.0),
        base_position + Vector2(9, 5)
    ])
    draw_colored_polygon(flame, Color("ee7c32"))
    draw_colored_polygon(PackedVector2Array([
        base_position + Vector2(-4, 4),
        base_position + Vector2(0, -10 - flicker * 2.0),
        base_position + Vector2(5, 4)
    ]), Color("ffd879"))

    # Storage crate makes deposit function visually obvious.
    var crate_pos := base_position + Vector2(39, 20)
    draw_rect(Rect2(crate_pos - Vector2(13, 9), Vector2(26, 18)), Color("4e321f"))
    draw_rect(Rect2(crate_pos - Vector2(11, 7), Vector2(22, 14)), Color("865a31"))
    draw_rect(Rect2(crate_pos + Vector2(-11, -1), Vector2(22, 3)), Color("b27c42"))
    draw_rect(Rect2(crate_pos + Vector2(-2, -7), Vector2(4, 14)), Color("5d3d24"))

func _draw_palisade() -> void:
    var radius_x: float = 78.0
    var radius_y: float = 66.0
    for i: int in range(28):
        var angle: float = TAU * float(i) / 28.0
        # Leave a small gate on the lower side.
        if angle > 1.30 and angle < 1.84:
            continue
        var pos: Vector2 = base_position + Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
        draw_rect(Rect2(pos - Vector2(3, 8), Vector2(6, 17)), Color("4e3321"))
        draw_rect(Rect2(pos - Vector2(2, 7), Vector2(4, 14)), Color("8d633b"))
        draw_colored_polygon(PackedVector2Array([
            pos + Vector2(-3, -8), pos + Vector2(0, -14), pos + Vector2(3, -8)
        ]), Color("b68a54"))

