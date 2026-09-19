extends Node

const SAVE_PATH := "user://axehold_save.json"
const SAVE_VERSION := 13

var data: Dictionary = {}

func _ready() -> void:
    _load_save()
    ensure_daily_state()

func defaults() -> Dictionary:
    return {
        "save_version": SAVE_VERSION,
        "coins": 180,
        "shards": 0,
        "best_wave": 0,
        "wins": 0,
        "runs": 0,
        "selected_biome": 0,
        "tutorial_complete": false,
        "coach_complete": false,
        "upgrades": {"damage": 0, "hp": 0, "bag": 0, "speed": 0},
        "biome_wins": [0, 0, 0],
        "biome_mastery": [0, 0, 0],
        "boss_relics": [false, false, false],
        "weapons_owned": ["axes"],
        "selected_weapon": "axes",
        "weapon_mastery": {
            "axes":{"runs":0,"wins":0,"kills":0},
            "spear":{"runs":0,"wins":0,"kills":0},
            "hammer":{"runs":0,"wins":0,"kills":0},
            "twin_blades":{"runs":0,"wins":0,"kills":0}
        },
        "meta_notices": [],
        "lore_fragments": 0,
        "story_state": {
            "chapter": 1,
            "chapter1_ready_notified": false,
            "chapter1_seen": false,
            "chapter1_claimed": false
        },
        "camp_renown": 0,
        "contract_state": {
            "date":"",
            "offers":[],
            "selected":"",
            "completed_today":[],
            "completed_total":0
        },
        "dynamic_world_stats": {
            "events":0,
            "failures":0,
            "elites":0,
            "rescues":0,
            "chains":0
        },
        "biome_event_stats": {
            "forest":{"events":0,"perfect":0,"hunts":0},
            "frost":{"events":0,"perfect":0,"hunts":0},
            "ash":{"events":0,"perfect":0,"hunts":0}
        },
        "field_objective_stats": {
            "completed":0,
            "failed":0,
            "perfect":0
        },
        "threat_unlocked": [1,1,1],
        "threat_clears": [
            [false,false,false,false,false],
            [false,false,false,false,false],
            [false,false,false,false,false]
        ],
        "selected_threat": 1,
        "run_mode": "expedition",
        "endless_stats": {
            "runs":0,
            "best_wave":0,
            "best_kills":0,
            "best_coins":0
        },
        "relic_forge": {
            "power":0,
            "ward":0,
            "fortune":0
        },
        "skins_owned": [true, false, false, false],
        "selected_skin": 0,
        "daily_date": "",
        "supply_claimed": false,
        "settings": {"sound": true, "haptics": true, "hints": true},
        "stats": {"kills": 0, "trees": 0, "builds": 0},
        "missions": {
            "trees": {"value": 0, "goal": 12, "reward": 30, "claimed": false},
            "kills": {"value": 0, "goal": 18, "reward": 45, "claimed": false},
            "builds": {"value": 0, "goal": 2, "reward": 35, "claimed": false}
        },
        "trophies_claimed": [],
        "quest_state": {"date":"", "active":[], "used_ids":[], "claimed_today":0, "archive":0},
        "building_projects": {"wall": false, "forge": false, "turret": false, "shrine": false},
        "residents": {
            "mira": {"unlocked": false, "trust": 0, "quest_step": 0, "quest_progress": 0},
            "thorn": {"unlocked": false, "trust": 0, "quest_step": 0, "quest_progress": 0}
        }
    }

func _load_save() -> void:
    data = defaults()
    if not FileAccess.file_exists(SAVE_PATH):
        save()
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        _merge_dictionary(data, parsed)
        _migrate_save()

