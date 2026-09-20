class_name AxPlayer
extends CharacterBody2D

signal died
signal damaged(amount: float, blocked: bool)
signal level_up_requested(level: int)
signal build_evolved(evolution_id: String, title: String, description: String)
signal legendary_triggered(title: String, description: String)

const WANDERER_ART: Texture2D = preload("res://assets/art/forgotten_forest/wanderer.png")

var target_position: Vector2 = Vector2.ZERO
var move_input: Vector2 = Vector2.ZERO
var direct_control: bool = false
var move_speed: float = 138.0
var max_hp: float = 100.0
var hp: float = 100.0
var damage: float = 25.0
var capacity: int = 24
var axes: int = 1
var orbit_radius: float = 44.0
var crit_chance: float = 0.05
var shield_hits: int = 0
var angle: float = 0.0
var xp: int = 0
var level: int = 1
var next_xp: int = 16
var inventory: Dictionary = {"wood": 0, "stone": 0, "ore": 0}
var skin_body: Color = Color("466bc8")
var skin_cape: Color = Color("364f9c")
var motion_time: float = 0.0
var damage_flash: float = 0.0
var block_flash: float = 0.0
var perk_flash: float = 0.0
var facing_x: float = 1.0
var weapon_id: String = "axes"
var weapon_style: String = "axes"
var base_meta_damage: float = 25.0
var base_meta_speed: float = 138.0
var base_meta_crit: float = 0.05
var movement_bounds: Rect2 = Rect2()
var has_movement_bounds: bool = false
var home_target: Vector2 = Vector2.ZERO
var home_hint_active: bool = false
var weapon_action_time: float = 0.0
var weapon_action_duration: float = 0.24
var weapon_action_direction: Vector2 = Vector2.RIGHT
var weapon_combo_visual: int = 0

# Weapon-exclusive perk state. These are reset at the beginning of each run.
var axes_dps_bonus: float = 1.0
var spear_pierce_bonus: int = 0
var spear_damage_bonus: float = 1.0
var hammer_radius_bonus: float = 0.0
var hammer_damage_bonus: float = 1.0
var blades_combo_cap_bonus: int = 0
var blades_combo_step_bonus: float = 0.0
var blades_combo_timeout_bonus: float = 0.0
var weapon_cooldown_mult: float = 1.0
var environment_speed_mult: float = 1.0
var environment_speed_time: float = 0.0
var orbit_visual_boost: float = 1.0
var harvest_heal_per_node: float = 0.0
var hearth_damage_bonus: float = 0.0
var loaded_pack_damage_bonus: float = 0.0
var kill_heal_every: int = 0
var kill_heal_amount: float = 0.0
var field_target: Vector2 = Vector2.ZERO
var field_hint_active: bool = false
var field_hint_color: Color = Color("d5a652")
var damage_grace_time: float = 0.0
var fire_orb_level: int = 0
var frost_aura_level: int = 0
var thorn_ring_level: int = 0
var guardian_spirit_level: int = 0
var crit_multiplier: float = 2.0
var phoenix_charges: int = 0
var perk_counts: Dictionary = {}
var family_counts: Dictionary = {}
var evolutions: Dictionary = {}
var legendary_traits: Dictionary = {}
var visual_identity_version: int = 3

func setup(meta_upgrades: Dictionary, skin: Dictionary) -> void:
    var hp_level: int = int(meta_upgrades.get("hp", 0))
    var damage_level: int = int(meta_upgrades.get("damage", 0))
    var bag_level: int = int(meta_upgrades.get("bag", 0))
    var speed_level: int = int(meta_upgrades.get("speed", 0))
    max_hp = 100.0 + hp_level * 10.0
    hp = max_hp
    base_meta_damage = 25.0 * pow(1.10, damage_level)
    base_meta_speed = 138.0 * pow(1.04, speed_level)
    base_meta_crit = 0.05
    capacity = 24 + bag_level * 5
    skin_body = Color(str(skin.get("body", "466bc8")))
    skin_cape = Color(str(skin.get("cape", "364f9c")))
    target_position = global_position
    apply_weapon_profile(str(GameState.data.get("selected_weapon", "axes")))
    queue_redraw()

func visual_identity_profile() -> Dictionary:
    return {
        "version":visual_identity_version,
        "silhouette":"hooded_wanderer",
        "anchor":"hearth_rune",
        "weapon_readable":true,
        "build_reactive":true,
        "production_art":true,
        "art_texture":"res://assets/art/forgotten_forest/wanderer.png"
    }

func apply_weapon_profile(id: String) -> void:
    weapon_id = id if WeaponRules.WEAPONS.has(id) else "axes"
    var profile: Dictionary = WeaponRules.profile(weapon_id)
    weapon_style = str(profile.get("style", weapon_id))
    damage = base_meta_damage * float(profile.get("damage_mult", 1.0))
    weapon_action_time = 0.0
    weapon_combo_visual = 0
    move_speed = base_meta_speed * float(profile.get("speed_mult", 1.0))
    orbit_radius = float(profile.get("orbit_radius", 44.0))
    axes = int(profile.get("axes", 1))
    crit_chance = clampf(base_meta_crit + float(profile.get("crit_bonus", 0.0)), 0.0, 0.65)

    # Reset run-only weapon perks before applying persistent mastery.
    axes_dps_bonus = 1.0
    spear_pierce_bonus = 0
    spear_damage_bonus = 1.0
    hammer_radius_bonus = 0.0
    hammer_damage_bonus = 1.0
    blades_combo_cap_bonus = 0
    blades_combo_step_bonus = 0.0
    blades_combo_timeout_bonus = 0.0
    weapon_cooldown_mult = 1.0
    harvest_heal_per_node = 0.0
    hearth_damage_bonus = 0.0
    loaded_pack_damage_bonus = 0.0
    kill_heal_every = 0
    kill_heal_amount = 0.0
    fire_orb_level = 0
    frost_aura_level = 0
    thorn_ring_level = 0
    guardian_spirit_level = 0
    crit_multiplier = 2.0
    phoenix_charges = 0
    perk_counts.clear()
    family_counts.clear()
    evolutions.clear()
    legendary_traits.clear()
    _apply_weapon_mastery(GameState.weapon_mastery_level(weapon_id))

    perk_flash = 1.0
    queue_redraw()

