class_name FrontierRules
extends RefCounted

const ASSIGNMENTS := {
    "beacon": {
        "name":"ДВА ОГНЯ",
        "desc":"Зажги 2 сигнальных костра до второй ночи и вернись к Последнему Очагу.",
        "event":"signal_fire",
        "goal":2,
        "deadline_wave":1,
        "reward_type":"coins",
        "reward":120,
        "guarantee":"signal_fire"
    },
    "purge": {
        "name":"ВЫЖЕЧЬ КОРНИ",
        "desc":"Уничтожь 2 Гнезда Тьмы до второй ночи и вернись к Последнему Очагу.",
        "event":"nest_destroyed",
        "goal":2,
        "deadline_wave":1,
        "reward_type":"coins",
        "reward":135,
        "guarantee":"nest"
    },
    "salvage": {
        "name":"СЕРДЦЕ МЕХАНИЗМА",
        "desc":"Найди 2 Детали механизма до второй ночи и доставь их домой.",
        "event":"mechanism_part",
        "goal":2,
        "deadline_wave":1,
        "reward_type":"coins",
        "reward":110,
        "guarantee":"rare_ore"
    },
    "rekindle": {
        "name":"ОГОНЬ ВО ТЬМЕ",
        "desc":"После первой ночи зажги погасший Очаг и вернись домой до второй ночи.",
        "event":"hearth_relit",
        "goal":1,
        "deadline_wave":1,
        "reward_type":"shards",
        "reward":1,
        "guarantee":"old_hearth"
    }
}

const SUPPORTS := {
    "mira_route": {
        "name":"МАРШРУТ МИРЫ",
        "resident":"mira",
        "trust":1,
        "desc":"+7% скорость и -1 Угроза Тьмы в следующей экспедиции."
    },
    "thorn_kit": {
        "name":"НАБОР ТОРНА",
        "resident":"thorn",
        "trust":1,
        "desc":"Следующая экспедиция начинается с 1 Деталью механизма."
    }
}

static func assignment_ids() -> Array[String]:
    return ["beacon", "purge", "salvage", "rekindle"]

static func assignment(id: String) -> Dictionary:
    if not ASSIGNMENTS.has(id):
        return {}
    return (ASSIGNMENTS[id] as Dictionary).duplicate(true)

static func support_ids() -> Array[String]:
    return ["mira_route", "thorn_kit"]

static func support(id: String) -> Dictionary:
    if not SUPPORTS.has(id):
        return {}
    return (SUPPORTS[id] as Dictionary).duplicate(true)

static func reward_text(spec: Dictionary) -> String:
    var amount: int = int(spec.get("reward", 0))
    return "%d ОСК." % amount if str(spec.get("reward_type", "coins")) == "shards" else "%d МОН." % amount

static func progress_text(completed: int) -> String:
    if completed <= 0:
        return "Старая сеть найдена, но путь ещё не закреплён."
    if completed == 1:
        return "Первый дальний маршрут подтверждён."
    if completed == 2:
        return "Мира отметила безопасные точки возврата."
    if completed == 3:
        return "Торн считает, что механизмы выдержат дальний переход."
    return "Путь к первому внешнему Очагу нанесён на карту."
