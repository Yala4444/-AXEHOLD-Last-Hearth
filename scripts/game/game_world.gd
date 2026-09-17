class_name GameWorld
extends Node2D

signal run_finished(result: Dictionary)
signal quit_requested

const PlayerScene := preload("res://scenes/player.tscn")
const EnemyScene := preload("res://scenes/enemy.tscn")
const ResourceScene := preload("res://scenes/resource_spot.tscn")
const BuildPadScene := preload("res://scenes/build_pad.tscn")

var biome_index := 0
var biome: Dictionary = {}
var player: AxPlayer
var hud: GameHud
var base_position := Vector2.ZERO
var base_hp := 270.0
var base_max_hp := 270.0
var storage := {"wood":0,"stone":0,"ore":0}
var built := {"wall":false,"forge":false,"turret":false,"shrine":false}
var pads: Array[BuildPad] = []
var resources: Array[ResourceSpot] = []
var enemies: Array[AxEnemy] = []
var phase := "day"
var phase_time := 28.0
var phase_max := 28.0
var wave := 0
var spawn_left := 0
var spawn_timer := 0.0
var boss_spawned := false
var boss_ref: AxEnemy
var run_coins := 0
var run_shards := 0
var kills := 0
var builds := 0
var trees_cut := 0
var revived := false
var paused_local := false
var finishing := false
var turret_timer := 0.0
var boss_warning_active := false
var boss_warning_position := Vector2.ZERO
var boss_warning_time := 0.0

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
    player.setup(GameState.data["upgrades"], GameRules.skin(int(GameState.data.get("selected_skin", 0))))
    player.died.connect(_on_player_died)
    player.damaged.connect(_on_player_damaged)
    player.level_up_requested.connect(_show_perks)
    _create_pads()
    for i in range(23): _spawn_resource("tree")
    for i in range(9): _spawn_resource("rock")
    for i in range(6 if biome_index == 2 else 4): _spawn_resource("ore")
    Analytics.event("run_start", {"biome": biome_index})
    hud.show_banner(str(biome["name"]))
    if bool(GameState.data["settings"].get("hints", true)) and not bool(GameState.data.get("tutorial_complete", false)):
        GameState.data["tutorial_complete"] = true
        GameState.save()
        hud.show_modal("🔥", "Последний Очаг", "Коснись места — герой побежит туда. Топоры сами добывают ресурсы и атакуют. Возвращайся к Очагу, чтобы выгрузить рюкзак.", [{"text":"Начать","action":"close"}])
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
        if built["shrine"]:
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
    if event is InputEventScreenTouch and event.pressed:
        player.set_target(event.position)
    elif event is InputEventScreenDrag:
        player.set_target(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        player.set_target(event.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        player.set_target(event.position)

func _create_pads() -> void:
    for spec in GameRules.BUILD_SPECS:
        var pad := BuildPadScene.instantiate() as BuildPad
        add_child(pad)
        pad.global_position = base_position + Vector2(spec["offset"])
        pad.configure(str(spec["id"]), str(spec["name"]), Dictionary(spec["cost"]), false)
        pads.append(pad)

func _spawn_resource(kind: String) -> void:
    var spot := ResourceScene.instantiate() as ResourceSpot
    add_child(spot)
    spot.global_position = _free_spawn_position()
    spot.configure(kind, randi() % 3)
    resources.append(spot)

func _free_spawn_position() -> Vector2:
    var size := get_viewport_rect().size
    for i in range(40):
        var point := Vector2(randf_range(28.0, size.x - 28.0), randf_range(100.0, size.y - 85.0))
        if point.distance_to(base_position) > 170.0:
            return point
    return Vector2(35, 120)

func _maintain_resources() -> void:
    var counts := {"tree":0,"rock":0,"ore":0}
    for spot in resources:
        if is_instance_valid(spot):
            counts[spot.resource_type] = int(counts.get(spot.resource_type, 0)) + 1
    while int(counts["tree"]) < 19:
        _spawn_resource("tree")
        counts["tree"] += 1
    while int(counts["rock"]) < 7:
        _spawn_resource("rock")
        counts["rock"] += 1
    var ore_target := 5 if biome_index == 2 else 3
    while int(counts["ore"]) < ore_target:
        _spawn_resource("ore")
        counts["ore"] += 1

func _harvest(delta: float) -> void:
    if player.inventory_total() >= player.capacity:
        return
    var reach := player.orbit_radius + player.axes * 4.0
    var removed: Array[ResourceSpot] = []
    for spot in resources:
        if not is_instance_valid(spot):
            continue
        if player.global_position.distance_to(spot.global_position) > reach + spot.radius:
            continue
        if spot.damage(player.damage * delta * GameRules.harvest_multiplier(spot.resource_type)):
            var kind := "wood" if spot.resource_type == "tree" else ("stone" if spot.resource_type == "rock" else "ore")
            var amount := GameRules.resource_yield(spot.resource_type, biome_index)
            var actual := player.add_resource(kind, amount)
            if spot.resource_type == "tree":
                trees_cut += 1
                GameState.mission_add("trees")
            player.gain_xp(2)
            hud.set_status("+%d %s" % [actual, "дерева" if kind == "wood" else ("камня" if kind == "stone" else "руды")])
            removed.append(spot)
    for spot in removed:
        resources.erase(spot)
        spot.queue_free()

func _deposit_and_build() -> void:
    if player.global_position.distance_to(base_position) < 45.0 and player.inventory_total() > 0:
        var inv := player.clear_inventory()
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
            "forge": player.damage *= 1.30
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
    player.heal(18.0 + (12.0 if built["shrine"] else 0.0))
    run_coins += 5 + wave * 3
    hud.show_banner("РАССВЕТ", Color("fff0b4"))
    hud.set_status("Есть время укрепить лагерь")

func _spawn_enemy(is_boss: bool = false) -> void:
    var enemy := EnemyScene.instantiate() as AxEnemy
    add_child(enemy)
    enemy.global_position = _edge_position()
    var kind := "boss" if is_boss else GameRules.random_enemy_type()
    enemy.configure(kind, float(biome["difficulty"]), wave, Color(str(biome["enemy"])), is_boss)
    if is_boss:
        enemy.max_hp *= 1.0 + biome_index * 0.28
        enemy.hp = enemy.max_hp
        boss_ref = enemy
        hud.show_banner("ХРАНИТЕЛЬ", Color("ffb66a"))
    enemy.killed.connect(_on_enemy_killed)
    enemies.append(enemy)

func _edge_position() -> Vector2:
    var size := get_viewport_rect().size
    match randi() % 4:
        0: return Vector2(randf_range(10.0, size.x - 10.0), 92.0)
        1: return Vector2(size.x - 8.0, randf_range(110.0, size.y - 80.0))
        2: return Vector2(randf_range(10.0, size.x - 10.0), size.y - 72.0)
        _: return Vector2(8.0, randf_range(110.0, size.y - 80.0))

func _update_night(delta: float) -> void:
    spawn_timer -= delta
    if spawn_left > 0 and spawn_timer <= 0.0:
        spawn_timer = maxf(0.5, 1.5 - wave * 0.12)
        _spawn_enemy()
        spawn_left -= 1
    if wave == 3 and not boss_spawned and spawn_left <= 3:
        boss_spawned = true
        _spawn_enemy(true)

    var reach := player.orbit_radius + player.axes * 4.0
    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            continue
        _update_boss_special(enemy, delta)
        if enemy.windup > 0.0:
            enemy.clear_target()
        else:
            var target := player.global_position if enemy.global_position.distance_to(player.global_position) < 155.0 else base_position
            enemy.set_target_position(target)
        if player.global_position.distance_to(enemy.global_position) <= reach + (24.0 if enemy.boss else 12.0):
            var hit := player.damage * delta * 1.34
            if randf() < player.crit_chance:
                hit *= 2.0
            enemy.take_damage(hit)
        enemy.hit_cooldown = maxf(0.0, enemy.hit_cooldown - delta)
        if enemy.hit_cooldown <= 0.0:
            if enemy.global_position.distance_to(player.global_position) < (34.0 if enemy.boss else 23.0):
                player.take_damage(enemy.contact_damage)
                enemy.hit_cooldown = 0.78
            elif enemy.global_position.distance_to(base_position) < 52.0:
                var amount := enemy.contact_damage * (0.5 if built["wall"] else 1.0)
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
    if not built["turret"] or enemies.is_empty():
        return
    turret_timer -= delta
    if turret_timer > 0.0:
        return
    turret_timer = 0.5
    var nearest: AxEnemy = null
    var best := INF
    for enemy in enemies:
        if not is_instance_valid(enemy): continue
        var d := enemy.global_position.distance_to(base_position)
        if d < best:
            best = d
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
    var reward := 25 if enemy.boss else (3 if enemy.enemy_type == "brute" else 1)
    run_coins += reward
    player.gain_xp(20 if enemy.boss else (6 if enemy.enemy_type == "brute" else 4))
    if enemy.boss:
        run_shards = int(biome["reward"])
        boss_ref = null
        hud.hide_boss()
    enemy.queue_free()

func _show_perks(level: int) -> void:
    var buttons: Array = []
    for perk in GameRules.random_perks(3):
        buttons.append({"text":"%s %s — %s" % [perk["icon"], perk["name"], perk["desc"]], "action":"perk:" + str(perk["id"])})
    hud.show_modal("✨", "Уровень %d" % level, "Выбери усиление на этот забег", buttons)

func _on_player_died() -> void:
    if finishing:
        return
    finishing = true
    var buttons: Array = []
    if not revived:
        buttons.append({"text":"▶ Воскреснуть с 50% HP","action":"revive"})
    buttons.append({"text":"Завершить экспедицию","action":"end"})
    hud.show_modal("💀", "Герой пал", "Одно rewarded-воскрешение доступно на забег." if not revived else "Второго воскрешения нет.", buttons)

func _on_player_damaged(_amount: float, blocked: bool) -> void:
    hud.damage_feedback(blocked)
    hud.set_status("Щит поглотил удар" if blocked else "Получен урон")

func _finish_run(won: bool) -> void:
    if finishing and player.hp > 0.0:
        return
    finishing = true
    var reward := 22 + wave * 15 + run_coins + builds * 3
    GameState.register_run(wave, won, biome_index, kills, builds, trees_cut)
    Analytics.event("run_end", {"won":won,"wave":wave,"biome":biome_index,"kills":kills})
    run_finished.emit({"won":won,"biome":biome_index,"wave":wave,"coins":reward,"shards":run_shards if won else 0,"kills":kills})

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
        hud.show_modal("Ⅱ", "Пауза", "Текущий забег не сохраняется после выхода.", [{"text":"Продолжить","action":"resume"},{"text":"В лагерь","action":"quit"}])
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
    var size := get_viewport_rect().size
    var night := phase == "night"
    var top := Color(str(biome.get("sky", "dceabc")))
    var bottom := Color(str(biome.get("ground", "9fc77c")))
    if night:
        top = Color("213647") if biome_index < 2 else Color("38262d")
        bottom = Color("304a40") if biome_index < 2 else Color("58322f")
    draw_rect(Rect2(Vector2.ZERO, size), bottom)
    for i in range(28):
        var y := float(i) / 27.0 * size.y
        draw_rect(Rect2(0, y, size.x, size.y / 27.0 + 1.0), top.lerp(bottom, float(i) / 27.0))
    for i in range(70):
        draw_rect(Rect2(fmod(i * 97.0, size.x), fmod(i * 53.0, size.y), 2, 5), Color(0.2,0.35,0.18,0.12))
    draw_circle(base_position, 64, Color("b69a6b") if night else Color("d6be8c"))
    draw_arc(base_position, 64, 0, TAU, 64, Color("684b31") if built["wall"] else Color("987f5b"), 8.0 if built["wall"] else 2.5)
    draw_rect(Rect2(base_position - Vector2(23,17), Vector2(46,34)), Color("835f40"))
    draw_colored_polygon(PackedVector2Array([base_position+Vector2(-29,-17),base_position+Vector2(0,-40),base_position+Vector2(29,-17)]), Color("5e402d"))
    draw_circle(base_position + Vector2(0,4), 7, Color("ffbd58"))
    draw_circle(base_position + Vector2(0,4), 32, Color(1.0,0.74,0.34,0.16))
    var ratio := clampf(base_hp / maxf(1.0, base_max_hp), 0.0, 1.0)
    draw_rect(Rect2(base_position+Vector2(-46,-80),Vector2(92,5)),Color(0.1,0.1,0.1,0.22))
    draw_rect(Rect2(base_position+Vector2(-46,-80),Vector2(92*ratio,5)),Color("79aa6d"))
    if boss_warning_active:
        draw_circle(boss_warning_position, 64, Color(0.84,0.27,0.27,0.12))
        draw_arc(boss_warning_position, 64, 0, TAU, 64, Color(0.9,0.35,0.35,0.75), 3)
