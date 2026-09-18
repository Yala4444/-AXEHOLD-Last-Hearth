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
    _record_frontier_assignment(event_name, amount, context)

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
    if resident_id == "mira":
        var chain: Array[Dictionary] = [
            {"title":"МЕТКИ НА ДОРОГЕ","desc":"Зажги 2 сигнальных костра в экспедициях.","event":"signal_fire","goal":2,"reward_type":"shards","reward":1},
            {"title":"ДАЛЬНИЙ ПУТЬ","desc":"Доберись до внешнего кольца мира 2 раза.","event":"reach_outer","goal":2,"reward_type":"coins","reward":90},
            {"title":"ЧЁРНЫЕ КОРНИ","desc":"Уничтожь 3 гнезда Тьмы.","event":"nest_destroyed","goal":3,"reward_type":"shards","reward":1}
        ]
        if step >= chain.size():
            return {"complete":true,"title":"РАЗВЕДЧИЦА МИРА","desc":"Все текущие поручения выполнены.","progress":3,"goal":3}
        var spec: Dictionary = chain[step].duplicate(true)
        spec["progress"] = progress
        spec["ready"] = progress >= int(spec.get("goal", 1))
        spec["complete"] = false
        return spec

    if resident_id == "thorn":
        var thorn_chain: Array[Dictionary] = [
            {"title":"СЕРДЦЕ МЕХАНИЗМА","desc":"Найди 4 Детали механизма в экспедициях.","event":"mechanism_part","goal":4,"reward_type":"coins","reward":120},
            {"title":"ЧЕРТЁЖ В ПОЛЕ","desc":"Улучши одну постройку до уровня II.","event":"build_upgrade","goal":1,"reward_type":"shards","reward":1},
            {"title":"КРЕПКАЯ ОСНОВА","desc":"Улучши ещё 2 постройки до уровня II.","event":"build_upgrade","goal":2,"reward_type":"coins","reward":170}
        ]
        if step >= thorn_chain.size():
            return {"complete":true,"title":"МЕХАНИК ТОРН","desc":"Все текущие поручения выполнены. Торн готовит лагерь к дальней дороге.","progress":3,"goal":3}
        var thorn_spec: Dictionary = thorn_chain[step].duplicate(true)
        thorn_spec["progress"] = progress
        thorn_spec["ready"] = progress >= int(thorn_spec.get("goal", 1))
        thorn_spec["complete"] = false
        return thorn_spec
    return {}

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

    resident["trust"] = mini(3, int(resident.get("trust", 0)) + 1)
    resident["quest_step"] = int(resident.get("quest_step", 0)) + 1
    resident["quest_progress"] = 0
    residents[resident_id] = resident
    GameState.data["residents"] = residents
    GameState.save()
    Feedback.play("victory", 10)
    Analytics.event("resident_quest_claimed", {
        "resident":resident_id,
        "step":int(resident.get("quest_step", 0)),
        "trust":int(resident.get("trust", 0))
    })
    return {"ok":true,"reward":reward,"reward_type":reward_type}

func _record_resident_event(event_name: String, amount: int, _context: Dictionary) -> void:
    var residents: Dictionary = GameState.data.get("residents", {})
    var changed: bool = false
    for resident_id: String in ["mira", "thorn"]:
        var resident: Dictionary = residents.get(resident_id, {})
        if not bool(resident.get("unlocked", false)):
            continue
        var quest: Dictionary = resident_quest_state(resident_id)
        if quest.is_empty() or bool(quest.get("complete", false)):
            continue
        if str(quest.get("event", "")) != event_name:
            continue

        var goal: int = maxi(1, int(quest.get("goal", 1)))
        resident["quest_progress"] = mini(goal, int(resident.get("quest_progress", 0)) + amount)
        residents[resident_id] = resident
        changed = true
    if changed:
        GameState.data["residents"] = residents
        GameState.save()

func begin_frontier_assignment_run() -> Dictionary:
    var assignment_id: String = GameState.frontier_assignment_id()
    if assignment_id.is_empty():
        return {}
    var spec: Dictionary = FrontierRules.assignment(assignment_id)
    if spec.is_empty():
        GameState.clear_frontier_assignment()
        return {}

    var state: Dictionary = GameState.data.get("frontier_state", {})
    state["assignment_progress"] = 0
    state["assignment_ready"] = false
    state["assignment_failed"] = false
    GameState.data["frontier_state"] = state
    GameState.save()
    Analytics.event("frontier_assignment_started", {"id":assignment_id})
    return frontier_assignment_state()

