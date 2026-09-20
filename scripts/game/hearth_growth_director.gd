class_name HearthGrowthDirector
extends Node

signal stage_changed(stage: int, title: String, description: String)

const STAGES: Array[Dictionary] = [
    {
        "stage":0,
        "name":"УГОЛЁК",
        "threshold":0,
        "safe_radius":92.0,
        "deposit_radius":68.0,
        "art_scale":0.82,
        "max_hp_bonus":0.0,
        "home_regen":0.0
    },
    {
        "stage":1,
        "name":"КОСТЁР",
        "threshold":18,
        "safe_radius":118.0,
        "deposit_radius":74.0,
        "art_scale":0.94,
        "max_hp_bonus":40.0,
        "home_regen":0.18
    },
    {
        "stage":2,
        "name":"ПОСЛЕДНИЙ ОЧАГ",
        "threshold":46,
        "safe_radius":150.0,
        "deposit_radius":82.0,
        "art_scale":1.06,
        "max_hp_bonus":105.0,
        "home_regen":0.30
    },
    {
        "stage":3,
        "name":"МАЯК",
        "threshold":86,
        "safe_radius":182.0,
        "deposit_radius":92.0,
        "art_scale":1.18,
        "max_hp_bonus":185.0,
        "home_regen":0.42
    }
]

var world: GameWorld
var delivered_total: int = 0
var stage: int = 0
var applied_max_hp_bonus: float = 0.0
var stage_up_count: int = 0
var last_deposit_total: int = 0

func setup(world_ref: GameWorld) -> void:
    world = world_ref
    delivered_total = 0
    stage = 0
    applied_max_hp_bonus = 0.0
    stage_up_count = 0
    last_deposit_total = 0

func record_deposit(inventory: Dictionary) -> Dictionary:
    var amount: int = (
        int(inventory.get("wood",0))
        + int(inventory.get("stone",0))
        + int(inventory.get("ore",0))
    )
    last_deposit_total = amount
    if amount <= 0:
        return snapshot()

    delivered_total += amount
    var target_stage: int = _stage_for_total(delivered_total)
    if target_stage > stage:
        _advance_to(target_stage)
    return snapshot()

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world) or world.player == null or world.finishing:
        return
    if stage <= 0:
        return

    var distance: float = world.player.global_position.distance_to(world.base_position)
    if distance > safe_radius():
        return

    # Home should feel safe without invalidating night combat.
    var rate: float = home_regen()
    if world.phase == "night":
        rate *= 0.30
    world.player.heal(rate * delta)

func _advance_to(target_stage: int) -> void:
    while stage < target_stage and stage < STAGES.size() - 1:
        stage += 1
        stage_up_count += 1
        var spec: Dictionary = current_spec()
        var desired_bonus: float = float(spec.get("max_hp_bonus",0.0))
        var delta_bonus: float = maxf(0.0, desired_bonus - applied_max_hp_bonus)
        if world != null and delta_bonus > 0.0:
            world.base_max_hp += delta_bonus
            world.base_hp = minf(world.base_max_hp, world.base_hp + delta_bonus)
        applied_max_hp_bonus = desired_bonus

        stage_changed.emit(
            stage,
            str(spec.get("name","ОЧАГ")),
            _stage_description(stage)
        )

func _stage_for_total(total: int) -> int:
    var result: int = 0
    for spec_variant: Variant in STAGES:
        var spec: Dictionary = spec_variant
        if total >= int(spec.get("threshold",0)):
            result = int(spec.get("stage",0))
    return clampi(result,0,STAGES.size()-1)

func current_spec() -> Dictionary:
    return STAGES[clampi(stage,0,STAGES.size()-1)].duplicate(true)

func safe_radius() -> float:
    return float(current_spec().get("safe_radius",92.0))

func deposit_radius() -> float:
    return float(current_spec().get("deposit_radius",68.0))

func art_scale() -> float:
    return float(current_spec().get("art_scale",0.82))

func home_regen() -> float:
    return float(current_spec().get("home_regen",0.0))

func next_threshold() -> int:
    var next_stage: int = stage + 1
    if next_stage >= STAGES.size():
        return delivered_total
    return int((STAGES[next_stage] as Dictionary).get("threshold",delivered_total))

func progress_to_next() -> float:
    if stage >= STAGES.size() - 1:
        return 1.0
    var current_threshold: int = int(current_spec().get("threshold",0))
    var target: int = next_threshold()
    return clampf(
        float(delivered_total - current_threshold) / float(maxi(1,target-current_threshold)),
        0.0,
        1.0
    )

func snapshot() -> Dictionary:
    var spec: Dictionary = current_spec()
    return {
        "stage":stage,
        "name":str(spec.get("name","УГОЛЁК")),
        "delivered":delivered_total,
        "next_threshold":next_threshold(),
        "progress":progress_to_next(),
        "safe_radius":safe_radius(),
        "deposit_radius":deposit_radius(),
        "stage_ups":stage_up_count
    }

func _stage_description(value: int) -> String:
    match value:
        1:
            return "Принесённые ресурсы разожгли настоящий костёр. Очаг крепче, а рядом с ним Странник понемногу восстанавливается."
        2:
            return "Последний Очаг окреп. Тёплая территория расширилась, запас прочности вырос, возвращаться домой стало безопаснее."
        3:
            return "Очаг стал Маяком. Его свет виден издалека, территория дома максимальна, а защита достигла пика этого забега."
        _:
            return "Тепло Последнего Очагa растёт вместе с лагерем."