func _migrate_save() -> void:
    var version: int = int(data.get("save_version", 1))
    if version < 2:
        data["daily_date"] = ""
        data["tutorial_complete"] = false
    if version < 3:
        data["coach_complete"] = false
    if version < 4:
        _retrofit_meta_progression()
    if version < 5:
        data["quest_state"] = {"date":"", "active":[], "used_ids":[], "claimed_today":0, "archive":0}
        if not data.has("residents"):
            data["residents"] = {
                "mira": {"unlocked": false, "trust": 0, "quest_step": 0, "quest_progress": 0},
                "thorn": {"unlocked": false, "trust": 0, "quest_step": 0, "quest_progress": 0}
            }
    if version < 6:
        data["building_projects"] = {"wall": false, "forge": false, "turret": false, "shrine": false}
    if version < 7:
        data["weapon_mastery"] = {
            "axes":{"runs":0,"wins":0,"kills":0},
            "spear":{"runs":0,"wins":0,"kills":0},
            "hammer":{"runs":0,"wins":0,"kills":0},
            "twin_blades":{"runs":0,"wins":0,"kills":0}
        }
    if version < 8:
        data["story_state"] = {
            "chapter": 1,
            "chapter1_ready_notified": false,
            "chapter1_seen": false,
            "chapter1_claimed": false
        }
        var residents: Dictionary = data.get("residents", {})
        for resident_id: String in ["mira", "thorn"]:
            var resident: Dictionary = residents.get(resident_id, {})
            resident["unlocked"] = bool(resident.get("unlocked", false))
            resident["trust"] = int(resident.get("trust", 0))
            resident["quest_step"] = int(resident.get("quest_step", 0))
            resident["quest_progress"] = int(resident.get("quest_progress", 0))
            residents[resident_id] = resident
        data["residents"] = residents
    if version < 9:
        var backfill_renown: int = total_mastery()
        var backfill_residents: Dictionary = data.get("residents", {})
        for resident_variant: Variant in backfill_residents.values():
            var resident: Dictionary = resident_variant as Dictionary
            if bool(resident.get("unlocked", false)):
                backfill_renown += 2 + int(resident.get("trust", 0))
        var projects: Dictionary = data.get("building_projects", {})
        for project_value: Variant in projects.values():
            if bool(project_value):
                backfill_renown += 1
        data["camp_renown"] = maxi(int(data.get("camp_renown", 0)), backfill_renown)
        data["contract_state"] = {
            "date":"",
            "offers":[],
            "selected":"",
            "completed_today":[],
            "completed_total":0
        }
    if version < 10:
        data["dynamic_world_stats"] = {
            "events":0,
            "failures":0,
            "elites":0,
            "rescues":0,
            "chains":0
        }
    if version < 11:
        data["biome_event_stats"] = {
            "forest":{"events":0,"perfect":0,"hunts":0},
            "frost":{"events":0,"perfect":0,"hunts":0},
            "ash":{"events":0,"perfect":0,"hunts":0}
        }
    if version < 12:
        data["field_objective_stats"] = {
            "completed":0,
            "failed":0,
            "perfect":0
        }
    if version < 13:
        var mastery_backfill: Array = data.get("biome_mastery", [0,0,0])
        var unlocked: Array = [1,1,1]
        var clears: Array = [
            [false,false,false,false,false],
            [false,false,false,false,false],
            [false,false,false,false,false]
        ]
        for biome_index: int in range(3):
            var mastery_level: int = int(mastery_backfill[biome_index]) if biome_index < mastery_backfill.size() else 0
            unlocked[biome_index] = clampi(mastery_level + 1, 1, ThreatRules.MAX_LEVEL)
            for level_index: int in range(mini(mastery_level, ThreatRules.MAX_LEVEL)):
                clears[biome_index][level_index] = true
        data["threat_unlocked"] = unlocked
        data["threat_clears"] = clears
        data["selected_threat"] = 1
        data["run_mode"] = "expedition"
        data["endless_stats"] = {"runs":0,"best_wave":0,"best_kills":0,"best_coins":0}
        data["relic_forge"] = {"power":0,"ward":0,"fortune":0}
    data["save_version"] = SAVE_VERSION
    save()

func _retrofit_meta_progression() -> void:
    var wins: Array = data.get("biome_wins", [0, 0, 0])
    var mastery: Array = [0, 0, 0]
    var relics: Array = [false, false, false]
    var owned: Array = ["axes"]
    for biome_index: int in range(mini(3, wins.size())):
        var count: int = int(wins[biome_index])
        mastery[biome_index] = count
        if count > 0:
            relics[biome_index] = true
            var weapon_id: String = WeaponRules.unlock_for_biome(biome_index)
            if not weapon_id.is_empty() and not owned.has(weapon_id):
                owned.append(weapon_id)
    data["biome_mastery"] = mastery
    data["boss_relics"] = relics
    data["weapons_owned"] = owned

    var relic_total: int = 0
    for relic_value: Variant in relics:
        if bool(relic_value):
            relic_total += 1
    if relic_total >= 3:
        var story: Dictionary = data.get("story_state", {})
        if not bool(story.get("chapter1_ready_notified", false)):
            story["chapter1_ready_notified"] = true
            data["story_state"] = story
            _push_meta_notice("Три реликвии отозвались одновременно. В Хронике открылся финал Главы I.")
            Analytics.event("chapter_ready", {"chapter":1})
    var selected: String = str(data.get("selected_weapon", "axes"))
    data["selected_weapon"] = selected if owned.has(selected) else "axes"
    data["meta_notices"] = []

