class_name BiomeEventDirector
extends Node

var world: GameWorld
var hazards: Array[BiomeHazardZone] = []
var started_environment: bool = false
var started_hunt: bool = false
var active_environment: bool = false
var environment_time: float = 0.0
var hazard_spawn_timer: float = 0.0
var hazards_spawned: int = 0
var environment_hits: int = 0

var mini_boss: AxEnemy = null
var mini_hunt_time: float = 0.0
var mini_support: Array[AxEnemy] = []

var night_penalties: Dictionary = {}
var events_completed: int = 0
var events_failed: int = 0
var hunts_completed: int = 0
var perfect_events: int = 0

func setup(world_ref: GameWorld) -> void:
    world = world_ref
    set_process(true)

func _process(delta: float) -> void:
    if world != null and world.tutorial_run:
        return
    if world == null or not is_instance_valid(world) or world.player == null or world.finishing:
        return
    if world.paused_local or world.hud.modal_open():
        return

    _update_hazards()

    if world.phase != "day":
        if active_environment:
            _finish_environment(false, "Ночь прервала региональное событие.")
        return

    if world.wave == 1 and not started_environment and world.phase_time <= 34.0:
        if (world.dynamic_world == null or world.dynamic_world.active_event.is_empty()) and (world.field_objectives == null or world.field_objectives.active.is_empty()):
            _start_environment_event()

    if active_environment:
        _update_environment(delta)

    if world.wave == 2 and not started_hunt and not active_environment and world.phase_time <= 29.0:
        # Only one named hunt should define a run. If Events 2.0 already
        # produced one, the regional director yields instead of stacking noise.
        if world.dynamic_world != null and world.dynamic_world.seen_types.has("elite_hunt"):
            started_hunt = true
        elif (world.dynamic_world == null or world.dynamic_world.active_event.is_empty()) and (world.field_objectives == null or world.field_objectives.active.is_empty()):
            _start_regional_hunt()

    if mini_boss != null and is_instance_valid(mini_boss) and not mini_boss.dying:
        mini_hunt_time -= delta
        if mini_hunt_time <= 0.0:
            _fail_regional_hunt()

func _start_environment_event() -> void:
    started_environment = true
    active_environment = true
    environment_time = 10.0
    hazard_spawn_timer = 0.15
    hazards_spawned = 0
    environment_hits = 0

    match world.biome_index:
        1:
            world.player.apply_environment_slow(0.88, 10.0)
            world.hud.show_banner("БЕЛАЯ БУРЯ", Color("b9e8f2"))
            world.hud.set_status("Метель режет скорость. Следи за трескающимся льдом и не стой на месте.")
        2:
            world.hud.show_banner("РАЗЛОМ ЖАРА", Color("f18a55"))
            world.hud.set_status("Земля вскрывается под ногами. Уходи из отмеченных огнём зон.")
        _:
            world.hud.show_banner("КОРНИ ПРОБУЖДАЮТСЯ", Color("a9cf78"))
            world.hud.set_status("Старые корни хватают всё живое. Смотри под ноги и меняй маршрут.")

    Analytics.event("biome_event_started", {
        "biome":world.biome_index,
        "wave":world.wave
    })

func _update_environment(delta: float) -> void:
    environment_time -= delta
    hazard_spawn_timer -= delta

    var spawn_goal: int = 5
    if world.biome_index == 2:
        spawn_goal = 6

    if hazard_spawn_timer <= 0.0 and hazards_spawned < spawn_goal:
        hazards_spawned += 1
        hazard_spawn_timer = 1.45 if world.biome_index == 1 else (1.28 if world.biome_index == 2 else 1.55)
        _spawn_environment_hazard()

    if environment_time <= 0.0:
        _finish_environment(environment_hits <= 1, "")

func _spawn_environment_hazard() -> void:
    var velocity_hint: Vector2 = world.player.velocity * 0.24
    var direction := Vector2.from_angle(randf_range(0.0, TAU))
    var distance: float = randf_range(16.0, 58.0)
    var point: Vector2 = world.player.global_position + velocity_hint + direction * distance
    var safe: Rect2 = world.world_rect.grow(-45.0)
    point.x = clampf(point.x, safe.position.x, safe.end.x)
    point.y = clampf(point.y, safe.position.y, safe.end.y)

    match world.biome_index:
        1:
            _spawn_zone("ice", point, 34.0, 0.78, 2.2, true)
        2:
            _spawn_zone("ember", point, 38.0, 0.72, 2.4, true)
        _:
            _spawn_zone("root", point, 32.0, 0.86, 2.6, true)

func _spawn_zone(kind_id: String, point: Vector2, radius: float, warning: float, linger: float, counts_for_event: bool) -> BiomeHazardZone:
    var zone := BiomeHazardZone.new()
    world.add_child(zone)
    zone.global_position = point
    zone.configure(kind_id, radius, warning, linger)
    zone.set_meta("counts_for_biome_event", counts_for_event)
    hazards.append(zone)
    return zone

