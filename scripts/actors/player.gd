class_name AxPlayer
extends CharacterBody2D

signal died
signal damaged(amount: float, blocked: bool)
signal level_up_requested(level: int)

var target_position: Vector2 = Vector2.ZERO
var move_input: Vector2 = Vector2.ZERO
var direct_control: bool = false
var move_speed: float = 126.0
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
var base_meta_speed: float = 126.0
var base_meta_crit: float = 0.05
var movement_bounds: Rect2 = Rect2()
var has_movement_bounds: bool = false
var home_target: Vector2 = Vector2.ZERO
var home_hint_active: bool = false

func setup(meta_upgrades: Dictionary, skin: Dictionary) -> void:
    var hp_level: int = int(meta_upgrades.get("hp", 0))
    var damage_level: int = int(meta_upgrades.get("damage", 0))
    var bag_level: int = int(meta_upgrades.get("bag", 0))
    var speed_level: int = int(meta_upgrades.get("speed", 0))
    max_hp = 100.0 + hp_level * 10.0
    hp = max_hp
    base_meta_damage = 25.0 * pow(1.10, damage_level)
    base_meta_speed = 126.0 * pow(1.04, speed_level)
    base_meta_crit = 0.05
    capacity = 24 + bag_level * 5
    skin_body = Color(str(skin.get("body", "466bc8")))
    skin_cape = Color(str(skin.get("cape", "364f9c")))
    target_position = global_position
    apply_weapon_profile(str(GameState.data.get("selected_weapon", "axes")))
    queue_redraw()

func apply_weapon_profile(id: String) -> void:
    weapon_id = id if WeaponRules.WEAPONS.has(id) else "axes"
    var profile: Dictionary = WeaponRules.profile(weapon_id)
    weapon_style = str(profile.get("style", weapon_id))
    damage = base_meta_damage * float(profile.get("damage_mult", 1.0))
    move_speed = base_meta_speed * float(profile.get("speed_mult", 1.0))
    orbit_radius = float(profile.get("orbit_radius", 44.0))
    axes = int(profile.get("axes", 1))
    crit_chance = clampf(base_meta_crit + float(profile.get("crit_bonus", 0.0)), 0.0, 0.65)
    perk_flash = 1.0
    queue_redraw()

func weapon_name() -> String:
    return str(WeaponRules.profile(weapon_id).get("name", "Топоры Странника"))

func _physics_process(delta: float) -> void:
    motion_time += delta
    damage_flash = maxf(0.0, damage_flash - delta * 4.8)
    block_flash = maxf(0.0, block_flash - delta * 3.6)
    perk_flash = maxf(0.0, perk_flash - delta * 2.0)

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
        velocity = direction * move_speed * analog_strength
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
    if shield_hits > 0:
        shield_hits -= 1
        block_flash = 1.0
        Feedback.play("shield", 24)
        damaged.emit(0.0, true)
        queue_redraw()
        return
    hp = maxf(0.0, hp - amount)
    damage_flash = 1.0
    Feedback.play("hit", 38)
    damaged.emit(amount, false)
    if hp <= 0.0:
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
            crit_chance = minf(0.50, crit_chance + 0.12)
        "shield":
            shield_hits += 3
    perk_flash = 1.0
    queue_redraw()

