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
var base_position: Vector2 = Vector2.ZERO
var base_hp: float = 270.0
var base_max_hp: float = 270.0
var storage: Dictionary = {"wood": 0, "stone": 0, "ore": 0}
var built: Dictionary = {"wall": false, "forge": false, "turret": false, "shrine": false}
var pads: Array[BuildPad] = []
var resources: Array[ResourceSpot] = []
var enemies: Array[AxEnemy] = []
var phase: String = "day"
var phase_time: float = 28.0
var phase_max: float = 28.0
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
var boss_warning_active: bool = false
var boss_warning_position: Vector2 = Vector2.ZERO
var boss_warning_time: float = 0.0

func configure(index: int) -> void:
    biome_index = index

func _ready() -> void:
    hud = GameHud.new()
    add_child(hud)
    hud.action_requested.connect(_on_hud_action)
    _start_run()

func _start_run() -> void:
    biome_index = clampi(biome_index, 0, GameRules.BIOMES.size() - 1)
    biome = GameRules.biome(biome_index)
    base_position = get_viewport_rect().size * Vector2(0.5, 0.53)
    player = PlayerScene.instantiate() as AxPlayer
    add_child(player)
    player.global_position = base_position + Vector2(0, 38)
    var upgrades: Dictionary = GameState.data["upgrades"]
    var skin_index: int = int(GameState.data.get("selected_skin", 0))
    player.setup(upgrades, GameRules.skin(skin_index))
    player.died.connect(_on_player_died)
    player.damaged.connect(_on_player_damaged)
    player.level_up_requested.connect(_show_perks)
    _create_pads()
    for _i in range(23):
        _spawn_resource("tree")
    for _i in range(9):
        _spawn_resource("rock")
    var initial_ore: int = 6 if biome_index == 2 else 4
    for _i in range(initial_ore):
        _spawn_resource("ore")
    Analytics.event("run_start", {"biome": biome_index})
    hud.show_banner(str(biome["name"]))
    var settings: Dictionary = GameState.data["settings"]
    if bool(settings.get("hints", true)) and not bool(GameState.data.get("tutorial_complete", false)):
        GameState.data["tutorial_complete"] = true
        GameState.save()
        hud.show_modal("🔥", "Последний Очаг", "Коснись места — герой побежит туда. Топоры сами добывают ресурсы и атакуют. Возвращайся к Очагу, чтобы выгрузить рюкзак.", [{"text": "Начать", "action": "close"}])
    _refresh_hud()
    queue_redraw()

func _process(delta: float) -> void:
    if paused_local or finishing or hud.modal_open():
        queue_redraw()
        return
    _harvest(delta)
    _deposit_and_build()
    _maintain_resources()
    if phase == "day":
        phase_time -= delta
        if bool(built["shrine"]):
            player.heal(delta * 0.9)
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
    for spec_variant in GameRules.BUILD_SPECS:
        var spec: Dictionary = spec_variant
        var pad: BuildPad = BuildPadScene.instantiate() as BuildPad
        add_child(pad)
        var offset: Vector2 = spec.get("offset", Vector2.ZERO)
        var build_cost: Dictionary = spec.get("cost", {})
        pad.global_position = base_position + offset
        pad.configure(str(spec.get("id", "wall")), str(spec.get("name", "ПОСТРОЙКА")), build_cost, false)
        pads.append(pad)

func _spawn_resource(kind: String) -> void:
    var spot: ResourceSpot = ResourceScene.instantiate() as ResourceSpot
    add_child(spot)
    spot.global_position = _free_spawn_position()
    spot.configure(kind, randi() % 3)
    resources.append(spot)

func _free_spawn_position() -> Vector2:
    var size: Vector2 = get_viewport_rect().size
    for _i in range(40):
        var point := Vector2(randf_range(28.0, size.x - 28.0), randf_range(100.0, size.y - 85.0))
        if point.distance_to(base_position) > 170.0:
            return point
    return Vector2(35, 120)

func _maintain_resources() -> void:
    var counts: Dictionary = {"tree": 0, "rock": 0, "ore": 0}
    for spot in resources:
        if is_instance_valid(spot):
            counts[spot.resource_type] = int(counts.get(spot.resource_type, 0)) + 1
    while int(counts["tree"]) < 19:
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
        return
    var reach: float = player.orbit_radius + player.axes * 4.0
    var removed: Array[ResourceSpot] = []
    for spot in resources:
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
            var resource_name: String = "дерева" if kind == "wood" else ("камня" if kind == "stone" else "руды")
            hud.set_status("+%d %s" % [actual, resource_name])
            removed.append(spot)
    for spot in removed:
        resources.erase(spot)
        spot.queue_free()