func frontier_assignment_state() -> Dictionary:
    var assignment_id: String = GameState.frontier_assignment_id()
    if assignment_id.is_empty():
        return {}
    var spec: Dictionary = FrontierRules.assignment(assignment_id)
    if spec.is_empty():
        return {}
    var state: Dictionary = GameState.data.get("frontier_state", {})
    var result: Dictionary = spec.duplicate(true)
    result["id"] = assignment_id
    result["progress"] = int(state.get("assignment_progress", 0))
    result["ready"] = bool(state.get("assignment_ready", false))
    result["failed"] = bool(state.get("assignment_failed", false))
    return result

func assignment_hud_text() -> String:
    var state: Dictionary = frontier_assignment_state()
    if state.is_empty():
        return ""
    if bool(state.get("failed", false)):
        return "ДАЛЬНИЙ ВЫХОД ПРОВАЛЕН"
    if bool(state.get("ready", false)):
        return "ЗАДАНИЕ ГОТОВО · ВЕРНИСЬ К ОЧАГУ"
    return "%s · %d/%d" % [
        str(state.get("name", "ДАЛЬНИЙ ВЫХОД")),
        int(state.get("progress", 0)),
        int(state.get("goal", 1))
    ]

func tick_frontier_assignment(wave: int) -> bool:
    var current: Dictionary = frontier_assignment_state()
    if current.is_empty() or bool(current.get("ready", false)) or bool(current.get("failed", false)):
        return false
    var deadline: int = int(current.get("deadline_wave", 1))
    if wave <= deadline:
        return false
    var state: Dictionary = GameState.data.get("frontier_state", {})
    state["assignment_failed"] = true
    GameState.data["frontier_state"] = state
    GameState.save()
    Analytics.event("frontier_assignment_failed", {"id":str(current.get("id", "")),"wave":wave})
    return true

func try_complete_frontier_assignment_at_hearth(at_hearth: bool, phase: String) -> Dictionary:
    if not at_hearth or phase != "day":
        return {"ok":false}
    var current: Dictionary = frontier_assignment_state()
    if current.is_empty() or not bool(current.get("ready", false)) or bool(current.get("failed", false)):
        return {"ok":false}

    var reward: int = int(current.get("reward", 0))
    var reward_type: String = str(current.get("reward_type", "coins"))
    if reward_type == "shards":
        GameState.data["shards"] = int(GameState.data.get("shards", 0)) + reward
    else:
        GameState.data["coins"] = int(GameState.data.get("coins", 0)) + reward

    var state: Dictionary = GameState.data.get("frontier_state", {})
    var history: Dictionary = state.get("assignment_history", {})
    var assignment_id: String = str(current.get("id", ""))
    history[assignment_id] = int(history.get(assignment_id, 0)) + 1
    state["assignment_history"] = history
    state["assignments_completed"] = int(state.get("assignments_completed", 0)) + 1
    state["selected_assignment"] = ""
    state["assignment_progress"] = 0
    state["assignment_ready"] = false
    state["assignment_failed"] = false
    GameState.data["frontier_state"] = state
    GameState.save()

    Feedback.play("victory", 12)
    Analytics.event("frontier_assignment_completed", {
        "id":assignment_id,
        "reward":reward,
        "reward_type":reward_type,
        "total":int(state.get("assignments_completed", 0))
    })
    return {
        "ok":true,
        "name":str(current.get("name", "ДАЛЬНИЙ ВЫХОД")),
        "reward":reward,
        "reward_type":reward_type
    }

func end_frontier_assignment_run() -> void:
    var current: Dictionary = frontier_assignment_state()
    if current.is_empty():
        return
    if bool(current.get("failed", false)):
        GameState.clear_frontier_assignment()

func _record_frontier_assignment(event_name: String, amount: int, context: Dictionary) -> void:
    var current: Dictionary = frontier_assignment_state()
    if current.is_empty() or bool(current.get("ready", false)) or bool(current.get("failed", false)):
        return
    if str(current.get("event", "")) != event_name:
        return

    var event_wave: int = int(context.get("wave", 0))
    var deadline: int = int(current.get("deadline_wave", 1))
    if event_wave > deadline:
        tick_frontier_assignment(event_wave)
        return

    var goal: int = maxi(1, int(current.get("goal", 1)))
    var state: Dictionary = GameState.data.get("frontier_state", {})
    var progress: int = mini(goal, int(state.get("assignment_progress", 0)) + amount)
    state["assignment_progress"] = progress
    if progress >= goal:
        state["assignment_ready"] = true
        Feedback.play("level", 8)
    GameState.data["frontier_state"] = state
    GameState.save()
    Analytics.event("frontier_assignment_progress", {
        "id":str(current.get("id", "")),
        "progress":progress,
        "goal":goal
    })

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
