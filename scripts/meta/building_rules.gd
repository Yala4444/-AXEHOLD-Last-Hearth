class_name BuildingRules
extends RefCounted

const PROJECTS := {
    "wall": {
        "name":"ПАЛИСАД II",
        "desc":"Открывает две ветки усиления Палисада в экспедиции.",
        "coins":240,
        "shards":1,
        "min_mastery":0
    },
    "forge": {
        "name":"КУЗНИЦА II",
        "desc":"Открывает две ветки боевой специализации Кузницы.",
        "coins":320,
        "shards":1,
        "min_mastery":1
    },
    "turret": {
        "name":"БАШНЯ II",
        "desc":"Открывает Баллисту или Скорострельную Башню.",
        "coins":420,
        "shards":2,
        "min_mastery":2
    },
    "shrine": {
        "name":"СВЯТИЛИЩЕ II",
        "desc":"Открывает усиленное исцеление или защитный оберег.",
        "coins":380,
        "shards":2,
        "min_mastery":2
    }
}

const RUN_UPGRADES := {
    "wall": {
        "cost":{"wood":10,"stone":5,"ore":0,"parts":1},
        "branches":[
            {
                "id":"bastion",
                "name":"БАСТИОН",
                "desc":"+140 прочности Очагa, сильнее замедление и меньше входящего урона."
            },
            {
                "id":"spikes",
                "name":"ШИПЫ",
                "desc":"+80 прочности. Враги у Палисада получают постоянный урон."
            }
        ]
    },
    "forge": {
        "cost":{"wood":8,"stone":8,"ore":4,"parts":1},
        "branches":[
            {
                "id":"temper",
                "name":"ЗАКАЛКА",
                "desc":"+22% урона героя до конца экспедиции."
            },
            {
                "id":"reach",
                "name":"МАСТЕРСКАЯ ДУГИ",
                "desc":"+12 радиуса оружия и +4% к шансу критического удара."
            }
        ]
    },
    "turret": {
        "cost":{"wood":10,"stone":10,"ore":6,"parts":2},
        "branches":[
            {
                "id":"ballista",
                "name":"БАЛЛИСТА",
                "desc":"Редкие тяжёлые выстрелы: значительно выше урон по бронированным врагам."
            },
            {
                "id":"repeater",
                "name":"СКОРОСТРЕЛ",
                "desc":"Стреляет почти вдвое чаще, но каждый выстрел слабее."
            }
        ]
    },
    "shrine": {
        "cost":{"wood":8,"stone":9,"ore":5,"parts":2},
        "branches":[
            {
                "id":"renewal",
                "name":"ВОЗРОЖДЕНИЕ",
                "desc":"Сильно ускоряет лечение героя и восстановление Очагa."
            },
            {
                "id":"ward",
                "name":"ОБЕРЕГ",
                "desc":"Умеренное лечение и защитный заряд герою после каждого рассвета."
            }
        ]
    }
}

static func project_spec(build_type: String) -> Dictionary:
    if not PROJECTS.has(build_type):
        return {}
    return (PROJECTS[build_type] as Dictionary).duplicate(true)

static func upgrade_spec(build_type: String) -> Dictionary:
    if not RUN_UPGRADES.has(build_type):
        return {}
    return (RUN_UPGRADES[build_type] as Dictionary).duplicate(true)

static func upgrade_cost(build_type: String) -> Dictionary:
    return (upgrade_spec(build_type).get("cost", {}) as Dictionary).duplicate(true)

static func branches(build_type: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var spec: Dictionary = upgrade_spec(build_type)
    for item_variant: Variant in spec.get("branches", []):
        result.append((item_variant as Dictionary).duplicate(true))
    return result

static func branch_spec(build_type: String, branch_id: String) -> Dictionary:
    for branch: Dictionary in branches(build_type):
        if str(branch.get("id", "")) == branch_id:
            return branch
    return {}

static func branch_title(build_type: String, branch_id: String) -> String:
    return str(branch_spec(build_type, branch_id).get("name", "УРОВЕНЬ II"))

static func branch_effect(build_type: String, branch_id: String) -> String:
    return str(branch_spec(build_type, branch_id).get("desc", ""))

static func cost_text(build_type: String) -> String:
    var cost: Dictionary = upgrade_cost(build_type)
    return "Д%d  К%d  Р%d  ДЕТ%d" % [
        int(cost.get("wood", 0)),
        int(cost.get("stone", 0)),
        int(cost.get("ore", 0)),
        int(cost.get("parts", 0))
    ]
