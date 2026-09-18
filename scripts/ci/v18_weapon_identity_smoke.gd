extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["weapons_owned"] = ["axes", "spear", "hammer", "twin_blades"]
    GameState.data["selected_weapon"] = "axes"

    _test_profile_identity()
    _test_weapon_perk_offers()
    await _test_runtime_attacks()

    if failures.is_empty():
        print("[V1.8 WEAPONS] four combat identities and exclusive perks passed")
    _finish()

func _test_profile_identity() -> void:
    var styles: Dictionary = {}
    for weapon_id: String in WeaponRules.ordered_ids():
        var profile: Dictionary = WeaponRules.profile(weapon_id)
        var style: String = str(profile.get("style", ""))
        styles[style] = true
        if str(profile.get("identity", "")).is_empty():
            _fail("Weapon has no identity text: " + weapon_id)
        if str(profile.get("signature", "")).is_empty():
            _fail("Weapon has no signature text: " + weapon_id)
        if not profile.has("damage_factor") or not profile.has("harvest_mult"):
            _fail("Weapon lacks v1.8 mechanic data: " + weapon_id)

    if styles.size() != 4:
        _fail("Expected four unique weapon styles")

    if WeaponRules.mechanic_value("spear", "attack_range", 0.0) <= WeaponRules.mechanic_value("twin_blades", "attack_range", 0.0):
        _fail("Spear must outrange Twin Blades")
    if WeaponRules.mechanic_value("hammer", "attack_cooldown", 0.0) <= WeaponRules.mechanic_value("twin_blades", "attack_cooldown", 0.0):
        _fail("Hammer must have a slower attack rhythm than Twin Blades")

func _test_weapon_perk_offers() -> void:
    for weapon_id: String in WeaponRules.ordered_ids():
        var choices: Array = GameRules.random_perks(3, weapon_id)
        if choices.size() != 3:
            _fail("Perk offer did not return three choices for " + weapon_id)
            continue
        var found_weapon_perk: bool = false
        for choice_variant: Variant in choices:
            var choice: Dictionary = choice_variant as Dictionary
            if str(choice.get("weapon", "")) == weapon_id:
                found_weapon_perk = true
        if not found_weapon_perk:
            _fail("Perk offer lacks weapon-exclusive option for " + weapon_id)

func _test_runtime_attacks() -> void:
    var world: GameWorld = GameScene.instantiate() as GameWorld
    add_child(world)
    world.configure(0)
    await _wait_frames(7)
    world.paused_local = true

    await _test_axes(world)
    await _test_spear(world)
    await _test_hammer(world)
    await _test_twin_blades(world)

    # Perk state must actually feed the resolver.
    world.player.apply_weapon_profile("spear")
    var pierce_before: int = world.player.spear_pierce_bonus
    world.player.apply_perk("spear_pierce")
    if world.player.spear_pierce_bonus != pierce_before + 1:
        _fail("Spear exclusive perk did not modify runtime state")

    world.player.apply_weapon_profile("hammer")
    var radius_before: float = world.player.hammer_radius_bonus
    world.player.apply_perk("hammer_crater")
    if world.player.hammer_radius_bonus <= radius_before:
        _fail("Hammer exclusive perk did not modify runtime state")

    world.queue_free()
    await _wait_frames(3)

func _test_axes(world: GameWorld) -> void:
    world.player.apply_weapon_profile("axes")
    world.player.crit_chance = 0.0
    world.weapon_attack_timer = 0.0

    var near := _make_enemy(world, Vector2(34, 0))
    var far := _make_enemy(world, Vector2(100, 0))
    var near_before: float = near.hp
    var far_before: float = far.hp

    world._resolve_player_weapon([near, far], 0.20)

    if near.hp >= near_before:
        _fail("Axes failed to damage enemy inside orbit")
    if far.hp < far_before:
        _fail("Axes damaged enemy outside orbit")
    if world.weapon_last_hit_count != 1:
        _fail("Axes hit accounting is incorrect")

    await _dispose([near, far])

