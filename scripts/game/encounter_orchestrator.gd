class_name EncounterOrchestrator
extends Node

## Owns the attention budget for timed expedition encounters.
## Specialized directors still implement their gameplay, but only one of them
## may own the run objective / encounter slot at a time.

signal encounter_started(owner_id: String, kind: String)
signal encounter_finished(owner_id: String, kind: String, outcome: String)

var world: GameWorld
var active: Dictionary = {}
var cooldown: float = 0.0
var history: Array[Dictionary] = []
var denied_requests: int = 0

func setup(world_ref: GameWorld) -> void:
    world = world_ref
    set_process(true)

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if active.is_empty() or world == null or not is_instance_valid(world):
        return
    if world.finishing:
        release(str(active.get("owner", "")), "run_finished", 0.0)
    elif world.phase != "day":
        call_deferred("_release_after_phase_change", str(active.get("owner", "")))

func _release_after_phase_change(owner_id: String) -> void:
    # Event directors get the current frame to record their specific failure.
    # This fallback only clears a genuinely orphaned slot.
    if not active.is_empty() and str(active.get("owner", "")) == owner_id:
        release(owner_id, "phase_changed", 0.0)

func request(owner_id: String, kind: String, priority: int = 0, cooldown_after: float = 18.0) -> bool:
    if owner_id.is_empty() or kind.is_empty():
        return false
    if world == null or not is_instance_valid(world) or world.finishing:
        return false
    if world.tutorial_run or world.phase != "day" or world.hud == null or world.hud.modal_open():
        denied_requests += 1
        return false
    if not active.is_empty():
        if str(active.get("owner", "")) == owner_id:
            return true
        denied_requests += 1
        return false
    if cooldown > 0.0:
        denied_requests += 1
        return false

    active = {
        "owner":owner_id,
        "kind":kind,
        "priority":priority,
        "wave":world.wave,
        "cooldown_after":maxf(0.0, cooldown_after)
    }
    encounter_started.emit(owner_id, kind)
    Analytics.event("encounter_slot_started", {
        "owner":owner_id,
        "kind":kind,
        "priority":priority,
        "wave":world.wave,
        "biome":world.biome_index
    })
    return true

func release(owner_id: String, outcome: String = "resolved", cooldown_override: float = -1.0) -> bool:
    if active.is_empty() or str(active.get("owner", "")) != owner_id:
        return false

    var finished: Dictionary = active.duplicate(true)
    active.clear()
    var after: float = cooldown_override
    if after < 0.0:
        after = float(finished.get("cooldown_after", 18.0))
    cooldown = maxf(cooldown, maxf(0.0, after))
    finished["outcome"] = outcome
    history.append(finished)
    while history.size() > 8:
        history.remove_at(0)

    var kind: String = str(finished.get("kind", ""))
    encounter_finished.emit(owner_id, kind, outcome)
    Analytics.event("encounter_slot_finished", {
        "owner":owner_id,
        "kind":kind,
        "outcome":outcome,
        "wave":int(finished.get("wave", 0)),
        "biome":world.biome_index if world != null else -1
    })
    return true

func is_busy(except_owner: String = "") -> bool:
    if active.is_empty():
        return false
    return except_owner.is_empty() or str(active.get("owner", "")) != except_owner

func ready() -> bool:
    return active.is_empty() and cooldown <= 0.0

func active_owner() -> String:
    return str(active.get("owner", ""))

func result_summary() -> Dictionary:
    return {
        "completed_slots":history.size(),
        "denied_requests":denied_requests,
        "last":history[history.size() - 1].duplicate(true) if not history.is_empty() else {}
    }
