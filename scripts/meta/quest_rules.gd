class_name QuestRules
extends RefCounted

const DAILY_CLAIM_CAP := 6

const DAILY_POOL: Array[Dictionary] = [
    {"id":"woodcut","category":"resource","event":"harvest_wood","title":"ЛЕСОРУБ","desc":"Добудь 24 дерева.","goal":24,"reward_type":"coins","reward":34},
    {"id":"stonework","category":"resource","event":"harvest_stone","title":"КАМЕННЫЙ ЗАПАС","desc":"Добудь 14 камня.","goal":14,"reward_type":"coins","reward":38},
    {"id":"ore_run","category":"resource","event":"harvest_ore","title":"РУДНЫЙ РЫВОК","desc":"Добудь 8 руды.","goal":8,"reward_type":"coins","reward":48},
    {"id":"defender","category":"combat","event":"kill_enemy","title":"ЗАЩИТНИК","desc":"Уничтожь 30 врагов.","goal":30,"reward_type":"coins","reward":44},
    {"id":"builder","category":"build","event":"build_structure","title":"СТРОИТЕЛЬ","desc":"Построй 3 сооружения.","goal":3,"reward_type":"coins","reward":42},
    {"id":"nestbreaker","category":"risk","event":"nest_destroyed","title":"ЛОМАТЕЛЬ ГНЁЗД","desc":"Уничтожь 2 гнезда Тьмы.","goal":2,"reward_type":"coins","reward":58},
    {"id":"explorer","category":"explore","event":"activity_resolved","title":"ИССЛЕДОВАТЕЛЬ","desc":"Заверши 4 события мира.","goal":4,"reward_type":"coins","reward":46},
    {"id":"old_fire","category":"explore","event":"hearth_relit","title":"СТАРЫЙ ОГОНЬ","desc":"Зажги погасший Очаг.","goal":1,"reward_type":"coins","reward":52},
    {"id":"cursed_reward","category":"risk","event":"cursed_cache","title":"ЦЕНА ЖАДНОСТИ","desc":"Открой проклятый тайник.","goal":1,"reward_type":"coins","reward":54},
    {"id":"contractor","category":"run","event":"contract_complete","title":"СЛОВО СТРАННИКА","desc":"Выполни контракт экспедиции.","goal":1,"reward_type":"coins","reward":50},
    {"id":"nightwatch","category":"defense","event":"night_survive","title":"НОЧНОЙ ДОЗОР","desc":"Переживи 2 ночи.","goal":2,"reward_type":"coins","reward":48},
    {"id":"riftbreaker","category":"defense","event":"rift_destroyed","title":"ЗАКРОЙ РАЗЛОМ","desc":"Уничтожь Разлом Тьмы.","goal":1,"reward_type":"coins","reward":58},
    {"id":"far_reach","category":"explore","event":"reach_outer","title":"ДАЛЬНИЙ КРАЙ","desc":"Доберись до внешнего кольца мира.","goal":1,"reward_type":"coins","reward":45},
    {"id":"victory","category":"run","event":"run_win","title":"ВОЗВРАЩЕНИЕ С ПОБЕДОЙ","desc":"Победи Хранителя.","goal":1,"reward_type":"coins","reward":70},
    {"id":"no_tower","category":"build","event":"night_no_tower","title":"СВОИМИ СИЛАМИ","desc":"Переживи первую ночь без Башни.","goal":1,"reward_type":"coins","reward":62},
    {"id":"forest_clear","category":"biome","event":"run_win","filter_key":"biome","filter_value":0,"title":"СЕРДЦЕ ЛЕСА","desc":"Победи Хранителя Забытого леса.","goal":1,"reward_type":"coins","reward":72},
    {"id":"frost_clear","category":"biome","event":"run_win","filter_key":"biome","filter_value":1,"title":"СКВОЗЬ МЕТЕЛЬ","desc":"Победи Хранителя Морозной лощины.","goal":1,"reward_type":"coins","reward":78},
    {"id":"ash_clear","category":"biome","event":"run_win","filter_key":"biome","filter_value":2,"title":"ПОД ПЕПЛОМ","desc":"Победи Хранителя Пепельных земель.","goal":1,"reward_type":"shards","reward":1}
]

static func spec(id: String) -> Dictionary:
    for item_variant: Variant in DAILY_POOL:
        var item: Dictionary = item_variant
        if str(item.get("id", "")) == id:
            return item.duplicate(true)
    return {}

static func ids() -> Array[String]:
    var out: Array[String] = []
    for item_variant: Variant in DAILY_POOL:
        out.append(str((item_variant as Dictionary).get("id", "")))
    return out

static func make_runtime(spec_data: Dictionary) -> Dictionary:
    return {
        "id": str(spec_data.get("id", "")),
        "category": str(spec_data.get("category", "general")),
        "event": str(spec_data.get("event", "")),
        "filter_key": str(spec_data.get("filter_key", "")),
        "filter_value": spec_data.get("filter_value", null),
        "title": str(spec_data.get("title", "ЗАДАНИЕ")),
        "desc": str(spec_data.get("desc", "")),
        "goal": int(spec_data.get("goal", 1)),
        "progress": 0,
        "reward_type": str(spec_data.get("reward_type", "coins")),
        "reward": int(spec_data.get("reward", 20)),
        "ready": false
    }
