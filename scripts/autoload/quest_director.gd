extends Node

func _ready() -> void:
    ensure_daily_quests()

func ensure_daily_quests() -> void:
    var state: Dictionary = GameState.data.get("quest_state", {})
    var today: String = Time.get_date_string_from_system()

    if str(state.get("date", "")) != today:
        state = {
            "date": today,
            "active": [],
            "used_ids": [],
            "claimed_today": 0,
            "archive": int(state.get("archive", 0))
        }
        GameState.data["quest_state"] = state
        _fill_active(3)
        GameState.save()
        Analytics.event("daily_quests_refreshed", {"date":today})
        return

    if not state.has("active"):
        state["active"] = []
    if not state.has("used_ids"):
        state["used_ids"] = []
    if not state.has("claimed_today"):
        state["claimed_today"] = 0
    if not state.has("archive"):
        state["archive"] = 0

    GameState.data["quest_state"] = state
    if (state["active"] as Array).size() < 3 and int(state.get("claimed_today", 0)) < QuestRules.DAILY_CLAIM_CAP:
        _fill_active(3)
        GameState.save()

func active_quests() -> Array[Dictionary]:
    ensure_daily_quests()
    var result: Array[Dictionary] = []
    var state: Dictionary = GameState.data.get("quest_state", {})
    for quest_variant: Variant in state.get("active", []):
        result.append((quest_variant as Dictionary).duplicate(true))
    return result

func record(event_name: String, amount: int = 1, context: Dictionary = {}) -> void:
    if amount <= 0:
        return
    ensure_daily_quests()
    var state: Dictionary = GameState.data.get("quest_state", {})
    var active: Array = state.get("active", [])
    var changed: bool = false

    for i: int in range(active.size()):
        var quest: Dictionary = active[i]
        if bool(quest.get("ready", false)):
            continue
        if str(quest.get("event", "")) != event_name:
            continue
        var filter_key: String = str(quest.get("filter_key", ""))
        if not filter_key.is_empty():
            if not context.has(filter_key) or context.get(filter_key) != quest.get("filter_value"):
                continue

        var goal: int = maxi(1, int(quest.get("goal", 1)))
        quest["progress"] = mini(goal, int(quest.get("progress", 0)) + amount)
        if int(quest["progress"]) >= goal:
            quest["ready"] = true
            Feedback.play("level", 6)
            Analytics.event("daily_quest_completed", {"id":str(quest.get("id", ""))})
        active[i] = quest
        changed = true

    _record_resident_event(event_name, amount, context)

    if changed:
        state["active"] = active
        GameState.data["quest_state"] = state
        GameState.save()

func claim(quest_id: String) -> Dictionary:
    ensure_daily_quests()
    var state: Dictionary = GameState.data.get("quest_state", {})
    var active: Array = state.get("active", [])

    for i: int in range(active.size()):
        var quest: Dictionary = active[i]
        if str(quest.get("id", "")) != quest_id or not bool(quest.get("ready", false)):
            continue

        var reward: int = int(quest.get("reward", 0))
        var reward_type: String = str(quest.get("reward_type", "coins"))
        if reward_type == "shards":
            GameState.data["shards"] = int(GameState.data.get("shards", 0)) + reward
        else:
            GameState.data["coins"] = int(GameState.data.get("coins", 0)) + reward

        active.remove_at(i)
        state["active"] = active
        state["claimed_today"] = int(state.get("claimed_today", 0)) + 1
        state["archive"] = int(state.get("archive", 0)) + 1
        GameState.data["quest_state"] = state

        if int(state.get("claimed_today", 0)) < QuestRules.DAILY_CLAIM_CAP:
            _fill_active(3)

        GameState.save()
        Feedback.play("victory", 8)
        Analytics.event("daily_quest_claimed", {
            "id":quest_id,
            "reward":reward,
            "reward_type":reward_type,
            "claimed_today":int(state.get("claimed_today", 0))
        })
        return {"ok":true,"reward":reward,"reward_type":reward_type}

    return {"ok":false}

func resident_quest_state(resident_id: String) -> Dictionary:
    var residents: Dictionary = GameState.data.get("residents", {})
    var resident: Dictionary = residents.get(resident_id, {})
    if not bool(resident.get("unlocked", false)):
        return {}

    var step: int = int(resident.get("quest_step", 0))
    var progress: int = int(resident.get("quest_progress", 0))
    var chain_size: int = ResidentRules.chain_size(resident_id)
    if chain_size <= 0:
        return {}

    if step >= chain_size:
        return {
            "complete":true,
            "title":"ЦЕПОЧКА ЗАВЕРШЕНА",
            "desc":"Все текущие поручения %s выполнены." % ResidentRules.name_for(resident_id),
            "progress":chain_size,
            "goal":chain_size
        }

    var spec: Dictionary = ResidentRules.quest(resident_id, step)
    spec["progress"] = progress
    spec["ready"] = progress >= int(spec.get("goal", 1))
    spec["complete"] = false
    return spec

