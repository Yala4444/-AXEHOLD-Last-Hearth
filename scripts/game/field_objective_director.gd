class_name FieldObjectiveDirector
extends Node

var world: GameWorld
var active: Dictionary = {}
var started_waves: Dictionary = {}
var wave_seen: int = -1
var start_delay: float = 4.5

var completed: int = 0
var failed: int = 0
var perfect: int = 0
var salvage_done: int = 0
var purge_done: int = 0

func setup(world_ref: GameWorld) -> void:
    world = world_ref
    wave_seen = world.wave
    world.enemy_defeated.connect(_on_enemy_defeated)
    set_process(true)

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world) or world.player == null or world.finishing:
        return

    if world.phase != "day":
        if not active.is_empty():
            _fail("Наступила ночь.")
        return

    if world.wave != wave_seen:
        wave_seen = world.wave
        start_delay = 4.0
        _clear_player_target()

    if not active.is_empty():
        _update_active(delta)
        return

    if started_waves.has(world.wave) or world.wave > 2:
        return

    if world.hud.modal_open():
        return

    # Early-day micro-objective comes before the larger dynamic encounter.
    start_delay -= delta
    if start_delay <= 0.0:
        if _other_event_busy():
            start_delay = 1.5
            return
        _start_objective(world.wave)

func _other_event_busy() -> bool:
    if world.dynamic_world != null and not world.dynamic_world.active_event.is_empty():
        return true
    if world.biome_events != null:
        if world.biome_events.active_environment:
            return true
        if world.biome_events.mini_boss != null and is_instance_valid(world.biome_events.mini_boss):
            return true
    return false

func start_objective_for_test(kind: String, wave: int = 0) -> void:
    if not active.is_empty():
        _clear()
    started_waves[wave] = true
    _start_kind(kind, wave)

func _start_objective(wave: int) -> void:
    started_waves[wave] = true

    var kind: String
    if wave == 0:
        kind = "survey" if randf() < 0.62 else "salvage"
    elif wave == 1:
        kind = "salvage" if randf() < 0.52 else "purge"
    else:
        kind = "purge" if randf() < 0.58 else "survey"

    _start_kind(kind, wave)

func _start_kind(kind: String, wave: int) -> void:
    var occupied: Array = []
    if world.activity_director != null:
        for activity: WorldActivity in world.activity_director.activities:
            if is_instance_valid(activity):
                occupied.append(activity.global_position)

    var point: Vector2 = world.world_generator.activity_point(270.0, 620.0, occupied)
    var duration: float = 21.0
    var title: String = "ТОЧКА РАЗВЕДКИ"
    var accent: Color = Color("d5a652")
    var required: float = 1.5

    if kind == "salvage":
        duration = 23.0
        title = "ПОЛЕВОЙ ТАЙНИК"
        accent = Color("9ab6a8")
        required = 2.2
    elif kind == "purge":
        duration = 25.0
        title = "ОЧИСТИТЬ УЧАСТОК"
        accent = Color("ce7564")
        required = 1.0

    var marker := FieldObjectiveMarker.new()
    world.add_child(marker)
    marker.global_position = point
    marker.configure(kind, title, duration, accent)

    active = {
        "kind":kind,
        "title":title,
        "point":point,
        "time":duration,
        "duration":duration,
        "required":required,
        "progress":0.0,
        "marker":marker,
        "enemies":[]
    }

    world.player.set_field_target(point, true, accent)

    if kind == "purge":
        _spawn_purge(point)

    var resident_prefix: String = "МИРА" if GameState.resident_trust("mira") > 0 else "РАЗВЕДКА"
    if kind == "salvage" and GameState.resident_trust("thorn") > 0:
        resident_prefix = "ТОРН"
    world.hud.show_banner("%s · %s" % [resident_prefix, title], accent.lightened(0.10))
    world.hud.set_status(_instruction(kind))
    Analytics.event("field_objective_started", {"type":kind,"wave":wave,"biome":world.biome_index})

func _instruction(kind: String) -> String:
    match kind:
        "survey":
            return "Доберись до метки и удерживай позицию. Времени мало."
        "salvage":
            return "Найди тайник и разбери его до наступления следующего события."
        "purge":
            return "Метка показывает скопление Тьмы. Уничтожь всех отмеченных врагов."
    return "Выполни полевую цель."

func _spawn_purge(point: Vector2) -> void:
    var kinds: Array[String]
    match world.biome_index:
        1:
            kinds = ["runner","stalker","normal","runner"]
        2:
            kinds = ["brute","normal","runner","brute"]
        _:
            kinds = ["runner","normal","normal","brute"]

    var tracked: Array[AxEnemy] = []
    for i: int in range(kinds.size()):
        var a: float = TAU * float(i) / float(kinds.size()) + 0.28
        var pos: Vector2 = point + Vector2(cos(a),sin(a)) * (44.0 + float(i%2)*14.0)
        var enemy: AxEnemy = world.spawn_event_enemy(kinds[i], pos, "", "field:%d" % world.wave, point, "attack_anchor")
        tracked.append(enemy)
    active["enemies"] = tracked