func _apply_weapon_mastery(level_value: int) -> void:
    match weapon_id:
        "axes":
            if level_value >= 2:
                orbit_radius += 4.0
            if level_value >= 4:
                axes_dps_bonus *= 1.08
        "spear":
            if level_value >= 2:
                spear_pierce_bonus += 1
            if level_value >= 4:
                weapon_cooldown_mult *= 0.92
        "hammer":
            if level_value >= 2:
                hammer_radius_bonus += 6.0
            if level_value >= 4:
                hammer_damage_bonus *= 1.08
        "twin_blades":
            if level_value >= 2:
                blades_combo_cap_bonus += 1
            if level_value >= 4:
                blades_combo_timeout_bonus += 0.12

func weapon_name() -> String:
    return str(WeaponRules.profile(weapon_id).get("name", "Топоры Странника"))

func _physics_process(delta: float) -> void:
    motion_time += delta
    damage_flash = maxf(0.0, damage_flash - delta * 4.8)
    block_flash = maxf(0.0, block_flash - delta * 3.6)
    perk_flash = maxf(0.0, perk_flash - delta * 2.0)
    damage_grace_time = maxf(0.0, damage_grace_time - delta)
    weapon_action_time = maxf(0.0, weapon_action_time - delta)
    environment_speed_time = maxf(0.0, environment_speed_time - delta)
    if environment_speed_time <= 0.0:
        environment_speed_mult = move_toward(environment_speed_mult, 1.0, delta * 2.8)

    var movement: Vector2 = Vector2.ZERO
    var analog_strength: float = 1.0

    if direct_control:
        movement = move_input
        analog_strength = clampf(move_input.length(), 0.0, 1.0)
    else:
        var distance: float = global_position.distance_to(target_position)
        if distance > 4.0:
            movement = global_position.direction_to(target_position)

    if movement.length_squared() > 0.0025:
        var direction: Vector2 = movement.normalized()
        if absf(direction.x) > 0.08:
            facing_x = signf(direction.x)
        velocity = direction * move_speed * environment_speed_mult * analog_strength
        move_and_slide()
        if has_movement_bounds:
            global_position = Vector2(
                clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x),
                clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)
            )
        if direct_control:
            target_position = global_position
    else:
        velocity = Vector2.ZERO

    var rotation_speed: float = 3.65 + float(axes - 1) * 0.06
    if weapon_style == "hammer":
        rotation_speed *= 0.76
    elif weapon_style == "twin_blades":
        rotation_speed *= 1.22
    elif weapon_style == "spear":
        rotation_speed *= 0.88
    angle += delta * rotation_speed
    queue_redraw()

func apply_environment_slow(multiplier: float, duration: float) -> void:
    environment_speed_mult = minf(environment_speed_mult, clampf(multiplier, 0.45, 1.0))
    environment_speed_time = maxf(environment_speed_time, maxf(0.1, duration))

func clear_environment_slow() -> void:
    environment_speed_mult = 1.0
    environment_speed_time = 0.0

func trigger_weapon_action(direction: Vector2, duration: float = 0.24) -> void:
    if direction.length_squared() > 0.001:
        weapon_action_direction = direction.normalized()
        facing_x = signf(weapon_action_direction.x) if absf(weapon_action_direction.x) > 0.05 else facing_x
    weapon_action_duration = maxf(0.05, duration)
    weapon_action_time = weapon_action_duration
    queue_redraw()

func set_weapon_combo_visual(value: int) -> void:
    if weapon_combo_visual == value:
        return
    weapon_combo_visual = maxi(0, value)
    queue_redraw()

func weapon_action_ratio() -> float:
    if weapon_action_duration <= 0.0:
        return 0.0
    return clampf(weapon_action_time / weapon_action_duration, 0.0, 1.0)

func set_target(pos: Vector2) -> void:
    if direct_control:
        return
    target_position = pos

func set_world_bounds(rect: Rect2) -> void:
    movement_bounds = rect
    has_movement_bounds = rect.size.x > 0.0 and rect.size.y > 0.0

func set_home_target(pos: Vector2) -> void:
    home_target = pos

func set_home_hint(value: bool) -> void:
    if home_hint_active == value:
        return
    home_hint_active = value
    queue_redraw()

func set_field_target(pos: Vector2, active: bool, color: Color) -> void:
    field_target = pos
    field_hint_active = active
    field_hint_color = color
    queue_redraw()

func set_move_input(value: Vector2) -> void:
    move_input = value.limit_length(1.0)
    direct_control = true
    target_position = global_position

func release_move_input() -> void:
    move_input = Vector2.ZERO
    direct_control = false
    target_position = global_position
    velocity = Vector2.ZERO

func inventory_total() -> int:
    return int(inventory["wood"]) + int(inventory["stone"]) + int(inventory["ore"])

