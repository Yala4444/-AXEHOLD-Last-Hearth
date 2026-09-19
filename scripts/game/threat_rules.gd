class_name ThreatRules
extends RefCounted

const MAX_LEVEL := 5

const LEVELS: Array[Dictionary] = [
    {"level":1,"name":"ПУТЬ СТРАННИКА","enemy_hp":1.00,"enemy_damage":1.00,"enemy_speed":1.00,"spawn":1.00,"boss_hp":1.00,"reward":1.00,"desc":"Базовая экспедиция. Изучи регион и Хранителя."},
    {"level":2,"name":"ТЬМА ПРОСЫПАЕТСЯ","enemy_hp":1.18,"enemy_damage":1.10,"enemy_speed":1.04,"spawn":1.12,"boss_hp":1.20,"reward":1.30,"desc":"Больше врагов и элит. Хранитель становится опаснее."},
    {"level":3,"name":"ЗЕМЛЯ СОПРОТИВЛЯЕТСЯ","enemy_hp":1.38,"enemy_damage":1.22,"enemy_speed":1.08,"spawn":1.24,"boss_hp":1.45,"reward":1.62,"desc":"Региональные угрозы усиливаются. Ошибки заметно дороже."},
    {"level":4,"name":"ОСАДА","enemy_hp":1.64,"enemy_damage":1.38,"enemy_speed":1.13,"spawn":1.38,"boss_hp":1.78,"reward":2.05,"desc":"Элиты, плотные ночи и серьёзное давление на постройки."},
    {"level":5,"name":"КОШМАР РЕГИОНА","enemy_hp":1.95,"enemy_damage":1.58,"enemy_speed":1.18,"spawn":1.55,"boss_hp":2.20,"reward":2.55,"desc":"Максимальная ручная сложность. Редкие награды и усиленный Хранитель."}
]

static func spec(level: int) -> Dictionary:
    var safe: int = clampi(level,1,MAX_LEVEL)
    return LEVELS[safe-1].duplicate(true)

static func reward_multiplier(level: int) -> float:
    return float(spec(level).get("reward",1.0))

static func first_clear_reward(level: int) -> Dictionary:
    match clampi(level,1,MAX_LEVEL):
        2:
            return {"coins":90,"shards":0}
        3:
            return {"coins":130,"shards":1}
        4:
            return {"coins":190,"shards":0}
        5:
            return {"coins":280,"shards":2}
        _:
            return {"coins":45,"shards":0}

static func stars(level: int) -> String:
    var out := ""
    for i: int in range(MAX_LEVEL):
        out += "★" if i < clampi(level,0,MAX_LEVEL) else "☆"
    return out

static func endless_enemy_hp(wave: int) -> float:
    return 1.0 + maxf(0.0,float(wave-1))*0.12 + floor(float(maxi(0,wave-1))/5.0)*0.14

static func endless_enemy_damage(wave: int) -> float:
    return 1.0 + maxf(0.0,float(wave-1))*0.075 + floor(float(maxi(0,wave-1))/5.0)*0.08

static func endless_enemy_speed(wave: int) -> float:
    return minf(1.38,1.0 + maxf(0.0,float(wave-1))*0.018)

static func endless_spawn_multiplier(wave: int) -> float:
    return 1.0 + maxf(0.0,float(wave-1))*0.075

static func endless_reward_multiplier(wave: int) -> float:
    return 1.0 + maxf(0.0,float(wave-1))*0.11

static func endless_is_boss_wave(wave: int) -> bool:
    return wave > 0 and wave % 5 == 0

static func endless_title(wave: int) -> String:
    if wave < 5:
        return "ПЕРВЫЙ НАТИСК"
    if wave < 10:
        return "ТЬМА СГУЩАЕТСЯ"
    if wave < 15:
        return "ОСАДА ПОСЛЕДНЕГО ОГНЯ"
    if wave < 20:
        return "БЕЗДНА СМОТРИТ В ОТВЕТ"
    return "ПРЕДЕЛ ТЬМЫ"
