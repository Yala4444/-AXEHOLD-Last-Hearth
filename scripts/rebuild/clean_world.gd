class_name AXEHOLDCleanWorld
extends GameWorld

const CleanPlayerScene: PackedScene = preload("res://scenes/rebuild/clean_player.tscn")
const CleanEnemyScene: PackedScene = preload("res://scenes/rebuild/clean_enemy.tscn")
const CleanResourceScene: PackedScene = preload("res://scenes/rebuild/clean_resource.tscn")
const CleanBuildPadScene: PackedScene = preload("res://scenes/rebuild/clean_build_pad.tscn")

const FOREST_ARENA_PATH := "res://assets/art/vertical_slice_i/forest_arena.webp"
const HEARTH_STRIP_PATH := "res://assets/art/vertical_slice_i/hearth_fire.webp"

var clean_background: Texture2D
var clean_hearth_strip: Texture2D
var clean_hearth: AnimatedSprite2D
var clean_canvas_modulate: CanvasModulate
var clean_rng := RandomNumberGenerator.new()
var clean_ground_marks: Array[Dictionary] = []
var clean_ground_patches: Array[Dictionary] = []
var clean_respawns: Array[Dictionary] = []
var clean_deposit_cooldown: float = 0.0
var clean_spawn_cooldown: float = 0.0
var clean_turret_cooldown: float = 0.0
var clean_level_choice_pending: bool = false
var clean_boss_pending: bool = false
var clean_boss_spawned: bool = false
var clean_boss_dead: bool = false
var clean_run_time: float = 0.0
var clean_night_cap: float = 0.0

func configure(index: int, selected_threat: int = 1, mode: String = "expedition") -> void:
    biome_index = clampi(index, 0, GameRules.BIOMES.size() - 1)
    threat_level = clampi(selected_threat, 1, ThreatRules.MAX_LEVEL)
    run_mode = mode if mode in ["expedition","endless"] else "expedition"
    visual_v2_enabled = true
    tutorial_run = false

func _ready() -> void:
    # This scene intentionally does not call the legacy GameWorld._ready().
    # Mechanics are re-authored here as a small coherent core instead of
    # stacking another visual mode over the old runtime.
    y_sort_enabled = true
    world_size = Vector2(1170, 2380)
    world_rect = Rect2(Vector2.ZERO, world_size)
    base_position = Vector2(world_size.x * 0.5, 405.0)
    biome = GameRules.biome(biome_index)
    base_max_hp = 270.0
    base_hp = base_max_hp
    storage = {"wood":0,"stone":0,"ore":0,"parts":0}
    built = {"wall":false,"forge":false,"turret":false,"shrine":false}
    phase = "day"
    wave = 0
    phase_max = 58.0
    phase_time = phase_max
    spawn_left = 0
    kills = 0
    builds = 0
    run_coins = 0
    run_shards = 0
    finishing = false
    paused_local = false

    clean_rng.seed = 94021 + int(GameState.data.get("selected_threat",1)) * 137 + biome_index * 811
    clean_background = ResourceLoader.load(FOREST_ARENA_PATH) as Texture2D
    clean_hearth_strip = ResourceLoader.load(HEARTH_STRIP_PATH) as Texture2D
    _seed_ground_details()

    core_fx = CoreFX.new()
    add_child(core_fx)
    core_fx.set_visual_gate(true)

    var clean_biome_fx := BiomeFX.new()
    add_child(clean_biome_fx)
    clean_biome_fx.setup(self,biome_index)

    _create_clean_hearth()
    _create_clean_player()
    _create_clean_build_pads()
    _spawn_initial_resources()

    hud = GameHud.new()
    add_child(hud)
    hud.set_visual_gate(true)
    hud.action_requested.connect(_on_clean_hud_action)
    hud.set_run_objective("ДЕНЬ 1 · СОБЕРИ РЕСУРСЫ И УКРЕПИ ОЧАГ")
    hud.set_status("Новая сборка AXEHOLD: мир, герой и бой пересобраны с нуля.",1,3.4)

    clean_canvas_modulate = CanvasModulate.new()
    add_child(clean_canvas_modulate)
    clean_canvas_modulate.color = Color.WHITE

    if MobileControls != null:
        MobileControls.bind_world(self)

    queue_redraw()
    _update_clean_hud()

