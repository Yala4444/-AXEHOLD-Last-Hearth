class_name WeaponRules
extends RefCounted

const WEAPONS := {
    "axes": {
        "name": "Топоры Странника",
        "icon": "🪓",
        "desc": "Сбалансированное оружие с вращающейся зоной контроля.",
        "damage_mult": 1.00,
        "speed_mult": 1.00,
        "orbit_radius": 44.0,
        "axes": 1,
        "crit_bonus": 0.00,
        "style": "axes"
    },
    "spear": {
        "name": "Копьё Корней",
        "icon": "🗡️",
        "desc": "Большая дистанция и безопасный контроль пространства.",
        "damage_mult": 0.90,
        "speed_mult": 1.05,
        "orbit_radius": 70.0,
        "axes": 1,
        "crit_bonus": 0.04,
        "style": "spear"
    },
    "hammer": {
        "name": "Молот Инея",
        "icon": "🔨",
        "desc": "Медленнее, но каждый проход оружия наносит тяжёлый урон.",
        "damage_mult": 1.55,
        "speed_mult": 0.90,
        "orbit_radius": 38.0,
        "axes": 1,
        "crit_bonus": 0.00,
        "style": "hammer"
    },
    "twin_blades": {
        "name": "Пепельные клинки",
        "icon": "⚔️",
        "desc": "Быстрый агрессивный стиль: две короткие дуги и высокий шанс крита.",
        "damage_mult": 0.82,
        "speed_mult": 1.12,
        "orbit_radius": 36.0,
        "axes": 2,
        "crit_bonus": 0.10,
        "style": "twin_blades"
    }
}

static func profile(id: String) -> Dictionary:
    var key: String = id if WEAPONS.has(id) else "axes"
    return (WEAPONS[key] as Dictionary).duplicate(true)

static func ordered_ids() -> Array[String]:
    return ["axes", "spear", "hammer", "twin_blades"]

static func unlock_for_biome(biome_index: int) -> String:
    match biome_index:
        0:
            return "spear"
        1:
            return "hammer"
        2:
            return "twin_blades"
    return ""

static func relic_name(biome_index: int) -> String:
    match biome_index:
        0:
            return "Сердце Корней"
        1:
            return "Осколок Вечной Зимы"
        2:
            return "Ядро Пепельного Тирана"
    return "Неизвестная реликвия"

static func camp_title(total_mastery: int) -> String:
    if total_mastery >= 9:
        return "Крепость Последнего Огня"
    if total_mastery >= 5:
        return "Укреплённый Оплот"
    if total_mastery >= 2:
        return "Живой Лагерь"
    return "Последний Очаг"

static func mastery_bonus_text(wins: int) -> String:
    if wins >= 5:
        return "★★★★★"
    if wins >= 4:
        return "★★★★☆"
    if wins >= 3:
        return "★★★☆☆"
    if wins >= 2:
        return "★★☆☆☆"
    if wins >= 1:
        return "★☆☆☆☆"
    return "☆☆☆☆☆"