func _merge_dictionary(base: Dictionary, incoming: Dictionary) -> void:
    for key: Variant in incoming.keys():
        if base.has(key) and base[key] is Dictionary and incoming[key] is Dictionary:
            _merge_dictionary(base[key], incoming[key])
        else:
            base[key] = incoming[key]

func _today_key() -> String:
    return Time.get_date_string_from_system()

func ensure_daily_state() -> void:
    var today: String = _today_key()
    if str(data.get("daily_date", "")) != today:
        data["daily_date"] = today
        data["supply_claimed"] = false
        var default_missions: Dictionary = defaults()["missions"]
        data["missions"] = default_missions.duplicate(true)
    ensure_contract_board()
    save()

func ensure_contract_board() -> void:
    var today: String = _today_key()
    var state: Dictionary = data.get("contract_state", {})
    var offers: Array = state.get("offers", [])
    if str(state.get("date", "")) == today and offers.size() == 3:
        return

    var pool: Array[String] = GameRules.contract_ids()
    pool.shuffle()
    var new_offers: Array[String] = []
    for i: int in range(mini(3, pool.size())):
        new_offers.append(pool[i])

    state["date"] = today
    state["offers"] = new_offers
    state["selected"] = new_offers[0] if not new_offers.is_empty() else ""
    state["completed_today"] = []
    state["completed_total"] = int(state.get("completed_total", 0))
    data["contract_state"] = state

func save() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))

func contract_offers() -> Array[String]:
    ensure_contract_board()
    var result: Array[String] = []
    var state: Dictionary = data.get("contract_state", {})
    for id_variant: Variant in state.get("offers", []):
        result.append(str(id_variant))
    return result

func selected_contract_id() -> String:
    ensure_contract_board()
    var state: Dictionary = data.get("contract_state", {})
    return str(state.get("selected", ""))

func selected_contract() -> Dictionary:
    var contract_id: String = selected_contract_id()
    return GameRules.contract_by_id(contract_id)

func select_contract(contract_id: String) -> bool:
    ensure_contract_board()
    var offers: Array[String] = contract_offers()
    if not offers.has(contract_id):
        return false
    var state: Dictionary = data.get("contract_state", {})
    var completed: Array = state.get("completed_today", [])
    if completed.has(contract_id):
        return false
    state["selected"] = contract_id
    data["contract_state"] = state
    save()
    Analytics.event("contract_selected", {"id":contract_id})
    return true

func contract_completed_today(contract_id: String) -> bool:
    ensure_contract_board()
    var state: Dictionary = data.get("contract_state", {})
    var completed: Array = state.get("completed_today", [])
    return completed.has(contract_id)

func complete_contract_meta(contract_id: String) -> Dictionary:
    ensure_contract_board()
    var spec: Dictionary = GameRules.contract_by_id(contract_id)
    if spec.is_empty():
        return {"ok":false,"renown":0,"level_up":false}

    var state: Dictionary = data.get("contract_state", {})
    var completed: Array = state.get("completed_today", [])
    if completed.has(contract_id):
        return {"ok":false,"renown":0,"level_up":false}

    var old_level: int = camp_level()
    completed.append(contract_id)
    state["completed_today"] = completed
    state["completed_total"] = int(state.get("completed_total", 0)) + 1
    if str(state.get("selected", "")) == contract_id:
        state["selected"] = ""
    data["contract_state"] = state

    var renown_gain: int = GameRules.contract_renown(contract_id)
    data["camp_renown"] = int(data.get("camp_renown", 0)) + renown_gain
    var new_level: int = camp_level()
    if new_level > old_level:
        _push_meta_notice("Последний Очаг вырос: %s." % camp_level_name())
        Analytics.event("camp_level_up", {"level":new_level,"renown":int(data.get("camp_renown", 0))})
    save()
    return {"ok":true,"renown":renown_gain,"level_up":new_level > old_level}

func camp_renown() -> int:
    return int(data.get("camp_renown", 0))