func _update_hazards() -> void:
    for i: int in range(hazards.size() - 1, -1, -1):
        var zone: BiomeHazardZone = hazards[i]
        if zone == null or not is_instance_valid(zone):
            hazards.remove_at(i)
            continue
        if not zone.is_active() or zone.spent:
            continue
        if not zone.contains_point(world.player.global_position):
            continue

        zone.spent = true
        if bool(zone.get_meta("counts_for_biome_event", false)):
            environment_hits += 1

        match zone.hazard_kind:
            "ice":
                world.player.take_damage(5.0 * float(world.biome.get("difficulty", 1.0)))
                world.player.apply_environment_slow(0.68, 2.0)
                world.hud.set_status("Лёд сковал шаги. Выбери чистый участок.")
            "ember":
                world.player.take_damage(9.0 * float(world.biome.get("difficulty", 1.0)))
                world.hud.set_status("Жар ударил по герою. Не стой в трещинах.")
            _:
                world.player.take_damage(4.0 * float(world.biome.get("difficulty", 1.0)))
                world.player.apply_environment_slow(0.60, 1.6)
                world.hud.set_status("Корни схватили Странника. Рывок наружу!")
        if world.core_fx != null:
            world.core_fx.environment_hit(zone.hazard_kind, zone.global_position)
        Feedback.play("danger", 6)

func _finish_environment(success: bool, reason: String) -> void:
    if not active_environment:
        return
    active_environment = false
    _clear_event_hazards()

    if success:
        events_completed += 1
        if environment_hits == 0:
            perfect_events += 1
        var reward: int = 10 + world.biome_index * 3
        world.run_coins += reward
        _give_biome_resource(4)
        if world.run_variation != null:
            world.run_variation.reduce_threat(0.8, "biome_event_mastered")
        var regional_boon: String = ""
        if environment_hits == 0:
            match world.biome_index:
                1:
                    world.player.shield_hits = mini(5, world.player.shield_hits + 2)
                    regional_boon = "идеальное прохождение дало +2 защитных заряда"
                2:
                    world.player.damage *= 1.12
                    regional_boon = "идеальное прохождение дало +12% урона до конца забега"
                _:
                    world.resource_yield_multiplier *= 1.15
                    regional_boon = "идеальное прохождение дало +15% добычи до конца забега"
        if world.expedition_memory != null:
            world.expedition_memory.remember(
                "region_event_%d" % world.biome_index,
                "%s ПРЕОДОЛЕНО" % GameRules.biome_event_name(world.biome_index),
                regional_boon if not regional_boon.is_empty() else "Региональное испытание пройдено, давление Тьмы снизилось.",
                "green" if environment_hits == 0 else "neutral",
                environment_hits == 0
            )
        QuestDirector.record("biome_event", 1, {"biome":world.biome_index})
        GameState.record_biome_event(world.biome_index, {"events":1,"perfect":1 if environment_hits == 0 else 0})
        world.hud.show_banner("РЕГИОН УСМИРЁН", Color("d8cc91"))
        world.hud.set_status(("+%d мон. · %s" % [reward, regional_boon]) if not regional_boon.is_empty() else "+%d мон. · ресурс биома · Угроза снижена." % reward)
        Analytics.event("biome_event_completed", {"biome":world.biome_index,"hits":environment_hits})
    else:
        events_failed += 1
        if world.run_variation != null:
            world.run_variation.add_threat(1.0, "biome_event_failed")
        _apply_night_penalty(world.wave + 1, false)
        if world.expedition_memory != null:
            world.expedition_memory.remember(
                "region_event_failed_%d" % world.biome_index,
                "%s ВЗЯЛО СВОЁ" % GameRules.biome_event_name(world.biome_index),
                "Региональное испытание сорвано. Его эффект перешёл в следующую ночь.",
                "danger",
                true
            )
        world.hud.show_banner("РЕГИОН ВЗЯЛ СВОЁ", Color("d27868"))
        world.hud.set_status((reason + " " if not reason.is_empty() else "") + "Следующая ночь получила региональное усиление.")
        Analytics.event("biome_event_failed", {"biome":world.biome_index,"hits":environment_hits})

