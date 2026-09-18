class_name GameWorld
extends Node2D

signal run_finished(result: Dictionary)
signal quit_requested

const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")
const ResourceScene: PackedScene = preload("res://scenes/resource_spot.tscn")
const BuildPadScene: PackedScene = preload("res://scenes/build_pad.tscn")

var biome_index: int = 0
var biome: Dictionary = {}
var player: AxPlayer
var hud: GameHud
var core_fx: CoreFX
var base_position: Vector2 = Vector2.ZERO
var base_hp: float = 270.0
var base_max_hp: float = 270.0
var storage: Dictionary = {"wood": 0, "stone": 0, "ore": 0}
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

func configure(index: int) -> void:
    biome_index = index

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
        maxf(1080.0, viewport_size.x * 3.0),
        maxf(2100.0, viewport_size.y * 3.0)
    )
    world_rect = Rect2(Vector2.ZERO, world_size)
    base_position = world_size * 0.5
    phase_max = GameRules.day_duration(0)
    phase_time = phase_max

    player = PlayerScene.instantiate() as AxPlayer
    add_child(player)
    player.global_position = base_position + Vector2(0, 42)
    var upgrades: Dictionary = GameState.data["upgrades"]
    var skin_index: int = int(GameState.data.get("selected_skin", 0))
    player.setup(upgrades, GameRules.skin(skin_index))
    player.set_world_bounds(world_rect.grow(-34.0))
    player.set_home_target(base_position)
    _setup_camera()
    player.died.connect(_on_player_died)
    player.damaged.connect(_on_player_damaged)
    player.level_up_requested.connect(_show_perks)

    _create_pads()
    for _i in range(52):
        _spawn_resource("tree")
    for _i in range(20):
        _spawn_resource("rock")
    var initial_ore: int = 12 if biome_index == 2 else 9
    for _i in range(initial_ore):
        _spawn_resource("ore")

    Analytics.event("run_start", {"biome": biome_index})
    hud.show_banner(str(biome["name"]).to_upper())
    hud.set_status("Собирай добычу и возвращайся к Очагу.")

    var settings: Dictionary = GameState.data["settings"]
    if bool(settings.get("hints", true)) and not bool(GameState.data.get("v1_tutorial_complete", false)):
        GameState.data["v1_tutorial_complete"] = true
        GameState.save()
        hud.show_banner("РУБИ ДНЁМ. ДЕРЖИ ОБОРОНУ НОЧЬЮ.", Color("f3d58d"))
        hud.set_status("Коснись свободного места и веди пальцем. Оружие работает само.")
    _refresh_hud()
    queue_redraw()

func _setup_camera() -> void:
    camera = Camera2D.new()
    player.add_child(camera)
    camera.position = Vector2.ZERO
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.2
    camera.limit_left = int(world_rect.position.x)
    camera.limit_top = int(world_rect.position.y)
    camera.limit_right = int(world_rect.end.x)
    camera.limit_bottom = int(world_rect.end.y)
    camera.limit_smoothed = true
    camera.make_current()

func _update_camera_lookahead(delta: float) -> void:
    if camera == null or player == null:
        return
    var target_offset := Vector2.ZERO
    if player.velocity.length_squared() > 64.0:
        target_offset = player.velocity.normalized() * 24.0
    camera.position = camera.position.lerp(target_offset, clampf(delta * 4.6, 0.0, 1.0))

func _process(delta: float) -> void:
    deposit_pulse = maxf(0.0, deposit_pulse - delta * 2.8)
    turret_shot_time = maxf(0.0, turret_shot_time - delta * 8.0)

    if paused_local or finishing or hud.modal_open():
        queue_redraw()
        return

    _harvest(delta)
    _deposit_and_build(delta)
    _maintain_resources()
    _update_building_passives(delta)
    _update_camera_lookahead(delta)
    var bag_ratio: float = float(player.inventory_total()) / float(maxi(1, player.capacity))
    var return_soon: bool = bag_ratio >= 0.82 or (phase == "day" and phase_time <= 12.0)
    player.set_home_hint(return_soon and player.global_position.distance_to(base_position) > 110.0)

    if phase == "day":
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
    spot.configure(kind, randi() % 3)
    resources.append(spot)

