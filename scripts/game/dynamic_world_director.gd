class_name DynamicWorldDirector
extends Node

var world: GameWorld
var active_event: Dictionary = {}
var event_timer: float = 18.0
var last_day_wave: int = -1
var started_waves: Dictionary = {}
var seen_types: Dictionary = {}
var event_counter: int = 0

var events_completed: int = 0
var events_failed: int = 0
var elites_killed: int = 0
var rescues_completed: int = 0
var chains_completed: int = 0

func setup(world_ref: GameWorld) -> void:
    world = world_ref
    world.enemy_defeated.connect(_on_enemy_defeated)
    last_day_wave = world.wave
    event_timer = 18.0
    set_process(true)

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world) or world.player == null or world.finishing:
        return

    if world.phase != "day":
        if not active_event.is_empty():
            _fail_event("Наступила ночь раньше, чем событие было завершено.")
        return

    if world.wave != last_day_wave:
        last_day_wave = world.wave
        event_timer = 13.0 if world.wave == 1 else 10.0

    if not active_event.is_empty():
        _update_active_event(delta)
        return

    if started_waves.has(world.wave) or world.wave >= 3:
        return

    event_timer -= delta
    if event_timer <= 0.0:
        _start_for_wave(world.wave)

func _start_for_wave(wave: int) -> void:
    started_waves[wave] = true
    var event_type: String = ""

    if wave == 0:
        var pool: Array[String] = ["caravan_defense", "survivor_rescue", "ambush"]
        event_type = pool[randi() % pool.size()]
    elif wave == 1:
        var pool: Array[String] = ["elite_hunt", "caravan_defense", "survivor_rescue", "ambush"]
        event_type = pool[randi() % pool.size()]
    else:
        if not seen_types.has("elite_hunt"):
            event_type = "elite_hunt"
        else:
            var pool: Array[String] = ["elite_hunt", "survivor_rescue", "caravan_defense"]
            event_type = pool[randi() % pool.size()]

    _start_event(event_type)

func _start_event(event_type: String) -> void:
    event_counter += 1
    seen_types[event_type] = true
    var event_id: String = "%d:%d:%s" % [world.wave, event_counter, event_type]
    var point: Vector2 = world.player.global_position
    var duration: float = 30.0
    var title: String = "СОБЫТИЕ"
    var enemies: Array[AxEnemy] = []
    var stage: String = "combat"

    match event_type:
        "caravan_defense":
            duration = 34.0
            title = "КАРАВАН ПОД АТАКОЙ"
            point = _event_point(175.0, 245.0)
        "survivor_rescue":
            duration = 32.0
            title = "ВЫЖИВШИЙ В ОКРУЖЕНИИ"
            point = _event_point(165.0, 230.0)
        "elite_hunt":
            duration = 38.0
            title = "РЕДКАЯ ЦЕЛЬ"
            point = _event_point(190.0, 260.0)
        "ambush":
            duration = 24.0
            title = "ЗАСАДА"
            point = world.player.global_position

    var marker := DynamicEventMarker.new()
    world.add_child(marker)
    marker.global_position = point
    marker.configure(event_type, title, duration)

    active_event = {
        "id":event_id,
        "type":event_type,
        "point":point,
        "duration":duration,
        "time":duration,
        "marker":marker,
        "enemies":enemies,
        "stage":stage,
        "secure_progress":0.0
    }

    match event_type:
        "caravan_defense":
            _spawn_pack(point, event_id, ["normal", "runner", "brute"], "attack_anchor")
            if world.wave >= 1:
                _spawn_elite(point + Vector2(46, -22), event_id, "brute", "armored", "attack_anchor")
            world.hud.show_banner("КАРАВАН ПОД АТАКОЙ", Color("e0b86f"))
            world.hud.set_status("Успей добраться до каравана и перебить нападающих.")
        "survivor_rescue":
            _spawn_pack(point, event_id, ["normal", "runner"], "attack_anchor")
            _spawn_elite(point + Vector2(42, 16), event_id, "runner", "ravenous", "attack_anchor")
            world.hud.show_banner("КРИК О ПОМОЩИ", Color("a8d0b1"))
            world.hud.set_status("Выживший окружён. Сначала очисти место, затем подойди к нему.")
        "elite_hunt":
            var kind: String = "guardian" if world.biome_index != 2 else "brute"
            var elite_trait_id: String = ["warlord", "volatile", "armored"][world.biome_index]
            _spawn_elite(point, event_id, kind, elite_trait_id, "hunt")
            world.hud.show_banner("МИРА ОТМЕТИЛА РЕДКУЮ ЦЕЛЬ", Color("dd8068"))
            world.hud.set_status("Элита находится рядом. Убей её до наступления ночи.")
        "ambush":
            _spawn_ambush(point, event_id)
            if world.run_variation != null:
                world.run_variation.add_threat(0.35, "day_ambush")
            world.hud.show_banner("ЗАСАДА!", Color("c392d9"))
            world.hud.set_status("Тьма вышла на твой след. Переживи короткую схватку.")

    Analytics.event("dynamic_event_started", {
        "type":event_type,
        "wave":world.wave,
        "biome":world.biome_index
    })