func camp_level() -> int:
    var value: int = camp_renown()
    var level: int = 1
    if value >= 25:
        level = 5
    elif value >= 15:
        level = 4
    elif value >= 8:
        level = 3
    elif value >= 3:
        level = 2

    # Legacy mastery remains meaningful for long-time saves. Renown adds a
    # second growth route instead of visually downgrading an established camp.
    var mastery_value: int = total_mastery()
    if mastery_value >= 9:
        level = maxi(level, 5)
    elif mastery_value >= 5:
        level = maxi(level, 3)
    elif mastery_value >= 2:
        level = maxi(level, 2)
    return level

func camp_level_name() -> String:
    match camp_level():
        5:
            return "КРЕПОСТЬ ОГНЯ"
        4:
            return "ЖИВОЕ ПОСЕЛЕНИЕ"
        3:
            return "ДОЗОРНЫЙ ЛАГЕРЬ"
        2:
            return "УБЕЖИЩЕ"
        _:
            return "ПОСЛЕДНИЙ ОЧАГ"

func camp_next_renown() -> int:
    match camp_level():
        1:
            return 3
        2:
            return 8
        3:
            return 15
        4:
            return 25
        _:
            return 25

func resident_trust(resident_id: String) -> int:
    var residents: Dictionary = data.get("residents", {})
    var resident: Dictionary = residents.get(resident_id, {})
    return int(resident.get("trust", 0)) if bool(resident.get("unlocked", false)) else 0

func expedition_resident_bonuses() -> Dictionary:
    var mira_trust: int = resident_trust("mira")
    var thorn_trust: int = resident_trust("thorn")
    return {
        "move_mult": 1.0 + float(mira_trust) * 0.01,
        "preview_bonus": float(mira_trust) * 1.2,
        "starting_parts": 2 if thorn_trust >= 4 else (1 if thorn_trust >= 2 else 0),
        "tower_damage_mult": 1.05 if thorn_trust >= 4 else 1.0
    }

func record_dynamic_world(delta_stats: Dictionary) -> void:
    var stats: Dictionary = data.get("dynamic_world_stats", {
        "events":0,"failures":0,"elites":0,"rescues":0,"chains":0
    })
    for key_variant: Variant in delta_stats.keys():
        var key: String = str(key_variant)
        stats[key] = int(stats.get(key, 0)) + int(delta_stats.get(key_variant, 0))
    data["dynamic_world_stats"] = stats
    save()

func dynamic_world_stats() -> Dictionary:
    var stats: Dictionary = data.get("dynamic_world_stats", {})
    return stats.duplicate(true)

func record_field_objective(delta_stats: Dictionary) -> void:
    var stats: Dictionary = data.get("field_objective_stats", {"completed":0,"failed":0,"perfect":0})
    for key_variant: Variant in delta_stats.keys():
        var key: String = str(key_variant)
        stats[key] = int(stats.get(key, 0)) + int(delta_stats.get(key_variant, 0))
    data["field_objective_stats"] = stats
    save()

func field_objective_stats() -> Dictionary:
    return (data.get("field_objective_stats", {"completed":0,"failed":0,"perfect":0}) as Dictionary).duplicate(true)

func record_biome_event(biome_index: int, delta_stats: Dictionary) -> void:
    var biome_data: Dictionary = GameRules.biome(biome_index)
    var biome_id: String = str(biome_data.get("id", "forest"))
    var all_stats: Dictionary = data.get("biome_event_stats", {})
    var stats: Dictionary = all_stats.get(biome_id, {"events":0,"perfect":0,"hunts":0})
    for key_variant: Variant in delta_stats.keys():
        var key: String = str(key_variant)
        stats[key] = int(stats.get(key, 0)) + int(delta_stats.get(key_variant, 0))
    all_stats[biome_id] = stats
    data["biome_event_stats"] = all_stats
    save()

func biome_event_stats(index: int = -1) -> Dictionary:
    var all_stats: Dictionary = data.get("biome_event_stats", {})
    if index < 0:
        return all_stats.duplicate(true)
    var biome_id: String = str(GameRules.biome(index).get("id", "forest"))
    var stats: Dictionary = all_stats.get(biome_id, {"events":0,"perfect":0,"hunts":0})
    return stats.duplicate(true)

func threat_unlocked_level(biome_index: int) -> int:
    var values: Array = data.get("threat_unlocked", [1,1,1])
    if biome_index < 0 or biome_index >= values.size():
        return 1
    return clampi(int(values[biome_index]), 1, ThreatRules.MAX_LEVEL)

