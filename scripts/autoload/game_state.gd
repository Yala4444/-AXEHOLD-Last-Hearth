extends Node

const SAVE_PATH := "user://axehold_save.json"
const SAVE_VERSION := 2

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
        "upgrades": {"damage": 0, "hp": 0, "bag": 0, "speed": 0},
        "biome_wins": [0, 0, 0],
        "skins_owned": [true, false, false, false],
        "selected_skin": 0,
        "daily_date": "",
        "supply_claimed": false,
        "settings": {"sound": true, "haptics": true, "hints": true},
        "stats": {"kills": 0, "trees": 0, "builds": 0},
        "missions": {
            "trees": {"value": 0, "goal": 15, "reward": 35, "claimed": false},
            "kills": {"value": 0, "goal": 14, "reward": 45, "claimed": false},
            "builds": {"value": 0, "goal": 3, "reward": 40, "claimed": false}
        },
        "trophies_claimed": []
    }

func _load_save() -> void:
    data = defaults()
    if not FileAccess.file_exists(SAVE_PATH):
        save()
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        _merge_dictionary(data, parsed)
        _migrate_save()

func _migrate_save() -> void:
    var version := int(data.get("save_version", 1))
    if version < 2:
        data["daily_date"] = ""
        data["tutorial_complete"] = false
    data["save_version"] = SAVE_VERSION
    save()

func _merge_dictionary(base: Dictionary, incoming: Dictionary) -> void:
    for key in incoming.keys():
        if base.has(key) and base[key] is Dictionary and incoming[key] is Dictionary:
            _merge_dictionary(base[key], incoming[key])
        else:
            base[key] = incoming[key]

func _today_key() -> String:
    return Time.get_date_string_from_system()

func ensure_daily_state() -> void:
    var today := _today_key()
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
    var level := int(levels.get(kind, 0))
    match kind:
        "damage": return 80 + level * 70
        "hp": return 70 + level * 60
        "bag": return 60 + level * 50
        "speed": return 65 + level * 55
    return 999999

func buy_upgrade(kind: String) -> bool:
    var cost := upgrade_cost(kind)
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
    var m: Dictionary = data["missions"][kind]
    if bool(m["claimed"]) or int(m["value"]) < int(m["goal"]):
        return false
    m["claimed"] = true
    add_coins(int(m["reward"]))
    return true

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
    save()