func _spawn_pack(point: Vector2, event_id: String, kinds: Array[String], behavior: String) -> void:
    for i: int in range(kinds.size()):
        var angle: float = TAU * float(i) / float(maxi(1, kinds.size())) + 0.35
        var pos: Vector2 = point + Vector2(cos(angle), sin(angle)) * (48.0 + float(i % 2) * 16.0)
        var enemy: AxEnemy = world.spawn_event_enemy(kinds[i], pos, "", event_id, point, behavior)
        _track_enemy(enemy)

func _spawn_elite(point: Vector2, event_id: String, kind: String, trait_id: String, behavior: String) -> void:
    var enemy: AxEnemy = world.spawn_event_enemy(kind, point, trait_id, event_id, point, behavior)
    _track_enemy(enemy)

func _spawn_ambush(point: Vector2, event_id: String) -> void:
    var kinds: Array[String] = ["runner", "normal", "normal", "stalker"]
    for i: int in range(kinds.size()):
        var angle: float = TAU * float(i) / 4.0 + randf_range(-0.18, 0.18)
        var pos: Vector2 = point + Vector2(cos(angle), sin(angle)) * randf_range(68.0, 102.0)
        var enemy: AxEnemy = world.spawn_event_enemy(kinds[i], pos, "", event_id, point, "hunt")
        _track_enemy(enemy)

func _track_enemy(enemy: AxEnemy) -> void:
    if enemy == null or active_event.is_empty():
        return
    var enemies: Array = active_event.get("enemies", [])
    enemies.append(enemy)
    active_event["enemies"] = enemies

func _update_active_event(delta: float) -> void:
    var time_left: float = float(active_event.get("time", 0.0)) - delta
    active_event["time"] = time_left

    var marker: DynamicEventMarker = active_event.get("marker") as DynamicEventMarker
    if marker != null and is_instance_valid(marker):
        marker.set_time(time_left)

    var event_type: String = str(active_event.get("type", ""))
    var stage: String = str(active_event.get("stage", "combat"))

    if event_type == "trail_cache":
        _update_chain_cache(delta)
        return

    if stage == "combat" and _alive_event_enemies() == 0:
        _resolve_cleared_combat()
        return

    if str(active_event.get("stage", "")) == "secure":
        var point: Vector2 = active_event.get("point", world.player.global_position)
        if world.player.global_position.distance_to(point) <= 46.0:
            var progress: float = float(active_event.get("secure_progress", 0.0)) + delta
            active_event["secure_progress"] = progress
            if progress >= 1.25:
                _complete_event()
                return
        else:
            active_event["secure_progress"] = maxf(0.0, float(active_event.get("secure_progress", 0.0)) - delta * 0.8)

    if time_left <= 0.0:
        _fail_event("Ты не успел вмешаться.")

func _resolve_cleared_combat() -> void:
    if active_event.is_empty() or str(active_event.get("stage", "")) != "combat":
        return
    var event_type: String = str(active_event.get("type", ""))
    if event_type == "survivor_rescue":
        var time_left: float = float(active_event.get("time", 0.0))
        active_event["stage"] = "secure"
        active_event["time"] = minf(15.0, maxf(8.0, time_left))
        active_event["duration"] = 15.0
        active_event["secure_progress"] = 0.0
        var marker: DynamicEventMarker = active_event.get("marker") as DynamicEventMarker
        if marker != null and is_instance_valid(marker):
            marker.duration = 15.0
            marker.set_state("secure")
        world.hud.show_banner("МЕСТО ОЧИЩЕНО", Color("a8d0b1"))
        world.hud.set_status("Подойди к выжившему и задержись рядом.")
    else:
        _complete_event()