func _draw() -> void:
    var moving: bool = velocity.length_squared() > 36.0
    var bob: float = round(sin(motion_time * (10.0 if moving else 2.2)) * (1.0 if moving else 0.35))
    var stride: int = int(round(sin(motion_time * 11.0) * 2.0)) if moving else 0
    var body_offset := Vector2(0, bob)

    draw_rect(Rect2(-13, 15, 27, 5), Color(0.04, 0.06, 0.05, 0.24))

    var radius: float = orbit_radius + axes * 4.0
    for i: int in range(axes):
        var weapon_angle: float = angle + float(i) * TAU / float(maxi(1, axes))
        draw_arc(Vector2.ZERO, radius, weapon_angle - 0.34, weapon_angle - 0.08, 7, Color(0.82, 0.90, 0.95, 0.13), 4.0)

    # Cape is a crisp pixel silhouette behind the hero.
    var cape_shift: float = -facing_x * (3.0 if moving else 1.0)
    var cape := PackedVector2Array([
        body_offset + Vector2(-8 + cape_shift, -3),
        body_offset + Vector2(-9 + cape_shift, 14),
        body_offset + Vector2(0 + cape_shift, 18),
        body_offset + Vector2(9 + cape_shift, 14),
        body_offset + Vector2(8 + cape_shift, -3)
    ])
    draw_colored_polygon(cape, skin_cape.darkened(0.06))
    draw_polyline(cape, skin_cape.lightened(0.16), 1.0)

    var flash_body: Color = skin_body.lightened(damage_flash * 0.38)
    var leg: Color = skin_body.darkened(0.34)
    var boot: Color = Color("292626")

    draw_rect(Rect2(body_offset + Vector2(-7 + stride, 8), Vector2(5, 10)), leg)
    draw_rect(Rect2(body_offset + Vector2(2 - stride, 8), Vector2(5, 10)), leg)
    draw_rect(Rect2(body_offset + Vector2(-8 + stride, 16), Vector2(7, 4)), boot)
    draw_rect(Rect2(body_offset + Vector2(1 - stride, 16), Vector2(7, 4)), boot)

    # Torso with one-pixel-like outline.
    draw_rect(Rect2(body_offset + Vector2(-9, -5), Vector2(18, 16)), Color("20242a"))
    draw_rect(Rect2(body_offset + Vector2(-7, -4), Vector2(14, 14)), flash_body)
    draw_rect(Rect2(body_offset + Vector2(-7, 5), Vector2(14, 3)), Color("9d7144"))
    draw_rect(Rect2(body_offset + Vector2(-1, 5), Vector2(3, 3)), Color("e0b65b"))

    var sleeve: Color = flash_body.darkened(0.14)
    draw_rect(Rect2(body_offset + Vector2(-12, -2), Vector2(5, 10)), sleeve)
    draw_rect(Rect2(body_offset + Vector2(7, -2), Vector2(5, 10)), sleeve)
    draw_rect(Rect2(body_offset + Vector2(-13, 6), Vector2(4, 4)), Color("d4a077"))
    draw_rect(Rect2(body_offset + Vector2(9, 6), Vector2(4, 4)), Color("d4a077"))

    # Square readable head / hood: intentionally 16-bit rather than vector-cartoon.
    var head := body_offset + Vector2(0, -12)
    draw_rect(Rect2(head + Vector2(-7, -7), Vector2(14, 14)), Color("2d2522"))
    draw_rect(Rect2(head + Vector2(-6, -5), Vector2(12, 11)), Color("d6a47d").lightened(damage_flash * 0.20))
    draw_rect(Rect2(head + Vector2(-7, -7), Vector2(14, 4)), skin_cape.lightened(0.08))
    draw_rect(Rect2(head + Vector2(-5, -4), Vector2(10, 3)), Color("4a372e"))
    var eye_x: float = 2.0 * facing_x
    draw_rect(Rect2(head + Vector2(eye_x, 0), Vector2(2, 2)), Color("211d1b"))

    draw_rect(Rect2(body_offset + Vector2(-8 * facing_x - 1, -4), Vector2(3, 3)), Color("dfb45a"))

    for i: int in range(axes):
        var weapon_angle: float = angle + float(i) * TAU / float(maxi(1, axes))
        var pos: Vector2 = Vector2(cos(weapon_angle), sin(weapon_angle)) * radius
        _draw_weapon(pos, weapon_angle)

    if shield_hits > 0 or block_flash > 0.0:
        var shield_alpha: float = 0.46 + block_flash * 0.30
        draw_rect(Rect2(-24, -24, 48, 48), Color(0.55, 0.88, 1.0, shield_alpha), false, 2.0)

    if perk_flash > 0.0:
        var grow: float = (1.0 - perk_flash) * 12.0
        draw_rect(Rect2(-25 - grow, -25 - grow, 50 + grow * 2.0, 50 + grow * 2.0), Color(1.0, 0.85, 0.42, perk_flash * 0.55), false, 2.0)

    _draw_inventory_gauge()