func add_resource(kind: String, amount: int) -> int:
    var available: int = maxi(0, capacity - inventory_total())
    var actual: int = mini(amount, available)
    inventory[kind] = int(inventory.get(kind, 0)) + actual
    queue_redraw()
    return actual

func clear_inventory() -> Dictionary:
    var result: Dictionary = inventory.duplicate(true)
    inventory = {"wood": 0, "stone": 0, "ore": 0}
    queue_redraw()
    return result

func take_damage(amount: float) -> void:
    if damage_grace_time > 0.0:
        return
    if shield_hits > 0:
        damage_grace_time = 0.20
        shield_hits -= 1
        block_flash = 1.0
        Feedback.play("shield", 24)
        damaged.emit(0.0, true)
        queue_redraw()
        return
    damage_grace_time = 0.52
    hp = maxf(0.0, hp - amount)
    damage_flash = 1.0
    Feedback.play("hit", 38)
    damaged.emit(amount, false)
    if hp <= 0.0:
        if phoenix_charges > 0:
            phoenix_charges -= 1
            hp = maxf(1.0, max_hp * 0.38)
            shield_hits = mini(5, shield_hits + 2)
            damage_grace_time = 1.15
            perk_flash = 1.0
            Feedback.play("level", 28)
            legendary_triggered.emit("ПОСЛЕДНЯЯ ИСКРА", "Смертельный удар сожжён. Странник вернулся с 38% HP и двумя зарядами щита.")
            queue_redraw()
            return
        died.emit()

func heal(amount: float) -> void:
    hp = minf(max_hp, hp + amount)

func gain_xp(amount: int) -> void:
    xp += amount
    if xp >= next_xp:
        xp -= next_xp
        level += 1
        next_xp = int(round(next_xp * 1.38))
        perk_flash = 1.0
        Feedback.play("level", 18)
        level_up_requested.emit(level)

func apply_perk(id: String) -> void:
    match id:
        "axe":
            axes = mini(8, axes + 1)
        "damage":
            damage *= 1.22
        "orbit":
            orbit_radius *= 1.16
        "speed":
            move_speed *= 1.14
        "hp":
            max_hp += 25.0
            hp = minf(max_hp, hp + 35.0)
        "bag":
            capacity += 8
        "crit":
            crit_chance = minf(0.60, crit_chance + 0.12)
        "shield":
            shield_hits += 3
        "axes_whirl":
            axes_dps_bonus *= 1.18
        "axes_edge":
            orbit_radius += 8.0
            crit_chance = minf(0.70, crit_chance + 0.05)
        "spear_pierce":
            spear_pierce_bonus += 1
        "spear_impale":
            spear_damage_bonus *= 1.22
        "hammer_crater":
            hammer_radius_bonus += 14.0
        "hammer_force":
            hammer_damage_bonus *= 1.22
        "blades_chain":
            blades_combo_cap_bonus += 2
        "blades_fury":
            blades_combo_step_bonus += 0.03
        "harvest_heal":
            harvest_heal_per_node += 3.0
        "hearth_aura":
            hearth_damage_bonus += 0.35
        "loaded_pack":
            loaded_pack_damage_bonus += 0.25
        "hunter_rhythm":
            kill_heal_every = 10 if kill_heal_every == 0 else mini(kill_heal_every, 10)
            kill_heal_amount += 12.0
        "fire_orb":
            fire_orb_level = mini(3, fire_orb_level + 1)
        "frost_aura":
            frost_aura_level = mini(3, frost_aura_level + 1)
        "thorn_ring":
            thorn_ring_level = mini(3, thorn_ring_level + 1)
        "guardian_spirit":
            guardian_spirit_level = mini(3, guardian_spirit_level + 1)
            shield_hits += 1
        "phoenix_oath":
            phoenix_charges += 1
            fire_orb_level = maxi(1, fire_orb_level)
            legendary_traits[id] = true
        "storm_crown":
            axes = mini(8, axes + 2)
            axes_dps_bonus *= 1.35
            orbit_radius += 10.0
            legendary_traits[id] = true
        "eternal_winter":
            frost_aura_level = 3
            move_speed *= 1.08
            legendary_traits[id] = true
        "hearthbound":
            max_hp += 40.0
            hp = minf(max_hp, hp + 40.0)
            hearth_damage_bonus += 0.65
            guardian_spirit_level = maxi(1, guardian_spirit_level)
            legendary_traits[id] = true
        "blood_moon":
            crit_chance = minf(0.72, crit_chance + 0.15)
            crit_multiplier += 0.65
            kill_heal_every = 6 if kill_heal_every == 0 else mini(kill_heal_every, 6)
            kill_heal_amount = maxf(kill_heal_amount, 10.0)
            legendary_traits[id] = true
        "worldroot":
            thorn_ring_level = 3
            harvest_heal_per_node += 4.0
            capacity += 8
            legendary_traits[id] = true
        _:
            return

    _register_buildcraft(id)
    perk_flash = 1.0
    queue_redraw()

func has_perk(id: String) -> bool:
    return int(perk_counts.get(id,0)) > 0

func perk_count(id: String) -> int:
    return int(perk_counts.get(id,0))

func family_count(family: String) -> int:
    return int(family_counts.get(family,0))

func has_evolution(family: String) -> bool:
    return bool(evolutions.get(family,false))

func _register_buildcraft(id: String) -> void:
    perk_counts[id] = int(perk_counts.get(id,0)) + 1
    var family: String = GameRules.perk_family(id)
    if family.is_empty():
        return
    family_counts[family] = int(family_counts.get(family,0)) + 1
    if int(family_counts[family]) >= 3 and not has_evolution(family):
        _activate_evolution(family)