func _update_chain_cache(delta: float) -> void:
    var point: Vector2 = active_event.get("point", world.player.global_position)
    var progress: float = float(active_event.get("secure_progress", 0.0))
    if world.player.global_position.distance_to(point) <= 44.0:
        progress += delta
        active_event["secure_progress"] = progress
        if progress >= 0.8:
            chains_completed += 1
            events_completed += 1
            world.run_coins += 9
            _give_resource("ore", 3, point)
            QuestDirector.record("event_chain", 1, {"biome":world.biome_index})
            QuestDirector.record("dynamic_event", 1, {"type":"trail_cache","biome":world.biome_index})
            GameState.record_dynamic_world({"events":1,"chains":1})
            world.hud.show_banner("СЛЕД ПРИВЁЛ К ТАЙНИКУ", Color("e4c87f"))
            world.hud.set_status("+9 мон. · +3 руды · цепочка события завершена.")
            Analytics.event("dynamic_event_completed", {"type":"trail_cache","wave":world.wave,"biome":world.biome_index})
            _clear_active_event()
            return
    else:
        active_event["secure_progress"] = maxf(0.0, progress - delta)

    if float(active_event.get("time", 0.0)) <= 0.0:
        _fail_event("След остыл, тайник потерян.")

func _complete_event() -> void:
    if active_event.is_empty():
        return
    var event_type: String = str(active_event.get("type", ""))
    var point: Vector2 = active_event.get("point", world.player.global_position)

    events_completed += 1
    QuestDirector.record("dynamic_event", 1, {"type":event_type,"biome":world.biome_index})

    match event_type:
        "caravan_defense":
            world.run_coins += 14
            _give_resource("wood", 6, point)
            _give_resource("stone", 3, point)
            if world.run_variation != null:
                world.run_variation.reduce_threat(0.8, "caravan_saved")
            world.hud.show_banner("КАРАВАН СПАСЁН", Color("e2bd72"))
            world.hud.set_status("+14 мон. · припасы спасены. На ящиках найден след тайника.")
        "survivor_rescue":
            rescues_completed += 1
            world.run_coins += 12
            world.player.heal(22.0)
            world.player.shield_hits = mini(5, world.player.shield_hits + 1)
            QuestDirector.record("world_rescue", 1, {"biome":world.biome_index})
            world.hud.show_banner("ВЫЖИВШИЙ СПАСЁН", Color("a7d0b2"))
            world.hud.set_status("+12 мон. · лечение · защитный заряд.")
        "elite_hunt":
            world.run_coins += 18
            world.add_mechanism_parts(1, point)
            if world.run_variation != null:
                world.run_variation.reduce_threat(0.6, "elite_hunted")
            world.hud.show_banner("РЕДКАЯ ЦЕЛЬ УНИЧТОЖЕНА", Color("df8a68"))
            world.hud.set_status("+18 мон. · деталь механизма · Угроза снижена.")
        "ambush":
            world.run_coins += 10
            world.player.gain_xp(8)
            world.hud.show_banner("ЗАСАДА СОРВАНА", Color("c7a0d9"))
            world.hud.set_status("+10 мон. · +8 опыта.")

    GameState.record_dynamic_world({
        "events":1,
        "rescues":1 if event_type == "survivor_rescue" else 0
    })
    Analytics.event("dynamic_event_completed", {
        "type":event_type,
        "wave":world.wave,
        "biome":world.biome_index
    })

    var should_chain: bool = event_type == "caravan_defense"
    var origin: Vector2 = point
    _clear_active_event()
    if should_chain and world.phase == "day":
        _start_chain_cache(origin)

