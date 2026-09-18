class_name WorldActivityDirector
extends Node

var world: GameWorld
var generator: WorldGenerator
var activities: Array[WorldActivity] = []
var altar_spawned: bool = false
var old_hearth_spawned: bool = false
var altar_pending: WorldActivity = null
var nests_destroyed: int = 0
var hearths_relit: int = 0
var activities_resolved: int = 0
var last_focus: WorldActivity = null

func setup(world_ref: GameWorld, generator_ref: WorldGenerator) -> void:
    world = world_ref
    generator = generator_ref
    world.hud.action_requested.connect(_on_hud_action)
    _spawn_initial_activities()

func _spawn_initial_activities() -> void:
    var occupied: Array = []
    var selected: Dictionary = {}

    # Every run receives a readable mix: strategic pressure, a clean reward,
    # a risk/reward choice and at least one story/utility hook.
    for _i: int in range(2):
        _spawn("nest", 560.0, 1320.0, occupied)
    selected["nest"] = true

    var positive: Array[String] = ["caravan", "rare_ore", "wind_shrine"]
    var risk: Array[String] = ["chest", "wanderer_grave", "infected_cache"]
    var story: Array[String] = ["wounded_scout", "memory_rift", "signal_fire"]
    var utility: Array[String] = ["broken_tower", "rare_ore", "signal_fire", "caravan"]

    var picks: Array[String] = [
        _pick_unique(positive, selected),
        _pick_unique(risk, selected),
        _pick_unique(story, selected),
        _pick_unique(utility, selected)
    ]
    for kind: String in picks:
        if kind.is_empty():
            continue
        _spawn(kind, 390.0, 1280.0, occupied)

    var bonus_pool: Array[String] = [
        "caravan", "chest", "rare_ore", "broken_tower", "wind_shrine",
        "wanderer_grave", "signal_fire", "infected_cache", "memory_rift", "wounded_scout"
    ]
    var bonus: String = _pick_unique(bonus_pool, selected)
    if not bonus.is_empty():
        _spawn(bonus, 520.0, 1340.0, occupied)

    # A selected Frontier Assignment always creates the content required to
    # complete it, so the mission tests routing/time rather than RNG.
    var assignment: Dictionary = FrontierRules.assignment(GameState.frontier_assignment_id())
    var guarantee: String = str(assignment.get("guarantee", ""))
    if guarantee == "signal_fire":
        _spawn("signal_fire", 520.0, 1120.0, occupied)
        _spawn("signal_fire", 720.0, 1320.0, occupied)
    elif guarantee == "rare_ore":
        _spawn("rare_ore", 560.0, 1160.0, occupied)
        _spawn("rare_ore", 760.0, 1340.0, occupied)

    # Thorn appears only after Chapter I. He turns the finale into playable
    # follow-up content instead of a dead-end story card.
    var residents: Dictionary = GameState.data.get("residents", {})
    var thorn: Dictionary = residents.get("thorn", {})
    if GameState.chapter_one_complete() and not bool(thorn.get("unlocked", false)):
        _spawn("stranded_engineer", 760.0, 1340.0, occupied)