func _start_regional_hunt() -> void:
    started_hunt = true
    mini_hunt_time = 26.0
    var point: Vector2 = _hunt_point()
    var event_id: String = "biome_hunt:%d" % world.biome_index

    match world.biome_index:
        1:
            mini_boss = world.spawn_event_enemy("stalker", point, "frost_reaver", event_id, point, "hunt")
            mini_support = [
                world.spawn_event_enemy("runner", point + Vector2(48, 12), "", event_id, point, "hunt"),
                world.spawn_event_enemy("runner", point + Vector2(-42, -18), "", event_id, point, "hunt")
            ]
            world.hud.show_banner("БЕЛЫЙ ОХОТНИК", Color("b9e8f2"))
            world.hud.set_status("Редкий хищник вышел в метель. Убей его до третьей ночи.")
        2:
            mini_boss = world.spawn_event_enemy("brute", point, "ash_seeder", event_id, point, "hunt")
            mini_support = [
                world.spawn_event_enemy("guardian", point + Vector2(52, 0), "", event_id, point, "hunt"),
                world.spawn_event_enemy("normal", point + Vector2(-44, 20), "", event_id, point, "hunt")
            ]
            world.hud.show_banner("ПЕПЕЛЬНЫЙ СЕЯТЕЛЬ", Color("f28b55"))
            world.hud.set_status("Он несёт жар в следующую ночь. Останови его сейчас.")
        _:
            mini_boss = world.spawn_event_enemy("guardian", point, "root_alpha", event_id, point, "hunt")
            mini_support = [
                world.spawn_event_enemy("runner", point + Vector2(48, 14), "", event_id, point, "hunt"),
                world.spawn_event_enemy("runner", point + Vector2(-44, -16), "", event_id, point, "hunt"),
                world.spawn_event_enemy("normal", point + Vector2(4, 52), "", event_id, point, "hunt")
            ]
            world.hud.show_banner("ВОЖАК КОРНЕЙ", Color("a9cf78"))
            world.hud.set_status("Стая держится рядом с вожаком. Разорви её до наступления ночи.")

    Analytics.event("regional_hunt_started", {"biome":world.biome_index,"wave":world.wave})

func _hunt_point() -> Vector2:
    var safe: Rect2 = world.world_rect.grow(-70.0)
    var direction := Vector2.from_angle(randf_range(0.0, TAU))
    var point: Vector2 = world.player.global_position + direction * randf_range(180.0, 245.0)
    point.x = clampf(point.x, safe.position.x, safe.end.x)
    point.y = clampf(point.y, safe.position.y, safe.end.y)
    return point

func _complete_regional_hunt() -> void:
    if mini_boss == null:
        return
    hunts_completed += 1
    world.run_coins += 20 + world.biome_index * 3
    world.add_mechanism_parts(1, mini_boss.global_position if is_instance_valid(mini_boss) else world.player.global_position)
    var relic: Dictionary = GameRules.event_relic_for_biome(world.biome_index)
    world.player.apply_perk(str(relic.get("id","guardian_spirit")))
    if world.run_variation != null:
        world.run_variation.reduce_threat(1.0, "regional_hunt_complete")
    if world.expedition_memory != null:
        world.expedition_memory.remember(
            "regional_hunt_%d" % world.biome_index,
            "%s ПОВЕРЖЕН" % GameRules.regional_target_name(world.biome_index),
            "Охота принесла реликвию «%s», которая останется с тобой до конца экспедиции." % str(relic.get("name","Реликвия")),
            "violet",
            true
        )
    QuestDirector.record("regional_hunt", 1, {"biome":world.biome_index})
    GameState.record_biome_event(world.biome_index, {"hunts":1})
    world.hud.show_banner("РЕГИОНАЛЬНАЯ ЦЕЛЬ ПОВЕРЖЕНА", Color("e6c779"))
    world.hud.set_status("Реликвия «%s» получена · деталь механизма · давление следующей ночи снижено." % str(relic.get("name","Реликвия")))
    Analytics.event("regional_hunt_completed", {"biome":world.biome_index,"wave":world.wave})
    mini_boss = null

func _fail_regional_hunt() -> void:
    if mini_boss == null or not is_instance_valid(mini_boss) or mini_boss.dying:
        return
    events_failed += 1
    mini_boss.set_meta("dynamic_event_id", "")
    mini_boss.set_meta("day_behavior", "hunt")
    _apply_night_penalty(world.wave + 1, true)
    if world.run_variation != null:
        world.run_variation.add_threat(1.2, "regional_hunt_failed")
    if world.expedition_memory != null:
        world.expedition_memory.remember(
            "regional_hunt_failed_%d" % world.biome_index,
            "%s УШЁЛ В ТЕМНОТУ" % GameRules.regional_target_name(world.biome_index),
            "Региональная элита пережила охоту и усилила следующую ночь.",
            "danger",
            true
        )
    world.hud.show_banner("ЦЕЛЬ УШЛА В ТЕМНОТУ", Color("d27868"))
    world.hud.set_status("Региональная элита усилит следующую ночь и останется на карте.")
    Analytics.event("regional_hunt_failed", {"biome":world.biome_index,"wave":world.wave})
    mini_boss = null

