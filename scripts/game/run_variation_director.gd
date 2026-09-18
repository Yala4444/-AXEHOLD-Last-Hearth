class_name RunVariationDirector
extends Node

var world: GameWorld
var threat: float = 0.0
var current_modifier: Dictionary = {}
var previewed_modifier: Dictionary = {}
var preview_wave: int = 0
var contract: Dictionary = {}
var contract_from_board: bool = false
var contract_completed: bool = false
var contract_renown_awarded: int = 0
var max_distance_from_hearth: float = 0.0
var night_rift: NightRift = null
var effective_threat: float = 0.0
var last_announced_contract_progress: int = -1
var outer_reach_recorded: bool = false

func setup(world_ref: GameWorld) -> void:
    world = world_ref
    contract = GameState.selected_contract()
    contract_from_board = not contract.is_empty()
    if contract.is_empty():
        contract = GameRules.random_contract()
    call_deferred("_announce_contract")

func _process(_delta: float) -> void:
    if world == null or not is_instance_valid(world) or world.player == null or world.finishing:
        return

    max_distance_from_hearth = maxf(
        max_distance_from_hearth,
        world.player.global_position.distance_to(world.base_position)
    )
    if not outer_reach_recorded and max_distance_from_hearth >= 720.0:
        outer_reach_recorded = true
        QuestDirector.record("reach_outer", 1, {"biome":world.biome_index})
    _check_contract_progress()
    _maybe_preview_night()

    if night_rift != null and not is_instance_valid(night_rift):
        night_rift = null

func _announce_contract() -> void:
    if world == null or world.hud == null or contract.is_empty():
        return
    world.hud.show_banner("КОНТРАКТ: " + str(contract.get("name", "")), Color("d8bd7b"))
    var board_suffix: String = " · +%d славы" % int(contract.get("renown", 1)) if contract_from_board else ""
    world.hud.set_status("%s%s" % [str(contract.get("desc", "")), board_suffix])
    world.hud.set_run_objective("КОНТРАКТ · " + str(contract.get("name", "")))
    Analytics.event("run_contract_started", {
        "id": str(contract.get("id", "")),
        "biome": world.biome_index
    })

func _maybe_preview_night() -> void:
    var preview_bonus: float = float(GameState.expedition_resident_bonuses().get("preview_bonus", 0.0))
    if world == null or world.phase != "day" or world.phase_time > 18.0 + preview_bonus:
        return
    var upcoming_wave: int = world.wave + 1
    if preview_wave == upcoming_wave:
        return

    var active_nests: int = world.activity_director.unresolved_nests() if world.activity_director != null else 0
    var preview_threat: float = clampf(threat + float(active_nests) * 1.25, 0.0, 12.0)
    previewed_modifier = GameRules.random_night_modifier(upcoming_wave, preview_threat)
    preview_wave = upcoming_wave

    var name: String = str(previewed_modifier.get("name", "НОЧЬ"))
    var desc: String = str(previewed_modifier.get("desc", ""))
    world.hud.show_banner("ПРЕДВЕСТИЕ: " + name, Color("d8c7a0"))
    world.hud.set_status(desc)
    world.hud.set_run_objective("ГРЯДЁТ %s · УГРОЗА %s" % [name, _threat_name_for(preview_threat)])
    Analytics.event("night_modifier_previewed", {
        "id": str(previewed_modifier.get("id", "")),
        "wave": upcoming_wave,
        "threat": preview_threat,
        "biome": world.biome_index
    })

func _threat_name_for(value: float) -> String:
    if value < 2.5:
        return "НИЗКАЯ"
    if value < 5.0:
        return "СРЕДНЯЯ"
    if value < 8.0:
        return "ВЫСОКАЯ"
    return "КРИТИЧЕСКАЯ"

func add_threat(amount: float, reason: String = "") -> void:
    threat = clampf(threat + amount, 0.0, 12.0)
    if world != null and world.hud != null and world.phase == "day" and not contract_completed:
        world.hud.set_run_objective("КОНТРАКТ · %s · УГРОЗА %s" % [str(contract.get("name", "")), threat_name()])
    Analytics.event("run_threat_changed", {
        "value": threat,
        "delta": amount,
        "reason": reason,
        "wave": world.wave if world != null else 0
    })

func reduce_threat(amount: float, reason: String = "") -> void:
    add_threat(-absf(amount), reason)

