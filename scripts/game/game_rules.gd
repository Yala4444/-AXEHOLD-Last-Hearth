class_name GameRules
extends RefCounted

const BIOMES := [
    {
        "id":"forest",
        "name":"Забытый лес",
        "difficulty":1.0,
        "enemy":"755b76",
        "sky":"80936c",
        "ground":"5e795c",
        "reward":1,
        "boss_name":"Лесной Хранитель",
        "rule":"Много дерева. Стаи ускоряются рядом друг с другом, а старые корни могут ожить прямо под ногами.",
        "night_speed":1.0,
        "enemy_weights":{"normal":0.52,"runner":0.16,"brute":0.14,"stalker":0.12,"guardian":0.06}
    },
    {
        "id":"frost",
        "name":"Морозная лощина",
        "difficulty":1.18,
        "enemy":"577086",
        "sky":"819ea5",
        "ground":"69898e",
        "reward":1,
        "boss_name":"Ледяной Страж",
        "rule":"Больше камня. Морозные удары замедляют героя, белые бури меняют безопасный маршрут.",
        "night_speed":0.90,
        "enemy_weights":{"normal":0.40,"runner":0.27,"brute":0.10,"stalker":0.17,"guardian":0.06}
    },
    {
        "id":"ash",
        "name":"Пепельные земли",
        "difficulty":1.40,
        "enemy":"783f46",
        "sky":"9a6b5a",
        "ground":"72473e",
        "reward":2,
        "boss_name":"Пепельный Тиран",
        "rule":"Больше руды. Тяжёлые враги оставляют жар после смерти, а разломы давят на позиционирование.",
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
        "cost":{"wood":14,"stone":0,"ore":0},
        "effect":"Замедляет врагов • -65% урон Очагу"
    },
    {
        "id":"forge","name":"КУЗНИЦА","offset":Vector2(118,92),
        "cost":{"wood":14,"stone":6,"ore":0},
        "effect":"+30% урон • +6 радиус атаки"
    },
    {
        "id":"turret","name":"БАШНЯ","offset":Vector2(0,-136),
        "cost":{"wood":22,"stone":13,"ore":5},
        "effect":"Снимает часть давления ночью · уязвима к Сталкерам"
    },
    {
        "id":"shrine","name":"СВЯТИЛИЩЕ","offset":Vector2(118,-88),
        "cost":{"wood":12,"stone":9,"ore":4},
        "effect":"Лечит героя • восстанавливает Очаг"
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
    {"id":"bag","icon":"BAG","name":"Сборщик","desc":"+8 вместимости","category":"utility"},
    {"id":"harvest_heal","icon":"SAP","name":"Живой запас","desc":"Каждая полностью добытая точка лечит 3 HP","category":"survival"},
    {"id":"hearth_aura","icon":"FIRE","name":"Клятва Очага","desc":"+35% урона вблизи Последнего Очага","category":"offense"},
    {"id":"loaded_pack","icon":"LOAD","name":"Тяжёлая ноша","desc":"+25% урона при рюкзаке 75%+","category":"offense"},
    {"id":"hunter_rhythm","icon":"HUNT","name":"Ритм охоты","desc":"Каждые 10 убийств лечат 12 HP","category":"survival"},
    {"id":"fire_orb","icon":"ORB","name":"Огненная сфера","desc":"Вокруг героя вращается сфера, обжигающая ближайших врагов","category":"relic"},
    {"id":"frost_aura","icon":"ICE","name":"Холодный круг","desc":"Ледяная аура замедляет врагов рядом с героем","category":"relic"},
    {"id":"thorn_ring","icon":"THR","name":"Кольцо шипов","desc":"Периодически выпускает поражающую волну вокруг героя","category":"relic"},
    {"id":"guardian_spirit","icon":"SPT","name":"Дух Хранителя","desc":"Летающий дух периодически восстанавливает защитный заряд","category":"relic"}
]

const WEAPON_PERKS := [
    {"id":"axes_whirl","icon":"AXE","name":"Плотный вихрь","desc":"+18% урона Вихря","category":"weapon","weapon":"axes"},
    {"id":"axes_edge","icon":"AXE","name":"Широкий обод","desc":"+8 радиуса и +5% крита","category":"weapon","weapon":"axes"},
    {"id":"spear_pierce","icon":"SPR","name":"Разветвлённый корень","desc":"Корневой выпад пробивает ещё 1 цель","category":"weapon","weapon":"spear"},
    {"id":"spear_impale","icon":"SPR","name":"Глубокий прокол","desc":"+22% урона Корневого выпада","category":"weapon","weapon":"spear"},
    {"id":"hammer_crater","icon":"HAM","name":"Широкий кратер","desc":"+14 радиуса Ледяного раскола","category":"weapon","weapon":"hammer"},
    {"id":"hammer_force","icon":"HAM","name":"Ледяное ядро","desc":"+22% урона ударной волны","category":"weapon","weapon":"hammer"},
    {"id":"blades_chain","icon":"TWN","name":"Длинная серия","desc":"+2 к максимуму комбо","category":"weapon","weapon":"twin_blades"},
    {"id":"blades_fury","icon":"TWN","name":"Жар серии","desc":"+3% урона за каждый уровень комбо","category":"weapon","weapon":"twin_blades"}
]

const NIGHT_MODIFIERS := [
    {
        "id":"swarm","name":"ГОЛОДНАЯ НОЧЬ",
        "desc":"Из тьмы идёт больше быстрых существ.",
        "min_wave":1,"enemy_mult":1.28,"spawn_interval_mult":0.86,
        "enemy_hp_mult":0.88,"enemy_damage_mult":0.92,"enemy_speed_mult":1.05,
        "tower_damage_mult":1.0,"tower_fire_mult":1.0,"reward_mult":1.05,
        "bias":"runner"
    },
    {
        "id":"siege","name":"ОСАДА",
        "desc":"Тяжёлые твари давят на Очаг. Башня одна их не остановит.",
        "min_wave":1,"enemy_mult":0.96,"spawn_interval_mult":1.05,
        "enemy_hp_mult":1.12,"enemy_damage_mult":1.10,"enemy_speed_mult":0.96,
        "tower_damage_mult":0.92,"tower_fire_mult":1.0,"reward_mult":1.12,
        "bias":"brute"
    },
    {
        "id":"black_wind","name":"ЧЁРНЫЙ ВЕТЕР",
        "desc":"Башня стреляет реже, а враги быстрее пересекают темноту.",
        "min_wave":2,"enemy_mult":1.0,"spawn_interval_mult":0.95,
        "enemy_hp_mult":1.0,"enemy_damage_mult":1.0,"enemy_speed_mult":1.12,
        "tower_damage_mult":0.88,"tower_fire_mult":1.35,"reward_mult":1.12,
        "bias":"stalker"
    },
    {
        "id":"blood_tide","name":"КРОВАВЫЙ ПРИЛИВ",
        "desc":"Враги крепче и опаснее, но ночь приносит больше монет.",
        "min_wave":2,"enemy_mult":1.08,"spawn_interval_mult":0.94,
        "enemy_hp_mult":1.18,"enemy_damage_mult":1.14,"enemy_speed_mult":1.02,
        "tower_damage_mult":1.0,"tower_fire_mult":1.0,"reward_mult":1.34,
        "bias":"guardian"
    },
    {
        "id":"quiet_dark","name":"ТИХАЯ ТЬМА",
        "desc":"Врагов меньше, но каждый из них заметно крепче.",
        "min_wave":1,"enemy_mult":0.76,"spawn_interval_mult":1.18,
        "enemy_hp_mult":1.38,"enemy_damage_mult":1.08,"enemy_speed_mult":0.98,
        "tower_damage_mult":1.0,"tower_fire_mult":1.0,"reward_mult":1.10,
        "bias":"normal"
    }
]

const RUN_CONTRACTS := [
    {
        "id":"nest_hunter","name":"ОХОТНИК НА ГНЁЗДА",
        "desc":"Уничтожь 2 гнезда до второй ночи.",
        "reward":24,"renown":2,"risk":"СРЕДНИЙ"
    },
    {
        "id":"outer_reach","name":"ДАЛЬНИЙ ВЫХОД",
        "desc":"Доберись до внешнего кольца мира до второй ночи.",
        "reward":20,"renown":1,"risk":"НИЗКИЙ"
    },
    {
        "id":"lean_defense","name":"СКУПАЯ ОБОРОНА",
        "desc":"Переживи первую ночь, построив не больше одного сооружения.",
        "reward":26,"renown":2,"risk":"СРЕДНИЙ"
    },
    {
        "id":"scavenger","name":"ИСКАТЕЛЬ",
        "desc":"Разбери 3 события мира до второй ночи.",
        "reward":22,"renown":1,"risk":"НИЗКИЙ"
    },
    {
        "id":"no_tower","name":"СВОИМИ СИЛАМИ",
        "desc":"Переживи первую ночь без Башни.",
        "reward":28,"renown":2,"risk":"ВЫСОКИЙ"
    },
    {
        "id":"hearthkeeper","name":"ХРАНИТЕЛЬ ОЧАГА",
        "desc":"Заверши экспедицию, сохранив не меньше 75% прочности Очагa.",
        "reward":34,"renown":3,"risk":"ВЫСОКИЙ"
    },
    {
        "id":"rekindle","name":"ИСКРА СТАРОГО МИРА",
        "desc":"Найди и зажги погасший Очаг до третьей ночи.",
        "reward":30,"renown":2,"risk":"СРЕДНИЙ"
    }
]

const DAWN_DOCTRINES := [
    {"id":"hunt","name":"ОХОТА","desc":"+16% урона и +4% крита"},
    {"id":"fortify","name":"УКРЕПЛЕНИЕ","desc":"+70 прочности и ремонт Очагa"},
    {"id":"supply","name":"СНАБЖЕНИЕ","desc":"+6 к рюкзаку и припасы"},
    {"id":"scout","name":"РАЗВЕДКА","desc":"+10% скорость и меньше Угроза Тьмы"},
    {"id":"gather","name":"СБОР","desc":"+18% добычи и +2 к рюкзаку"},
    {"id":"embers","name":"ХРАНИТЕЛЬ ОГНЯ","desc":"Лечение героя и сильный ремонт Очагa"},
    {"id":"overwatch","name":"ДОЗОР","desc":"Башня стреляет быстрее и сильнее"}
]

static func random_night_modifier(wave: int, threat: float = 0.0) -> Dictionary:
    var pool: Array[Dictionary] = []
    for spec_variant: Variant in NIGHT_MODIFIERS:
        var spec: Dictionary = spec_variant
        if wave >= int(spec.get("min_wave", 1)):
            pool.append(spec.duplicate(true))
    if pool.is_empty():
        return NIGHT_MODIFIERS[0].duplicate(true)

    # High threat makes the harsher modifiers more likely without secretly
    # scaling enemy HP behind the player's back.
    if threat >= 6.0 and wave >= 2:
        for spec_variant: Variant in NIGHT_MODIFIERS:
            var spec: Dictionary = spec_variant
            if str(spec.get("id", "")) in ["siege", "black_wind", "blood_tide"]:
                pool.append(spec.duplicate(true))
    return pool[randi() % pool.size()].duplicate(true)

static func random_contract() -> Dictionary:
    return RUN_CONTRACTS[randi() % RUN_CONTRACTS.size()].duplicate(true)

static func contract_by_id(contract_id: String) -> Dictionary:
    for spec_variant: Variant in RUN_CONTRACTS:
        var spec: Dictionary = spec_variant
        if str(spec.get("id", "")) == contract_id:
            return spec.duplicate(true)
    return {}

static func contract_ids() -> Array[String]:
    var ids: Array[String] = []
    for spec_variant: Variant in RUN_CONTRACTS:
        var spec: Dictionary = spec_variant
        ids.append(str(spec.get("id", "")))
    return ids

static func contract_risk(contract_id: String) -> String:
    return str(contract_by_id(contract_id).get("risk", "СРЕДНИЙ"))

static func contract_renown(contract_id: String) -> int:
    return int(contract_by_id(contract_id).get("renown", 1))

static func random_doctrines(count: int = 3) -> Array[Dictionary]:
    var pool: Array[Dictionary] = []
    for spec_variant: Variant in DAWN_DOCTRINES:
        pool.append((spec_variant as Dictionary).duplicate(true))
    pool.shuffle()
    var result: Array[Dictionary] = []
    for i: int in range(mini(count, pool.size())):
        result.append(pool[i])
    return result

static func biome_event_name(index: int) -> String:
    match clampi(index, 0, 2):
        1:
            return "БЕЛАЯ БУРЯ"
        2:
            return "РАЗЛОМ ЖАРА"
        _:
            return "КОРНИ ПРОБУЖДАЮТСЯ"

static func regional_target_name(index: int) -> String:
    match clampi(index, 0, 2):
        1:
            return "БЕЛЫЙ ОХОТНИК"
        2:
            return "ПЕПЕЛЬНЫЙ СЕЯТЕЛЬ"
        _:
            return "ВОЖАК КОРНЕЙ"

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
            return 64.0
        1:
            return 58.0
        2:
            return 52.0
        _:
            return 46.0

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

static func random_perks(count: int = 3, weapon_id: String = "") -> Array:
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
    if not weapon_id.is_empty():
        var weapon_pool: Array[Dictionary] = []
        for perk_variant: Variant in WEAPON_PERKS:
            var perk: Dictionary = perk_variant
            if str(perk.get("weapon", "")) == weapon_id:
                weapon_pool.append(perk.duplicate(true))
        _append_random_unique(result, weapon_pool)

    if result.size() < count:
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