func _start_chain_cache(origin: Vector2) -> void:
    event_counter += 1
    var direction := Vector2.from_angle(randf_range(0.0, TAU))
    var point: Vector2 = origin + direction * randf_range(105.0, 160.0)
    var safe: Rect2 = world.world_rect.grow(-60.0)
    point.x = clampf(point.x, safe.position.x, safe.end.x)
    point.y = clampf(point.y, safe.position.y, safe.end.y)

    var marker := DynamicEventMarker.new()
    world.add_child(marker)
    marker.global_position = point
    marker.configure("trail_cache", "СЛЕД К ТАЙНИКУ", 22.0)
    marker.set_state("chain")

    active_event = {
        "id":"chain:%d" % event_counter,
        "type":"trail_cache",
        "point":point,
        "duration":22.0,
        "time":22.0,
        "marker":marker,
        "enemies":[],
        "stage":"chain",
        "secure_progress":0.0
    }
    world.hud.set_status("На спасённом караване была карта. У тебя 22 сек., чтобы добраться до тайника.")
    Analytics.event("dynamic_event_chain_started", {"wave":world.wave,"biome":world.biome_index})

func _fail_event(reason: String) -> void:
    if active_event.is_empty():
        return
    events_failed += 1
    var event_type: String = str(active_event.get("type", ""))
    if world.run_variation != null:
        var threat: float = 1.4 if event_type == "caravan_defense" or event_type == "ambush" else 0.8
        world.run_variation.add_threat(threat, "dynamic_event_failed")

    for enemy_variant: Variant in active_event.get("enemies", []):
        var enemy: AxEnemy = enemy_variant as AxEnemy
        if enemy != null and is_instance_valid(enemy) and not enemy.dying:
            enemy.set_meta("day_behavior", "hunt")
            enemy.set_meta("dynamic_event_id", "")

    GameState.record_dynamic_world({"failures":1})
    Analytics.event("dynamic_event_failed", {
        "type":event_type,
        "wave":world.wave,
        "biome":world.biome_index
    })
    world.hud.show_banner("СОБЫТИЕ УПУЩЕНО", Color("c98075"))
    world.hud.set_status(reason + " Угроза следующей ночи выросла.")
    _clear_active_event()

func _clear_active_event() -> void:
    var marker: DynamicEventMarker = active_event.get("marker") as DynamicEventMarker
    if marker != null and is_instance_valid(marker):
        marker.queue_free()
    active_event.clear()

func _alive_event_enemies() -> int:
    var alive: int = 0
    var cleaned: Array[AxEnemy] = []
    for enemy_variant: Variant in active_event.get("enemies", []):
        var enemy: AxEnemy = enemy_variant as AxEnemy
        if enemy != null and is_instance_valid(enemy) and not enemy.dying:
            cleaned.append(enemy)
            alive += 1
    active_event["enemies"] = cleaned
    return alive

func _on_enemy_defeated(enemy: AxEnemy) -> void:
    if enemy == null:
        return
    if enemy.elite:
        elites_killed += 1
        GameState.record_dynamic_world({"elites":1})

    if active_event.is_empty():
        return
    var event_id: String = str(active_event.get("id", ""))
    if str(enemy.get_meta("dynamic_event_id", "")) != event_id:
        return
    if _alive_event_enemies() == 0 and str(active_event.get("stage", "")) == "combat":
        call_deferred("_resolve_cleared_combat")

func _event_point(min_distance: float, max_distance: float) -> Vector2:
    var safe: Rect2 = world.world_rect.grow(-70.0)
    for _attempt: int in range(10):
        var angle: float = randf_range(0.0, TAU)
        var point: Vector2 = world.player.global_position + Vector2.from_angle(angle) * randf_range(min_distance, max_distance)
        point.x = clampf(point.x, safe.position.x, safe.end.x)
        point.y = clampf(point.y, safe.position.y, safe.end.y)
        if point.distance_to(world.base_position) > 145.0:
            return point
    return Vector2(
        clampf(world.player.global_position.x + min_distance, safe.position.x, safe.end.x),
        clampf(world.player.global_position.y, safe.position.y, safe.end.y)
    )

func _give_resource(kind: String, amount: int, source: Vector2) -> void:
    var actual: int = world.player.add_resource(kind, amount)
    if actual > 0 and world.core_fx != null:
        world.core_fx.harvest(kind, source, actual, world.player.global_position)

func result_summary() -> Dictionary:
    return {
        "completed":events_completed,
        "failed":events_failed,
        "elites":elites_killed,
        "rescues":rescues_completed,
        "chains":chains_completed
    }