func _pick_unique(pool: Array[String], selected: Dictionary) -> String:
    var candidates: Array[String] = []
    for kind: String in pool:
        if not selected.has(kind):
            candidates.append(kind)
    if candidates.is_empty():
        return ""
    var picked: String = candidates[randi() % candidates.size()]
    selected[picked] = true
    return picked

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

    if world.wave >= 1 and world.phase == "day" and not old_hearth_spawned:
        old_hearth_spawned = true
        var occupied_hearth: Array = []
        for item: WorldActivity in activities:
            if is_instance_valid(item):
                occupied_hearth.append(item.global_position)
        _spawn("old_hearth", 720.0, 1320.0, occupied_hearth)

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

        if activity.activity_type == "old_hearth":
            activity.set_focus(distance <= 58.0)
            if distance <= 45.0 and world.phase == "day":
                var carried_wood: int = int(world.player.inventory.get("wood", 0))
                if carried_wood >= 4:
                    if activity.interact(delta):
                        _grant_activity_reward(activity)
                else:
                    activity.decay_progress(delta)
                    world.hud.set_status("Погасшему Очагу нужно 4 дерева в рюкзаке.")
            else:
                activity.decay_progress(delta)
            continue

        if activity.activity_type == "broken_tower":
            activity.set_focus(distance <= 58.0)
            if distance <= 45.0 and world.phase == "day":
                var carried_stone: int = int(world.player.inventory.get("stone", 0))
                if carried_stone >= 4:
                    if activity.interact(delta):
                        _grant_activity_reward(activity)
                else:
                    activity.decay_progress(delta)
                    world.hud.set_status("Для ремонта сломанной башни нужно 4 камня в рюкзаке.")
            else:
                activity.decay_progress(delta)
            continue

        if activity.activity_type == "signal_fire":
            activity.set_focus(distance <= 58.0)
            if distance <= 45.0 and world.phase == "day":
                var carried_signal_wood: int = int(world.player.inventory.get("wood", 0))
                if carried_signal_wood >= 3:
                    if activity.interact(delta):
                        _grant_activity_reward(activity)
                else:
                    activity.decay_progress(delta)
                    world.hud.set_status("Сигнальному костру нужно 3 дерева.")
            else:
                activity.decay_progress(delta)
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
            return "Проклятый тайник: награда выше, но Тьма ответит." if activity.cursed else "Тайник. Задержись рядом, чтобы открыть."
        "nest":
            return "Гнездо усилит ночь, если оставить его в живых."
        "altar":
            return "Древний алтарь предлагает силу за цену."
        "old_hearth":
            return "Погасший Очаг. Принеси 4 дерева и верни ему огонь."
        "rare_ore":
            return "Редкая жила. Добыча ценная, но шум повышает Угрозу."
        "broken_tower":
            return "Сломанная башня. Принеси 4 камня и восстанови механизм."
        "wind_shrine":
            return "Святилище ветра. Активируй его для ускорения Странника."
        "wanderer_grave":
            return "Могила Странника. Реликт внутри может привлечь Тьму."
        "signal_fire":
            return "Сигнальный костёр. Принеси 3 дерева и зажги ориентир."
        "infected_cache":
            return "Заражённый склад. Богатый лут, но очистка поднимает Угрозу."
        "memory_rift":
            return "Разлом памяти. Задержись рядом, чтобы услышать прошлое."
        "wounded_scout":
            return "Раненая разведчица. Помоги ей подняться и вернуться к Очагу."
        "stranded_engineer":
            return "Механик окружён сломанными деталями. Помоги Торну вернуться к Последнему Очагу."
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
        if world.run_variation != null:
            world.run_variation.add_threat(1.0, "altar_power")
        world.hud.show_banner("ОГОНЬ ПРИНЯЛ КЛЯТВУ", Color("f1b36d"))
        altar_pending.finish()
    elif action == "activity:altar_speed":
        world.player.max_hp = maxf(50.0, world.player.max_hp * 0.90)
        world.player.hp = minf(world.player.hp, world.player.max_hp)
        world.player.move_speed *= 1.15
        if world.run_variation != null:
            world.run_variation.add_threat(0.6, "altar_speed")
        world.hud.show_banner("ПУТЬ ОТКРЫТ", Color("c8dfb6"))
        altar_pending.finish()
    else:
        altar_pending.set_focus(false)

    world.hud.hide_modal()
    altar_pending = null