func _update_active(delta: float) -> void:
    active["time"] = maxf(0.0, float(active.get("time",0.0)) - delta)
    var kind: String = str(active.get("kind","survey"))
    var point: Vector2 = active.get("point", world.player.global_position)
    var distance: float = world.player.global_position.distance_to(point)
    var progress: float = float(active.get("progress",0.0))

    if kind == "purge":
        var alive: int = _alive_enemies()
        if alive <= 0:
            _complete()
            return
        world.hud.set_run_objective("ПОЛЕВАЯ ЦЕЛЬ · %s · врагов %d · %dс" % [
            str(active.get("title","ОЧИСТКА")), alive, int(ceil(float(active.get("time",0.0))))
        ])
    else:
        if distance <= 42.0:
            progress = minf(float(active.get("required",1.0)), progress + delta)
        else:
            progress = maxf(0.0, progress - delta * 0.70)
        active["progress"] = progress

        if progress >= float(active.get("required",1.0)):
            _complete()
            return

        var pct: int = int(round(progress / maxf(0.01,float(active.get("required",1.0))) * 100.0))
        world.hud.set_run_objective("ПОЛЕВАЯ ЦЕЛЬ · %s · %d%% · %dс" % [
            str(active.get("title","ЦЕЛЬ")), pct, int(ceil(float(active.get("time",0.0))))
        ])

    var marker: FieldObjectiveMarker = active.get("marker") as FieldObjectiveMarker
    if marker != null and is_instance_valid(marker):
        marker.update_state(
            float(active.get("time",0.0)),
            progress / maxf(0.01,float(active.get("required",1.0))) if kind != "purge" else 0.0
        )

    if float(active.get("time",0.0)) <= 0.0:
        _fail("Время вышло.")

func _complete() -> void:
    if active.is_empty():
        return
    var kind: String = str(active.get("kind","survey"))
    var remaining: float = float(active.get("time",0.0))
    var was_perfect: bool = remaining >= 8.0

    completed += 1
    if was_perfect:
        perfect += 1

    match kind:
        "survey":
            world.run_coins += 8
            world.player.move_speed *= 1.04
            if world.run_variation != null:
                world.run_variation.reduce_threat(0.55, "field_survey")
            world.hud.show_banner("МАРШРУТ ПРОВЕРЕН", Color("dfbd72"))
            world.hud.set_status("+8 мон. · скорость +4% · Угроза снижена.")
        "salvage":
            salvage_done += 1
            world.run_coins += 7
            world.add_mechanism_parts(1, active.get("point", world.player.global_position))
            var resource: String = "wood"
            if world.biome_index == 1:
                resource = "stone"
            elif world.biome_index == 2:
                resource = "ore"
            var amount: int = 4 if resource != "ore" else 3
            var actual: int = world.player.add_resource(resource, amount)
            if actual > 0 and world.core_fx != null:
                world.core_fx.harvest(resource, active.get("point",world.player.global_position), actual, world.player.global_position)
            world.hud.show_banner("ТАЙНИК РАЗОБРАН", Color("a9c5b4"))
            world.hud.set_status("+1 деталь · припасы отправлены в рюкзак.")
        "purge":
            purge_done += 1
            world.run_coins += 12
            world.player.gain_xp(8)
            if world.run_variation != null:
                world.run_variation.reduce_threat(0.80, "field_purge")
            world.hud.show_banner("УЧАСТОК ОЧИЩЕН", Color("d18c72"))
            world.hud.set_status("+12 мон. · Угроза следующей ночи снижена.")

    QuestDirector.record("field_objective",1,{"type":kind,"biome":world.biome_index})
    if was_perfect:
        QuestDirector.record("field_objective_perfect",1,{"type":kind,"biome":world.biome_index})
        world.run_coins += 4

    GameState.record_field_objective({"completed":1,"perfect":1 if was_perfect else 0})
    Analytics.event("field_objective_completed",{
        "type":kind,"wave":world.wave,"biome":world.biome_index,"perfect":was_perfect
    })
    _clear()

func _fail(reason: String) -> void:
    if active.is_empty():
        return
    failed += 1
    var kind: String = str(active.get("kind","survey"))

    if kind == "purge":
        for enemy_variant: Variant in active.get("enemies",[]):
            var enemy: AxEnemy = enemy_variant as AxEnemy
            if enemy != null and is_instance_valid(enemy) and not enemy.dying:
                enemy.set_meta("day_behavior","hunt")
                enemy.set_meta("dynamic_event_id","")

    if world.run_variation != null:
        world.run_variation.add_threat(0.55, "field_objective_failed")

    GameState.record_field_objective({"failed":1})
    Analytics.event("field_objective_failed",{"type":kind,"wave":world.wave,"biome":world.biome_index})
    world.hud.show_banner("ПОЛЕВАЯ ЦЕЛЬ УПУЩЕНА", Color("c97a6d"))
    world.hud.set_status(reason + " Угроза немного выросла.")
    _clear()

func _alive_enemies() -> int:
    var alive: int = 0
    var cleaned: Array[AxEnemy] = []
    for enemy_variant: Variant in active.get("enemies",[]):
        var enemy: AxEnemy = enemy_variant as AxEnemy
        if enemy != null and is_instance_valid(enemy) and not enemy.dying:
            cleaned.append(enemy)
            alive += 1
    active["enemies"] = cleaned
    return alive

func _on_enemy_defeated(_enemy: AxEnemy) -> void:
    if active.is_empty() or str(active.get("kind","")) != "purge":
        return
    if _alive_enemies() == 0:
        call_deferred("_complete")

func _clear_player_target() -> void:
    if world != null and world.player != null:
        world.player.set_field_target(Vector2.ZERO, false, Color.WHITE)

func _clear() -> void:
    var marker: FieldObjectiveMarker = active.get("marker") as FieldObjectiveMarker
    if marker != null and is_instance_valid(marker):
        marker.queue_free()
    _clear_player_target()
    active.clear()
    world.hud.set_run_objective("")

func result_summary() -> Dictionary:
    return {
        "completed":completed,
        "failed":failed,
        "perfect":perfect,
        "salvage":salvage_done,
        "purge":purge_done
    }
