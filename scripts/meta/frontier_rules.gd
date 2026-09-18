class_name FrontierRules
extends RefCounted

const ASSIGNMENTS := {
    "beacon": {
        "name":"ДВА ОГНЯ",
        "desc":"Зажги 2 сигнальных костра до второй ночи и вернись к Очагу.",
        "event":"signal_fire",
        "goal":2,
        "deadline_wave":1,
        "reward_type":"coins",
        "reward":120,
        "guarantee":"signal_fire"
    },
    "purge": {
        "name":"ВЫЖЕЧЬ КОРНИ",
        "desc":"Уничтожь 2 Гнезда Тьмы до второй ночи и вернись к Очагу.",
        "event":"nest_destroyed",
        "goal":2,
        "deadline_wave":1,
        "reward_type":"coins",
        "reward":135,
        "guarantee":"nest"
    },
    "salvage": {
        "name":"СЕРДЦЕ МЕХАНИЗМА",
        "desc":"Найди 2 редкие детали до второй ночи и доставь их к Очагу.",
        "event":"mechanism_part",
        "goal":2,
        "deadline_wave":1,
        "reward_type":"coins",
        "reward":110,
        "guarantee":"rare_ore"
    },
    "rekindle": {
        "name":"ОГОНЬ ВО ТЬМЕ",
        "desc":"После первой ночи найди погасший Очаг, зажги его и вернись домой до второй ночи.",
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
        "desc":"+7% скорость в следующей экспедиции и -1 Угроза Тьмы."
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
    var reward: int = int(spec.get("reward", 0))
    return "%d ОСК." % reward if str(spec.get("reward_type", "coins")) == "shards" else "%d МОН." % reward
