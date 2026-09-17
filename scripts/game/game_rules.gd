class_name GameRules
extends RefCounted

const BIOMES := [
    {"name":"Забытый лес","difficulty":1.0,"enemy":"6c5574","sky":"dceabc","ground":"9fc77c","reward":1},
    {"name":"Морозная лощина","difficulty":1.18,"enemy":"577086","sky":"dcebed","ground":"8db8c3","reward":1},
    {"name":"Пепельные земли","difficulty":1.40,"enemy":"783f46","sky":"dfbea6","ground":"a66652","reward":2}
]

const SKINS := [
    {"body":"466bc8","cape":"364f9c"},
    {"body":"4f8b65","cape":"375f48"},
    {"body":"5c7f9c","cape":"3d586f"},
    {"body":"9a5a4b","cape":"61382f"}
]

const BUILD_SPECS := [
    {"id":"wall","name":"ЗАБОР","offset":Vector2(-118,92),"cost":{"wood":16,"stone":0,"ore":0}},
    {"id":"forge","name":"КУЗНИЦА","offset":Vector2(118,92),"cost":{"wood":20,"stone":8,"ore":2}},
    {"id":"turret","name":"ТУРЕЛЬ","offset":Vector2(0,-136),"cost":{"wood":24,"stone":13,"ore":4}},
    {"id":"shrine","name":"СВЯТИЛИЩЕ","offset":Vector2(118,-88),"cost":{"wood":14,"stone":12,"ore":5}}
]

const PERKS := [
    {"id":"axe","icon":"🪓","name":"Вихрь стали","desc":"+1 вращающийся топор"},
    {"id":"damage","icon":"⚔️","name":"Острые лезвия","desc":"+22% урона"},
    {"id":"orbit","icon":"🌀","name":"Широкая дуга","desc":"+16% радиуса"},
    {"id":"speed","icon":"👢","name":"Лёгкие сапоги","desc":"+14% скорости"},
    {"id":"hp","icon":"❤️","name":"Живучесть","desc":"+25 HP и лечение"},
    {"id":"bag","icon":"🎒","name":"Сборщик","desc":"+8 вместимости"},
    {"id":"crit","icon":"💥","name":"Точный удар","desc":"+12% шанс двойного урона"},
    {"id":"shield","icon":"🛡️","name":"Оберег","desc":"Щит на 3 удара"}
]

static func biome(index: int) -> Dictionary:
    return BIOMES[clampi(index, 0, BIOMES.size() - 1)].duplicate(true)

static func skin(index: int) -> Dictionary:
    return SKINS[clampi(index, 0, SKINS.size() - 1)].duplicate(true)

static func day_duration(wave: int) -> float:
    return maxf(20.0, 28.0 - max(0, wave - 1) * 3.0)

static func wave_count(wave: int, difficulty: float) -> int:
    return int(round((6 + wave * 4) * difficulty))

static func resource_yield(kind: String, biome_index: int) -> int:
    if kind == "tree":
        return 5 if biome_index == 0 else 4
    if kind == "rock":
        return 4 if biome_index == 1 else 3
    return 3 if biome_index == 2 else 2

static func harvest_multiplier(kind: String) -> float:
    if kind == "tree": return 1.45
    if kind == "rock": return 0.90
    return 0.65

static func random_enemy_type() -> String:
    var roll := randf()
    if roll < 0.18: return "brute"
    if roll < 0.36: return "runner"
    return "normal"

static func random_perks(count: int = 3) -> Array:
    var pool := PERKS.duplicate(true)
    pool.shuffle()
    return pool.slice(0, mini(count, pool.size()))