func _draw_inventory_gauge() -> void:
    var ratio: float = clampf(float(inventory_total()) / float(maxi(1, capacity)), 0.0, 1.0)
    var pulse: float = (sin(motion_time * 7.0) + 1.0) * 0.5
    var track := Rect2(-20, -35, 40, 5)
    draw_rect(track, Color(0.035, 0.05, 0.05, 0.78))
    draw_rect(track, Color(0.72, 0.79, 0.72, 0.26), false, 1.0)

    var fill_color: Color = Color("72a978")
    if ratio >= 0.82:
        fill_color = Color("d6ad55")
    if ratio >= 0.98:
        fill_color = Color("ce6257").lightened(pulse * 0.10)

    if ratio > 0.0:
        draw_rect(Rect2(-19, -34, 38.0 * ratio, 3), fill_color)

    if ratio >= 0.65:
        var font: Font = ThemeDB.fallback_font
        var text: String = "%d/%d" % [inventory_total(), capacity]
        draw_string(font, Vector2(-20, -39), text, HORIZONTAL_ALIGNMENT_CENTER, 40, 7, Color("f2ecdc"))

    if ratio >= 0.98:
        var font_full: Font = ThemeDB.fallback_font
        draw_string(font_full, Vector2(-20, -43), "ПОЛОН", HORIZONTAL_ALIGNMENT_CENTER, 40, 6, Color("f4c0a0"))

    if home_hint_active and global_position.distance_to(home_target) > 70.0:
        var dir: Vector2 = global_position.direction_to(home_target)
        if dir.length_squared() > 0.01:
            var anchor := Vector2(0, -49)
            var side := Vector2(-dir.y, dir.x)
            draw_colored_polygon(PackedVector2Array([
                anchor + dir * 8.0,
                anchor - dir * 4.0 + side * 4.5,
                anchor - dir * 4.0 - side * 4.5
            ]), Color("f1cb73"))

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
    draw_line(handle_a, handle_b, Color("68482f"), 4.0)
    draw_line(pos + Vector2(-7, -9).rotated(weapon_angle), pos + Vector2(7, -9).rotated(weapon_angle), Color("b8bec1").lightened(perk_flash * 0.22), 6.0)
    draw_circle(pos, 2.2, Color(0.96, 0.97, 0.98, 0.55))

func _draw_spear(pos: Vector2, weapon_angle: float) -> void:
    var shaft_a: Vector2 = pos + Vector2(0, 13).rotated(weapon_angle)
    var shaft_b: Vector2 = pos + Vector2(0, -16).rotated(weapon_angle)
    draw_line(shaft_a, shaft_b, Color("725038"), 3.0)
    var tip: Vector2 = pos + Vector2(0, -21).rotated(weapon_angle)
    var left: Vector2 = pos + Vector2(-5, -14).rotated(weapon_angle)
    var right: Vector2 = pos + Vector2(5, -14).rotated(weapon_angle)
    draw_colored_polygon(PackedVector2Array([tip, left, right]), Color("d5e2e5").lightened(perk_flash * 0.18))
    draw_circle(pos + Vector2(0, 10).rotated(weapon_angle), 2.0, Color("8fb06d"))

func _draw_hammer(pos: Vector2, weapon_angle: float) -> void:
    var handle_a: Vector2 = pos + Vector2(0, 12).rotated(weapon_angle)
    var handle_b: Vector2 = pos + Vector2(0, -9).rotated(weapon_angle)
    draw_line(handle_a, handle_b, Color("674832"), 5.0)
    var head_center: Vector2 = pos + Vector2(0, -13).rotated(weapon_angle)
    var side: Vector2 = Vector2(1, 0).rotated(weapon_angle)
    var up: Vector2 = Vector2(0, 1).rotated(weapon_angle)
    var p1: Vector2 = head_center - side * 10.0 - up * 5.0
    var p2: Vector2 = head_center + side * 10.0 - up * 5.0
    var p3: Vector2 = head_center + side * 10.0 + up * 5.0
    var p4: Vector2 = head_center - side * 10.0 + up * 5.0
    draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color("9fb4c2").lightened(perk_flash * 0.16))
    draw_line(p1, p2, Color("d8eef5"), 1.5)

func _draw_twin_blade(pos: Vector2, weapon_angle: float) -> void:
    var inner: Vector2 = pos + Vector2(0, 8).rotated(weapon_angle)
    var outer: Vector2 = pos + Vector2(0, -13).rotated(weapon_angle)
    draw_line(inner, outer, Color("5b473b"), 3.0)
    var tip: Vector2 = pos + Vector2(0, -18).rotated(weapon_angle)
    var wing: Vector2 = pos + Vector2(5, -10).rotated(weapon_angle)
    draw_colored_polygon(PackedVector2Array([outer, tip, wing]), Color("e1a07c").lightened(perk_flash * 0.20))
    draw_circle(inner, 2.0, Color("f1c26f"))

func _draw_shadow_ellipse(center_pos: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(24):
        var ellipse_angle: float = TAU * float(i) / 24.0
        points.append(center_pos + Vector2(cos(ellipse_angle) * radii.x, sin(ellipse_angle) * radii.y))
    draw_colored_polygon(points, color)