func _resource_spawn_position(kind: String) -> Vector2:
    var min_radius: float = 145.0
    var max_radius: float = 500.0
    match kind:
        "rock":
            min_radius = 260.0
            max_radius = 690.0
        "ore":
            min_radius = 470.0 if biome_index != 2 else 390.0
            max_radius = 900.0

    var safe_rect: Rect2 = world_rect.grow(-42.0)
    for _i in range(80):
        var angle: float = randf_range(0.0, TAU)
        var radius: float = randf_range(min_radius, max_radius)
        var point: Vector2 = base_position + Vector2(cos(angle), sin(angle)) * radius
        point.x = clampf(point.x, safe_rect.position.x, safe_rect.end.x)
        point.y = clampf(point.y, safe_rect.position.y, safe_rect.end.y)
        if point.distance_to(base_position) < 135.0:
            continue
        var too_close: bool = false
        for pad: BuildPad in pads:
            if is_instance_valid(pad) and point.distance_to(pad.global_position) < 58.0:
                too_close = true
                break
        if not too_close:
            return point
    return base_position + Vector2(min_radius, 0)

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
    var removed: Array[ResourceSpot] = []
    for spot: ResourceSpot in resources:
        if not is_instance_valid(spot):
            continue
        if player.global_position.distance_to(spot.global_position) > reach + spot.radius:
            continue
        var harvest_damage: float = player.damage * delta * GameRules.harvest_multiplier(spot.resource_type)
        if spot.damage(harvest_damage):
            var kind: String = "wood" if spot.resource_type == "tree" else ("stone" if spot.resource_type == "rock" else "ore")
            var amount: int = GameRules.resource_yield(spot.resource_type, biome_index)
            var actual: int = player.add_resource(kind, amount)
            if spot.resource_type == "tree":
                trees_cut += 1
                GameState.mission_add("trees")
            player.gain_xp(2)
            if actual > 0:
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
        for key: String in storage.keys():
            storage[key] = int(storage[key]) + int(inv[key])
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

        pad.set_context_state(pad.can_build(storage), distance <= 92.0 and not pad.built)

        if pad.built:
            continue

        if distance <= 38.0 and pad.can_build(storage):
            if pad.advance_construction(delta):
                _complete_build(pad)
        elif distance > 45.0:
            pad.reset_construction()

    if nearest != null and nearest_distance <= 92.0:
        if nearest.built:
            hud.set_built_context(nearest.label, nearest.effect)
        else:
            hud.set_build_context(
                nearest.label,
                nearest.effect,
                nearest.cost,
                storage,
                nearest.can_build(storage),
                nearest.construction_progress
            )
    else:
        hud.hide_build_context()

func _complete_build(pad: BuildPad) -> void:
    if pad.built or not pad.can_build(storage):
        return
    pad.consume(storage)
    built[pad.build_type] = true
    builds += 1
    GameState.mission_add("builds")
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
        player.heal(delta * (0.75 if phase == "day" else 0.35))
        var base_regen: float = 0.85 if phase == "day" else 0.22
        base_hp = minf(base_max_hp, base_hp + delta * base_regen)

func _start_night() -> void:
    phase = "night"
    wave += 1
    spawn_left = GameRules.wave_count(wave, float(biome["difficulty"]))
    spawn_timer = 0.1
    boss_spawned = false
    hud.hide_build_context()
    hud.show_banner("НОЧЬ %d" % wave, Color("d9e7ff"))
    var active_count: int = 0
    for value: Variant in built.values():
        if bool(value):
            active_count += 1
    hud.set_status("Защищай Очаг • активных построек: %d" % active_count)
    Analytics.event("wave_start", {"wave": wave, "biome": biome_index})

func _start_day() -> void:
    phase = "day"
    phase_max = GameRules.day_duration(wave)
    phase_time = phase_max
    player.heal(18.0 + (10.0 if bool(built["shrine"]) else 0.0))
    run_coins += 5 + wave * 3
    hud.show_banner("РАССВЕТ • СНОВА ЗА РЕСУРСАМИ", Color("fff0b4"))
    hud.set_status("Укрепи слабое место лагеря до следующей ночи.")

func _spawn_enemy(is_boss: bool = false) -> void:
    var enemy: AxEnemy = EnemyScene.instantiate() as AxEnemy
    add_child(enemy)
    enemy.global_position = _edge_position()
    var kind: String = "boss" if is_boss else GameRules.enemy_type_for_biome(biome_index)
    enemy.configure(kind, float(biome["difficulty"]), wave, Color(str(biome["enemy"])), is_boss)
    if is_boss:
        enemy.max_hp *= 1.0 + biome_index * 0.28
        enemy.hp = enemy.max_hp
        boss_ref = enemy
        hud.show_banner(str(biome.get("boss_name", "ХРАНИТЕЛЬ")).to_upper(), Color("ffb66a"))
    enemy.killed.connect(_on_enemy_killed)
    enemies.append(enemy)

func _edge_position() -> Vector2:
    var angle: float = randf_range(0.0, TAU)
    var radius: float = randf_range(330.0, 430.0)
    var point: Vector2 = base_position + Vector2(cos(angle), sin(angle)) * radius
    var safe_rect: Rect2 = world_rect.grow(-30.0)
    point.x = clampf(point.x, safe_rect.position.x, safe_rect.end.x)
    point.y = clampf(point.y, safe_rect.position.y, safe_rect.end.y)
    return point

