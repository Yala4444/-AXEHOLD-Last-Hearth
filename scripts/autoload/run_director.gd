extends Node

var world: GameWorld = null
var fx: BiomeFX = null
var elapsed: float = 0.0
var coach_step: int = 0
var first_run_coaching: bool = false
var night_warning_shown: bool = false
var full_bag_hint_cooldown: float = 0.0
var danger_hint_cooldown: float = 0.0
var highlighted_pad: BuildPad = null
var last_phase: String = ""
var last_wave: int = -1
var pending_dawn_choice: int = 0
var doctrine_choices: Array[String] = []
var seen_enemies: Dictionary = {}
var night_speed_applied: bool = false
var night_speed_multiplier: float = 1.0
var frost_slow_applied: bool = false
var frost_slow_time: float = 0.0
var environment_hazard_timer: float = 5.0
var boss_cycle_timer: float = 4.0
var tracked_boss_id: int = 0

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
    full_bag_hint_cooldown = maxf(0.0, full_bag_hint_cooldown - delta)
    danger_hint_cooldown = maxf(0.0, danger_hint_cooldown - delta)

    _handle_phase_transition()
    _retune_new_enemies()
    _update_biome_mechanics(delta)
    _show_pending_dawn_choice()

    if first_run_coaching:
        _update_first_run_coaching()
    _update_contextual_hints()

func _reset_runtime_refs() -> void:
    world = null
    fx = null
    seen_enemies.clear()
    tracked_boss_id = 0
    night_speed_applied = false
    frost_slow_applied = false

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
    coach_step = 0
    night_warning_shown = false
    full_bag_hint_cooldown = 0.0
    danger_hint_cooldown = 0.0
    highlighted_pad = null
    last_phase = world.phase
    last_wave = world.wave
    pending_dawn_choice = 0
    doctrine_choices.clear()
    seen_enemies.clear()
    tracked_boss_id = 0
    environment_hazard_timer = 5.0
    boss_cycle_timer = 4.0
    night_speed_applied = false
    frost_slow_applied = false
    frost_slow_time = 0.0

    world.phase_max = GameRules.day_duration(0)
    world.phase_time = world.phase_max

    fx = BiomeFX.new()
    world.add_child(fx)
    fx.setup(world, world.biome_index)
    fx.hazard_triggered.connect(_on_hazard_triggered)
    world.hud.action_requested.connect(_on_hud_action)

    var biome_data: Dictionary = GameRules.biome(world.biome_index)
    world.hud.set_status(str(biome_data.get("rule", "Подготовь лагерь к ночи.")))

    var settings: Dictionary = GameState.data.get("settings", {})
    first_run_coaching = bool(settings.get("hints", true)) and not bool(GameState.data.get("coach_complete", false))
    if first_run_coaching:
        Analytics.event("coach_start", {"biome": world.biome_index})

func _handle_phase_transition() -> void:
    if world == null:
        return
    if world.phase == last_phase and world.wave == last_wave:
        return

    var previous_phase: String = last_phase
    last_phase = world.phase
    last_wave = world.wave

    if world.phase == "night":
        _clear_highlight()
        night_warning_shown = false
        environment_hazard_timer = 4.8
        boss_cycle_timer = 3.8
        _apply_biome_night_speed()
        if world.biome_index == 1:
            world.hud.show_banner("МОРОЗ КРЕПЧАЕТ", Color("cdeeff"))
            world.hud.set_status("❄️ В Морозной лощине ночью герой движется медленнее.")
        elif world.biome_index == 2:
            world.hud.show_banner("ЗЕМЛЯ НЕСТАБИЛЬНА", Color("ffb086"))
            world.hud.set_status("🔥 Следи за красными зонами — пепельные выбросы телеграфируются заранее.")
        return

    if previous_phase == "night" and world.phase == "day":
        night_warning_shown = false
        _remove_biome_night_speed()
        _clear_frost_slow()
        if fx != null and is_instance_valid(fx):
            fx.clear_hazards()
        if world.wave == 1 or world.wave == 2:
            pending_dawn_choice = world.wave
        _show_dawn_priority(world.wave)

func _apply_biome_night_speed() -> void:
    if world == null or world.player == null or night_speed_applied:
        return
    var biome_data: Dictionary = GameRules.biome(world.biome_index)
    night_speed_multiplier = float(biome_data.get("night_speed", 1.0))
    if night_speed_multiplier < 0.999:
        world.player.move_speed *= night_speed_multiplier
        night_speed_applied = true