func _exit_tree() -> void:
    if MobileControls != null:
        MobileControls.unbind_world(self)

func _create_clean_player() -> void:
    player = CleanPlayerScene.instantiate() as AxPlayer
    add_child(player)
    player.global_position = base_position + Vector2(0, 155)
    var upgrades: Dictionary = GameState.data.get("upgrades", {}) as Dictionary
    var skin_index: int = int(GameState.data.get("selected_skin",0))
    player.setup(upgrades, GameRules.skin(skin_index))
    player.set_world_bounds(world_rect.grow(-28.0))
    player.set_home_target(base_position)
    player.damage = maxf(27.0, player.damage)
    player.axes = clampi(player.axes,1,5)
    player.damaged.connect(_on_clean_player_damaged)
    player.died.connect(_on_clean_player_died)

    camera = Camera2D.new()
    player.add_child(camera)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 7.5
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(world_size.x)
    camera.limit_bottom = int(world_size.y)
    camera.limit_smoothed = true
    camera.make_current()

func _create_clean_hearth() -> void:
    if clean_hearth_strip == null:
        return
    var frames := SpriteFrames.new()
    frames.add_animation("burn")
    frames.set_animation_loop("burn",true)
    frames.set_animation_speed("burn",6.5)
    var frame_w: float = clean_hearth_strip.get_width() / 4.0
    var frame_h: float = clean_hearth_strip.get_height()
    for i: int in range(4):
        var atlas := AtlasTexture.new()
        atlas.atlas = clean_hearth_strip
        atlas.region = Rect2(frame_w * i,0,frame_w,frame_h)
        frames.add_frame("burn",atlas)
    clean_hearth = AnimatedSprite2D.new()
    clean_hearth.sprite_frames = frames
    clean_hearth.animation = "burn"
    clean_hearth.position = base_position
    clean_hearth.scale = Vector2.ONE * 0.56
    add_child(clean_hearth)
    clean_hearth.play()

func _create_clean_build_pads() -> void:
    pads.clear()
    for spec_variant: Variant in GameRules.BUILD_SPECS:
        var spec: Dictionary = spec_variant as Dictionary
        var pad := CleanBuildPadScene.instantiate() as BuildPad
        add_child(pad)
        pad.global_position = base_position + Vector2(spec.get("offset",Vector2.ZERO))
        pad.configure(
            str(spec.get("id","wall")),
            str(spec.get("name","ПОСТРОЙКА")),
            spec.get("cost",{}) as Dictionary,
            false,
            str(spec.get("effect",""))
        )
        pad.set_visual_gate(true)
        pads.append(pad)

func _spawn_initial_resources() -> void:
    resources.clear()
    for _i: int in range(22):
        _spawn_clean_resource("tree")
    for _i: int in range(8):
        _spawn_clean_resource("rock")
    for _i: int in range(5):
        _spawn_clean_resource("ore")

func _spawn_clean_resource(kind: String) -> void:
    var spot := CleanResourceScene.instantiate() as ResourceSpot
    add_child(spot)
    spot.configure(kind, clean_rng.randi_range(0,2), 0)
    var pos: Vector2 = _clean_resource_position(kind)
    spot.global_position = pos
    resources.append(spot)

func _clean_resource_position(kind: String) -> Vector2:
    var min_base_distance: float = 270.0
    var min_other: float = 102.0 if kind == "tree" else 72.0
    for _attempt: int in range(80):
        var pos := Vector2(
            clean_rng.randf_range(72.0,world_size.x-72.0),
            clean_rng.randf_range(210.0,world_size.y-92.0)
        )
        if pos.distance_to(base_position) < min_base_distance:
            continue
        var clear: bool = true
        for existing: ResourceSpot in resources:
            if is_instance_valid(existing) and existing.global_position.distance_to(pos) < min_other:
                clear = false
                break
        if clear:
            return pos
    return Vector2(clean_rng.randf_range(80,world_size.x-80),clean_rng.randf_range(650,world_size.y-120))

