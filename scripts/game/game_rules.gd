class_name GameRules
extends RefCounted

const BIOMES := [
    {
        "id":"forest",
        "name":"Забытый лес",
        "difficulty":1.0,
        "enemy":"755b76",
        "sky":"b9cf8d",
        "ground":"7fa268",
        "reward":1,
        "boss_name":"Лесной Хранитель",
        "rule":"Много дерева, спокойный старт и смешанные угрозы.",
        "night_speed":1.0,
        "enemy_weights":{"normal":0.52,"runner":0.16,"brute":0.14,"stalker":0.12,"guardian":0.06}
    },
    {
        "id":"frost",
        "name":"Морозная лощина",
        "difficulty":1.18,
        "enemy":"577086",
        "sky":"b9d3d6",
        "ground":"709ca7",
        "reward":1,
        "boss_name":"Ледяной Страж",
        "rule":"Больше камня. Ночью холод замедляет героя, а Сталкеры давят рывками.",
        "night_speed":0.90,
        "enemy_weights":{"normal":0.40,"runner":0.27,"brute":0.10,"stalker":0.17,"guardian":0.06}
    },
    {
        "id":"ash",
        "name":"Пепельные земли",
        "difficulty":1.40,
        "enemy":"783f46",
        "sky":"c99b7d",
        "ground":"8f5145",
        "reward":2,
        "boss_name":"Пепельный Тиран",
        "rule":"Больше руды. Тяжёлые и бронированные враги проверяют развитый лагерь.",
        "night_speed":1.0,
        "enemy_weights":{"normal":0.38,"runner":0.08,"brute":0.25,"stalker":0.09,"guardian":0.20}
    }
]

const SKINS := [
    {"body":"466bc8","cape":"364f9c"},
    {"body":"4f8b65","cape":"375f48"},
    {"body":"5c7f9c","cape":"3d586f"},
    {"body":"9a5a4b","cape":"61382f"}
]

const BUILD_SPECS := [
    {
        "id":"wall","name":"ПАЛИСАД","offset":Vector2(-118,92),
        "cost":{"wood":12,"stone":0,"ore":0},
        "effect":"Замедляет врагов у Очага и снижает урон базе на 65%."
    },
    {
        "id":"forge","name":"КУЗНИЦА","offset":Vector2(118,92),
        "cost":{"wood":12,"stone":5,"ore":0},
        "effect":"+30% урона оружия и +6 к радиусу атаки."
    },
    {
        "id":"turret","name":"БАШНЯ","offset":Vector2(0,-136),
        "cost":{"wood":15,"stone":8,"ore":2},
        "effect":"Автоматически стреляет по ближайшему врагу всю ночь."
    },
    {
        "id":"shrine","name":"СВЯТИЛИЩЕ","offset":Vector2(118,-88),
        "cost":{"wood":10,"stone":8,"ore":3},
        "effect":"Лечит героя и постепенно восстанавливает прочность Очага."
    }
]

const PERKS := [
    {"id":"axe","icon":"X2","name":"Вихрь стали","desc":"+1 вращающееся оружие","category":"offense"},
    {"id":"damage","icon":"DMG","name":"Острые лезвия","desc":"+22% урона","category":"offense"},
    {"id":"crit","icon":"CRT","name":"Точный удар","desc":"+12% шанс двойного урона","category":"offense"},
    {"id":"hp","icon":"HP","name":"Живучесть","desc":"+25 HP и лечение","category":"survival"},
    {"id":"shield","icon":"SHD","name":"Оберег","desc":"Щит на 3 удара","category":"survival"},
    {"id":"orbit","icon":"RNG","name":"Широкая дуга","desc":"+16% радиуса атаки","category":"utility"},
    {"id":"speed","icon":"SPD","name":"Лёгкие сапоги","desc":"+14% скорости","category":"utility"},
    {"id":"bag","icon":"BAG","name":"Сборщик","desc":"+8 вместимости","category":"utility"}
]

static func biome(index: int) -> Dictionary:
    return BIOMES[clampi(index, 0, BIOMES.size() - 1)].duplicate(true)

static func skin(index: int) -> Dictionary:
    return SKINS[clampi(index, 0, SKINS.size() - 1)].duplicate(true)

static func build_spec(id: String) -> Dictionary:
    for spec_variant: Variant in BUILD_SPECS:
        var spec: Dictionary = spec_variant
        if str(spec.get("id", "")) == id:
            return spec.duplicate(true)
    return {}

static func build_effect(id: String) -> String:
    return str(build_spec(id).get("effect", ""))

static func day_duration(wave: int) -> float:
    match wave:
        0:
            return 58.0
        1:
            return 52.0
        2:
            return 46.0
        _:
            return 42.0

static func wave_count(wave: int, difficulty: float) -> int:
    var base_count: int = 8
    match wave:
        1:
            base_count = 8
        2:
            base_count = 11
        _:
            base_count = 15
    return maxi(1, int(round(float(base_count) * difficulty)))

static func resource_yield(kind: String, biome_index: int) -> int:
    if kind == "tree":
        return 5 if biome_index == 0 else 4
    if kind == "rock":
        return 5 if biome_index == 1 else 4
    return 4 if biome_index == 2 else 3

static func harvest_multiplier(kind: String) -> float:
    if kind == "tree":
        return 1.62
    if kind == "rock":
        return 1.04
    return 0.78

static func random_enemy_type() -> String:
    return enemy_type_for_biome(0)

static func enemy_type_for_biome(index: int) -> String:
    var data: Dictionary = biome(index)
    var weights: Dictionary = data.get("enemy_weights", {"normal":1.0})
    var roll: float = randf()
    var cumulative: float = 0.0
    var order: Array[String] = ["runner", "brute", "stalker", "guardian", "normal"]
    for kind: String in order:
        cumulative += float(weights.get(kind, 0.0))
        if roll <= cumulative:
            return kind
    return "normal"

static func random_perks(count: int = 3) -> Array:
    var offense: Array[Dictionary] = []
    var survival: Array[Dictionary] = []
    var utility: Array[Dictionary] = []
    var all_perks: Array[Dictionary] = []

    for perk_variant: Variant in PERKS:
        var perk: Dictionary = perk_variant
        var perk_copy: Dictionary = perk.duplicate(true)
        all_perks.append(perk_copy)
        match str(perk.get("category", "utility")):
            "offense":
                offense.append(perk_copy)
            "survival":
                survival.append(perk_copy)
            _:
                utility.append(perk_copy)

    var result: Array = []
    _append_random_unique(result, offense)
    if result.size() < count:
        _append_random_unique(result, survival)
    if result.size() < count:
        _append_random_unique(result, utility)

    all_perks.shuffle()
    for perk: Dictionary in all_perks:
        if result.size() >= count:
            break
        var already_added: bool = false
        for selected_variant: Variant in result:
            var selected: Dictionary = selected_variant
            if str(selected.get("id", "")) == str(perk.get("id", "")):
                already_added = true
                break
        if not already_added:
            result.append(perk.duplicate(true))
    return result

static func _append_random_unique(result: Array, pool: Array[Dictionary]) -> void:
    if pool.is_empty():
        return
    var index: int = randi() % pool.size()
    result.append(pool[index].duplicate(true))