func _remove_biome_night_speed() -> void:
    if world == null or world.player == null or not night_speed_applied:
        return
    if night_speed_multiplier > 0.01:
        world.player.move_speed /= night_speed_multiplier
    night_speed_applied = false
    night_speed_multiplier = 1.0

func _show_pending_dawn_choice() -> void:
    if world == null or world.hud == null or pending_dawn_choice <= 0:
        return
    if world.hud.modal_open():
        return

    var completed_wave: int = pending_dawn_choice
    pending_dawn_choice = 0
    world.hud.show_modal(
        "🔥",
        "Рассвет после ночи %d" % completed_wave,
        "Выбери курс лагеря. Усиление действует до конца этой экспедиции и может складываться.",
        [
            {"text":"⚔️ Охота — +16% урона и +4% крита", "action":"doctrine:hunt"},
            {"text":"🏰 Укрепление — +70 прочности и ремонт", "action":"doctrine:fortify"},
            {"text":"🎒 Снабжение — +6 рюкзак и ресурсы", "action":"doctrine:supply"}
        ]
    )

func _on_hud_action(action: String) -> void:
    if not action.begins_with("doctrine:"):
        return
    if world == null or world.player == null:
        return

    var doctrine: String = action.trim_prefix("doctrine:")
    if doctrine == "hunt":
        world.player.damage *= 1.16
        world.player.crit_chance = minf(0.55, world.player.crit_chance + 0.04)
        world.hud.show_banner("КУРС: ОХОТА", Color("ffd28c"))
        world.hud.set_status("⚔️ Герой наносит больше урона и чаще критует.")
    elif doctrine == "fortify":
        world.base_max_hp += 70.0
        world.base_hp = minf(world.base_max_hp, world.base_hp + 110.0)
        world.hud.show_banner("КУРС: УКРЕПЛЕНИЕ", Color("c9e6b5"))
        world.hud.set_status("🏰 Очаг укреплён и частично восстановлен.")
    elif doctrine == "supply":
        world.player.capacity += 6
        world.storage["wood"] = int(world.storage.get("wood", 0)) + 8
        world.storage["stone"] = int(world.storage.get("stone", 0)) + 5
        world.storage["ore"] = int(world.storage.get("ore", 0)) + 2
        world.hud.show_banner("КУРС: СНАБЖЕНИЕ", Color("d7d4ff"))
        world.hud.set_status("🎒 Рюкзак расширен, на склад доставлены ресурсы.")
    else:
        return

    doctrine_choices.append(doctrine)
    world.hud.hide_modal()
    Feedback.play("level", 14)
    Analytics.event("dawn_doctrine", {"choice": doctrine, "wave": world.wave, "biome": world.biome_index})

func _retune_new_enemies() -> void:
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

        var desired_type: String = GameRules.enemy_type_for_biome(world.biome_index)
        if desired_type != enemy.enemy_type:
            enemy.configure(
                desired_type,
                float(world.biome.get("difficulty", 1.0)),
                world.wave,
                Color(str(world.biome.get("enemy", "6c5574"))),
                false
            )

func _update_biome_mechanics(delta: float) -> void:
    if world == null or world.player == null:
        return

    if frost_slow_applied:
        frost_slow_time -= delta
        if frost_slow_time <= 0.0:
            _clear_frost_slow()

    if world.phase != "night":
        return

    if world.biome_index == 2:
        _update_ash_hazards(delta)

    _update_boss_identity(delta)

func _update_ash_hazards(delta: float) -> void:
    if fx == null or not is_instance_valid(fx):
        return
    if world.boss_ref != null and is_instance_valid(world.boss_ref):
        return

    environment_hazard_timer -= delta
    if environment_hazard_timer > 0.0:
        return

    environment_hazard_timer = maxf(4.8, 7.0 - float(world.wave) * 0.55)
    var target: Vector2 = world.player.global_position + Vector2(randf_range(-28.0, 28.0), randf_range(-28.0, 28.0))
    var damage: float = (10.0 + float(world.wave) * 2.0) * float(world.biome.get("difficulty", 1.0))
    fx.telegraph("ember", target, 46.0, 0.90, damage)
    if world.wave >= 2:
        var second: Vector2 = target + Vector2(randf_range(-85.0, 85.0), randf_range(-70.0, 70.0))
        fx.telegraph("ember", second, 40.0, 1.15, damage * 0.85)

