class_name ExpeditionMemoryDirector
extends Node

var world: GameWorld
var moments: Array[Dictionary] = []
var flags: Dictionary = {}
var night_spawn_delta: Dictionary = {}
var dawn_seen: Dictionary = {}
var major_events: int = 0
var choices_made: int = 0
var consequences_triggered: int = 0

func setup(world_ref: GameWorld) -> void:
    world = world_ref

func remember(id: String, title: String, detail: String, tone: String = "gold", major: bool = true) -> void:
    if id.is_empty():
        return
    for moment_variant: Variant in moments:
        var moment: Dictionary = moment_variant
        if str(moment.get("id", "")) == id:
            moment["title"] = title
            moment["detail"] = detail
            moment["tone"] = tone
            moment["major"] = major
            return
    moments.append({
        "id":id,
        "title":title,
        "detail":detail,
        "tone":tone,
        "major":major
    })
    if major:
        major_events += 1

func choose(id: String, title: String, detail: String, tone: String = "gold") -> void:
    choices_made += 1
    remember(id, title, detail, tone, true)

func set_flag(id: String, value: Variant = true) -> void:
    flags[id] = value

func has_flag(id: String) -> bool:
    return bool(flags.get(id, false))

func flag_value(id: String, fallback: Variant = null) -> Variant:
    return flags.get(id, fallback)

func add_night_spawn_delta(wave: int, amount: int) -> void:
    if wave <= 0 or amount == 0:
        return
    night_spawn_delta[wave] = int(night_spawn_delta.get(wave, 0)) + amount

func consume_night_spawn_delta(wave: int) -> int:
    var amount: int = int(night_spawn_delta.get(wave, 0))
    if amount != 0:
        night_spawn_delta.erase(wave)
        consequences_triggered += 1
    return amount

func on_night_started(wave: int) -> void:
    if wave == 1 and has_flag("caravan_taken"):
        remember(
            "caravan_revenge",
            "ЗА ГРУЗОМ ПРИШЛИ",
            "Разграбленный караван привёл к Очагу охотников. Первая ночь стала плотнее.",
            "danger",
            true
        )
    if wave == 3 and has_flag("altar_oath"):
        remember(
            "altar_oath_finale",
            "КЛЯТВА ДОЖИЛА ДО ХРАНИТЕЛЯ",
            "Цена алтаря всё ещё действует в финальной ночи.",
            "violet",
            false
        )

func on_dawn(wave: int) -> String:
    if dawn_seen.has(wave):
        return ""
    dawn_seen[wave] = true

    var notes: Array[String] = []
    if has_flag("caravan_escorted"):
        world.storage["wood"] = int(world.storage.get("wood", 0)) + 4
        world.storage["stone"] = int(world.storage.get("stone", 0)) + 2
        world.base_hp = minf(world.base_max_hp, world.base_hp + 16.0)
        notes.append("караван доставил припасы")

    if has_flag("rescued_watcher"):
        world.base_hp = minf(world.base_max_hp, world.base_hp + 14.0)
        if world.player != null:
            world.player.heal(8.0)
        notes.append("спасённый дозорный помог у Очагa")

    if has_flag("old_hearth_relit"):
        world.base_hp = minf(world.base_max_hp, world.base_hp + 12.0)
        if world.player != null:
            world.player.heal(10.0)
        notes.append("старый Очаг ответил теплом")

    if notes.is_empty():
        return ""

    consequences_triggered += 1
    return "Последствия экспедиции: " + " · ".join(notes) + "."

func result_summary() -> Dictionary:
    var visible: Array[Dictionary] = []
    for moment_variant: Variant in moments:
        var moment: Dictionary = moment_variant
        if bool(moment.get("major", false)):
            visible.append(moment.duplicate(true))
    if visible.size() < 3:
        for moment_variant: Variant in moments:
            if visible.size() >= 5:
                break
            var moment: Dictionary = moment_variant
            if not bool(moment.get("major", false)):
                visible.append(moment.duplicate(true))
    if visible.size() > 5:
        visible = visible.slice(maxi(0, visible.size() - 5), visible.size())
    return {
        "moments":visible,
        "major_events":major_events,
        "choices":choices_made,
        "consequences":consequences_triggered
    }