func _seed_ground_details() -> void:
    clean_ground_marks.clear()
    clean_ground_patches.clear()
    for _i: int in range(58):
        clean_ground_patches.append({
            "pos":Vector2(clean_rng.randf_range(35,world_size.x-35),clean_rng.randf_range(40,world_size.y-40)),
            "radius":clean_rng.randf_range(48.0,128.0),
            "tone":clean_rng.randi_range(0,2)
        })
    for _i: int in range(220):
        var pos := Vector2(clean_rng.randf_range(20,world_size.x-20),clean_rng.randf_range(20,world_size.y-20))
        var roll: float = clean_rng.randf()
        clean_ground_marks.append({
            "pos":pos,
            "kind":0 if roll < 0.50 else (1 if roll < 0.78 else 2),
            "size":clean_rng.randf_range(1.2,3.4),
            "rot":clean_rng.randf_range(-0.8,0.8)
        })

func _process(delta: float) -> void:
    clean_run_time += delta
    if finishing:
        return

    _update_world_tint(delta)
    queue_redraw()

    if paused_local or (hud != null and hud.modal_open()):
        _update_clean_hud()
        return

    clean_deposit_cooldown = maxf(0.0,clean_deposit_cooldown-delta)
    clean_turret_cooldown = maxf(0.0,clean_turret_cooldown-delta)

    _resolve_player_resource_overlap()
    _update_resource_loop(delta)
    _update_deposit_loop()
    _update_build_loop(delta)
    _update_build_effects(delta)

    if phase == "day":
        phase_time = maxf(0.0,phase_time-delta)
        if phase_time <= 0.0:
            _begin_clean_night()
    else:
        _update_clean_night(delta)

    _update_respawns(delta)
    _update_clean_hud()
    _check_clean_failure()

func _update_world_tint(delta: float) -> void:
    if clean_canvas_modulate == null:
        return
    var target := Color.WHITE
    if phase == "night":
        target = Color(0.54,0.62,0.73)
    elif phase_time < 12.0:
        target = Color(0.92,0.78,0.66)
    clean_canvas_modulate.color = clean_canvas_modulate.color.lerp(target,clampf(delta*1.8,0.0,1.0))

func _update_resource_loop(delta: float) -> void:
    var dead: Array[ResourceSpot] = []
    for spot: ResourceSpot in resources:
        if not is_instance_valid(spot):
            dead.append(spot)
            continue
        var reach: float = player.orbit_radius + spot.radius * 0.45
        if player.global_position.distance_to(spot.global_position) <= reach:
            if spot.damage(player.damage * delta * 0.78):
                var resource_kind: String = "wood" if spot.resource_type == "tree" else ("stone" if spot.resource_type == "rock" else "ore")
                var amount: int = 5 if resource_kind == "wood" else (4 if resource_kind == "stone" else 3)
                var gained: int = player.add_resource(resource_kind,amount)
                if gained > 0:
                    if spot.resource_type == "tree":
                        trees_cut += 1
                    hud.set_status("+%d %s в рюкзак" % [gained,_clean_resource_name(resource_kind)],0,1.1)
                clean_respawns.append({"kind":spot.resource_type,"time":10.0 + clean_rng.randf_range(0.0,5.0)})
                dead.append(spot)
                spot.queue_free()

    for item: ResourceSpot in dead:
        resources.erase(item)

func _clean_resource_name(kind: String) -> String:
    match kind:
        "wood": return "дерева"
        "stone": return "камня"
        "ore": return "руды"
        _: return kind

func _update_respawns(delta: float) -> void:
    var done: Array[int] = []
    for i: int in range(clean_respawns.size()):
        clean_respawns[i]["time"] = float(clean_respawns[i].get("time",0.0)) - delta
        if float(clean_respawns[i]["time"]) <= 0.0:
            _spawn_clean_resource(str(clean_respawns[i].get("kind","tree")))
            done.append(i)
    done.reverse()
    for index: int in done:
        clean_respawns.remove_at(index)

