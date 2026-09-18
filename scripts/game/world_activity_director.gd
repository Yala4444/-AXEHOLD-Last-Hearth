class_name WorldActivityDirector
extends Node

var world: GameWorld
var generator: WorldGenerator
var activities: Array[WorldActivity] = []
var altar_spawned: bool = false
var altar_pending: WorldActivity = null
var nests_destroyed: int = 0
var activities_resolved: int = 0
var last_focus: WorldActivity = null

func setup(world_ref: GameWorld, generator_ref: WorldGenerator) -> void:
    world = world_ref
    generator = generator_ref
    world.hud.action_requested.connect(_on_hud_action)
    _spawn_initial_activities()

func _spawn_initial_activities() -> void:
    var occupied: Array = []
    for _i in range(2):
        _spawn("caravan", 420.0, 1020.0, occupied)
    for _i in range(3):
        _spawn("chest", 360.0, 1220.0, occupied)
    for _i in range(3):
        _spawn("nest", 560.0, 1320.0, occupied)

func _spawn(kind: String, min_radius: float, max_radius: float, occupied: Array) -> WorldActivity:
    var point: Vector2 = generator.activity_point(min_radius, max_radius, occupied)
    occupied.append(point)
    var activity := WorldActivity.new()
    world.add_child(activity)
    activity.global_position = point
    activity.configure(kind, world.biome_index)
    activity.resolved.connect(_on_activity_resolved)
    activities.append(activity)
    return activity

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world) or world.player == null or world.finishing:
        return

    if world.wave >= 1 and world.phase == "day" and not altar_spawned:
        altar_spawned = true
        var occupied: Array = []
        for item: WorldActivity in activities:
            if is_instance_valid(item):
                occupied.append(item.global_position)
        _spawn("altar", 620.0, 1250.0, occupied)

    var nearest: WorldActivity = null
    var nearest_distance: float = INF
    for activity: WorldActivity in activities:
        if not is_instance_valid(activity) or activity.finished:
            continue
        var distance: float = world.player.global_position.distance_to(activity.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = activity

        if activity.activity_type == "nest":
            var attack_reach: float = world.player.orbit_radius + world.player.axes * 4.0 + 24.0
            if distance <= attack_reach:
                activity.set_focus(true)
                activity.damage(world.player.damage * delta * 0.78)
                if world.core_fx != null and randf() < delta * 4.0:
                    world.core_fx.enemy_hit(activity.global_position, false)
            else:
                activity.set_focus(false)
            continue

        if activity.activity_type == "altar":
            activity.set_focus(distance <= 58.0)
            if distance <= 48.0 and world.phase == "day" and not world.hud.modal_open() and altar_pending == null:
                altar_pending = activity
                _show_altar(activity)
            continue

        if distance <= 45.0 and world.phase == "day":
            activity.set_focus(true)
            if activity.interact(delta):
                _grant_activity_reward(activity)
        else:
            activity.set_focus(false)
            activity.decay_progress(delta)

    if last_focus != nearest:
        last_focus = nearest
        if nearest != null and nearest_distance <= 82.0 and not nearest.finished:
            world.hud.set_status(_hint_for(nearest))

func _hint_for(activity: WorldActivity) -> String:
    match activity.activity_type:
        "caravan":
            return "Обыщи разбитый караван — здесь могли остаться припасы."
        "chest":
            return "Тайник. Задержись рядом, чтобы открыть."
        "nest":
            return "Гнездо усилит ночь, если оставить его в живых."
        "altar":
            return "Древний алтарь предлагает силу за цену."
    return ""

func _show_altar(activity: WorldActivity) -> void:
    world.hud.show_modal(
        "",
        "ДРЕВНИЙ АЛТАРЬ",
        "Огонь предлагает силу. Выбери цену — или оставь алтарь нетронутым.",
        [
            {"text":"КЛЯТВА ОГНЯ  -20% HP  +25% УРОНА", "action":"activity:altar_power"},
            {"text":"ПУТЬ  +15% СКОРОСТЬ  -10% MAX HP", "action":"activity:altar_speed"},
            {"text":"УЙТИ", "action":"activity:altar_leave"}
        ]
    )

func _on_hud_action(action: String) -> void:
    if not action.begins_with("activity:"):
        return
    if altar_pending == null or not is_instance_valid(altar_pending):
        world.hud.hide_modal()
        altar_pending = null
        return

    if action == "activity:altar_power":
        world.player.hp = maxf(1.0, world.player.hp - world.player.max_hp * 0.20)
        world.player.damage *= 1.25
        world.hud.show_banner("ОГОНЬ ПРИНЯЛ КЛЯТВУ", Color("f1b36d"))
        altar_pending.finish()
    elif action == "activity:altar_speed":
        world.player.max_hp = maxf(50.0, world.player.max_hp * 0.90)
        world.player.hp = minf(world.player.hp, world.player.max_hp)
        world.player.move_speed *= 1.15
        world.hud.show_banner("ПУТЬ ОТКРЫТ", Color("c8dfb6"))
        altar_pending.finish()
    else:
        altar_pending.set_focus(false)

    world.hud.hide_modal()
    altar_pending = null

func _on_activity_resolved(activity: WorldActivity) -> void:
    activities_resolved += 1
    if activity.activity_type == "nest":
        nests_destroyed += 1
        _grant_nest_reward(activity)
    Analytics.event("world_activity_resolved", {
        "type": activity.activity_type,
        "wave": world.wave,
        "biome": world.biome_index
    })

func _grant_activity_reward(activity: WorldActivity) -> void:
    if activity.activity_type == "caravan":
        _give_resource("wood", 7, activity.global_position)
        _give_resource("stone", 4, activity.global_position)
        _give_resource("ore", 1, activity.global_position)
        world.run_coins += 5
        world.hud.show_banner("КАРАВАН ОБЫСКАН", Color("e4c078"))
    elif activity.activity_type == "chest":
        _give_resource("stone", 3, activity.global_position)
        _give_resource("ore", 2, activity.global_position)
        world.run_coins += 9
        world.player.gain_xp(6)
        world.player.shield_hits = mini(5, world.player.shield_hits + 1)
        world.hud.show_banner("ТАЙНИК ОТКРЫТ", Color("d6bb78"))
    Feedback.play("level", 6)

func _grant_nest_reward(activity: WorldActivity) -> void:
    world.run_coins += 8
    world.player.gain_xp(8)
    _give_resource("ore", 2, activity.global_position)
    world.hud.show_banner("ГНЕЗДО УНИЧТОЖЕНО", Color("d7d094"))
    world.hud.set_status("Этой ночью к Очагу придёт меньше врагов.")
    Feedback.play("kill", 7)

func _give_resource(kind: String, amount: int, source: Vector2) -> void:
    var actual: int = world.player.add_resource(kind, amount)
    if actual > 0 and world.core_fx != null:
        world.core_fx.harvest(kind, source, actual, world.player.global_position)

func night_extra_enemies() -> int:
    var active_nests: int = 0
    for activity: WorldActivity in activities:
        if is_instance_valid(activity) and activity.activity_type == "nest" and not activity.finished:
            active_nests += 1
    return active_nests * 2

func unresolved_nests() -> int:
    return night_extra_enemies() / 2