func _apply_night_penalty(wave: int, hunt_failure: bool) -> void:
    var spec: Dictionary = night_penalties.get(wave, {})
    match world.biome_index:
        1:
            spec["name"] = "ЛЕДЯНОЙ ФРОНТ"
            spec["spawn_interval_mult"] = minf(float(spec.get("spawn_interval_mult", 1.0)), 0.88 if hunt_failure else 0.93)
            spec["enemy_speed_mult"] = maxf(float(spec.get("enemy_speed_mult", 1.0)), 1.12 if hunt_failure else 1.07)
            spec["bias"] = "stalker"
        2:
            spec["name"] = "ЖАР РАЗЛОМА"
            spec["enemy_damage_mult"] = maxf(float(spec.get("enemy_damage_mult", 1.0)), 1.16 if hunt_failure else 1.10)
            spec["base_damage_mult"] = maxf(float(spec.get("base_damage_mult", 1.0)), 1.18 if hunt_failure else 1.10)
            spec["tower_fire_mult"] = maxf(float(spec.get("tower_fire_mult", 1.0)), 1.20 if hunt_failure else 1.10)
            spec["bias"] = "brute"
        _:
            spec["name"] = "СТАЯ НА СЛЕДУ"
            spec["enemy_mult"] = maxf(float(spec.get("enemy_mult", 1.0)), 1.20 if hunt_failure else 1.12)
            spec["spawn_interval_mult"] = minf(float(spec.get("spawn_interval_mult", 1.0)), 0.90 if hunt_failure else 0.95)
            spec["enemy_speed_mult"] = maxf(float(spec.get("enemy_speed_mult", 1.0)), 1.10 if hunt_failure else 1.05)
            spec["bias"] = "runner"
    night_penalties[wave] = spec

func penalty_for_night(wave: int) -> Dictionary:
    var spec: Dictionary = night_penalties.get(wave, {})
    return spec.duplicate(true)

func apply_enemy_behavior(enemy: AxEnemy) -> void:
    if enemy == null or not is_instance_valid(enemy) or enemy.boss:
        return
    match world.biome_index:
        1:
            if enemy.enemy_type == "runner" or enemy.enemy_type == "stalker":
                enemy.set_meta("biome_behavior", "chill")
                enemy.move_speed *= 1.03
        2:
            if enemy.enemy_type == "brute" or enemy.enemy_type == "guardian":
                enemy.set_meta("biome_behavior", "ember_core")
                enemy.contact_damage *= 1.06
        _:
            if enemy.enemy_type == "runner" or enemy.enemy_type == "normal":
                enemy.set_meta("biome_behavior", "pack")

func update_enemy_behavior(enemy: AxEnemy) -> void:
    if enemy == null or not is_instance_valid(enemy) or enemy.dying:
        return
    var behavior: String = str(enemy.get_meta("biome_behavior", ""))
    if behavior != "pack":
        enemy.behavior_speed_multiplier = 1.0
        return

    var nearby: int = 0
    for other: AxEnemy in world.enemies:
        if other == enemy or not is_instance_valid(other) or other.dying:
            continue
        if other.global_position.distance_to(enemy.global_position) <= 92.0:
            nearby += 1
            if nearby >= 3:
                break
    enemy.behavior_speed_multiplier = 1.0 + minf(0.12, float(nearby) * 0.04)

func on_enemy_contact(enemy: AxEnemy) -> void:
    if enemy == null or not is_instance_valid(enemy):
        return
    if str(enemy.get_meta("biome_behavior", "")) == "chill":
        world.player.apply_environment_slow(0.74, 1.45)
        world.hud.set_status("Морозный удар замедлил героя.")

func on_enemy_defeated(enemy: AxEnemy) -> void:
    if enemy == null:
        return

    if enemy == mini_boss:
        _complete_regional_hunt()

    if world.biome_index == 2 and str(enemy.get_meta("biome_behavior", "")) == "ember_core":
        _spawn_zone("ember", enemy.global_position, 30.0, 0.24, 2.2, false)

func _give_biome_resource(amount: int) -> void:
    var kind: String = "wood"
    if world.biome_index == 1:
        kind = "stone"
    elif world.biome_index == 2:
        kind = "ore"
    var actual: int = world.player.add_resource(kind, amount)
    if actual > 0 and world.core_fx != null:
        world.core_fx.harvest(kind, world.player.global_position + Vector2(0, -18), actual, world.player.global_position)

func _clear_event_hazards() -> void:
    for zone: BiomeHazardZone in hazards:
        if zone != null and is_instance_valid(zone) and bool(zone.get_meta("counts_for_biome_event", false)):
            zone.queue_free()

func result_summary() -> Dictionary:
    return {
        "completed":events_completed,
        "failed":events_failed,
        "hunts":hunts_completed,
        "perfect":perfect_events
    }