func selected_threat() -> int:
    return clampi(int(data.get("selected_threat", 1)), 1, threat_unlocked_level(int(data.get("selected_biome", 0))))

func select_threat(level: int) -> bool:
    var biome_index: int = clampi(int(data.get("selected_biome", 0)), 0, 2)
    var unlocked: int = threat_unlocked_level(biome_index)
    if level < 1 or level > unlocked:
        return false
    data["selected_threat"] = level
    save()
    Analytics.event("threat_selected", {"biome":biome_index,"level":level})
    return true

func threat_clear_done(biome_index: int, level: int) -> bool:
    var all_clears: Array = data.get("threat_clears", [])
    if biome_index < 0 or biome_index >= all_clears.size():
        return false
    var row: Array = all_clears[biome_index]
    var idx: int = clampi(level,1,ThreatRules.MAX_LEVEL)-1
    return idx < row.size() and bool(row[idx])

func record_threat_clear(biome_index: int, level: int) -> Dictionary:
    biome_index = clampi(biome_index,0,2)
    level = clampi(level,1,ThreatRules.MAX_LEVEL)
    var all_clears: Array = data.get("threat_clears", [])
    while all_clears.size() < 3:
        all_clears.append([false,false,false,false,false])
    var row: Array = all_clears[biome_index]
    while row.size() < ThreatRules.MAX_LEVEL:
        row.append(false)

    var first: bool = not bool(row[level-1])
    row[level-1] = true
    all_clears[biome_index] = row
    data["threat_clears"] = all_clears

    var unlocked: Array = data.get("threat_unlocked", [1,1,1])
    while unlocked.size() < 3:
        unlocked.append(1)
    if level < ThreatRules.MAX_LEVEL:
        unlocked[biome_index] = maxi(int(unlocked[biome_index]), level + 1)
    else:
        unlocked[biome_index] = ThreatRules.MAX_LEVEL
    data["threat_unlocked"] = unlocked

    var bonus: Dictionary = ThreatRules.first_clear_reward(level) if first else {"coins":0,"shards":0}
    if first:
        _push_meta_notice("Угроза %d покорена: %s" % [level, str(ThreatRules.spec(level).get("name",""))])
        Analytics.event("threat_first_clear", {"biome":biome_index,"level":level})
    save()
    return {"first":first,"coins":int(bonus.get("coins",0)),"shards":int(bonus.get("shards",0))}

func endless_unlocked() -> bool:
    return relic_count() >= 3 or total_mastery() >= 3

func record_endless_run(wave_value: int, kill_count: int, coin_value: int) -> Dictionary:
    var stats: Dictionary = data.get("endless_stats", {"runs":0,"best_wave":0,"best_kills":0,"best_coins":0})
    var old_best: int = int(stats.get("best_wave",0))
    stats["runs"] = int(stats.get("runs",0)) + 1
    stats["best_wave"] = maxi(old_best, wave_value)
    stats["best_kills"] = maxi(int(stats.get("best_kills",0)), kill_count)
    stats["best_coins"] = maxi(int(stats.get("best_coins",0)), coin_value)
    data["endless_stats"] = stats
    if wave_value > old_best:
        _push_meta_notice("Новый рекорд Последнего рубежа: ночь %d." % wave_value)
    save()
    return {"new_record":wave_value > old_best,"best_wave":int(stats.get("best_wave",0))}

func relic_forge_level(kind: String) -> int:
    var forge: Dictionary = data.get("relic_forge", {"power":0,"ward":0,"fortune":0})
    return clampi(int(forge.get(kind,0)),0,3)

func relic_forge_cost(kind: String) -> int:
    var level: int = relic_forge_level(kind)
    if level >= 3:
        return 999
    return [1,2,3][level]

func buy_relic_forge(kind: String) -> bool:
    if not ["power","ward","fortune"].has(kind):
        return false
    var level: int = relic_forge_level(kind)
    if level >= 3:
        return false
    var cost: int = relic_forge_cost(kind)
    if int(data.get("shards",0)) < cost:
        return false
    data["shards"] = int(data.get("shards",0)) - cost
    var forge: Dictionary = data.get("relic_forge", {})
    forge[kind] = level + 1
    data["relic_forge"] = forge
    _push_meta_notice("Реликтовая кузня усилена: %s III" % kind.to_upper() if level + 1 >= 3 else "Реликтовая кузня усилена: %s %d" % [kind.to_upper(),level+1])
    save()
    Analytics.event("relic_forge_up", {"kind":kind,"level":level+1,"cost":cost})
    return true