func _activate_evolution(family: String) -> void:
    var spec: Dictionary = GameRules.evolution_for_family(family)
    if spec.is_empty():
        return
    evolutions[family] = true
    match family:
        "flame":
            fire_orb_level = maxi(3, fire_orb_level)
            damage *= 1.10
        "steel":
            axes = mini(8, axes + 1)
            orbit_radius += 8.0
            axes_dps_bonus *= 1.16
        "frost":
            frost_aura_level = maxi(3, frost_aura_level)
            move_speed *= 1.06
        "guardian":
            max_hp += 30.0
            hp = minf(max_hp, hp + 30.0)
            guardian_spirit_level = maxi(2, guardian_spirit_level)
            shield_hits = mini(5, shield_hits + 2)
        "hunt":
            crit_chance = minf(0.72, crit_chance + 0.10)
            crit_multiplier += 0.40
            kill_heal_every = 6 if kill_heal_every == 0 else mini(kill_heal_every, 6)
            kill_heal_amount = maxf(kill_heal_amount, 8.0)
        "roots":
            thorn_ring_level = maxi(3, thorn_ring_level)
            harvest_heal_per_node += 2.0
            max_hp += 18.0
            hp = minf(max_hp, hp + 18.0)
    build_evolved.emit(str(spec.get("id","")), str(spec.get("name","ЭВОЛЮЦИЯ")), str(spec.get("desc","")))

func buildcraft_snapshot() -> Dictionary:
    var evolution_list: Array[Dictionary] = []
    for family: String in ["flame","steel","frost","guardian","hunt","roots"]:
        if not has_evolution(family):
            continue
        var spec: Dictionary = GameRules.evolution_for_family(family)
        if not spec.is_empty():
            evolution_list.append(spec)

    var legendary_list: Array[Dictionary] = []
    for perk_id: String in legendary_traits.keys():
        if not bool(legendary_traits.get(perk_id,false)):
            continue
        var spec: Dictionary = GameRules.perk_spec(perk_id)
        if not spec.is_empty():
            legendary_list.append(spec)

    var top_family: String = ""
    var top_count: int = 0
    for family: String in ["flame","steel","frost","guardian","hunt","roots"]:
        var count: int = family_count(family)
        if count > top_count:
            top_count = count
            top_family = family

    return {
        "perk_counts":perk_counts.duplicate(true),
        "families":family_counts.duplicate(true),
        "evolutions":evolution_list,
        "legendaries":legendary_list,
        "top_family":top_family,
        "top_count":top_count
    }

