class_name GameRules
extends RefCounted

const BIOMES := [
    {
        "id":"forest",
        "name":"Забытый лес",
        "difficulty":1.0,
        "enemy":"6c5574",
        "sky":"dceabc",
        "ground":"9fc77c",
        "reward":1,
        "boss_name":"Лесной Хранитель",
        "rule":"Сбалансированный биом. Больше дерева, смешанные враги.",
        "night_speed":1.0,
        "enemy_weights":{"normal":0.64,"runner":0.18,"brute":0.18}
    },
    {
        "id":"frost",
        "name":"Морозная лощина",
        "difficulty":1.18,
        "enemy":"577086",
        "sky":"dcebed",
        "ground":"8db8c3",
        "reward":1,
        "boss_name":"Ледяной Страж",
        "rule":"Ночью холод замедляет героя. Больше бегунов и камня.",
        "night_speed":0.90,
        "enemy_weights":{"normal":0.56,"runner":0.32,"brute":0.12}
    },
    {
        "id":"ash",
        "name":"Пепельные земли",
        "difficulty":1.40,
        "enemy":"783f46",
        "sky":"dfbea6",
        "ground":"a66652",
        "reward":2,
        "boss_name":"Пепельный Тиран",
        "rule":"Ночью земля извергает огонь. Больше тяжёлых врагов и руды.",
        "night_speed":1.0,
        "enemy_weights":{"normal":0.56,"runner":0.12,"brute":0.32}
    }
]

const SKINS := [
    {"body":"466bc8","cape":"364f9c"},
    {"body":"4f8b65","cape":"375f48"},
    {"body":"5c7f9c","cape":"3d586f"},
    {"body":"9a5a4b","cape":"61382f"}
]

const BUILD_SPECS := [
    {"id":"wall","name":"ЗАБОР","offset":Vector2(-118,92),"cost":{"wood":14,"stone":0,"ore":0}},
    {"id":"forge","name":"КУЗНИЦА","offset":Vector2(118,92),"cost":{"wood":18,"stone":6,"ore":1}},
    {"id":"turret","name":"ТУРЕЛЬ","offset":Vector2(0,-136),"cost":{"wood":23,"stone":11,"ore":3}},
    {"id":"shrine","name":"СВЯТИЛИЩЕ","offset":Vector2(118,-88),"cost":{"wood":15,"stone":10,"ore":4}}
]

const PERKS := [
    {"id":"axe","icon":"🪓","name":"Вихрь стали","desc":"+1 вращающийся топор","category":"offense"},
    {"id":"damage","icon":"⚔️","name":"Острые лезвия","desc":"+22% урона","category":"offense"},
    {"id":"crit","icon":"💥","name":"Точный удар","desc":"+12% шанс двойного урона","category":"offense"},
    {"id":"hp","icon":"❤️","name":"Живучесть","desc":"+25 HP и лечение","category":"survival"},
    {"id":"shield","icon":"🛡️","name":"Оберег","desc":"Щит на 3 удара","category":"survival"},
    {"id":"orbit","icon":"🌀","name":"Широкая дуга","desc":"+16% радиуса атаки","category":"utility"},
    {"id":"speed","icon":"👢","name":"Лёгкие сапоги","desc":"+14% скорости","category":"utility"},
    {"id":"bag","icon":"🎒","name":"Сборщик","desc":"+8 вместимости","category":"utility"}
]

static func biome(index: int) -> Dictionary:
    return BIOMES[clampi(index, 0, BIOMES.size() - 1)].duplicate(true)

static func skin(index: int) -> Dictionary:
    return SKINS[clampi(index, 0, SKINS.size() - 1)].duplicate(true)

static func day_duration(wave: int) -> float:
    match wave:
        0:
            return 36.0
        1:
            return 31.0
        2:
            return 26.0
        _:
            return 24.0

static func wave_count(wave: int, difficulty: float) -> int:
    var base_count: int = 8
    match wave:
        1:
            base_count = 8
        2:
            base_count = 12
        _:
            base_count = 16
    return maxi(1, int(round(float(base_count) * difficulty)))

static func resource_yield(kind: String, biome_index: int) -> int:
    if kind == "tree":
        return 5 if biome_index == 0 else 4
    if kind == "rock":
        return 4 if biome_index == 1 else 3
    return 3 if biome_index == 2 else 2

static func harvest_multiplier(kind: String) -> float:
    if kind == "tree":
        return 1.52
    if kind == "rock":
        return 0.95
    return 0.70

static func random_enemy_type() -> String:
    return enemy_type_for_biome(0)

static func enemy_type_for_biome(index: int) -> String:
    var data: Dictionary = biome(index)
    var weights: Dictionary = data.get("enemy_weights", {"normal":0.64,"runner":0.18,"brute":0.18})
    var roll: float = randf()
    var runner_weight: float = float(weights.get("runner", 0.18))
    var brute_weight: float = float(weights.get("brute", 0.18))
    if roll < runner_weight:
        return "runner"
    if roll < runner_weight + brute_weight:
        return "brute"
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