func _on_activity_resolved(activity: WorldActivity) -> void:
    activities_resolved += 1
    QuestDirector.record("activity_resolved", 1, {"type":activity.activity_type, "biome":world.biome_index, "wave":world.wave})
    if activity.activity_type == "nest":
        nests_destroyed += 1
        QuestDirector.record("nest_destroyed", 1, {"biome":world.biome_index, "wave":world.wave})
        _grant_nest_reward(activity)
    elif activity.activity_type == "old_hearth":
        hearths_relit += 1
        QuestDirector.record("hearth_relit", 1, {"biome":world.biome_index, "wave":world.wave})
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
    elif activity.activity_type == "old_hearth":
        world.player.inventory["wood"] = maxi(0, int(world.player.inventory.get("wood", 0)) - 4)
        world.player.queue_redraw()
        world.player.heal(28.0)
        world.run_coins += 7
        if world.run_variation != null:
            world.run_variation.reduce_threat(2.2, "old_hearth_relit")
        world.hud.show_banner("СТАРЫЙ ОЧАГ ЗАЖЖЁН", Color("f0bd71"))
        world.hud.set_status("Тьма отступила. +7 мон. · герой исцелён.")
    elif activity.activity_type == "rare_ore":
        _give_resource("ore", 6, activity.global_position)
        world.add_mechanism_parts(1, activity.global_position)
        world.run_coins += 8
        world.player.gain_xp(7)
        if world.run_variation != null:
            world.run_variation.add_threat(0.8, "rare_ore_noise")
        world.hud.show_banner("РЕДКАЯ ЖИЛА ИСЧЕРПАНА", Color("c49ad8"))
        world.hud.set_status("+6 руды · шум привлёк внимание Тьмы.")
    elif activity.activity_type == "broken_tower":
        world.player.inventory["stone"] = maxi(0, int(world.player.inventory.get("stone", 0)) - 4)
        world.add_mechanism_parts(1, activity.global_position)
        world.player.queue_redraw()
        world.turret_global_damage_mult *= 1.12
        world.turret_global_fire_mult *= 0.92
        world.run_coins += 5
        world.hud.show_banner("СТАРАЯ БАШНЯ ВОССТАНОВЛЕНА", Color("c3c9bd"))
        world.hud.set_status("Механизм передал чертежи: твоя Башня сильнее в этом забеге.")
    elif activity.activity_type == "wind_shrine":
        world.player.move_speed *= 1.08
        world.run_coins += 5
        if world.run_variation != null:
            world.run_variation.reduce_threat(0.5, "wind_shrine")
        world.hud.show_banner("ВЕТЕР ПОМНИТ ДОРОГУ", Color("a9d5d6"))
        world.hud.set_status("+8% скорость до конца экспедиции.")
    elif activity.activity_type == "wanderer_grave":
        world.run_coins += 14
        world.add_mechanism_parts(1, activity.global_position)
        world.player.gain_xp(10)
        world.player.shield_hits = mini(5, world.player.shield_hits + 1)
        if world.run_variation != null:
            world.run_variation.add_threat(1.3, "wanderer_grave")
        world.hud.show_banner("РЕЛИКТ СТРАННИКА", Color("b9b2a7"))
        world.hud.set_status("+14 мон. · защита +1 · Тьма заметила добычу.")
    elif activity.activity_type == "signal_fire":
        world.player.inventory["wood"] = maxi(0, int(world.player.inventory.get("wood", 0)) - 3)
        world.player.queue_redraw()
        world.run_coins += 7
        if world.run_variation != null:
            world.run_variation.reduce_threat(1.1, "signal_fire")
        QuestDirector.record("signal_fire", 1, {"biome":world.biome_index, "wave":world.wave})
        world.hud.show_banner("СИГНАЛЬНЫЙ ОГОНЬ ГОРИТ", Color("efbd78"))
        world.hud.set_status("Маршрут отмечен. Угроза Тьмы снизилась.")
    elif activity.activity_type == "infected_cache":
        _give_resource("stone", 4, activity.global_position)
        world.add_mechanism_parts(1, activity.global_position)
        _give_resource("ore", 3, activity.global_position)
        world.run_coins += 11
        if world.run_variation != null:
            world.run_variation.add_threat(1.5, "infected_cache")
        world.hud.show_banner("СКЛАД ОЧИЩЕН", Color("a7bd79"))
        world.hud.set_status("Ресурсы спасены, но заражение усилило следующую ночь.")
    elif activity.activity_type == "memory_rift":
        world.run_coins += 6
        GameState.data["lore_fragments"] = int(GameState.data.get("lore_fragments", 0)) + 1
        var notices: Array = GameState.data.get("meta_notices", [])
        notices.append("Разлом памяти: найден новый фрагмент прошлого.")
        GameState.data["meta_notices"] = notices
        GameState.save()
        world.hud.show_banner("ЭХО ПРОШЛОГО", Color("aebbe0"))
        world.hud.set_status("В памяти мелькнул другой Очаг. Фрагмент сохранён в лагере.")
    elif activity.activity_type == "stranded_engineer":
        var engineer_residents: Dictionary = GameState.data.get("residents", {})
        var thorn: Dictionary = engineer_residents.get("thorn", {"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0})
        if not bool(thorn.get("unlocked", false)):
            thorn["unlocked"] = true
            thorn["quest_progress"] = 0
            engineer_residents["thorn"] = thorn
            GameState.data["residents"] = engineer_residents
            var engineer_notices: Array = GameState.data.get("meta_notices", [])
            engineer_notices.append("В лагерь вернулся механик Торн. Его поручения связаны с Деталями и постройками II.")
            GameState.data["meta_notices"] = engineer_notices
            GameState.save()
            QuestDirector.record("resident_rescued", 1, {"resident":"thorn","biome":world.biome_index,"wave":world.wave})
            world.hud.show_banner("МЕХАНИК СПАСЁН", Color("d3b07b"))
            world.hud.set_status("Торн вернётся в лагерь и откроет новую цепочку поручений.")
        else:
            world.add_mechanism_parts(1, activity.global_position)
            world.run_coins += 10
            world.hud.show_banner("ТОРН ЗАБРАЛ ДЕТАЛИ", Color("d3b07b"))
            world.hud.set_status("+1 Деталь · +10 мон.")
    elif activity.activity_type == "wounded_scout":
        var residents: Dictionary = GameState.data.get("residents", {})
        var mira: Dictionary = residents.get("mira", {"unlocked":false,"trust":0,"quest_step":0,"quest_progress":0})
        if not bool(mira.get("unlocked", false)):
            mira["unlocked"] = true
            mira["quest_progress"] = 0
            residents["mira"] = mira
            GameState.data["residents"] = residents
            var resident_notices: Array = GameState.data.get("meta_notices", [])
            resident_notices.append("В лагерь вернулась разведчица Мира. На Доске появились её поручения.")
            GameState.data["meta_notices"] = resident_notices
            GameState.save()
            QuestDirector.record("resident_rescued", 1, {"resident":"mira","biome":world.biome_index})
            world.hud.show_banner("РАЗВЕДЧИЦА СПАСЕНА", Color("b9d0b8"))
            world.hud.set_status("Мира вернётся в лагерь после экспедиции.")
        else:
            world.run_coins += 12
            world.hud.show_banner("РАЗВЕДЧИЦА В БЕЗОПАСНОСТИ", Color("b9d0b8"))
            world.hud.set_status("+12 мон. за помощь разведотряду.")
    elif activity.activity_type == "chest":
        if activity.cursed:
            QuestDirector.record("cursed_cache", 1, {"biome":world.biome_index})
            _give_resource("stone", 2, activity.global_position)
            _give_resource("ore", 4, activity.global_position)
            world.run_coins += 16
            world.player.gain_xp(9)
            world.player.shield_hits = mini(5, world.player.shield_hits + 1)
            if world.run_variation != null:
                world.run_variation.add_threat(2.2, "cursed_cache")
            world.hud.show_banner("ТЬМА ОТВЕТИЛА", Color("d99abb"))
            world.hud.set_status("Ценная добыча получена, но следующая ночь станет опаснее.")
        else:
            _give_resource("stone", 3, activity.global_position)
            _give_resource("ore", 2, activity.global_position)
            world.run_coins += 9
            world.player.gain_xp(6)
            world.player.shield_hits = mini(5, world.player.shield_hits + 1)
            world.hud.show_banner("ТАЙНИК ОТКРЫТ", Color("d6bb78"))
    Feedback.play("level", 6)

func _grant_nest_reward(activity: WorldActivity) -> void:
    world.run_coins += 8
    if world.run_variation != null:
        world.run_variation.reduce_threat(1.25, "nest_destroyed")
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
    return int(night_extra_enemies() / 2)
