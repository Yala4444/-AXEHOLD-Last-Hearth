extends Node

const SAVE_PATH := "user://axehold_save.json"
const SAVE_VERSION := 9

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

func _award_biome_progress(biome: int) -> void:
    if biome < 0 or biome >= 3:
        return
    var mastery: Array = data.get("biome_mastery", [0, 0, 0])
    var relics: Array = data.get("boss_relics", [false, false, false])
    var owned: Array = data.get("weapons_owned", ["axes"])
    mastery[biome] = int(mastery[biome]) + 1
    var mastery_level: int = int(mastery[biome])

    if not bool(relics[biome]):
        relics[biome] = true
        var weapon_id: String = WeaponRules.unlock_for_biome(biome)
        if not weapon_id.is_empty() and not owned.has(weapon_id):
            owned.append(weapon_id)
            var profile: Dictionary = WeaponRules.profile(weapon_id)
            _push_meta_notice("🏆 %s добыта. Открыто оружие: %s %s" % [WeaponRules.relic_name(biome), str(profile.get("icon", "⚔️")), str(profile.get("name", weapon_id))])
        else:
            _push_meta_notice("🏆 Получена реликвия: %s" % WeaponRules.relic_name(biome))

    if mastery_level == 3:
        data["shards"] = int(data.get("shards", 0)) + 1
        _push_meta_notice("⭐ Мастерство биома III: +1 🔥")
    elif mastery_level == 5:
        data["shards"] = int(data.get("shards", 0)) + 2
        _push_meta_notice("⭐ Мастерство биома V: +2 🔥")

    data["biome_mastery"] = mastery
    data["boss_relics"] = relics
    data["weapons_owned"] = owned

func register_run(wave: int, won: bool, biome: int, kills: int, builds: int, trees: int) -> void:
    data["runs"] = int(data["runs"]) + 1
    _register_weapon_run(won, kills)
    data["best_wave"] = max(int(data["best_wave"]), wave)
    data["stats"]["kills"] = int(data["stats"]["kills"]) + kills
    data["stats"]["builds"] = int(data["stats"]["builds"]) + builds
    data["stats"]["trees"] = int(data["stats"]["trees"]) + trees
    if won:
        data["wins"] = int(data["wins"]) + 1
        var wins: Array = data["biome_wins"]
        if biome >= 0 and biome < wins.size():
            wins[biome] = int(wins[biome]) + 1
            data["biome_wins"] = wins
            _award_biome_progress(biome)
    save()
