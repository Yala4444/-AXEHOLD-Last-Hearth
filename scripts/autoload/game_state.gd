extends Node

const SAVE_PATH := "user://axehold_save.json"
const SAVE_VERSION := 5

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
        "meta_notices": [],
        "lore_fragments": 0,
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
                "mira": {"unlocked": false, "trust": 0, "quest_step": 0},
                "thorn": {"unlocked": false, "trust": 0, "quest_step": 0}
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
    if str(data.get("daily_date", "")) == today:
        return
    data["daily_date"] = today
    data["supply_claimed"] = false
    var default_missions: Dictionary = defaults()["missions"]
    data["missions"] = default_missions.duplicate(true)
    save()

func save() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))

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

func total_mastery() -> int:
    var total: int = 0
    var mastery: Array = data.get("biome_mastery", [0, 0, 0])
    for value: Variant in mastery:
        total += int(value)
    return total

func camp_title() -> String:
    return WeaponRules.camp_title(total_mastery())

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