func _draw() -> void:
    var moving: bool = velocity.length_squared() > 36.0
    var bob: float = round(sin(motion_time * (10.0 if moving else 2.2)) * (1.0 if moving else 0.35))
    var stride: int = int(round(sin(motion_time * 11.0) * 2.0)) if moving else 0
    var body_offset := Vector2(0, bob)
    var action_ratio: float = weapon_action_ratio()
    if weapon_action_time > 0.0:
        if weapon_style == "spear" or weapon_style == "twin_blades":
            body_offset += weapon_action_direction.normalized() * (3.0 + action_ratio * 2.0)
        elif weapon_style == "hammer":
            body_offset += Vector2(0, 2.0 + (1.0 - action_ratio) * 2.0)

    var shadow_scale: float = 1.0 + (0.08 if weapon_action_time > 0.0 else 0.0)
    _draw_shadow_ellipse(Vector2(0, 18), Vector2(14.5 * shadow_scale, 4.8), Color(0.025, 0.035, 0.03, 0.30))
    _draw_relic_auras()

    var radius: float = orbit_radius + axes * 4.0
    if weapon_style == "axes" or weapon_style == "twin_blades":
        for i: int in range(axes):
            var weapon_angle: float = angle + float(i) * TAU / float(maxi(1, axes))
            var trail_color: Color = Color(0.95, 0.58, 0.36, 0.17) if weapon_style == "twin_blades" else Color(0.82, 0.90, 0.95, 0.13)
            draw_arc(Vector2.ZERO, radius, weapon_angle - 0.34, weapon_angle - 0.08, 7, trail_color, 4.0)
    elif weapon_style == "spear":
        var idle_spear_angle: float = angle
        var idle_spear_dir := Vector2(cos(idle_spear_angle), sin(idle_spear_angle))
        draw_arc(Vector2.ZERO, radius, idle_spear_angle - 0.28, idle_spear_angle + 0.04, 9, Color(0.58, 0.82, 0.61, 0.16), 3.0)
        if weapon_action_time > 0.0:
            var spear_dir: Vector2 = weapon_action_direction.normalized()
            draw_line(spear_dir * 16.0, spear_dir * 112.0, Color(0.58, 0.82, 0.61, 0.20 + weapon_action_ratio() * 0.28), 5.0)
    elif weapon_style == "hammer":
        var hammer_idle_angle: float = angle * 0.72
        draw_arc(Vector2.ZERO, radius, hammer_idle_angle - 0.42, hammer_idle_angle - 0.08, 9, Color(0.62, 0.83, 0.94, 0.13), 5.0)
        if weapon_action_time > 0.0:
            var slam_radius: float = 42.0 + (1.0 - weapon_action_ratio()) * 20.0
            draw_arc(Vector2.ZERO, slam_radius, 0.0, TAU, 30, Color(0.62, 0.83, 0.94, weapon_action_ratio() * 0.42), 3.0)

    # Production silhouette: hooded wanderer with readable cape, shoulders and satchel.
    var cape_shift: float = -facing_x * (4.0 if moving else 1.5)
    if weapon_action_time > 0.0:
        cape_shift -= facing_x * 2.5 * action_ratio

    var cape_color: Color = skin_cape.darkened(0.04)
    var cape_shadow: Color = cape_color.darkened(0.25)
    var cape := PackedVector2Array([
        body_offset + Vector2(-10 + cape_shift, -5),
        body_offset + Vector2(-12 + cape_shift, 9),
        body_offset + Vector2(-8 + cape_shift, 19),
        body_offset + Vector2(-3 + cape_shift, 17),
        body_offset + Vector2(1 + cape_shift, 24),
        body_offset + Vector2(5 + cape_shift, 18),
        body_offset + Vector2(9 + cape_shift, 20),
        body_offset + Vector2(11 + cape_shift, 7),
        body_offset + Vector2(8 + cape_shift, -5)
    ])
    draw_colored_polygon(cape, cape_shadow)
    var cape_inner := PackedVector2Array([
        body_offset + Vector2(-8 + cape_shift, -4),
        body_offset + Vector2(-9 + cape_shift, 8),
        body_offset + Vector2(-5 + cape_shift, 16),
        body_offset + Vector2(0 + cape_shift, 19),
        body_offset + Vector2(7 + cape_shift, 15),
        body_offset + Vector2(8 + cape_shift, -3)
    ])
    draw_colored_polygon(cape_inner, cape_color)
    draw_line(body_offset + Vector2(-7 + cape_shift, 7), body_offset + Vector2(6 + cape_shift, 13), cape_color.lightened(0.14), 1.2)

    var flash_body: Color = skin_body.lightened(damage_flash * 0.40)
    var armor_dark: Color = flash_body.darkened(0.34)
    var cloth_dark: Color = Color("253039")
    var leather: Color = Color("8f6740")
    var skin: Color = Color("d4a077").lightened(damage_flash * 0.16)

    # Legs and boots — slightly exaggerated so movement reads on a phone.
    draw_colored_polygon(PackedVector2Array([
        body_offset + Vector2(-7 + stride, 8),
        body_offset + Vector2(-1 + stride, 8),
        body_offset + Vector2(-2 + stride, 19),
        body_offset + Vector2(-8 + stride, 19)
    ]), cloth_dark)
    draw_colored_polygon(PackedVector2Array([
        body_offset + Vector2(2 - stride, 8),
        body_offset + Vector2(8 - stride, 8),
        body_offset + Vector2(9 - stride, 19),
        body_offset + Vector2(3 - stride, 19)
    ]), cloth_dark)
    draw_rect(Rect2(body_offset + Vector2(-9 + stride, 17), Vector2(8, 4)), Color("171c20"))
    draw_rect(Rect2(body_offset + Vector2(2 - stride, 17), Vector2(8, 4)), Color("171c20"))

    # Torso / armor. Broad shoulders make the hero distinct from thin runners.
    var torso := PackedVector2Array([
        body_offset + Vector2(-10, -6),
        body_offset + Vector2(-13, 0),
        body_offset + Vector2(-9, 11),
        body_offset + Vector2(0, 15),
        body_offset + Vector2(9, 11),
        body_offset + Vector2(13, 0),
        body_offset + Vector2(10, -6)
    ])
    draw_colored_polygon(torso, Color("1c2429"))
    var chest := PackedVector2Array([
        body_offset + Vector2(-8, -5),
        body_offset + Vector2(-10, 1),
        body_offset + Vector2(-6, 10),
        body_offset + Vector2(0, 12),
        body_offset + Vector2(6, 10),
        body_offset + Vector2(10, 1),
        body_offset + Vector2(8, -5)
    ])
    draw_colored_polygon(chest, flash_body)
    draw_line(body_offset + Vector2(-8, -4), body_offset + Vector2(-10, 2), flash_body.lightened(0.24), 1.4)
    draw_line(body_offset + Vector2(-7, 1), body_offset + Vector2(7, 1), flash_body.lightened(0.16), 1.4)
    draw_line(body_offset + Vector2(-6, 8), body_offset + Vector2(6, 8), leather, 3.0)
    # The Last Hearth rune is the hero's permanent visual anchor.
    draw_circle(body_offset + Vector2(0, 5), 4.0, Color(0.08, 0.10, 0.10, 0.60))
    draw_circle(body_offset + Vector2(0, 5), 2.4, VisualSystem.GOLD.darkened(0.12))
    draw_line(body_offset + Vector2(0, 1), body_offset + Vector2(0, 9), VisualSystem.GOLD_BRIGHT, 1.2)

    # Shoulder guards and hands.
    draw_circle(body_offset + Vector2(-10.5, -1.5), 4.0, armor_dark)
    draw_circle(body_offset + Vector2(10.5, -1.5), 4.0, armor_dark)
    draw_arc(body_offset + Vector2(-10.5, -1.5), 4.0, 3.4, 5.8, 8, Color("aeb9bb"), 1.2)
    draw_arc(body_offset + Vector2(10.5, -1.5), 4.0, 3.6, 6.0, 8, Color("aeb9bb"), 1.2)
    draw_rect(Rect2(body_offset + Vector2(-14, 2), Vector2(4, 7)), armor_dark)
    draw_rect(Rect2(body_offset + Vector2(10, 2), Vector2(4, 7)), armor_dark)
    draw_circle(body_offset + Vector2(-13, 9), 2.3, skin)
    draw_circle(body_offset + Vector2(13, 9), 2.3, skin)

    # Hooded head. Face remains tiny, but light/dark masses read immediately.
    var head := body_offset + Vector2(0, -15)
    draw_circle(head, 9.0, Color("1c2024"))
    var hood := PackedVector2Array([
        head + Vector2(0, -10),
        head + Vector2(8, -5),
        head + Vector2(8, 4),
        head + Vector2(4, 8),
        head + Vector2(-5, 8),
        head + Vector2(-9, 3),
        head + Vector2(-8, -5)
    ])
    draw_colored_polygon(hood, skin_cape.darkened(0.08))
    var face := PackedVector2Array([
        head + Vector2(-5, -3),
        head + Vector2(5, -3),
        head + Vector2(4, 5),
        head + Vector2(-4, 5)
    ])
    draw_colored_polygon(face, Color("11171a").lightened(damage_flash * 0.16))
    draw_rect(Rect2(head + Vector2(-5, -4), Vector2(10, 3)), skin_cape.darkened(0.30))
    var eye_x: float = 2.3 * facing_x
    draw_rect(Rect2(head + Vector2(eye_x - 0.8, 0), Vector2(2, 2)), VisualSystem.GOLD_BRIGHT)

    # Scarf and backpack/satchel communicate the explorer fantasy.
    draw_line(body_offset + Vector2(-7 * facing_x, -7), body_offset + Vector2(-12 * facing_x, 1), VisualSystem.GOLD.darkened(0.12), 3.0)
    var bag_ratio: float = clampf(float(inventory_total()) / float(maxi(1, capacity)), 0.0, 1.0)
    if bag_ratio > 0.05:
        var bag_x: float = -11.0 * facing_x
        draw_rect(Rect2(body_offset + Vector2(bag_x - 4, 4), Vector2(8, 10)), leather.darkened(0.12))
        draw_line(body_offset + Vector2(bag_x - 3, 7), body_offset + Vector2(bag_x + 3, 7), leather.lightened(0.16), 1.0)

    # Production illustration overlays the lightweight procedural fallback.
    # The fallback keeps the hero safe if an import ever fails; the cutout is
    # the primary in-game presentation and receives subtle runtime animation.
    _draw_illustrated_wanderer(body_offset, moving)

    if weapon_style == "spear":
        var spear_dir: Vector2
        if weapon_action_time > 0.0:
            spear_dir = weapon_action_direction
        else:
            spear_dir = Vector2(cos(angle), sin(angle))
        if spear_dir.length_squared() < 0.01:
            spear_dir = Vector2.RIGHT
        spear_dir = spear_dir.normalized()
        var spear_distance: float = radius if weapon_action_time <= 0.0 else (54.0 + weapon_action_ratio() * 12.0)
        var spear_pos: Vector2 = spear_dir * spear_distance
        _draw_weapon(spear_pos, spear_dir.angle() + PI * 0.5)
    elif weapon_style == "hammer":
        var hammer_angle: float = angle * 0.72
        if weapon_action_time > 0.0:
            hammer_angle = weapon_action_direction.angle()
        var hammer_pos: Vector2 = Vector2(cos(hammer_angle), sin(hammer_angle)) * radius
        _draw_weapon(hammer_pos, hammer_angle)
    else:
        for i: int in range(axes):
            var weapon_angle: float = angle + float(i) * TAU / float(maxi(1, axes))
            var pos: Vector2 = Vector2(cos(weapon_angle), sin(weapon_angle)) * radius
            _draw_weapon(pos, weapon_angle)

    if weapon_style == "twin_blades" and weapon_combo_visual > 0:
        var combo_color := Color("f0a36f")
        draw_arc(Vector2.ZERO, 30.0, -2.65, -2.65 + TAU * minf(1.0, float(weapon_combo_visual) / 8.0), 28, combo_color, 2.0)
        var combo_font: Font = ThemeDB.fallback_font
        draw_string(combo_font, Vector2(-12, -48), "x%d" % weapon_combo_visual, HORIZONTAL_ALIGNMENT_CENTER, 24, 7, combo_color)

    if shield_hits > 0 or block_flash > 0.0:
        var shield_alpha: float = 0.46 + block_flash * 0.30
        draw_rect(Rect2(-24, -24, 48, 48), Color(0.55, 0.88, 1.0, shield_alpha), false, 2.0)

    if perk_flash > 0.0:
        var grow: float = (1.0 - perk_flash) * 12.0
        draw_rect(Rect2(-25 - grow, -25 - grow, 50 + grow * 2.0, 50 + grow * 2.0), Color(1.0, 0.85, 0.42, perk_flash * 0.55), false, 2.0)

    _draw_inventory_gauge()