func _update_night(delta: float) -> void:
    spawn_timer -= delta
    if spawn_left > 0 and spawn_timer <= 0.0:
        spawn_timer = maxf(0.52, 1.55 - wave * 0.12)
        _spawn_enemy()
        spawn_left -= 1
    if wave == 3 and not boss_spawned and spawn_left <= 3:
        boss_spawned = true
        _spawn_enemy(true)

    var reach: float = player.orbit_radius + player.axes * 4.0
    var enemy_snapshot: Array[AxEnemy] = enemies.duplicate()
    for enemy: AxEnemy in enemy_snapshot:
        if not is_instance_valid(enemy):
            continue

        _update_boss_special(enemy, delta)

        var dist_to_base: float = enemy.global_position.distance_to(base_position)
        enemy.movement_multiplier = 0.58 if bool(built["wall"]) and dist_to_base < 102.0 else 1.0

        if enemy.windup > 0.0:
            enemy.clear_target()
        else:
            var player_distance: float = enemy.global_position.distance_to(player.global_position)
            var target: Vector2 = player.global_position if player_distance < 125.0 else base_position
            enemy.set_target_position(target)

        var enemy_radius: float = 24.0 if enemy.boss else 12.0
        if player.global_position.distance_to(enemy.global_position) <= reach + enemy_radius:
            var hit: float = player.damage * delta * 1.34
            var critical: bool = randf() < player.crit_chance
            if critical:
                hit *= 2.0
            enemy.take_damage(hit)
            if core_fx != null and randf() < delta * 5.5:
                core_fx.enemy_hit(enemy.global_position, critical)

        enemy.hit_cooldown = maxf(0.0, enemy.hit_cooldown - delta)
        if enemy.hit_cooldown <= 0.0:
            var player_contact: float = 34.0 if enemy.boss else 23.0
            if enemy.global_position.distance_to(player.global_position) < player_contact:
                player.take_damage(enemy.contact_damage)
                enemy.hit_cooldown = 0.78
            elif dist_to_base < 53.0:
                var wall_multiplier: float = 0.35 if bool(built["wall"]) else 1.0
                var amount: float = enemy.contact_damage * wall_multiplier
                base_hp -= amount
                if core_fx != null:
                    core_fx.hearth_hit(base_position)
                enemy.hit_cooldown = 0.88

    _update_turret(delta)

    if base_hp <= 0.0:
        _finish_run(false)
        return

    if spawn_left == 0 and enemies.is_empty():
        if wave >= 3:
            _finish_run(true)
        else:
            _start_day()

func _update_turret(delta: float) -> void:
    if not bool(built["turret"]) or enemies.is_empty():
        return
    turret_timer -= delta
    if turret_timer > 0.0:
        return

    turret_timer = maxf(0.42, 0.64 - wave * 0.035)
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
        nearest.take_damage(28.0 + wave * 4.0)
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

func _on_enemy_killed(enemy: AxEnemy) -> void:
    if not enemies.has(enemy):
        return
    enemies.erase(enemy)
    kills += 1
    GameState.mission_add("kills")
    var reward: int = 25 if enemy.boss else (3 if enemy.enemy_type == "brute" or enemy.enemy_type == "guardian" else 1)
    run_coins += reward
    var xp_reward: int = 20 if enemy.boss else (6 if enemy.enemy_type == "brute" or enemy.enemy_type == "guardian" else 4)
    player.gain_xp(xp_reward)
    if enemy.boss:
        run_shards = int(biome["reward"])
        boss_ref = null
        hud.hide_boss()
    enemy.queue_free()

func _show_perks(level: int) -> void:
    var buttons: Array = []
    var choices: Array = GameRules.random_perks(3)
    for perk_variant: Variant in choices:
        var perk: Dictionary = perk_variant
        buttons.append({"text": "%s  %s — %s" % [perk["icon"], perk["name"], perk["desc"]], "action": "perk:" + str(perk["id"])})
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
    hud.set_status("Щит поглотил удар." if blocked else "Герой получил урон.")

func _finish_run(won: bool) -> void:
    if finishing and player.hp > 0.0:
        return
    finishing = true
    var reward: int = 22 + wave * 15 + run_coins + builds * 4
    GameState.register_run(wave, won, biome_index, kills, builds, trees_cut)
    Analytics.event("run_end", {"won": won, "wave": wave, "biome": biome_index, "kills": kills})
    var earned_shards: int = run_shards if won else 0
    run_finished.emit({
        "won": won,
        "biome": biome_index,
        "wave": wave,
        "coins": reward,
        "shards": earned_shards,
        "kills": kills
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
    var size: Vector2 = world_size
    var night: bool = phase == "night"
    var top: Color = Color(str(biome.get("sky", "b9cf8d")))
    var bottom: Color = Color(str(biome.get("ground", "7fa268")))
    if night:
        top = Color("20313a") if biome_index < 2 else Color("34242a")
        bottom = Color("30483d") if biome_index < 2 else Color("57332f")

    draw_rect(Rect2(Vector2.ZERO, size), bottom)

    var band_h: float = 14.0
    var bands: int = int(ceil(size.y / band_h))
    for i: int in range(bands):
        var t: float = float(i) / float(maxi(1, bands - 1))
        var band_color: Color = top.lerp(bottom, t)
        draw_rect(Rect2(0, float(i) * band_h, size.x, band_h + 1.0), band_color)

    _draw_ground_detail(size, night)
    _draw_clearing(night)
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
    var glow_strength: float = 0.13 if not night else 0.22
    draw_circle(base_position, 56.0, Color(1.0, 0.55, 0.18, glow_strength))
    draw_circle(base_position, 35.0, Color(1.0, 0.45, 0.12, glow_strength * 0.75))

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