func relic_forge_bonuses() -> Dictionary:
    var power: int = relic_forge_level("power")
    var ward: int = relic_forge_level("ward")
    var fortune: int = relic_forge_level("fortune")
    return {
        "damage_mult":1.0 + float(power)*0.05,
        "hp_bonus":float(ward)*12.0,
        "coin_mult":1.0 + float(fortune)*0.10
    }

func add_coins(amount: int) -> void:
    data["coins"] = int(data.get("coins", 0)) + amount
    save()

func add_shards(amount: int) -> void:
    data["shards"] = int(data.get("shards", 0)) + amount
    save()

func upgrade_cost(kind: String) -> int:
    var levels: Dictionary = data["upgrades"]
    var level: int = int(levels.get(kind, 0))
    match kind:
        "damage":
            return 80 + level * 70
        "hp":
            return 70 + level * 60
        "bag":
            return 60 + level * 50
        "speed":
            return 65 + level * 55
    return 999999

func buy_upgrade(kind: String) -> bool:
    var cost: int = upgrade_cost(kind)
    if int(data["coins"]) < cost:
        return false
    data["coins"] = int(data["coins"]) - cost
    data["upgrades"][kind] = int(data["upgrades"].get(kind, 0)) + 1
    save()
    return true

func has_building_project(build_type: String) -> bool:
    var projects: Dictionary = data.get("building_projects", {})
    return bool(projects.get(build_type, false))

func building_project_cost(build_type: String) -> Dictionary:
    var spec: Dictionary = BuildingRules.project_spec(build_type)
    return {
        "coins": int(spec.get("coins", 999999)),
        "shards": int(spec.get("shards", 999999))
    }

func buy_building_project(build_type: String) -> bool:
    if has_building_project(build_type):
        return false
    var spec: Dictionary = BuildingRules.project_spec(build_type)
    if spec.is_empty():
        return false
    if total_mastery() < int(spec.get("min_mastery", 0)):
        return false

    var coin_cost: int = int(spec.get("coins", 0))
    var shard_cost: int = int(spec.get("shards", 0))
    if int(data.get("coins", 0)) < coin_cost or int(data.get("shards", 0)) < shard_cost:
        return false

    data["coins"] = int(data.get("coins", 0)) - coin_cost
    data["shards"] = int(data.get("shards", 0)) - shard_cost
    var projects: Dictionary = data.get("building_projects", {})
    projects[build_type] = true
    data["building_projects"] = projects
    _push_meta_notice("Чертёж изучен: %s" % str(spec.get("name", "Уровень II")))
    save()
    Analytics.event("building_project_bought", {
        "type": build_type,
        "coins": coin_cost,
        "shards": shard_cost
    })
    return true

func mission_add(kind: String, amount: int = 1) -> void:
    ensure_daily_state()
    if not data["missions"].has(kind):
        return
    data["missions"][kind]["value"] = int(data["missions"][kind]["value"]) + amount
    save()

func claim_mission(kind: String) -> bool:
    ensure_daily_state()
    if not data["missions"].has(kind):
        return false
    var mission: Dictionary = data["missions"][kind]
    if bool(mission["claimed"]) or int(mission["value"]) < int(mission["goal"]):
        return false
    mission["claimed"] = true
    add_coins(int(mission["reward"]))
    return true

func owns_weapon(id: String) -> bool:
    var owned: Array = data.get("weapons_owned", ["axes"])
    return owned.has(id)

func select_weapon(id: String) -> bool:
    if not WeaponRules.WEAPONS.has(id) or not owns_weapon(id):
        return false
    data["selected_weapon"] = id
    save()
    return true

func weapon_mastery_data(weapon_id: String) -> Dictionary:
    var all_mastery: Dictionary = data.get("weapon_mastery", {})
    var entry: Dictionary = all_mastery.get(weapon_id, {"runs":0,"wins":0,"kills":0})
    return entry.duplicate(true)

func weapon_mastery_level(weapon_id: String) -> int:
    var entry: Dictionary = weapon_mastery_data(weapon_id)
    var runs_count: int = int(entry.get("runs", 0))
    var wins_count: int = int(entry.get("wins", 0))
    var kills_count: int = int(entry.get("kills", 0))
    var level: int = 0
    if runs_count >= 1:
        level = 1
    if wins_count >= 1 or runs_count >= 3:
        level = 2
    if wins_count >= 2 or kills_count >= 120:
        level = 3
    if wins_count >= 4 or kills_count >= 240:
        level = 4
    if wins_count >= 6 or kills_count >= 420:
        level = 5
    return level

