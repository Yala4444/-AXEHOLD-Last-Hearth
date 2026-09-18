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
    base_position = get_viewport_rect().size * Vector2(0.5, 0.53)
    phase_max = GameRules.day_duration(0)
    phase_time = phase_max

    player = PlayerScene.instantiate() as AxPlayer
    add_child(player)
    player.global_position = base_position + Vector2(0, 42)
    var upgrades: Dictionary = GameState.data["upgrades"]
    var skin_index: int = int(GameState.data.get("selected_skin", 0))
    player.setup(upgrades, GameRules.skin(skin_index))
    player.died.connect(_on_player_died)
    player.damaged.connect(_on_player_damaged)
    player.level_up_requested.connect(_show_perks)

    _create_pads()
    for _i in range(22):
        _spawn_resource("tree")
    for _i in range(9):
        _spawn_resource("rock")
    var initial_ore: int = 6 if biome_index == 2 else 4
    for _i in range(initial_ore):
        _spawn_resource("ore")

    Analytics.event("run_start", {"biome": biome_index})
    hud.show_banner(str(biome["name"]).to_upper())
    hud.set_status("Собирай добычу и возвращайся к Очагу.")

    var settings: Dictionary = GameState.data["settings"]
    if bool(settings.get("hints", true)) and not bool(GameState.data.get("v1_tutorial_complete", false)):
        GameState.data["v1_tutorial_complete"] = true
        GameState.save()
        hud.show_modal(
            "",
            "ДОБЫЧА → БАЗА → СТРОЙКА",
            "Двигайся стиком. Оружие само рубит и атакует. Ресурсы попадают в РЮКЗАК. Вернись к Очагу, чтобы переложить их на СКЛАД, затем подойди к нужному чертежу.",
            [{"text": "ПОНЯТНО", "action": "close"}]
        )
    _refresh_hud()
    queue_redraw()

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
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            player.set_target(touch.position)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        player.set_target(drag.position)
    elif event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
            player.set_target(button.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        var motion := event as InputEventMouseMotion
        player.set_target(motion.position)

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
    spot.global_position = _free_spawn_position()
    spot.configure(kind, randi() % 3)
    resources.append(spot)

func _free_spawn_position() -> Vector2:
    var size: Vector2 = get_viewport_rect().size
    var min_y: float = minf(250.0, size.y * 0.31)
    var max_y: float = maxf(min_y + 80.0, size.y - 95.0)
    for _i in range(50):
        var point := Vector2(randf_range(24.0, size.x - 24.0), randf_range(min_y, max_y))
        if point.distance_to(base_position) > 165.0:
            return point
    return Vector2(38, min_y + 30.0)

func _maintain_resources() -> void:
    var counts: Dictionary = {"tree": 0, "rock": 0, "ore": 0}
    for spot: ResourceSpot in resources:
        if is_instance_valid(spot):
            counts[spot.resource_type] = int(counts.get(spot.resource_type, 0)) + 1
    while int(counts["tree"]) < 18:
        _spawn_resource("tree")
        counts["tree"] = int(counts["tree"]) + 1
    while int(counts["rock"]) < 7:
        _spawn_resource("rock")
        counts["rock"] = int(counts["rock"]) + 1
    var ore_target: int = 5 if biome_index == 2 else 3
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
                    core_fx.harvest(kind, spot.global_position, actual)
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
            core_fx.deposit(inv, base_position)

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
    var size: Vector2 = get_viewport_rect().size
    var top_y: float = minf(245.0, size.y * 0.30)
    var bottom_y: float = size.y - 70.0
    match randi() % 4:
        0:
            return Vector2(randf_range(10.0, size.x - 10.0), top_y)
        1:
            return Vector2(size.x - 8.0, randf_range(top_y, bottom_y))
        2:
            return Vector2(randf_range(10.0, size.x - 10.0), bottom_y)
        _:
            return Vector2(8.0, randf_range(top_y, bottom_y))

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
    var size: Vector2 = get_viewport_rect().size
    var night: bool = phase == "night"
    var top: Color = Color(str(biome.get("sky", "dceabc")))
    var bottom: Color = Color(str(biome.get("ground", "9fc77c")))
    if night:
        top = Color("213647") if biome_index < 2 else Color("38262d")
        bottom = Color("304a40") if biome_index < 2 else Color("58322f")

    draw_rect(Rect2(Vector2.ZERO, size), bottom)
    var band_h: float = 16.0
    var bands: int = int(ceil(size.y / band_h))
    for i: int in range(bands):
        var t: float = float(i) / float(maxi(1, bands - 1))
        var band_color: Color = top.lerp(bottom, t)
        draw_rect(Rect2(0, float(i) * band_h, size.x, band_h + 1.0), band_color)

    # Pixel-ground clusters: deliberately chunky instead of smooth procedural noise.
    for i: int in range(52):
        var px: float = floor(fmod(float(i * 73), size.x) / 4.0) * 4.0
        var py: float = floor(fmod(float(i * 47 + 220), size.y) / 4.0) * 4.0
        var patch: Color = Color(0.18, 0.31, 0.16, 0.09) if not night else Color(0.08, 0.12, 0.13, 0.11)
        draw_rect(Rect2(px, py, 4, 8), patch)

    _draw_hearth(night)

    if bool(built["wall"]):
        _draw_palisade()

    if deposit_pulse > 0.0:
        var pulse_size: float = 116.0 + (1.0 - deposit_pulse) * 24.0
        draw_rect(
            Rect2(base_position - Vector2(pulse_size, pulse_size) * 0.5, Vector2(pulse_size, pulse_size)),
            Color(0.88, 0.73, 0.36, deposit_pulse * 0.34),
            false,
            3.0
        )

    var ratio: float = clampf(base_hp / maxf(1.0, base_max_hp), 0.0, 1.0)
    draw_rect(Rect2(base_position + Vector2(-48, -82), Vector2(96, 6)), Color(0.08, 0.09, 0.08, 0.32))
    draw_rect(Rect2(base_position + Vector2(-48, -82), Vector2(96 * ratio, 6)), Color("79aa6d"))

    if turret_shot_time > 0.0:
        draw_line(turret_shot_from, turret_shot_to, Color(1.0, 0.82, 0.38, 0.65 + turret_shot_time * 0.30), 3.0)
        draw_rect(Rect2(turret_shot_to - Vector2(3, 3), Vector2(6, 6)), Color("ffe8a3"))

    if boss_warning_active:
        draw_rect(Rect2(boss_warning_position - Vector2(62, 62), Vector2(124, 124)), Color(0.84, 0.27, 0.27, 0.10))
        draw_rect(Rect2(boss_warning_position - Vector2(62, 62), Vector2(124, 124)), Color(0.9, 0.35, 0.35, 0.72), false, 3.0)

func _draw_hearth(night: bool) -> void:
    var zone_color: Color = Color("b49b6d") if night else Color("d7c18f")
    draw_rect(Rect2(base_position - Vector2(58, 48), Vector2(116, 96)), zone_color)
    draw_rect(Rect2(base_position - Vector2(58, 48), Vector2(116, 96)), Color("8f7653"), false, 3.0)

    # Small pixel hearth / depot.
    draw_rect(Rect2(base_position + Vector2(-24, -18), Vector2(48, 36)), Color("7d5a3d"))
    draw_rect(Rect2(base_position + Vector2(-19, -13), Vector2(38, 31)), Color("936b48"))
    draw_colored_polygon(PackedVector2Array([
        base_position + Vector2(-30, -18),
        base_position + Vector2(0, -39),
        base_position + Vector2(30, -18)
    ]), Color("513a2b"))
    draw_rect(Rect2(base_position + Vector2(-7, 2), Vector2(14, 16)), Color("3c2b23"))
    draw_rect(Rect2(base_position + Vector2(-5, 7), Vector2(10, 10)), Color("f2a442"))
    draw_rect(Rect2(base_position + Vector2(-2, 5), Vector2(4, 8)), Color("ffe19a"))

func _draw_palisade() -> void:
    var left: float = base_position.x - 73.0
    var right: float = base_position.x + 73.0
    var top_y: float = base_position.y - 61.0
    var bottom_y: float = base_position.y + 61.0
    var wood: Color = Color("68472f")
    var light: Color = Color("8e6544")

    for x: int in range(int(left), int(right) + 1, 14):
        draw_rect(Rect2(float(x) - 3.0, top_y - 8.0, 6, 16), wood)
        draw_rect(Rect2(float(x) - 2.0, top_y - 7.0, 4, 14), light)
        draw_rect(Rect2(float(x) - 3.0, bottom_y - 8.0, 6, 16), wood)
        draw_rect(Rect2(float(x) - 2.0, bottom_y - 7.0, 4, 14), light)

    for y: int in range(int(top_y), int(bottom_y) + 1, 14):
        draw_rect(Rect2(left - 8.0, float(y) - 3.0, 16, 6), wood)
        draw_rect(Rect2(right - 8.0, float(y) - 3.0, 16, 6), wood)
