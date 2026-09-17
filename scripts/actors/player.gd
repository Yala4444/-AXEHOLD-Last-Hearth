class_name AxPlayer
extends CharacterBody2D

signal died
signal damaged(amount: float, blocked: bool)
signal level_up_requested(level: int)

var target_position: Vector2 = Vector2.ZERO
var move_speed: float = 126.0
var max_hp: float = 100.0
var hp: float = 100.0
var damage: float = 25.0
var capacity: int = 20
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
    capacity = 20 + bag_level * 5
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

    var direction: Vector2 = global_position.direction_to(target_position)
    var distance: float = global_position.distance_to(target_position)
    if distance > 4.0:
        if absf(direction.x) > 0.08:
            facing_x = signf(direction.x)
        velocity = direction * move_speed
        move_and_slide()
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
    target_position = pos

func inventory_total() -> int:
    return int(inventory["wood"]) + int(inventory["stone"]) + int(inventory["ore"])

func add_resource(kind: String, amount: int) -> int:
    var available: int = maxi(0, capacity - inventory_total())
    var actual: int = mini(amount, available)
    inventory[kind] = int(inventory.get(kind, 0)) + actual
    return actual

func clear_inventory() -> Dictionary:
    var result: Dictionary = inventory.duplicate(true)
    inventory = {"wood": 0, "stone": 0, "ore": 0}
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
    var bob: float = sin(motion_time * 10.0) * 1.4 if moving else sin(motion_time * 2.5) * 0.45
    var body_offset: Vector2 = Vector2(0, bob)

    _draw_shadow_ellipse(Vector2(3, 12), Vector2(13, 5), Color(0.08, 0.12, 0.08, 0.18))

    var radius: float = orbit_radius + axes * 4.0
    for i: int in range(axes):
        var weapon_angle: float = angle + float(i) * TAU / float(maxi(1, axes))
        var trail_width: float = 7.0 if weapon_style == "hammer" else 5.0
        var trail_alpha: float = 0.16 if weapon_style == "twin_blades" else 0.11
        draw_arc(Vector2.ZERO, radius, weapon_angle - 0.42, weapon_angle - 0.08, 10, Color(0.76, 0.86, 0.94, trail_alpha), trail_width)
        draw_arc(Vector2.ZERO, radius, weapon_angle - 0.24, weapon_angle - 0.04, 8, Color(0.89, 0.95, 1.0, 0.16), 2.0)

    var cape_shift: float = -facing_x * (3.0 if moving else 1.5)
    var cape: PackedVector2Array = PackedVector2Array([
        body_offset + Vector2(-8 + cape_shift, 2),
        body_offset + Vector2(cape_shift, 18),
        body_offset + Vector2(8 + cape_shift, 2)
    ])
    draw_colored_polygon(cape, skin_cape)

    var body_color: Color = skin_body.lightened(damage_flash * 0.38)
    draw_circle(body_offset, 11.0, body_color)
    draw_circle(body_offset + Vector2(0, -8), 5.0, Color("e6be96").lightened(damage_flash * 0.28))
    draw_circle(body_offset + Vector2(facing_x * 1.8, -9), 0.8, Color("40352e"))

    draw_line(body_offset + Vector2(-5, 8), body_offset + Vector2(-4, 14), skin_body.darkened(0.16), 3.0)
    draw_line(body_offset + Vector2(5, 8), body_offset + Vector2(4, 14), skin_body.darkened(0.16), 3.0)

    for i: int in range(axes):
        var weapon_angle: float = angle + float(i) * TAU / float(maxi(1, axes))
        var pos: Vector2 = Vector2(cos(weapon_angle), sin(weapon_angle)) * radius
        _draw_weapon(pos, weapon_angle)

    if shield_hits > 0 or block_flash > 0.0:
        var shield_alpha: float = 0.48 + sin(motion_time * 4.5) * 0.12 + block_flash * 0.28
        var shield_radius: float = 20.0 + block_flash * 4.0
        draw_circle(Vector2.ZERO, shield_radius, Color(0.35, 0.76, 1.0, 0.05 + block_flash * 0.06))
        draw_arc(Vector2.ZERO, shield_radius, 0.0, TAU, 48, Color(0.55, 0.88, 1.0, shield_alpha), 2.2)

    if perk_flash > 0.0:
        draw_arc(Vector2.ZERO, 24.0 + (1.0 - perk_flash) * 18.0, 0.0, TAU, 48, Color(1.0, 0.85, 0.42, perk_flash * 0.65), 2.0)

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

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(24):
        var ellipse_angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(ellipse_angle) * radii.x, sin(ellipse_angle) * radii.y))
    draw_colored_polygon(points, color)
