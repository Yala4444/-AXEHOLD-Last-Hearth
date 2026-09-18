class_name ResidentRules
extends RefCounted

const RESIDENTS := {
    "mira": {
        "name":"Мира",
        "role":"РАЗВЕДЧИЦА",
        "desc":"Видит дороги там, где остальные видят только Тьму. Её поручения раскрывают дальние маршруты и следы старых Очагов.",
        "color":"6f8f72",
        "max_trust":5,
        "chain":[
            {"title":"МЕТКИ НА ДОРОГЕ","desc":"Зажги 2 сигнальных костра в экспедициях.","event":"signal_fire","goal":2,"reward_type":"shards","reward":1},
            {"title":"ДАЛЬНИЙ ПУТЬ","desc":"Доберись до внешнего кольца мира 2 раза.","event":"reach_outer","goal":2,"reward_type":"coins","reward":90},
            {"title":"ЧЁРНЫЕ КОРНИ","desc":"Уничтожь 3 гнезда Тьмы.","event":"nest_destroyed","goal":3,"reward_type":"shards","reward":1},
            {"title":"ГОЛОСА ЗА ГРАНИЦЕЙ","desc":"Исследуй 2 Разлома памяти.","event":"memory_rift","goal":2,"reward_type":"coins","reward":110},
            {"title":"ОГНИ НА КАРТЕ","desc":"Зажги 2 старых Очага.","event":"hearth_relit","goal":2,"reward_type":"shards","reward":2}
        ]
    },
    "thorn": {
        "name":"Торн",
        "role":"ИНЖЕНЕР СТАРОГО ОГНЯ",
        "desc":"Помнит механизмы, которыми старый мир связывал Очаги. Его поручения превращают найденный металл в настоящие укрепления.",
        "color":"8d6b58",
        "max_trust":4,
        "chain":[
            {"title":"СТАРЫЕ МЕХАНИЗМЫ","desc":"Восстанови 2 сломанные башни.","event":"tower_repaired","goal":2,"reward_type":"coins","reward":95},
            {"title":"НЕ ХВАТАЕТ ДЕТАЛЕЙ","desc":"Найди 4 детали механизмов.","event":"mechanism_part","goal":4,"reward_type":"coins","reward":105},
            {"title":"НЕ ПРОСТО СТЕНА","desc":"Улучши 2 постройки до уровня II.","event":"build_upgrade","goal":2,"reward_type":"shards","reward":1},
            {"title":"ПРОВЕРКА ОГНЁМ","desc":"Переживи 3 ночи после знакомства с Торном.","event":"night_survive","goal":3,"reward_type":"shards","reward":2}
        ]
    }
}

static func ids() -> Array[String]:
    return ["mira", "thorn"]

static func spec(id: String) -> Dictionary:
    if not RESIDENTS.has(id):
        return {}
    return (RESIDENTS[id] as Dictionary).duplicate(true)

static func name_for(id: String) -> String:
    return str(spec(id).get("name", id.capitalize()))

static func role_for(id: String) -> String:
    return str(spec(id).get("role", "ЖИТЕЛЬ"))

static func description_for(id: String) -> String:
    return str(spec(id).get("desc", ""))

static func max_trust(id: String) -> int:
    return int(spec(id).get("max_trust", 3))

static func chain(id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var resident: Dictionary = spec(id)
    for item_variant: Variant in resident.get("chain", []):
        result.append((item_variant as Dictionary).duplicate(true))
    return result

static func quest(id: String, step: int) -> Dictionary:
    var quests: Array[Dictionary] = chain(id)
    if step < 0 or step >= quests.size():
        return {}
    return quests[step].duplicate(true)

static func chain_size(id: String) -> int:
    return chain(id).size()
