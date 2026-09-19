class_name BuildcraftDirector
extends Node

var world: GameWorld
var choices_taken: int = 0
var rarity_counts: Dictionary = {"common":0, "rare":0, "epic":0, "legendary":0}
var legendary_offered: bool = false

func setup(world_ref: GameWorld) -> void:
    world = world_ref

func roll_choices(count: int, level: int) -> Array[Dictionary]:
    var pool: Array[Dictionary] = []
    for spec_variant: Variant in GameRules.PERKS:
        var spec: Dictionary = (spec_variant as Dictionary).duplicate(true)
        if _eligible(spec):
            pool.append(spec)

    if world != null and world.player != null:
        for spec_variant: Variant in GameRules.WEAPON_PERKS:
            var spec: Dictionary = spec_variant
            if str(spec.get("weapon","")) == world.player.weapon_id and _eligible(spec):
                pool.append(spec.duplicate(true))

    var result: Array[Dictionary] = []
    var focus_family: String = _focus_family()
    if not focus_family.is_empty():
        var focused: Array[Dictionary] = []
        for spec: Dictionary in pool:
            if GameRules.perk_family(str(spec.get("id",""))) == focus_family:
                focused.append(spec)
        if not focused.is_empty():
            focused.shuffle()
            var focus_pick: Dictionary = focused[0].duplicate(true)
            focus_pick["rarity"] = _rarity_for_slot(level, 0)
            result.append(focus_pick)

    pool.shuffle()
    for spec: Dictionary in pool:
        if result.size() >= count:
            break
        if _contains_id(result, str(spec.get("id",""))):
            continue
        var pick: Dictionary = spec.duplicate(true)
        pick["rarity"] = _rarity_for_slot(level, result.size())
        result.append(pick)

    # From level 5 onward, a legendary can break the rules of the run.
    # It is not guaranteed every run, but the chance rises quickly.
    var legendary_chance: float = clampf(0.20 + float(maxi(0, level - 5)) * 0.10, 0.20, 0.62)
    if level >= 5 and not legendary_offered and randf() < legendary_chance:
        var legendaries: Array[Dictionary] = []
        for spec: Dictionary in GameRules.legendary_pool():
            if world == null or world.player == null or not world.player.has_perk(str(spec.get("id",""))):
                legendaries.append(spec)
        if not legendaries.is_empty():
            legendaries.shuffle()
            var legendary: Dictionary = legendaries[0].duplicate(true)
            legendary["rarity"] = "legendary"
            if result.size() >= count and not result.is_empty():
                result[result.size() - 1] = legendary
            else:
                result.append(legendary)
    while result.size() > count:
        result.remove_at(result.size() - 1)
    return result

func _eligible(spec: Dictionary) -> bool:
    if world == null or world.player == null:
        return true
    var perk_id: String = str(spec.get("id",""))
    var count: int = world.player.perk_count(perk_id)
    if perk_id in ["fire_orb","frost_aura","thorn_ring","guardian_spirit"] and count >= 3:
        return false
    if count >= 4:
        return false
    return true

func _focus_family() -> String:
    if world == null or world.player == null:
        return ""
    var best_family: String = ""
    var best_count: int = 0
    for family: String in ["flame","steel","frost","guardian","hunt","roots"]:
        if world.player.has_evolution(family):
            continue
        var value: int = world.player.family_count(family)
        if value > best_count:
            best_count = value
            best_family = family
    return best_family if best_count >= 2 else ""

func _rarity_for_slot(level: int, slot: int) -> String:
    var roll: float = randf()
    if level >= 5 and slot == 1:
        if roll < 0.38:
            return "epic"
        if roll < 0.82:
            return "rare"
        return "common"
    if level >= 3 and slot == 0:
        return "rare" if roll < 0.72 else "common"
    if roll < 0.06 + float(maxi(0, level - 4)) * 0.025:
        return "epic"
    if roll < 0.28 + float(maxi(0, level - 2)) * 0.025:
        return "rare"
    return "common"

func choice_text(spec: Dictionary) -> String:
    var perk_id: String = str(spec.get("id",""))
    var rarity: String = str(spec.get("rarity","common"))
    var family: String = GameRules.perk_family(perk_id)
    var progress: int = 0
    if world != null and world.player != null and not family.is_empty():
        progress = world.player.family_count(family)

    var rarity_label: String = rarity_name(rarity)
    var header: String = "%s · %s" % [rarity_label, str(spec.get("name","УСИЛЕНИЕ"))]
    var body: String = str(spec.get("desc",""))
    if rarity != "legendary" and not family.is_empty():
        body += "\n%s %d/3 → эволюция" % [GameRules.family_name(family), mini(3, progress + 1)]
    return header + "\n" + body

func apply_choice(perk_id: String, rarity: String = "common", source: String = "level") -> Dictionary:
    if world == null or world.player == null:
        return {}

    var before: Dictionary = world.player.buildcraft_snapshot()
    world.player.apply_perk(perk_id)

    match rarity:
        "rare":
            world.player.damage *= 1.04
        "epic":
            world.player.damage *= 1.08
            world.player.max_hp += 6.0
            world.player.hp = minf(world.player.max_hp, world.player.hp + 6.0)
        "legendary":
            pass
        _:
            rarity = "common"

    choices_taken += 1
    rarity_counts[rarity] = int(rarity_counts.get(rarity,0)) + 1
    if rarity == "legendary":
        legendary_offered = true

    var after: Dictionary = world.player.buildcraft_snapshot()
    Analytics.event("buildcraft_pick", {
        "perk":perk_id,
        "rarity":rarity,
        "family":GameRules.perk_family(perk_id),
        "source":source,
        "level":world.player.level
    })
    return {
        "perk":GameRules.perk_spec(perk_id),
        "rarity":rarity,
        "before":before,
        "after":after,
        "identity":short_identity()
    }

func short_identity() -> String:
    if world == null or world.player == null:
        return "НЕСФОРМИРОВАННЫЙ БИЛД"
    var snapshot: Dictionary = world.player.buildcraft_snapshot()
    var evolutions: Array = snapshot.get("evolutions", [])
    if not evolutions.is_empty():
        var last: Dictionary = evolutions[evolutions.size()-1]
        return str(last.get("name","ЭВОЛЮЦИЯ"))

    var top_family: String = str(snapshot.get("top_family",""))
    if top_family.is_empty():
        return "БИЛД ФОРМИРУЕТСЯ"
    return "%s · %d/3" % [GameRules.family_name(top_family), world.player.family_count(top_family)]

func result_summary() -> Dictionary:
    if world == null or world.player == null:
        return {}
    var snapshot: Dictionary = world.player.buildcraft_snapshot()
    snapshot["choices"] = choices_taken
    snapshot["rarities"] = rarity_counts.duplicate(true)
    snapshot["identity"] = short_identity()
    return snapshot

func rarity_name(rarity: String) -> String:
    match rarity:
        "rare":
            return "РЕДКОЕ"
        "epic":
            return "ЭПИЧЕСКОЕ"
        "legendary":
            return "ЛЕГЕНДАРНОЕ"
        _:
            return "ОБЫЧНОЕ"

func _contains_id(items: Array[Dictionary], perk_id: String) -> bool:
    for item: Dictionary in items:
        if str(item.get("id","")) == perk_id:
            return true
    return false