func _test_spear(world: GameWorld) -> void:
    world.player.apply_weapon_profile("spear")
    world.player.crit_chance = 0.0
    world.weapon_attack_timer = 0.0

    var front_a := _make_enemy(world, Vector2(52, 0))
    var front_b := _make_enemy(world, Vector2(98, 0))
    var side := _make_enemy(world, Vector2(0, 72))
    var a_before: float = front_a.hp
    var b_before: float = front_b.hp
    var side_before: float = side.hp

    world._resolve_player_weapon([front_a, front_b, side], 0.10)

    if front_a.hp >= a_before or front_b.hp >= b_before:
        _fail("Spear did not pierce enemies on its line")
    if side.hp < side_before:
        _fail("Spear incorrectly behaved like radial damage")
    if world.weapon_last_hit_count < 2:
        _fail("Spear pierce count did not register multiple line targets")

    await _dispose([front_a, front_b, side])

func _test_hammer(world: GameWorld) -> void:
    world.player.apply_weapon_profile("hammer")
    world.player.crit_chance = 0.0
    world.weapon_attack_timer = 0.0

    var near_a := _make_enemy(world, Vector2(28, 0))
    var near_b := _make_enemy(world, Vector2(0, 48))
    var far := _make_enemy(world, Vector2(105, 0))
    var distance_before: float = world.player.global_position.distance_to(near_a.global_position)
    var hp_a: float = near_a.hp
    var hp_b: float = near_b.hp
    var hp_far: float = far.hp

    world._resolve_player_weapon([near_a, near_b, far], 0.10)

    if near_a.hp >= hp_a or near_b.hp >= hp_b:
        _fail("Hammer slam did not hit nearby group")
    if far.hp < hp_far:
        _fail("Hammer slam reached beyond its intended radius")
    if world.player.global_position.distance_to(near_a.global_position) <= distance_before:
        _fail("Hammer slam did not knock enemy away")
    if world.weapon_attack_timer <= 0.7:
        _fail("Hammer did not enter its slow attack cooldown")

    await _dispose([near_a, near_b, far])

func _test_twin_blades(world: GameWorld) -> void:
    world.player.apply_weapon_profile("twin_blades")
    world.player.crit_chance = 0.0
    world.weapon_attack_timer = 0.0
    world.weapon_combo = 0
    world.weapon_combo_timeout = 0.0

    var near_a := _make_enemy(world, Vector2(28, 0))
    var near_b := _make_enemy(world, Vector2(0, 38))
    var far := _make_enemy(world, Vector2(90, 0))

    var hp_a: float = near_a.hp
    var hp_b: float = near_b.hp
    var hp_far: float = far.hp
    world._resolve_player_weapon([near_a, near_b, far], 0.10)

    var first_damage: float = hp_a - near_a.hp
    if first_damage <= 0.0 or near_b.hp >= hp_b:
        _fail("Twin Blades did not strike two nearby targets")
    if far.hp < hp_far:
        _fail("Twin Blades reached a distant target")
    if world.weapon_combo != 1:
        _fail("Twin Blades did not start combo")

    world.weapon_attack_timer = 0.0
    var second_before: float = near_a.hp
    world._resolve_player_weapon([near_a, near_b, far], 0.10)
    var second_damage: float = second_before - near_a.hp
    if world.weapon_combo != 2:
        _fail("Twin Blades combo did not build on continued aggression")
    if second_damage <= first_damage:
        _fail("Twin Blades combo did not increase follow-up damage")

    world._resolve_player_weapon([far], 1.0)
    if world.weapon_combo != 0:
        _fail("Twin Blades combo did not decay after disengaging")

    await _dispose([near_a, near_b, far])

func _make_enemy(world: GameWorld, offset: Vector2) -> AxEnemy:
    var enemy := AxEnemy.new()
    world.add_child(enemy)
    enemy.configure("normal", 1.0, 1, Color("6e5d76"), false)
    enemy.max_hp = 1000.0
    enemy.hp = 1000.0
    enemy.armor = 0.0
    enemy.global_position = world.player.global_position + offset
    return enemy

func _dispose(nodes: Array) -> void:
    for node_variant: Variant in nodes:
        var node: Node = node_variant as Node
        if node != null and is_instance_valid(node):
            node.queue_free()
    await _wait_frames(2)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.8 WEAPONS] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.8 WEAPONS] %s" % failure)
    get_tree().quit(1)