func _deposit_and_build() -> void:
    if player.global_position.distance_to(base_position) < 45.0 and player.inventory_total() > 0:
        var inv: Dictionary = player.clear_inventory()
        for key in storage.keys():
            storage[key] = int(storage[key]) + int(inv[key])
        hud.set_status("Ресурсы выгружены на склад")
    for pad in pads:
        if pad.built or player.global_position.distance_to(pad.global_position) >= 28.0:
            continue
        if not pad.can_build(storage):
            continue
        pad.consume(storage)
        built[pad.build_type] = true
        builds += 1
        GameState.mission_add("builds")
        player.gain_xp(7)
        match pad.build_type:
            "wall":
                base_max_hp += 180.0
                base_hp += 180.0
            "forge":
                player.damage *= 1.30
            "shrine":
                player.max_hp += 30.0
                player.hp += 30.0
        hud.set_status(pad.label + " построено")
        hud.show_banner(pad.label + " ГОТОВО", Color("fff0b3"))

func _start_night() -> void:
    phase = "night"
    wave += 1
    spawn_left = GameRules.wave_count(wave, float(biome["difficulty"]))
    spawn_timer = 0.1
    boss_spawned = false
    hud.show_banner("НОЧЬ %d" % wave, Color("d9e7ff"))
    hud.set_status("Последняя ночь. Хранитель приближается!" if wave == 3 else "Защищай Очаг")
    Analytics.event("wave_start", {"wave": wave, "biome": biome_index})

func _start_day() -> void:
    phase = "day"
    phase_max = GameRules.day_duration(wave)
    phase_time = phase_max
    player.heal(18.0 + (12.0 if bool(built["shrine"]) else 0.0))
    run_coins += 5 + wave * 3
    hud.show_banner("РАССВЕТ", Color("fff0b4"))
    hud.set_status("Есть время укрепить лагерь")

func _spawn_enemy(is_boss: bool = false) -> void:
    var enemy: AxEnemy = EnemyScene.instantiate() as AxEnemy
    add_child(enemy)
    enemy.global_position = _edge_position()
    var kind: String = "boss" if is_boss else GameRules.random_enemy_type()
    enemy.configure(kind, float(biome["difficulty"]), wave, Color(str(biome["enemy"])), is_boss)
    if is_boss:
        enemy.max_hp *= 1.0 + biome_index * 0.28
        enemy.hp = enemy.max_hp
        boss_ref = enemy
        hud.show_banner("ХРАНИТЕЛЬ", Color("ffb66a"))
    enemy.killed.connect(_on_enemy_killed)
    enemies.append(enemy)

func _edge_position() -> Vector2:
    var size: Vector2 = get_viewport_rect().size
    match randi() % 4:
        0:
            return Vector2(randf_range(10.0, size.x - 10.0), 92.0)
        1:
            return Vector2(size.x - 8.0, randf_range(110.0, size.y - 80.0))
        2:
            return Vector2(randf_range(10.0, size.x - 10.0), size.y - 72.0)
        _:
            return Vector2(8.0, randf_range(110.0, size.y - 80.0))

func _update_night(delta: float) -> void:
    spawn_timer -= delta
    if spawn_left > 0 and spawn_timer <= 0.0:
        spawn_timer = maxf(0.5, 1.5 - wave * 0.12)
        _spawn_enemy()
        spawn_left -= 1
    if wave == 3 and not boss_spawned and spawn_left <= 3:
        boss_spawned = true
        _spawn_enemy(true)

    var reach: float = player.orbit_radius + player.axes * 4.0
    var enemy_snapshot: Array[AxEnemy] = enemies.duplicate()
    for enemy in enemy_snapshot:
        if not is_instance_valid(enemy):
            continue
        _update_boss_special(enemy, delta)
        if enemy.windup > 0.0:
            enemy.clear_target()
        else:
            var target: Vector2 = player.global_position if enemy.global_position.distance_to(player.global_position) < 155.0 else base_position
            enemy.set_target_position(target)
        var enemy_radius: float = 24.0 if enemy.boss else 12.0
        if player.global_position.distance_to(enemy.global_position) <= reach + enemy_radius:
            var hit: float = player.damage * delta * 1.34
            if randf() < player.crit_chance:
                hit *= 2.0
            enemy.take_damage(hit)
        enemy.hit_cooldown = maxf(0.0, enemy.hit_cooldown - delta)
        if enemy.hit_cooldown <= 0.0:
            var player_contact: float = 34.0 if enemy.boss else 23.0
            if enemy.global_position.distance_to(player.global_position) < player_contact:
                player.take_damage(enemy.contact_damage)
                enemy.hit_cooldown = 0.78
            elif enemy.global_position.distance_to(base_position) < 52.0:
                var wall_multiplier: float = 0.5 if bool(built["wall"]) else 1.0
                var amount: float = enemy.contact_damage * wall_multiplier
                base_hp -= amount
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
    turret_timer = 0.5
    var nearest: AxEnemy = null
    var best: float = INF
    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue
        var distance_to_base: float = enemy.global_position.distance_to(base_position)
        if distance_to_base < best:
            best = distance_to_base
            nearest = enemy
    if nearest != null:
        nearest.take_damage(25.0 + wave * 3.0)

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
    var reward: int = 25 if enemy.boss else (3 if enemy.enemy_type == "brute" else 1)
    run_coins += reward
    var xp_reward: int = 20 if enemy.boss else (6 if enemy.enemy_type == "brute" else 4)
    player.gain_xp(xp_reward)
    if enemy.boss:
        run_shards = int(biome["reward"])
        boss_ref = null
        hud.hide_boss()
    enemy.queue_free()

