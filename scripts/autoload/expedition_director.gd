extends Node

var world: GameWorld = null
var fx: ExpeditionFX = null
var elapsed: float = 0.0
var last_phase: String = ""
var last_wave: int = -1
var signature_cooldown: float = 2.4
var signature_uses: int = 0
var elite_kills: int = 0
var elite_bonus_chance: float = 0.0
var forced_elites: int = 0
var seen_enemies: Dictionary = {}
var day_events_shown: Dictionary = {}

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world):
        _reset_runtime_refs()
        world = _find_world(get_tree().current_scene)
        if world != null:
            _attach_world(world)
        return

    if world.finishing:
        return

    elapsed += delta
    _track_new_enemies()
    _update_enemy_slows(delta)
    _handle_phase_transition()

    if world.player == null or world.hud == null:
        return

    if world.phase == "night" and not world.hud.modal_open():
        signature_cooldown -= delta
        if signature_cooldown <= 0.0:
            if trigger_signature_now():
                signature_cooldown = _signature_interval(world.player.weapon_id)
            else:
                signature_cooldown = 0.55

func _reset_runtime_refs() -> void:
    world = null
    fx = null
    seen_enemies.clear()
    day_events_shown.clear()
    last_phase = ""
    last_wave = -1

func _find_world(node: Node) -> GameWorld:
    if node == null:
        return null
    if node is GameWorld:
        return node as GameWorld
    for child: Node in node.get_children():
        var found: GameWorld = _find_world(child)
        if found != null:
            return found
    return null

func _attach_world(new_world: GameWorld) -> void:
    world = new_world
    elapsed = 0.0
    last_phase = world.phase
    last_wave = world.wave
    signature_cooldown = 2.2
    signature_uses = 0
    elite_kills = 0
    elite_bonus_chance = 0.0
    forced_elites = 0
    seen_enemies.clear()
    day_events_shown.clear()

    fx = ExpeditionFX.new()
    world.add_child(fx)
    fx.setup(world)

    if not world.hud.action_requested.is_connected(_on_hud_action):
        world.hud.action_requested.connect(_on_hud_action)

func _handle_phase_transition() -> void:
    if world == null:
        return
    if world.phase == last_phase and world.wave == last_wave:
        return

    last_phase = world.phase
    last_wave = world.wave
    if world.phase == "night":
        signature_cooldown = 1.6
        if world.hud != null:
            world.hud.set_status("⚔️ Фирменный приём оружия заряжается автоматически.")

func _track_new_enemies() -> void:
    if world == null:
        return
    for enemy: AxEnemy in world.enemies:
        if not is_instance_valid(enemy):
            continue
        var enemy_id: int = enemy.get_instance_id()
        if seen_enemies.has(enemy_id):
            continue
        seen_enemies[enemy_id] = true
        if enemy.boss:
            continue

        var chance: float = clampf(0.06 + maxf(0.0, float(world.wave - 1)) * 0.035 + elite_bonus_chance, 0.0, 0.55)
        if forced_elites > 0:
            forced_elites -= 1
            make_elite(enemy)
        elif randf() < chance:
            make_elite(enemy)

func make_elite(enemy: AxEnemy) -> bool:
    if enemy == null or not is_instance_valid(enemy) or enemy.boss or bool(enemy.get_meta("expedition_elite", false)):
        return false

    enemy.set_meta("expedition_elite", true)
    enemy.max_hp *= 1.72
    enemy.hp = enemy.max_hp
    enemy.move_speed *= 1.08
    enemy.contact_damage *= 1.30
    enemy.base_scale *= 1.10
    enemy.tint = enemy.tint.lightened(0.16)

    if not enemy.killed.is_connected(_on_elite_killed):
        enemy.killed.connect(_on_elite_killed)
    if fx != null and is_instance_valid(fx):
        fx.burst("elite", enemy.global_position, 34.0, 0.48)
    return true

func _on_elite_killed(enemy: AxEnemy) -> void:
    if world == null or not is_instance_valid(world):
        return
    if not bool(enemy.get_meta("expedition_elite", false)):
        return

    elite_kills += 1
    var bonus: int = 5 + maxi(0, world.wave - 1) * 2
    world.run_coins += bonus
    if world.player != null:
        world.player.gain_xp(5)
    if fx != null and is_instance_valid(fx):
        fx.burst("elite", enemy.global_position, 48.0, 0.62)
    if world.hud != null:
        world.hud.set_status("⚡ Элитный враг повержен · +%d 🪙" % bonus)
    Analytics.event("elite_killed", {"biome": world.biome_index, "wave": world.wave, "bonus": bonus})