func _resolve_player_resource_overlap() -> void:
    if player == null:
        return
    for spot: ResourceSpot in resources:
        if not is_instance_valid(spot):
            continue
        var min_distance: float = spot.radius + 13.0
        var delta_pos: Vector2 = player.global_position - spot.global_position
        var distance: float = delta_pos.length()
        if distance > 0.01 and distance < min_distance:
            player.global_position = spot.global_position + delta_pos.normalized() * min_distance
            player.velocity = player.velocity.slide(delta_pos.normalized())

func _update_deposit_loop() -> void:
    if player == null or player.inventory_total() <= 0 or clean_deposit_cooldown > 0.0:
        return
    if player.global_position.distance_to(base_position) > 105.0:
        return
    var bag: Dictionary = player.clear_inventory()
    for key: String in ["wood","stone","ore"]:
        storage[key] = int(storage.get(key,0)) + int(bag.get(key,0))
    clean_deposit_cooldown = 0.7
    hud.show_banner("РЕСУРСЫ ДОСТАВЛЕНЫ К ОЧАГУ",Color("e2c56d"),0)

func _update_build_loop(delta: float) -> void:
    var any_focus: bool = false
    for pad: BuildPad in pads:
        if not is_instance_valid(pad):
            continue
        var close: bool = player.global_position.distance_to(pad.global_position) < 63.0
        var afford: bool = pad.can_build(storage)
        pad.set_context_state(afford,close)
        if close:
            any_focus = true
            if pad.built:
                hud.set_built_context(pad.label,pad.effect)
            else:
                hud.set_build_context(pad.label,pad.effect,pad.cost,storage,afford,pad.construction_progress)
                if afford and pad.advance_construction(delta):
                    pad.consume(storage)
                    built[pad.build_type] = true
                    builds += 1
                    _apply_clean_build_effect(pad.build_type)
                    hud.show_banner("%s ПОСТРОЕНА" % pad.label,Color("e8c565"),0)
            if not afford and not pad.built:
                pad.reset_construction()
        elif not pad.built:
            pad.reset_construction()
    if not any_focus:
        hud.hide_build_context()

func _apply_clean_build_effect(kind: String) -> void:
    match kind:
        "forge":
            player.damage *= 1.30
            player.orbit_radius += 6.0
        "wall":
            base_max_hp += 80.0
            base_hp = minf(base_max_hp,base_hp + 80.0)
        "shrine":
            player.hp = minf(player.max_hp,player.hp + 25.0)
        "turret":
            pass

func _update_build_effects(delta: float) -> void:
    if bool(built.get("shrine",false)):
        player.hp = minf(player.max_hp,player.hp + delta * 0.7)
        base_hp = minf(base_max_hp,base_hp + delta * 0.9)

    if bool(built.get("turret",false)) and clean_turret_cooldown <= 0.0 and not enemies.is_empty():
        var target: AxEnemy = _nearest_clean_enemy(base_position,330.0)
        if target != null:
            target.take_damage(34.0)
            clean_turret_cooldown = 0.82

func _begin_clean_night() -> void:
    phase = "night"
    wave += 1
    phase_max = 42.0
    phase_time = phase_max
    spawn_left = GameRules.wave_count(wave,float(GameRules.biome(biome_index).get("difficulty",1.0)))
    clean_spawn_cooldown = 0.35
    clean_boss_pending = wave >= 3
    clean_boss_spawned = false
    clean_boss_dead = false
    clean_night_cap = 70.0
    hud.show_banner("НОЧЬ %d · ЗАЩИТИ ОЧАГ" % wave,Color("d9815b"),2)
    hud.set_run_objective("НОЧЬ %d · НЕ ДАЙ ТВАРЯМ ДОБРАТЬСЯ ДО ОЧАГА" % wave)

func _update_clean_night(delta: float) -> void:
    phase_time = maxf(0.0,phase_time-delta)
    clean_night_cap -= delta
    clean_spawn_cooldown -= delta

    if spawn_left > 0 and clean_spawn_cooldown <= 0.0:
        _spawn_clean_enemy(false)
        spawn_left -= 1
        clean_spawn_cooldown = maxf(0.45,1.12 - float(wave)*0.12)

    if spawn_left <= 0 and clean_boss_pending and not clean_boss_spawned and enemies.size() <= 2:
        _spawn_clean_enemy(true)
        clean_boss_spawned = true
        hud.show_banner("ЛЕСНОЙ ХРАНИТЕЛЬ ПРОБУДИЛСЯ",Color("d96d55"),3)

    _update_enemy_targets_and_combat(delta)

    if clean_boss_spawned and clean_boss_dead:
        _finish_clean_run(true)
        return

    if spawn_left <= 0 and enemies.is_empty() and not clean_boss_pending:
        _begin_clean_day()
        return

    if clean_night_cap <= 0.0 and enemies.is_empty():
        if clean_boss_pending and clean_boss_spawned:
            return
        _begin_clean_day()