func _show_perks(level: int) -> void:
    var buttons: Array = []
    var choices: Array = GameRules.random_perks(3)
    for perk_variant in choices:
        var perk: Dictionary = perk_variant
        buttons.append({"text": "%s %s — %s" % [perk["icon"], perk["name"], perk["desc"]], "action": "perk:" + str(perk["id"])})
    hud.show_modal("✨", "Уровень %d" % level, "Выбери усиление на этот забег", buttons)

func _on_player_died() -> void:
    if finishing:
        return
    finishing = true
    var buttons: Array = []
    if not revived:
        buttons.append({"text": "▶ Воскреснуть с 50% HP", "action": "revive"})
    buttons.append({"text": "Завершить экспедицию", "action": "end"})
    var text: String = "Одно rewarded-воскрешение доступно на забег." if not revived else "Второго воскрешения нет."
    hud.show_modal("💀", "Герой пал", text, buttons)

func _on_player_damaged(_amount: float, blocked: bool) -> void:
    hud.damage_feedback(blocked)
    hud.set_status("Щит поглотил удар" if blocked else "Получен урон")

func _finish_run(won: bool) -> void:
    if finishing and player.hp > 0.0:
        return
    finishing = true
    var reward: int = 22 + wave * 15 + run_coins + builds * 3
    GameState.register_run(wave, won, biome_index, kills, builds, trees_cut)
    Analytics.event("run_end", {"won": won, "wave": wave, "biome": biome_index, "kills": kills})
    var earned_shards: int = run_shards if won else 0
    run_finished.emit({"won": won, "biome": biome_index, "wave": wave, "coins": reward, "shards": earned_shards, "kills": kills})

func _refresh_hud() -> void:
    if player == null:
        return
    hud.update_stats(player.hp, base_hp, player.inventory_total(), player.capacity, wave, phase, phase_time, player.xp, player.next_xp, player.level, storage, spawn_left + enemies.size())
    if boss_ref != null and is_instance_valid(boss_ref):
        hud.show_boss("Хранитель", boss_ref.hp, boss_ref.max_hp)
    else:
        hud.hide_boss()

func _on_hud_action(action: String) -> void:
    if action == "close":
        hud.hide_modal()
    elif action == "pause":
        paused_local = true
        hud.show_modal("Ⅱ", "Пауза", "Текущий забег не сохраняется после выхода.", [{"text": "Продолжить", "action": "resume"}, {"text": "В лагерь", "action": "quit"}])
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
    hud.set_status("Воскрешение использовано")

func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size
    var night: bool = phase == "night"
    var top: Color = Color(str(biome.get("sky", "dceabc")))
    var bottom: Color = Color(str(biome.get("ground", "9fc77c")))
    if night:
        top = Color("213647") if biome_index < 2 else Color("38262d")
        bottom = Color("304a40") if biome_index < 2 else Color("58322f")
    draw_rect(Rect2(Vector2.ZERO, size), bottom)
    for i in range(28):
        var y: float = float(i) / 27.0 * size.y
        draw_rect(Rect2(0, y, size.x, size.y / 27.0 + 1.0), top.lerp(bottom, float(i) / 27.0))
    for i in range(70):
        draw_rect(Rect2(fmod(i * 97.0, size.x), fmod(i * 53.0, size.y), 2, 5), Color(0.2,0.35,0.18,0.12))
    draw_circle(base_position, 64, Color("b69a6b") if night else Color("d6be8c"))
    var wall_width: float = 8.0 if bool(built["wall"]) else 2.5
    draw_arc(base_position, 64, 0, TAU, 64, Color("684b31") if bool(built["wall"]) else Color("987f5b"), wall_width)
    draw_rect(Rect2(base_position - Vector2(23,17), Vector2(46,34)), Color("835f40"))
    draw_colored_polygon(PackedVector2Array([base_position + Vector2(-29,-17), base_position + Vector2(0,-40), base_position + Vector2(29,-17)]), Color("5e402d"))
    draw_circle(base_position + Vector2(0,4), 7, Color("ffbd58"))
    draw_circle(base_position + Vector2(0,4), 32, Color(1.0,0.74,0.34,0.16))
    var ratio: float = clampf(base_hp / maxf(1.0, base_max_hp), 0.0, 1.0)
    draw_rect(Rect2(base_position + Vector2(-46,-80), Vector2(92,5)), Color(0.1,0.1,0.1,0.22))
    draw_rect(Rect2(base_position + Vector2(-46,-80), Vector2(92 * ratio,5)), Color("79aa6d"))
    if boss_warning_active:
        draw_circle(boss_warning_position, 64, Color(0.84,0.27,0.27,0.12))
        draw_arc(boss_warning_position, 64, 0, TAU, 64, Color(0.9,0.35,0.35,0.75), 3)