func prepare_night(wave: int) -> Dictionary:
    var active_nests: int = world.activity_director.unresolved_nests() if world.activity_director != null else 0
    effective_threat = clampf(threat + float(active_nests) * 1.25, 0.0, 12.0)
    if preview_wave == wave and not previewed_modifier.is_empty():
        current_modifier = previewed_modifier.duplicate(true)
    else:
        current_modifier = GameRules.random_night_modifier(wave, effective_threat)
    previewed_modifier.clear()

    var modifier_name: String = str(current_modifier.get("name", "НОЧЬ"))
    var modifier_desc: String = str(current_modifier.get("desc", ""))
    world.hud.set_status("%s: %s" % [modifier_name, modifier_desc])
    world.hud.set_run_objective("УГРОЗА %s · %s" % [threat_name(), modifier_name])
    Analytics.event("night_modifier_selected", {
        "id": str(current_modifier.get("id", "")),
        "wave": wave,
        "threat": effective_threat,
        "biome": world.biome_index
    })

    if wave >= 2:
        var rift_chance: float = clampf(0.28 + effective_threat * 0.035 + float(wave - 2) * 0.12, 0.28, 0.72)
        if randf() < rift_chance:
            call_deferred("_spawn_night_rift", wave)
    return current_modifier.duplicate(true)

func on_night_completed(wave: int) -> void:
    QuestDirector.record("night_survive", 1, {"wave":wave, "biome":world.biome_index})
    if wave == 1:
        if not bool(world.built.get("turret", false)):
            QuestDirector.record("night_no_tower", 1, {"biome":world.biome_index})
        var id: String = str(contract.get("id", ""))
        if id == "lean_defense" and world.builds <= 1:
            _complete_contract()
        elif id == "no_tower" and not bool(world.built.get("turret", false)):
            _complete_contract()

    if night_rift != null and is_instance_valid(night_rift):
        night_rift.queue_free()
    night_rift = null
    if world != null and world.hud != null:
        if contract_completed:
            world.hud.set_run_objective("КОНТРАКТ ВЫПОЛНЕН")
        else:
            world.hud.set_run_objective("КОНТРАКТ · " + str(contract.get("name", "")))

func on_run_finished(won: bool) -> void:
    if won and str(contract.get("id", "")) == "hearthkeeper":
        var ratio: float = world.base_hp / maxf(1.0, world.base_max_hp)
        if ratio >= 0.75:
            _complete_contract()

func modify_spawn_count(base_count: int) -> int:
    if current_modifier.is_empty():
        return base_count
    return maxi(1, int(round(float(base_count) * float(current_modifier.get("enemy_mult", 1.0)))))

func spawn_interval_multiplier() -> float:
    return float(current_modifier.get("spawn_interval_mult", 1.0))

func turret_damage_multiplier() -> float:
    return float(current_modifier.get("tower_damage_mult", 1.0))

func turret_fire_multiplier() -> float:
    return float(current_modifier.get("tower_fire_mult", 1.0))

func base_damage_multiplier() -> float:
    return float(current_modifier.get("base_damage_mult", 1.0))

func reward_multiplier() -> float:
    return float(current_modifier.get("reward_mult", 1.0))

func pick_enemy_kind(default_kind: String, is_boss: bool = false) -> String:
    if is_boss or current_modifier.is_empty():
        return default_kind
    var bias: String = str(current_modifier.get("bias", ""))
    if not bias.is_empty() and randf() < 0.36:
        return bias
    return default_kind

func tune_enemy(enemy: AxEnemy) -> void:
    if enemy == null or not is_instance_valid(enemy) or enemy.boss:
        return
    enemy.max_hp *= float(current_modifier.get("enemy_hp_mult", 1.0))
    enemy.hp = enemy.max_hp
    enemy.contact_damage *= float(current_modifier.get("enemy_damage_mult", 1.0))
    enemy.move_speed *= float(current_modifier.get("enemy_speed_mult", 1.0))
    enemy.set_meta("variation_tuned", true)

func blocks_night_end() -> bool:
    return night_rift != null and is_instance_valid(night_rift) and not night_rift.dying

func threat_name() -> String:
    var value: float = effective_threat if world != null and world.phase == "night" else threat
    return _threat_name_for(value)

func contract_result() -> Dictionary:
    return {
        "id":str(contract.get("id", "")),
        "name":str(contract.get("name", "")),
        "completed":contract_completed,
        "board":contract_from_board,
        "renown":contract_renown_awarded
    }