func _draw_illustrated_wanderer(body_offset: Vector2, moving: bool) -> void:
    if WANDERER_ART == null:
        return
    var breathe: float = sin(motion_time * (8.0 if moving else 2.4))
    var action_tilt: float = -facing_x * weapon_action_ratio() * 0.045
    var width: float = 64.0 + breathe * (1.2 if moving else 0.45)
    var height: float = 79.0 - breathe * (1.0 if moving else 0.35)
    var tint_color := Color.WHITE.lerp(Color(1.0, 0.68, 0.58), clampf(damage_flash, 0.0, 1.0) * 0.72)
    draw_set_transform(body_offset + Vector2(0, -10), action_tilt, Vector2(facing_x, 1.0))
    draw_texture_rect(WANDERER_ART, Rect2(-width * 0.5, -height * 0.5, width, height), false, tint_color)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_inventory_gauge() -> void:
    var ratio: float = clampf(float(inventory_total()) / float(maxi(1, capacity)), 0.0, 1.0)
    var pulse: float = (sin(motion_time * 7.0) + 1.0) * 0.5
    var track := Rect2(-24, -62, 48, 6)
    draw_rect(track, Color(0.035, 0.05, 0.05, 0.78))
    draw_rect(track, Color(0.72, 0.79, 0.72, 0.26), false, 1.0)

    var fill_color: Color = Color("72a978")
    if ratio >= 0.80:
        fill_color = Color("d6ad55")
    if ratio >= 0.98:
        fill_color = Color("ce6257").lightened(pulse * 0.10)

    if ratio > 0.0:
        draw_rect(Rect2(-23, -61, 46.0 * ratio, 4), fill_color)

    if ratio >= 0.60:
        var font: Font = ThemeDB.fallback_font
        var text: String = "%d/%d" % [inventory_total(), capacity]
        draw_string(font, Vector2(-24, -66), text, HORIZONTAL_ALIGNMENT_CENTER, 48, 7, Color("f2ecdc"))

    if ratio >= 0.98:
        var font_full: Font = ThemeDB.fallback_font
        draw_string(font_full, Vector2(-24, -71), "ПОЛОН", HORIZONTAL_ALIGNMENT_CENTER, 48, 6, Color("f4c0a0"))

    if home_hint_active and global_position.distance_to(home_target) > 70.0:
        var dir: Vector2 = global_position.direction_to(home_target)
        if dir.length_squared() > 0.01:
            var anchor := Vector2(0, -76)
            var side := Vector2(-dir.y, dir.x)
            draw_colored_polygon(PackedVector2Array([
                anchor + dir * 8.0,
                anchor - dir * 4.0 + side * 4.5,
                anchor - dir * 4.0 - side * 4.5
            ]), Color("f1cb73"))

    if field_hint_active and global_position.distance_to(field_target) > 62.0:
        var field_dir: Vector2 = global_position.direction_to(field_target)
        if field_dir.length_squared() > 0.01:
            var field_anchor := field_dir * 33.0
            var field_side := Vector2(-field_dir.y, field_dir.x)
            draw_circle(field_anchor, 8.0, Color(field_hint_color, 0.15))
            draw_arc(field_anchor, 8.0, 0.0, TAU, 16, Color(field_hint_color, 0.72), 1.5)
            draw_colored_polygon(PackedVector2Array([
                field_anchor + field_dir * 7.0,
                field_anchor - field_dir * 3.0 + field_side * 4.0,
                field_anchor - field_dir * 3.0 - field_side * 4.0
            ]), field_hint_color)