func weapon_mastery_stars(weapon_id: String) -> String:
    var level: int = weapon_mastery_level(weapon_id)
    var out: String = ""
    for i: int in range(5):
        out += "★" if i < level else "☆"
    return out

func _register_weapon_run(won: bool, kills: int) -> void:
    var weapon_id: String = str(data.get("selected_weapon", "axes"))
    if not WeaponRules.WEAPONS.has(weapon_id):
        weapon_id = "axes"
    var all_mastery: Dictionary = data.get("weapon_mastery", {})
    var entry: Dictionary = all_mastery.get(weapon_id, {"runs":0,"wins":0,"kills":0})
    var old_level: int = weapon_mastery_level(weapon_id)
    entry["runs"] = int(entry.get("runs", 0)) + 1
    entry["kills"] = int(entry.get("kills", 0)) + maxi(0, kills)
    if won:
        entry["wins"] = int(entry.get("wins", 0)) + 1
    all_mastery[weapon_id] = entry
    data["weapon_mastery"] = all_mastery
    var new_level: int = weapon_mastery_level(weapon_id)
    if new_level > old_level:
        _push_meta_notice("Мастерство оружия: %s → %s" % [
            str(WeaponRules.profile(weapon_id).get("name", weapon_id)),
            weapon_mastery_stars(weapon_id)
        ])
        Analytics.event("weapon_mastery_up", {"weapon":weapon_id,"level":new_level})

func total_mastery() -> int:
    var total: int = 0
    var mastery: Array = data.get("biome_mastery", [0, 0, 0])
    for value: Variant in mastery:
        total += int(value)
    return total

func camp_title() -> String:
    return WeaponRules.camp_title(total_mastery())

func relic_count() -> int:
    var count: int = 0
    var relics: Array = data.get("boss_relics", [false, false, false])
    for value: Variant in relics:
        if bool(value):
            count += 1
    return count

func chapter_one_ready() -> bool:
    return relic_count() >= 3

func chapter_one_complete() -> bool:
    var story: Dictionary = data.get("story_state", {})
    return bool(story.get("chapter1_claimed", false))

func mark_chronicle_seen() -> void:
    var story: Dictionary = data.get("story_state", {})
    story["chapter1_seen"] = true
    data["story_state"] = story
    save()

func claim_chapter_one() -> Dictionary:
    if not chapter_one_ready():
        return {"ok":false,"reason":"relics"}
    var story: Dictionary = data.get("story_state", {})
    if bool(story.get("chapter1_claimed", false)):
        return {"ok":false,"reason":"claimed"}

    story["chapter"] = 2
    story["chapter1_seen"] = true
    story["chapter1_claimed"] = true
    story["chapter1_ready_notified"] = true
    data["story_state"] = story
    data["shards"] = int(data.get("shards", 0)) + 2
    _push_meta_notice("Глава I завершена. Карта старой сети Очагов раскрыта.")
    save()
    Analytics.event("chapter_completed", {"chapter":1,"reward_shards":2})
    return {"ok":true,"reward_shards":2}

func current_chapter() -> int:
    var story: Dictionary = data.get("story_state", {})
    return 2 if bool(story.get("chapter1_claimed", false)) else 1

func unlocked_resident_count() -> int:
    var count: int = 0
    var residents: Dictionary = data.get("residents", {})
    for resident_variant: Variant in residents.values():
        var resident: Dictionary = resident_variant as Dictionary
        if bool(resident.get("unlocked", false)):
            count += 1
    return count

func consume_meta_notices() -> Array[String]:
    var result: Array[String] = []
    var notices: Array = data.get("meta_notices", [])
    for notice: Variant in notices:
        result.append(str(notice))
    data["meta_notices"] = []
    save()
    return result

func _push_meta_notice(text: String) -> void:
    var notices: Array = data.get("meta_notices", [])
    notices.append(text)
    data["meta_notices"] = notices