func contract_summary() -> String:
    if contract.is_empty():
        return ""
    if contract_completed:
        return "КОНТРАКТ ВЫПОЛНЕН"
    return "%s · %s" % [str(contract.get("name", "")), str(contract.get("desc", ""))]

func _check_contract_progress() -> void:
    if contract_completed or contract.is_empty() or world.activity_director == null:
        return
    var id: String = str(contract.get("id", ""))
    match id:
        "nest_hunter":
            var count: int = world.activity_director.nests_destroyed
            if count >= 2 and world.wave <= 1:
                _complete_contract()
            elif count != last_announced_contract_progress and count > 0:
                last_announced_contract_progress = count
                world.hud.set_status("Контракт: гнёзда %d/2" % count)
        "outer_reach":
            if max_distance_from_hearth >= 720.0 and world.wave <= 1:
                _complete_contract()
        "scavenger":
            var resolved: int = world.activity_director.activities_resolved
            if resolved >= 3 and world.wave <= 1:
                _complete_contract()
            elif resolved != last_announced_contract_progress and resolved > 0:
                last_announced_contract_progress = resolved
                world.hud.set_status("Контракт: события мира %d/3" % resolved)
        "rekindle":
            if world.activity_director.hearths_relit >= 1 and world.wave <= 2:
                _complete_contract()

func _complete_contract() -> void:
    if contract_completed or contract.is_empty() or world == null:
        return
    contract_completed = true
    var reward: int = int(contract.get("reward", 20))
    world.run_coins += reward
    var meta_result: Dictionary = {}
    if contract_from_board:
        meta_result = GameState.complete_contract_meta(str(contract.get("id", "")))
    var renown_gain: int = int(meta_result.get("renown", 0))
    contract_renown_awarded = renown_gain
    world.hud.show_banner("КОНТРАКТ ВЫПОЛНЕН", Color("efcf83"))
    var renown_text: String = " · +%d славы" % renown_gain if renown_gain > 0 else ""
    world.hud.set_status("+%d мон.%s · %s" % [reward, renown_text, str(contract.get("name", ""))])
    world.hud.set_run_objective("КОНТРАКТ ВЫПОЛНЕН · +%d МОН.%s" % [reward, renown_text.to_upper()])
    Feedback.play("level", 12)
    QuestDirector.record("contract_complete", 1, {"id":str(contract.get("id", "")), "biome":world.biome_index})
    Analytics.event("run_contract_completed", {
        "id": str(contract.get("id", "")),
        "reward": reward,
        "wave": world.wave,
        "biome": world.biome_index
    })

func _spawn_night_rift(wave: int) -> void:
    if world == null or world.phase != "night" or world.finishing:
        return
    if night_rift != null and is_instance_valid(night_rift):
        return

    night_rift = NightRift.new()
    world.add_child(night_rift)
    var angle: float = randf_range(0.0, TAU)
    var radius: float = randf_range(145.0, 210.0)
    var point := world.base_position + Vector2(cos(angle), sin(angle)) * radius
    var safe: Rect2 = world.world_rect.grow(-55.0)
    point.x = clampf(point.x, safe.position.x, safe.end.x)
    point.y = clampf(point.y, safe.position.y, safe.end.y)
    night_rift.global_position = point
    night_rift.setup(world, wave)
    night_rift.destroyed.connect(_on_rift_destroyed)
    world.hud.show_banner("РАЗЛОМ ТЬМЫ", Color("d994bd"))
    world.hud.set_status("Разлом вызывает подкрепления. Оставь Очаг и уничтожь его.")
    Analytics.event("night_objective_started", {
        "type":"rift",
        "wave":wave,
        "biome":world.biome_index
    })

func _on_rift_destroyed(_rift: NightRift) -> void:
    if world == null:
        return
    world.run_coins += 12
    reduce_threat(1.5, "rift_destroyed")
    world.hud.show_banner("РАЗЛОМ ЗАКРЫТ", Color("d7cf98"))
    world.hud.set_status("+12 мон. · поток подкреплений остановлен.")
    QuestDirector.record("rift_destroyed", 1, {"wave":world.wave, "biome":world.biome_index})
    Analytics.event("night_objective_completed", {
        "type":"rift",
        "wave":world.wave,
        "biome":world.biome_index
    })