func claim_resident(resident_id: String) -> Dictionary:
    var quest: Dictionary = resident_quest_state(resident_id)
    if quest.is_empty() or bool(quest.get("complete", false)) or not bool(quest.get("ready", false)):
        return {"ok":false}

    var residents: Dictionary = GameState.data.get("residents", {})
    var resident: Dictionary = residents.get(resident_id, {})
    var reward: int = int(quest.get("reward", 0))
    var reward_type: String = str(quest.get("reward_type", "coins"))
    if reward_type == "shards":
        GameState.data["shards"] = int(GameState.data.get("shards", 0)) + reward
    else:
        GameState.data["coins"] = int(GameState.data.get("coins", 0)) + reward

    resident["trust"] = mini(ResidentRules.max_trust(resident_id), int(resident.get("trust", 0)) + 1)
    resident["quest_step"] = int(resident.get("quest_step", 0)) + 1
    resident["quest_progress"] = 0
    GameState.data["camp_renown"] = int(GameState.data.get("camp_renown", 0)) + 1
    residents[resident_id] = resident
    GameState.data["residents"] = residents

    var completed_now: bool = int(resident.get("quest_step", 0)) >= ResidentRules.chain_size(resident_id)
    if completed_now:
        var notices: Array = GameState.data.get("meta_notices", [])
        GameState.data["camp_renown"] = int(GameState.data.get("camp_renown", 0)) + 1
        notices.append("%s завершает текущую цепочку поручений. Лагерь получает дополнительную Славу." % ResidentRules.name_for(resident_id))
        GameState.data["meta_notices"] = notices

    GameState.save()
    Feedback.play("victory", 10)
    Analytics.event("resident_quest_claimed", {
        "resident":resident_id,
        "step":int(resident.get("quest_step", 0)),
        "trust":int(resident.get("trust", 0)),
        "chain_complete":completed_now
    })
    return {
        "ok":true,
        "reward":reward,
        "reward_type":reward_type,
        "chain_complete":completed_now
    }

func _record_resident_event(event_name: String, amount: int, context: Dictionary) -> void:
    var residents: Dictionary = GameState.data.get("residents", {})
    var changed: bool = false

    for resident_id: String in ResidentRules.ids():
        var resident: Dictionary = residents.get(resident_id, {})
        if not bool(resident.get("unlocked", false)):
            continue

        var quest: Dictionary = resident_quest_state(resident_id)
        if quest.is_empty() or bool(quest.get("complete", false)):
            continue
        if str(quest.get("event", "")) != event_name:
            continue

        var filter_key: String = str(quest.get("filter_key", ""))
        if not filter_key.is_empty():
            if not context.has(filter_key) or context.get(filter_key) != quest.get("filter_value"):
                continue

        var goal: int = maxi(1, int(quest.get("goal", 1)))
        var before: int = int(resident.get("quest_progress", 0))
        resident["quest_progress"] = mini(goal, before + amount)
        residents[resident_id] = resident
        changed = true

        if before < goal and int(resident["quest_progress"]) >= goal:
            Feedback.play("level", 6)
            Analytics.event("resident_quest_completed", {
                "resident":resident_id,
                "step":int(resident.get("quest_step", 0))
            })

    if changed:
        GameState.data["residents"] = residents
        GameState.save()

func claims_left_today() -> int:
    ensure_daily_quests()
    var state: Dictionary = GameState.data.get("quest_state", {})
    return maxi(0, QuestRules.DAILY_CLAIM_CAP - int(state.get("claimed_today", 0)))

func archive_count() -> int:
    var state: Dictionary = GameState.data.get("quest_state", {})
    return int(state.get("archive", 0))

func debug_refresh() -> void:
    if not OS.is_debug_build():
        return
    var state: Dictionary = GameState.data.get("quest_state", {})
    state["date"] = ""
    GameState.data["quest_state"] = state
    ensure_daily_quests()

func _fill_active(target_count: int) -> void:
    var state: Dictionary = GameState.data.get("quest_state", {})
    var active: Array = state.get("active", [])
    var used: Array = state.get("used_ids", [])

    var candidates: Array[Dictionary] = []
    for spec_variant: Variant in QuestRules.DAILY_POOL:
        var spec_data: Dictionary = spec_variant
        var id: String = str(spec_data.get("id", ""))
        var already_active: bool = false
        for quest_variant: Variant in active:
            if str((quest_variant as Dictionary).get("id", "")) == id:
                already_active = true
                break
        if already_active or used.has(id):
            continue
        candidates.append(spec_data.duplicate(true))

    if candidates.is_empty():
        used = []
        state["used_ids"] = used
        for spec_variant: Variant in QuestRules.DAILY_POOL:
            candidates.append((spec_variant as Dictionary).duplicate(true))

    var rng := RandomNumberGenerator.new()
    var seed_text: String = str(state.get("date", "")) + ":" + str(state.get("claimed_today", 0)) + ":" + str(active.size())
    rng.seed = abs(seed_text.hash())
    for i: int in range(candidates.size() - 1, 0, -1):
        var j: int = rng.randi_range(0, i)
        var tmp: Dictionary = candidates[i]
        candidates[i] = candidates[j]
        candidates[j] = tmp

    var categories: Dictionary = {}
    for quest_variant: Variant in active:
        categories[str((quest_variant as Dictionary).get("category", ""))] = true

    for spec_data: Dictionary in candidates:
        if active.size() >= target_count:
            break
        var category: String = str(spec_data.get("category", ""))
        if categories.has(category) and candidates.size() > target_count:
            continue
        active.append(QuestRules.make_runtime(spec_data))
        used.append(str(spec_data.get("id", "")))
        categories[category] = true

    if active.size() < target_count:
        for spec_data: Dictionary in candidates:
            if active.size() >= target_count:
                break
            var id: String = str(spec_data.get("id", ""))
            var duplicate: bool = false
            for quest_variant: Variant in active:
                if str((quest_variant as Dictionary).get("id", "")) == id:
                    duplicate = true
                    break
            if duplicate:
                continue
            active.append(QuestRules.make_runtime(spec_data))
            if not used.has(id):
                used.append(id)

    state["active"] = active
    state["used_ids"] = used
    GameState.data["quest_state"] = state