func _spawn_clean_enemy(is_boss: bool) -> void:
    var enemy := CleanEnemyScene.instantiate() as AxEnemy
    add_child(enemy)
    enemy.global_position = _clean_edge_position()
    var kind: String = "boss" if is_boss else _clean_enemy_kind()
    var difficulty: float = float(GameRules.biome(biome_index).get("difficulty",1.0)) * (1.0 + float(wave-1)*0.10)
    enemy.configure(kind,difficulty,wave,Color("705d70"),is_boss,0)
    enemy.killed.connect(_on_clean_enemy_killed)
    enemies.append(enemy)

func _clean_enemy_kind() -> String:
    var roll: float = clean_rng.randf()
    if wave <= 1:
        if roll < 0.68: return "normal"
        if roll < 0.88: return "runner"
        return "stalker"
    if roll < 0.42: return "normal"
    if roll < 0.62: return "runner"
    if roll < 0.78: return "brute"
    if roll < 0.91: return "stalker"
    return "guardian"

func _clean_edge_position() -> Vector2:
    var side: int = clean_rng.randi_range(0,3)
    match side:
        0: return Vector2(clean_rng.randf_range(50,world_size.x-50),55)
        1: return Vector2(clean_rng.randf_range(50,world_size.x-50),world_size.y-55)
        2: return Vector2(55,clean_rng.randf_range(100,world_size.y-70))
        _: return Vector2(world_size.x-55,clean_rng.randf_range(100,world_size.y-70))

func _update_enemy_targets_and_combat(delta: float) -> void:
    for enemy: AxEnemy in enemies:
        if not is_instance_valid(enemy) or enemy.dying:
            continue

        var distance_to_player: float = enemy.global_position.distance_to(player.global_position)
        var target: Vector2 = player.global_position if distance_to_player < 260.0 else base_position
        enemy.set_target_position(target)

        if distance_to_player <= player.orbit_radius + 24.0:
            var dps: float = player.damage * (0.74 + float(player.axes-1)*0.22)
            enemy.take_damage(dps * delta)

        if distance_to_player <= 27.0 and enemy.hit_cooldown <= 0.0:
            player.take_damage(enemy.contact_damage)
            enemy.hit_cooldown = 0.82

        var hearth_distance: float = enemy.global_position.distance_to(base_position)
        if hearth_distance < 74.0:
            var wall_mult: float = 0.38 if bool(built.get("wall",false)) else 1.0
            base_hp = maxf(0.0,base_hp - enemy.contact_damage * wall_mult * delta * 0.64)

func _on_clean_enemy_killed(enemy: AxEnemy) -> void:
    if enemy == null:
        return
    var was_boss: bool = enemy.boss
    enemies.erase(enemy)
    if is_instance_valid(enemy):
        enemy.queue_free()
    kills += 1
    run_coins += 3 if not was_boss else 45
    if was_boss:
        run_shards += 1
        clean_boss_dead = true
    _gain_clean_xp(5 if not was_boss else 32)

func _gain_clean_xp(amount: int) -> void:
    if player == null:
        return
    player.xp += amount
    if player.xp < player.next_xp:
        return
    player.xp -= player.next_xp
    player.level += 1
    player.next_xp = int(round(float(player.next_xp) * 1.34 + 4.0))
    _offer_clean_upgrade()

