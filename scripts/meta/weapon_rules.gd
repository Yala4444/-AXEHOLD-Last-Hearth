class_name WeaponRules
extends RefCounted

const WEAPONS := {
    "axes": {
        "name": "Топоры Странника",
        "icon": "🪓",
        "desc": "Надёжная круговая зона контроля. Чем плотнее враги подходят, тем выгоднее Топоры.",
        "identity": "КОНТРОЛЬ КРУГА",
        "signature": "Вихрь — непрерывно режет всех врагов в орбите.",
        "damage_mult": 1.00,
        "speed_mult": 1.00,
        "orbit_radius": 44.0,
        "axes": 1,
        "crit_bonus": 0.00,
        "style": "axes",
        "attack_cooldown": 0.0,
        "attack_range": 52.0,
        "damage_factor": 1.30,
        "harvest_mult": 1.00
    },
    "spear": {
        "name": "Копьё Корней",
        "icon": "🗡️",
        "desc": "Дальнобойные автоматические выпады. Лучшее оружие для коридоров и безопасной дистанции.",
        "identity": "ЛИНИЯ И ПРОБИТИЕ",
        "signature": "Корневой выпад — пронзает до трёх врагов на одной линии.",
        "damage_mult": 0.90,
        "speed_mult": 1.05,
        "orbit_radius": 70.0,
        "axes": 1,
        "crit_bonus": 0.04,
        "style": "spear",
        "attack_cooldown": 0.66,
        "attack_range": 116.0,
        "attack_width": 16.0,
        "damage_factor": 1.08,
        "pierce": 3,
        "harvest_mult": 0.90
    },
    "hammer": {
        "name": "Молот Инея",
        "icon": "🔨",
        "desc": "Медленный ритм и тяжёлые ударные волны. Нужно подпускать врагов ближе и ловить момент.",
        "identity": "ВЗРЫВНОЙ УДАР",
        "signature": "Ледяной раскол — периодический круговой удар с отбрасыванием.",
        "damage_mult": 1.55,
        "speed_mult": 0.90,
        "orbit_radius": 38.0,
        "axes": 1,
        "crit_bonus": 0.00,
        "style": "hammer",
        "attack_cooldown": 0.98,
        "attack_range": 62.0,
        "damage_factor": 0.92,
        "knockback": 18.0,
        "harvest_mult": 1.08
    },
    "twin_blades": {
        "name": "Пепельные клинки",
        "icon": "⚔️",
        "desc": "Очень близкая дистанция и серия быстрых ударов. Непрерывная агрессия разгоняет комбо.",
        "identity": "РИСК И КОМБО",
        "signature": "Пепельная серия — комбо усиливает каждый следующий короткий удар.",
        "damage_mult": 0.82,
        "speed_mult": 1.12,
        "orbit_radius": 36.0,
        "axes": 2,
        "crit_bonus": 0.10,
        "style": "twin_blades",
        "attack_cooldown": 0.20,
        "attack_range": 50.0,
        "damage_factor": 0.30,
        "targets": 2,
        "combo_cap": 6,
        "combo_step": 0.06,
        "harvest_mult": 0.95
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

static func mechanic_value(id: String, key: String, fallback: float = 0.0) -> float:
    return float(profile(id).get(key, fallback))

static func mechanic_int(id: String, key: String, fallback: int = 0) -> int:
    return int(profile(id).get(key, fallback))

static func identity_text(id: String) -> String:
    return str(profile(id).get("identity", ""))

static func signature_text(id: String) -> String:
    return str(profile(id).get("signature", ""))