func _unlock_first_biome_reward(biome: int) -> void:
    var relics: Array = data.get("boss_relics", [false,false,false])
    var owned: Array = data.get("weapons_owned", ["axes"])
    if bool(relics[biome]):
        return

    relics[biome] = true
    var weapon_id: String = WeaponRules.unlock_for_biome(biome)
    if not weapon_id.is_empty() and not owned.has(weapon_id):
        owned.append(weapon_id)
        var profile: Dictionary = WeaponRules.profile(weapon_id)
        _push_meta_notice("%s добыта. Открыто оружие: %s" % [
            WeaponRules.relic_name(biome),
            str(profile.get("name", weapon_id))
        ])
    else:
        _push_meta_notice("Получена реликвия: %s" % WeaponRules.relic_name(biome))

    data["boss_relics"] = relics
    data["weapons_owned"] = owned

func _sync_threat_from_legacy_mastery(biome: int, mastery_level: int) -> void:
    var safe_level: int = clampi(mastery_level, 0, ThreatRules.MAX_LEVEL)
    var all_clears: Array = data.get("threat_clears", [
        [false,false,false,false,false],
        [false,false,false,false,false],
        [false,false,false,false,false]
    ])
    while all_clears.size() < 3:
        all_clears.append([false,false,false,false,false])

    var row: Array = all_clears[biome]
    while row.size() < ThreatRules.MAX_LEVEL:
        row.append(false)
    for i: int in range(safe_level):
        row[i] = true
    all_clears[biome] = row
    data["threat_clears"] = all_clears

    var unlocked: Array = data.get("threat_unlocked", [1,1,1])
    while unlocked.size() < 3:
        unlocked.append(1)
    unlocked[biome] = clampi(maxi(int(unlocked[biome]), safe_level + 1), 1, ThreatRules.MAX_LEVEL)
    data["threat_unlocked"] = unlocked

func _award_legacy_biome_progress(biome: int) -> Dictionary:
    if biome < 0 or biome >= 3:
        return {"first":false,"coins":0,"shards":0}

    var mastery: Array = data.get("biome_mastery", [0,0,0])
    var old_level: int = int(mastery[biome])
    var new_level: int = mini(ThreatRules.MAX_LEVEL, old_level + 1)
    mastery[biome] = new_level
    data["biome_mastery"] = mastery
    _unlock_first_biome_reward(biome)
    _sync_threat_from_legacy_mastery(biome, new_level)

    # Compatibility for the pre-v1.16 mastery model. Real v1.16 gameplay passes
    # an explicit Threat level and therefore never uses this path.
    if new_level == 3 and old_level < 3:
        data["shards"] = int(data.get("shards",0)) + 1
        _push_meta_notice("Мастерство биома III: +1 осколок.")
    elif new_level == 5 and old_level < 5:
        data["shards"] = int(data.get("shards",0)) + 2
        _push_meta_notice("Мастерство биома V: +2 осколка.")

    return {"first":new_level > old_level,"coins":0,"shards":0}

func _award_biome_progress(biome: int, threat_level: int) -> Dictionary:
    if biome < 0 or biome >= 3:
        return {"first":false,"coins":0,"shards":0}

    var mastery: Array = data.get("biome_mastery", [0,0,0])
    var old_mastery: int = int(mastery[biome])
    mastery[biome] = maxi(old_mastery, clampi(threat_level,1,ThreatRules.MAX_LEVEL))
    data["biome_mastery"] = mastery
    _unlock_first_biome_reward(biome)
    return record_threat_clear(biome, threat_level)

func register_run(wave: int, won: bool, biome: int, kills: int, builds: int, trees: int, threat_level: int = 0, run_mode: String = "expedition", run_coins_value: int = 0) -> Dictionary:
    data["runs"] = int(data["runs"]) + 1
    _register_weapon_run(won, kills)
    data["best_wave"] = max(int(data["best_wave"]), wave)
    data["stats"]["kills"] = int(data["stats"]["kills"]) + kills
    data["stats"]["builds"] = int(data["stats"]["builds"]) + builds
    data["stats"]["trees"] = int(data["stats"]["trees"]) + trees

    var progress_reward: Dictionary = {"first":false,"coins":0,"shards":0}
    if run_mode == "endless":
        progress_reward = record_endless_run(wave, kills, run_coins_value)
    elif won:
        data["wins"] = int(data["wins"]) + 1
        var wins: Array = data["biome_wins"]
        if biome >= 0 and biome < wins.size():
            wins[biome] = int(wins[biome]) + 1
            data["biome_wins"] = wins
            if threat_level <= 0:
                progress_reward = _award_legacy_biome_progress(biome)
            else:
                progress_reward = _award_biome_progress(biome, threat_level)
    save()
    return progress_reward