func _offer_clean_upgrade() -> void:
    if clean_level_choice_pending or hud == null:
        return
    clean_level_choice_pending = true
    _set_clean_pause(true)

    var pool: Array[Dictionary] = [
        {"id":"damage","text":"ОСТРЫЕ ЛЕЗВИЯ\n+22% урона","rarity":"common"},
        {"id":"orbit","text":"ШИРОКАЯ ДУГА\n+10 радиус орбиты","rarity":"rare"},
        {"id":"weapon","text":"ЕЩЁ ОДНО ОРУЖИЕ\n+1 предмет на орбите","rarity":"epic"},
        {"id":"speed","text":"ЛЁГКИЕ САПОГИ\n+10% скорость","rarity":"rare"},
        {"id":"hp","text":"ЖИВУЧЕСТЬ\n+25 HP и лечение","rarity":"common"}
    ]
    pool.shuffle()
    var buttons: Array = []
    for i: int in range(3):
        var spec: Dictionary = pool[i]
        buttons.append({
            "text":spec["text"],
            "action":"clean_upgrade_" + str(spec["id"]),
            "rarity":spec["rarity"]
        })
    hud.show_modal("star","НОВЫЙ УРОВЕНЬ","Выбери одно усиление. Игра полностью остановлена.",buttons)

func _on_clean_hud_action(action: String) -> void:
    if action.begins_with("clean_upgrade_"):
        var id: String = action.trim_prefix("clean_upgrade_")
        _apply_clean_upgrade(id)
        hud.hide_modal()
        clean_level_choice_pending = false
        _set_clean_pause(false)
        return

    if action == "pause":
        if hud.modal_open():
            return
        _set_clean_pause(true)
        hud.show_modal("","ПАУЗА","Экспедиция остановлена.",[
            {"text":"ПРОДОЛЖИТЬ","action":"clean_resume"},
            {"text":"ВЫЙТИ В ЛАГЕРЬ","action":"clean_quit"}
        ])
    elif action == "clean_resume":
        hud.hide_modal()
        _set_clean_pause(false)
    elif action == "clean_quit":
        hud.hide_modal()
        _set_clean_pause(false)
        finishing = true
        quit_requested.emit()

func _apply_clean_upgrade(id: String) -> void:
    match id:
        "damage":
            player.damage *= 1.22
        "orbit":
            player.orbit_radius += 10.0
        "weapon":
            player.axes = mini(5,player.axes+1)
        "speed":
            player.move_speed *= 1.10
        "hp":
            player.max_hp += 25.0
            player.hp = minf(player.max_hp,player.hp+25.0)
    player.queue_redraw()

func _set_clean_pause(value: bool) -> void:
    paused_local = value
    if player != null:
        player.set_physics_process(not value)
        if value:
            player.release_move_input()
    for enemy: AxEnemy in enemies:
        if is_instance_valid(enemy):
            enemy.set_physics_process(not value)

func _begin_clean_day() -> void:
    phase = "day"
    phase_max = maxf(42.0,58.0-float(wave)*5.0)
    phase_time = phase_max
    clean_boss_pending = false
    clean_boss_spawned = false
    hud.show_banner("РАССВЕТ · НОЧЬ ПЕРЕЖИТА",Color("edc978"),1)
    hud.set_run_objective("ДЕНЬ %d · ДОБЫВАЙ И СТРОЙ" % (wave+1))

func _on_clean_player_damaged(_amount: float, blocked: bool) -> void:
    if hud != null:
        hud.damage_feedback(blocked)

func _on_clean_player_died() -> void:
    _finish_clean_run(false)

func _check_clean_failure() -> void:
    if finishing:
        return
    if player != null and player.hp <= 0.0:
        _finish_clean_run(false)
    elif base_hp <= 0.0:
        _finish_clean_run(false)

func _finish_clean_run(won: bool) -> void:
    if finishing:
        return
    finishing = true
    _set_clean_pause(true)
    if MobileControls != null:
        MobileControls.unbind_world(self)
    var result := {
        "won":won,
        "wave":wave,
        "kills":kills,
        "coins":run_coins + (60 if won else 0),
        "shards":run_shards,
        "builds":builds,
        "trees":trees_cut
    }
    run_finished.emit(result)

func _nearest_clean_enemy(origin: Vector2, max_distance: float) -> AxEnemy:
    var result: AxEnemy = null
    var best: float = max_distance
    for enemy: AxEnemy in enemies:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        var d: float = origin.distance_to(enemy.global_position)
        if d < best:
            best = d
            result = enemy
    return result