func _draw_relic_auras() -> void:
    if frost_aura_level > 0:
        var frost_evolved: bool = has_evolution("frost")
        var frost_radius: float = 58.0 + float(frost_aura_level) * 7.0 + (12.0 if frost_evolved else 0.0)
        draw_circle(Vector2.ZERO, frost_radius, Color(0.48,0.78,0.88,0.035 + float(frost_aura_level)*0.01))
        draw_arc(Vector2.ZERO, frost_radius, 0.0, TAU, 36, Color(0.60,0.88,0.96,0.30 if frost_evolved else 0.18), 2.4 if frost_evolved else 1.5)
        if frost_evolved:
            draw_arc(Vector2.ZERO, frost_radius - 8.0, motion_time*0.18, motion_time*0.18 + PI*1.35, 28, Color(0.78,0.94,1.0,0.22), 1.4)

    if thorn_ring_level > 0:
        var roots_evolved: bool = has_evolution("roots")
        var thorn_radius: float = 50.0 + float(thorn_ring_level) * 6.0 + (10.0 if roots_evolved else 0.0)
        var thorn_count: int = 14 if roots_evolved else 10
        for i: int in range(thorn_count):
            var a: float = TAU*float(i)/float(thorn_count) + motion_time*(0.28 if roots_evolved else 0.18)
            var p := Vector2(cos(a),sin(a))*thorn_radius
            var dir := p.normalized()
            var side := Vector2(-dir.y,dir.x)
            draw_colored_polygon(PackedVector2Array([
                p + dir*(7.0 if roots_evolved else 5.0),
                p - dir*3.0 + side*2.5,
                p - dir*3.0 - side*2.5
            ]),Color(0.52,0.79,0.42,0.76 if roots_evolved else 0.60))

    if fire_orb_level > 0:
        var flame_evolved: bool = has_evolution("flame")
        var orb_count: int = fire_orb_level + (2 if flame_evolved else 0)
        for i: int in range(orb_count):
            var a: float = -motion_time*(2.8 if flame_evolved else 2.2) + TAU*float(i)/float(maxi(1,orb_count))
            var p := Vector2(cos(a),sin(a))*(56.0 if flame_evolved else (48.0 + float(fire_orb_level)*4.0))
            draw_circle(p,9.5 if flame_evolved else 7.5,Color(0.95,0.36,0.12,0.13))
            draw_circle(p,5.2 if flame_evolved else 4.5,Color("e96b35"))
            draw_circle(p+Vector2(0,-1),2.5 if flame_evolved else 2.2,Color("ffd46f"))
        if flame_evolved:
            draw_arc(Vector2.ZERO, 56.0, 0.0, TAU, 40, Color(1.0,0.47,0.16,0.20), 1.6)

    if guardian_spirit_level > 0:
        var guardian_evolved: bool = has_evolution("guardian")
        var spirit_count: int = 2 if guardian_evolved else 1
        for i: int in range(spirit_count):
            var a: float = motion_time*(1.55 if guardian_evolved else 1.25) + TAU*float(i)/float(spirit_count)
            var p := Vector2(cos(a),sin(a))*(43.0 if guardian_evolved else 36.0) + Vector2(0,-8)
            draw_circle(p,7.0 if guardian_evolved else 6.0,Color(0.42,0.76,0.92,0.13))
            draw_circle(p,3.6 if guardian_evolved else 3.2,Color("8fd5e8"))
            draw_line(p, p + Vector2(0,-9), Color(0.74,0.93,1.0,0.55 if guardian_evolved else 0.42), 1.6)

    if has_evolution("steel"):
        var steel_angle: float = motion_time * 1.8
        draw_arc(Vector2.ZERO, orbit_radius + 20.0, steel_angle, steel_angle + PI*0.8, 20, Color(0.78,0.88,0.94,0.28), 2.0)
        draw_arc(Vector2.ZERO, orbit_radius + 20.0, steel_angle + PI, steel_angle + PI*1.8, 20, Color(0.78,0.88,0.94,0.22), 2.0)

    if has_evolution("hunt"):
        for i: int in range(3):
            var a: float = motion_time*0.75 + TAU*float(i)/3.0
            var p := Vector2(cos(a),sin(a))*31.0
            draw_circle(p,2.3,Color(0.88,0.24,0.22,0.72))