func _maybe_show_day_event() -> void:
    if world == null or world.hud == null or world.player == null:
        return
    if world.hud.modal_open():
        return
    # The first day is intentionally clean: learn harvest -> deposit -> build first.
    if world.wave <= 0:
        return
    if world.phase_time > world.phase_max - 7.0:
        return

    var day_key: String = str(world.wave)
    if bool(day_events_shown.get(day_key, false)):
        return
    day_events_shown[day_key] = true

    if world.wave == 1:
        world.hud.show_modal(
            "",
            "ТЛЕЮЩИЙ АЛТАРЬ",
            "После первой ночи в лесу вспыхнул древний огонь. Рискнуть здоровьем ради силы или забрать припасы?",
            [
                {"text":"КЛЯТВА ОГНЯ  -20% HP  +22% УРОНА", "action":"event:altar_power"},
                {"text":"РАЗОБРАТЬ  +6 ДЕРЕВА  +4 КАМНЯ", "action":"event:altar_supply"}
            ]
        )
    else:
        world.hud.show_modal(
            "",
            "ОСКВЕРНЁННЫЙ СУНДУК",
            "Перед последней ночью можно рискнуть ради большой награды. Открытие привлечёт более сильных врагов.",
            [
                {"text":"ОТКРЫТЬ  +26 МОНЕТ  +ЭЛИТА", "action":"event:chest_open"},
                {"text":"НЕ РИСКОВАТЬ  +10 МОНЕТ", "action":"event:chest_safe"}
            ]
        )

func _on_hud_action(action: String) -> void:
    if action.begins_with("event:"):
        apply_event_action(action)

func apply_event_action(action: String) -> bool:
    if world == null or world.player == null or world.hud == null:
        return false

    var banner: String = ""
    match action:
        "event:altar_power":
            var sacrifice: float = world.player.max_hp * 0.20
            world.player.hp = maxf(1.0, world.player.hp - sacrifice)
            world.player.damage *= 1.22
            banner = "КЛЯТВА ПРИНЯТА"
            if fx != null and is_instance_valid(fx):
                fx.burst("risk", world.player.global_position, 72.0, 0.72)
        "event:altar_supply":
            world.storage["wood"] = int(world.storage.get("wood", 0)) + 6
            world.storage["stone"] = int(world.storage.get("stone", 0)) + 4
            banner = "ПРИПАСЫ ДОБЫТЫ"
        "event:chest_open":
            world.run_coins += 26
            elite_bonus_chance = minf(0.40, elite_bonus_chance + 0.18)
            forced_elites += 1
            banner = "ТЬМА ПРОСНУЛАСЬ"
        "event:chest_safe":
            world.run_coins += 10
            banner = "БЕЗОПАСНАЯ ДОБЫЧА"
        "event:caravan_dark":
            world.storage["ore"] = int(world.storage.get("ore", 0)) + 7
            world.run_coins += 20
            forced_elites += 2
            elite_bonus_chance = minf(0.45, elite_bonus_chance + 0.10)
            banner = "ГРУЗ ЗАБРАН"
        "event:caravan_safe":
            world.storage["ore"] = int(world.storage.get("ore", 0)) + 3
            world.storage["wood"] = int(world.storage.get("wood", 0)) + 5
            banner = "ПРОВИЗИЯ СОБРАНА"
        _:
            return false

    world.hud.hide_modal()
    world.hud.show_banner(banner, Color("f0c778"))
    Feedback.play("level", 10)
    Analytics.event("day_event_choice", {"choice": action, "biome": world.biome_index, "wave": world.wave})
    return true

func trigger_signature_now() -> bool:
    if world == null or world.player == null or world.hud == null:
        return false

    var weapon_id: String = world.player.weapon_id
    var fired: bool = false
    match weapon_id:
        "spear":
            fired = _signature_spear()
        "hammer":
            fired = _signature_hammer()
        "twin_blades":
            fired = _signature_twin_blades()
        _:
            fired = _signature_axes()

    if fired:
        signature_uses += 1
        Feedback.play("level", 7)
        Analytics.event("weapon_signature", {"weapon": weapon_id, "biome": world.biome_index, "wave": world.wave})
    return fired

func _signature_axes() -> bool:
    var targets: Array[AxEnemy] = _targets_in_range(100.0)
    if targets.is_empty():
        return false
    for enemy: AxEnemy in targets:
        enemy.take_damage(world.player.damage * 1.48)
    if fx != null and is_instance_valid(fx):
        fx.burst("axes", world.player.global_position, 100.0, 0.62)
    world.hud.set_status("🪓 Круг Бури — удар по всем врагам рядом")
    return true