func _update_clean_hud() -> void:
    if hud == null or player == null:
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

func _unhandled_input(event: InputEvent) -> void:
    if finishing or paused_local or player == null or hud == null or hud.modal_open():
        return
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
            player.set_target(get_viewport().get_canvas_transform().affine_inverse() * mouse.position)

func _draw() -> void:
    _draw_clean_ground()
    _draw_ground_variation()
    _draw_clean_paths()
    _draw_clean_details()
    _draw_clean_hearth_socket()

func _draw_clean_ground() -> void:
    # One calm terrain surface. The concept illustration is used once around
    # the hearth instead of being tiled across the whole map.
    draw_rect(Rect2(Vector2.ZERO,world_size),Color("6b845f"))
    draw_rect(Rect2(Vector2.ZERO,world_size),Color(0.10,0.17,0.09,0.08))
    if clean_background != null:
        var scenic_rect := Rect2(Vector2(0,0),Vector2(world_size.x,900))
        draw_texture_rect(clean_background,scenic_rect,false,Color(0.82,0.88,0.78,0.66))
        # Gentle fade into the playable forest floor removes the old square seam.
        draw_rect(Rect2(0,700,world_size.x,70),Color(0.40,0.52,0.34,0.10))
        draw_rect(Rect2(0,770,world_size.x,70),Color(0.40,0.52,0.34,0.18))
        draw_rect(Rect2(0,840,world_size.x,80),Color(0.40,0.52,0.34,0.30))

func _draw_ground_variation() -> void:
    for patch: Dictionary in clean_ground_patches:
        var pos: Vector2 = patch.get("pos",Vector2.ZERO)
        var radius: float = float(patch.get("radius",70.0))
        var tone: int = int(patch.get("tone",0))
        var color := Color(0.18,0.29,0.14,0.035)
        if tone == 1:
            color = Color(0.46,0.41,0.24,0.030)
        elif tone == 2:
            color = Color(0.12,0.24,0.16,0.030)
        draw_circle(pos,radius,color)

func _draw_clean_paths() -> void:
    var main_path := PackedVector2Array([
        base_position,
        Vector2(base_position.x-18,650),
        Vector2(base_position.x+60,900),
        Vector2(base_position.x-45,1210),
        Vector2(base_position.x+42,1540),
        Vector2(base_position.x-35,1880),
        Vector2(base_position.x+30,2260)
    ])
    draw_polyline(main_path,Color(0.31,0.22,0.14,0.18),62.0,true)
    draw_polyline(main_path,Color(0.57,0.45,0.29,0.24),42.0,true)

    for pad: BuildPad in pads:
        if not is_instance_valid(pad):
            continue
        var branch := PackedVector2Array([base_position,pad.global_position])
        draw_polyline(branch,Color(0.34,0.24,0.15,0.16),30.0,true)
        draw_polyline(branch,Color(0.56,0.43,0.27,0.20),18.0,true)

func _draw_clean_details() -> void:
    for item: Dictionary in clean_ground_marks:
        var pos: Vector2 = item.get("pos",Vector2.ZERO)
        var kind: int = int(item.get("kind",0))
        var size: float = float(item.get("size",2.0))
        var rot: float = float(item.get("rot",0.0))
        if kind == 0:
            draw_line(pos, pos + Vector2(cos(rot),-absf(sin(rot))-1.2) * (4.0+size), Color(0.26,0.43,0.21,0.28),1.0)
        elif kind == 1:
            draw_circle(pos,size,Color(0.32,0.25,0.15,0.17))
        else:
            draw_circle(pos,size*0.72,Color(0.70,0.69,0.47,0.10))

func _draw_clean_hearth_socket() -> void:
    draw_circle(base_position,128.0,Color(0.96,0.69,0.29,0.042))
    draw_arc(base_position,128.0,0,TAU,64,Color(0.96,0.72,0.30,0.14),1.6)
    draw_set_transform(base_position+Vector2(0,30),0.0,Vector2(1.0,0.27))
    draw_circle(Vector2.ZERO,62.0,Color(0.03,0.035,0.025,0.22))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