func _draw_weapon(pos: Vector2, weapon_angle: float) -> void:
    match weapon_style:
        "spear":
            _draw_spear(pos, weapon_angle)
        "hammer":
            _draw_hammer(pos, weapon_angle)
        "twin_blades":
            _draw_twin_blade(pos, weapon_angle)
        _:
            _draw_axe(pos, weapon_angle)

func _draw_axe(pos: Vector2, weapon_angle: float) -> void:
    var handle_a: Vector2 = pos + Vector2(-1, -8).rotated(weapon_angle)
    var handle_b: Vector2 = pos + Vector2(1, 8).rotated(weapon_angle)
    draw_line(handle_a, handle_b, Color("68482f"), 4.6)
    draw_line(pos + Vector2(-7, -9).rotated(weapon_angle), pos + Vector2(7, -9).rotated(weapon_angle), Color("c6d0d2").lightened(perk_flash * 0.22), 7.0)
    draw_circle(pos, 2.2, Color(0.96, 0.97, 0.98, 0.55))
    draw_arc(pos, 9.0, weapon_angle - 0.9, weapon_angle + 0.3, 8, Color(0.82, 0.90, 0.95, 0.18), 1.5)

func _draw_spear(pos: Vector2, weapon_angle: float) -> void:
    var shaft_a: Vector2 = pos + Vector2(0, 13).rotated(weapon_angle)
    var shaft_b: Vector2 = pos + Vector2(0, -16).rotated(weapon_angle)
    draw_line(shaft_a, shaft_b, Color("725038"), 3.6)
    var tip: Vector2 = pos + Vector2(0, -21).rotated(weapon_angle)
    var left: Vector2 = pos + Vector2(-5, -14).rotated(weapon_angle)
    var right: Vector2 = pos + Vector2(5, -14).rotated(weapon_angle)
    draw_colored_polygon(PackedVector2Array([tip, left, right]), Color("d5e2e5").lightened(perk_flash * 0.18))
    draw_circle(pos + Vector2(0, 10).rotated(weapon_angle), 2.0, Color("8fb06d"))
    draw_circle(tip, 3.2, Color(0.64, 0.88, 0.61, 0.20 + weapon_action_ratio() * 0.28))

func _draw_hammer(pos: Vector2, weapon_angle: float) -> void:
    var handle_a: Vector2 = pos + Vector2(0, 12).rotated(weapon_angle)
    var handle_b: Vector2 = pos + Vector2(0, -9).rotated(weapon_angle)
    draw_line(handle_a, handle_b, Color("674832"), 5.6)
    var head_center: Vector2 = pos + Vector2(0, -13).rotated(weapon_angle)
    var side: Vector2 = Vector2(1, 0).rotated(weapon_angle)
    var up: Vector2 = Vector2(0, 1).rotated(weapon_angle)
    var p1: Vector2 = head_center - side * 10.0 - up * 5.0
    var p2: Vector2 = head_center + side * 10.0 - up * 5.0
    var p3: Vector2 = head_center + side * 10.0 + up * 5.0
    var p4: Vector2 = head_center - side * 10.0 + up * 5.0
    draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color("9fb4c2").lightened(perk_flash * 0.16))
    draw_line(p1, p2, Color("d8eef5"), 1.5)
    if weapon_action_time > 0.0:
        draw_circle(head_center, 13.0 + (1.0 - weapon_action_ratio()) * 4.0, Color(0.57, 0.83, 0.95, weapon_action_ratio() * 0.16))

func _draw_twin_blade(pos: Vector2, weapon_angle: float) -> void:
    var inner: Vector2 = pos + Vector2(0, 8).rotated(weapon_angle)
    var outer: Vector2 = pos + Vector2(0, -13).rotated(weapon_angle)
    draw_line(inner, outer, Color("5b473b"), 3.5)
    var tip: Vector2 = pos + Vector2(0, -18).rotated(weapon_angle)
    var wing: Vector2 = pos + Vector2(5, -10).rotated(weapon_angle)
    draw_colored_polygon(PackedVector2Array([outer, tip, wing]), Color("e1a07c").lightened(perk_flash * 0.20))
    draw_circle(inner, 2.0, Color("f1c26f"))
    draw_arc(pos, 10.0, weapon_angle - 0.7, weapon_angle + 0.5, 8, Color(0.96, 0.46, 0.28, 0.22), 1.5)

func _draw_shadow_ellipse(center_pos: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(24):
        var ellipse_angle: float = TAU * float(i) / 24.0
        points.append(center_pos + Vector2(cos(ellipse_angle) * radii.x, sin(ellipse_angle) * radii.y))
    draw_colored_polygon(points, color)