func _signature_spear() -> bool:
    var targets: Array[AxEnemy] = _nearest_targets(4, 185.0)
    if targets.is_empty():
        return false
    for enemy: AxEnemy in targets:
        enemy.take_damage(world.player.damage * 1.72)
        if fx != null and is_instance_valid(fx):
            fx.line("spear", world.player.global_position, enemy.global_position, 0.46)
    world.hud.set_status("🌿 Линия Корней — копьё пронзает несколько целей")
    return true

func _signature_hammer() -> bool:
    var targets: Array[AxEnemy] = _targets_in_range(105.0)
    if targets.is_empty():
        return false
    for enemy: AxEnemy in targets:
        enemy.take_damage(world.player.damage * 1.88)
        _apply_enemy_slow(enemy, 0.48, 1.75)
    if fx != null and is_instance_valid(fx):
        fx.burst("hammer", world.player.global_position, 108.0, 0.78)
    world.hud.set_status("❄️ Ледяной Удар — тяжёлый урон и замедление")
    return true

func _signature_twin_blades() -> bool:
    var targets: Array[AxEnemy] = _nearest_targets(5, 138.0)
    if targets.is_empty():
        return false
    for enemy: AxEnemy in targets:
        enemy.take_damage(world.player.damage * 1.02)
        if fx != null and is_instance_valid(fx):
            fx.line("twin_blades", world.player.global_position, enemy.global_position, 0.30)
    world.player.shield_hits = mini(5, world.player.shield_hits + 1)
    if fx != null and is_instance_valid(fx):
        fx.burst("twin_blades", world.player.global_position, 76.0, 0.48)
    world.hud.set_status("🔥 Пепельный Рывок — серия ударов и +1 заряд щита")
    return true

func _targets_in_range(max_distance: float) -> Array[AxEnemy]:
    var result: Array[AxEnemy] = []
    if world == null or world.player == null:
        return result
    for enemy: AxEnemy in world.enemies:
        if not is_instance_valid(enemy) or enemy.dying:
            continue
        if world.player.global_position.distance_to(enemy.global_position) <= max_distance:
            result.append(enemy)
    return result

func _nearest_targets(max_count: int, max_distance: float) -> Array[AxEnemy]:
    var result: Array[AxEnemy] = []
    if world == null or world.player == null:
        return result

    while result.size() < max_count:
        var best: AxEnemy = null
        var best_distance: float = INF
        for enemy: AxEnemy in world.enemies:
            if not is_instance_valid(enemy) or enemy.dying or result.has(enemy):
                continue
            var distance: float = world.player.global_position.distance_to(enemy.global_position)
            if distance <= max_distance and distance < best_distance:
                best = enemy
                best_distance = distance
        if best == null:
            break
        result.append(best)
    return result

func _apply_enemy_slow(enemy: AxEnemy, factor: float, duration: float) -> void:
    if enemy == null or not is_instance_valid(enemy) or enemy.dying:
        return
    var adjusted_factor: float = maxf(factor, 0.72) if enemy.boss else factor
    var adjusted_duration: float = duration * 0.55 if enemy.boss else duration
    if not enemy.has_meta("expedition_speed_before"):
        enemy.set_meta("expedition_speed_before", enemy.move_speed)
        enemy.move_speed *= adjusted_factor
    var current_time: float = float(enemy.get_meta("expedition_slow_time", 0.0))
    enemy.set_meta("expedition_slow_time", maxf(current_time, adjusted_duration))

func _update_enemy_slows(delta: float) -> void:
    if world == null:
        return
    for enemy: AxEnemy in world.enemies:
        if not is_instance_valid(enemy) or not enemy.has_meta("expedition_slow_time"):
            continue
        var time_left: float = float(enemy.get_meta("expedition_slow_time", 0.0)) - delta
        if time_left <= 0.0:
            if enemy.has_meta("expedition_speed_before"):
                enemy.move_speed = float(enemy.get_meta("expedition_speed_before", enemy.move_speed))
                enemy.remove_meta("expedition_speed_before")
            enemy.remove_meta("expedition_slow_time")
        else:
            enemy.set_meta("expedition_slow_time", time_left)

func _signature_interval(weapon_id: String) -> float:
    match weapon_id:
        "spear":
            return 5.8
        "hammer":
            return 7.1
        "twin_blades":
            return 4.7
    return 5.2