func _update_boss_identity(delta: float) -> void:
    if world.boss_ref == null or not is_instance_valid(world.boss_ref):
        tracked_boss_id = 0
        return

    var boss: AxEnemy = world.boss_ref
    var boss_id: int = boss.get_instance_id()
    if boss_id != tracked_boss_id:
        tracked_boss_id = boss_id
        boss_cycle_timer = 3.4
        var biome_data: Dictionary = GameRules.biome(world.biome_index)
        world.hud.show_banner(str(biome_data.get("boss_name", "Хранитель")), Color("ffc07b"))
        world.hud.set_status(_boss_hint(world.biome_index))

    if world.biome_index == 0:
        return

    boss.special_cooldown = 999.0
    if world.biome_index == 1:
        boss.charge_cooldown = 999.0

    boss_cycle_timer -= delta
    if boss_cycle_timer > 0.0:
        return

    if fx == null or not is_instance_valid(fx):
        return

    if world.biome_index == 1:
        boss_cycle_timer = randf_range(4.2, 5.0)
        fx.telegraph(
            "frost",
            boss.global_position,
            108.0,
            1.05,
            10.0 * float(world.biome.get("difficulty", 1.0))
        )
        world.hud.set_status("❄️ Ледяная волна! Отойди от Стража до схлопывания круга.")
    elif world.biome_index == 2:
        boss_cycle_timer = randf_range(3.8, 4.6)
        var damage: float = 16.0 * float(world.biome.get("difficulty", 1.0))
        var center: Vector2 = world.player.global_position
        fx.telegraph("ember", center, 50.0, 0.82, damage)
        fx.telegraph("ember", center + Vector2(randf_range(-82.0, 82.0), randf_range(-68.0, 68.0)), 44.0, 1.04, damage * 0.90)
        fx.telegraph("ember", center + Vector2(randf_range(-95.0, 95.0), randf_range(-78.0, 78.0)), 40.0, 1.26, damage * 0.80)
        world.hud.set_status("🔥 Пепельный Тиран вызывает цепочку извержений — двигайся между зонами.")

func _boss_hint(index: int) -> String:
    if index == 1:
        return "❄️ Ледяной Страж не делает рывков, но накрывает большую область замораживающей волной."
    if index == 2:
        return "🔥 Пепельный Тиран совмещает рывки с сериями огненных извержений."
    return "🌲 Лесной Хранитель чередует метку удара и прямой рывок."

func _on_hazard_triggered(kind: String, position: Vector2, radius: float, damage: float) -> void:
    if world == null or world.player == null or world.finishing:
        return
    if world.player.global_position.distance_to(position) > radius:
        return

    if kind == "frost":
        world.player.take_damage(damage)
        _apply_frost_slow(2.4)
        world.hud.set_status("❄️ Холод сковывает героя на несколько секунд.")
    else:
        world.player.take_damage(damage)
        world.hud.set_status("🔥 Герой попал под пепельный выброс.")

func _apply_frost_slow(duration: float) -> void:
    if world == null or world.player == null:
        return
    frost_slow_time = maxf(frost_slow_time, duration)
    if not frost_slow_applied:
        world.player.move_speed *= 0.72
        frost_slow_applied = true

func _clear_frost_slow() -> void:
    if world != null and world.player != null and frost_slow_applied:
        world.player.move_speed /= 0.72
    frost_slow_applied = false
    frost_slow_time = 0.0

func _show_dawn_priority(completed_wave: int) -> void:
    if world == null or world.hud == null:
        return
    var settings: Dictionary = GameState.data.get("settings", {})
    if not bool(settings.get("hints", true)):
        return

    if completed_wave == 1:
        world.hud.show_banner("ПЕРВАЯ НОЧЬ ПЕРЕЖИТА", Color("fff0b4"))
        if not bool(world.built.get("forge", false)):
            _highlight_build("forge")
            world.hud.set_status("⚒️ Кузница — сильный следующий шаг, но теперь ты ещё выбираешь курс лагеря.")
        return

    if completed_wave == 2:
        world.hud.show_banner("ПОСЛЕДНЯЯ ПОДГОТОВКА", Color("ffd79c"))
        var base_ratio: float = world.base_hp / maxf(1.0, world.base_max_hp)
        if base_ratio < 0.65 and not bool(world.built.get("shrine", false)):
            _highlight_build("shrine")
        elif not bool(world.built.get("turret", false)):
            _highlight_build("turret")

