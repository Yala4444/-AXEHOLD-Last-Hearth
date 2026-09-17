extends Node

var world: GameWorld = null
var elapsed: float = 0.0
var coach_step: int = 0
var first_run_coaching: bool = false
var night_warning_shown: bool = false
var full_bag_hint_cooldown: float = 0.0
var danger_hint_cooldown: float = 0.0
var highlighted_pad: BuildPad = null
var last_phase: String = ""
var last_wave: int = -1

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world):
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
    if first_run_coaching:
        _update_first_run_coaching()
    _update_contextual_hints()

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

    world.phase_max = GameRules.day_duration(0)
    world.phase_time = world.phase_max

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
        return

    if previous_phase == "night" and world.phase == "day":
        night_warning_shown = false
        _show_dawn_priority(world.wave)

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
            world.hud.set_status("⚒️ Следующий сильный шаг — Кузница. Она заметно ускорит убийство врагов.")
        else:
            world.hud.set_status("⚔️ Кузница уже работает. Собирай ресурсы на Турель или Святилище.")
        return

    if completed_wave == 2:
        world.hud.show_banner("ПОСЛЕДНЯЯ ПОДГОТОВКА", Color("ffd79c"))
        var base_ratio: float = world.base_hp / maxf(1.0, world.base_max_hp)
        if base_ratio < 0.65 and not bool(world.built.get("shrine", false)):
            _highlight_build("shrine")
            world.hud.set_status("✨ Очаг потрёпан. Святилище даст тебе запас HP и лечение перед Хранителем.")
        elif not bool(world.built.get("turret", false)):
            _highlight_build("turret")
            world.hud.set_status("🏹 Перед Хранителем выгодно поставить Турель — она сама снимает давление с центра.")
        else:
            world.hud.set_status("🔥 Оборона готова. Добери ресурсы и подготовься к Хранителю.")

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