func _update_first_run_coaching() -> void:
    if world == null or world.player == null or world.hud == null:
        return
    if world.hud.modal_open():
        return

    if coach_step == 0 and elapsed >= 0.7:
        world.hud.set_status("🌲 Подойди к деревьям. Топоры рубят автоматически.")
        coach_step = 1
        return

    if coach_step == 1 and world.player.inventory_total() >= 8:
        world.hud.show_banner("РЮКЗАК НАПОЛНЯЕТСЯ", Color("f5dfa4"))
        world.hud.set_status("🎒 Вернись к Очагу — ресурсы выгрузятся автоматически.")
        coach_step = 2
        return

    if coach_step == 2 and _storage_total() >= 8:
        _highlight_build("wall")
        world.hud.set_status("🔨 Теперь подойди к площадке ЗАБОРА. Стройка запустится сама, когда ресурсов хватит.")
        coach_step = 3
        return

    if coach_step == 3 and bool(world.built.get("wall", false)):
        _clear_highlight()
        world.hud.show_banner("ОБОРОНА ГОТОВА", Color("cfe9b1"))
        world.hud.set_status("🪨 Отлично. Собери камень и руду для следующих построек.")
        coach_step = 4
        return

    if world.phase == "day" and world.phase_time <= 10.0 and not night_warning_shown:
        night_warning_shown = true
        world.hud.show_banner("НОЧЬ ЧЕРЕЗ 10 СЕК", Color("dce8ff"))
        if not bool(world.built.get("wall", false)):
            _highlight_build("wall")
            world.hud.set_status("⚠️ До ночи мало времени. Забор сильно снизит урон по Очагу.")
        else:
            world.hud.set_status("🔥 Возвращайся к Очагу. Скоро начнётся первая атака.")

    if coach_step <= 4 and world.phase == "night" and world.wave >= 1:
        _clear_highlight()
        world.hud.set_status("⚔️ Не стой на месте: веди врагов через вращающиеся топоры и не отдавай им Очаг.")
        coach_step = 5
        return

    if coach_step == 5 and world.kills >= 3:
        world.hud.show_banner("ТЫ ПОНЯЛ ОСНОВУ", Color("fff0b4"))
        world.hud.set_status("Теперь решай сам: усиливать героя или вкладываться в оборону.")
        GameState.data["coach_complete"] = true
        GameState.save()
        Analytics.event("coach_complete", {"wave": world.wave, "kills": world.kills})
        first_run_coaching = false
        coach_step = 6

func _update_contextual_hints() -> void:
    if world == null or world.player == null or world.hud == null:
        return
    var settings: Dictionary = GameState.data.get("settings", {})
    if not bool(settings.get("hints", true)):
        return
    if world.hud.modal_open():
        return

    if highlighted_pad != null and is_instance_valid(highlighted_pad) and highlighted_pad.built:
        _clear_highlight()

    if world.player.inventory_total() >= world.player.capacity and full_bag_hint_cooldown <= 0.0:
        if world.player.global_position.distance_to(world.base_position) > 70.0:
            world.hud.set_status("🎒 Рюкзак заполнен — вернись к Очагу, чтобы не терять добычу.")
            full_bag_hint_cooldown = 7.0

    if world.phase == "day" and world.phase_time <= 8.0 and not bool(world.built.get("wall", false)) and danger_hint_cooldown <= 0.0:
        world.hud.set_status("⚠️ Ночь близко, а Забор ещё не построен.")
        danger_hint_cooldown = 8.0

    var base_ratio: float = world.base_hp / maxf(1.0, world.base_max_hp)
    if world.phase == "night" and base_ratio <= 0.30 and danger_hint_cooldown <= 0.0:
        world.hud.show_banner("ОЧАГ ПОД УГРОЗОЙ", Color("ff9f8d"))
        world.hud.set_status("🔥 Перехватывай врагов у центра — Очаг почти разрушен.")
        danger_hint_cooldown = 10.0

func _storage_total() -> int:
    if world == null:
        return 0
    return int(world.storage.get("wood", 0)) + int(world.storage.get("stone", 0)) + int(world.storage.get("ore", 0))

func _highlight_build(kind: String) -> void:
    if world == null:
        return
    for pad: BuildPad in world.pads:
        if pad.build_type == kind and not pad.built:
            if highlighted_pad != null and highlighted_pad != pad and is_instance_valid(highlighted_pad):
                highlighted_pad.modulate = Color.WHITE
                highlighted_pad.z_index = 0
            highlighted_pad = pad
            pad.modulate = Color(1.25, 1.15, 0.72, 1.0)
            pad.z_index = 5
            return

func _clear_highlight() -> void:
    if highlighted_pad != null and is_instance_valid(highlighted_pad):
        highlighted_pad.modulate = Color.WHITE
        highlighted_pad.z_index = 0
    highlighted_pad = null
