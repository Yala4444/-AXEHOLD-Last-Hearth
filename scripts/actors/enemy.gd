class_name AxEnemy
extends CharacterBody2D

signal killed(enemy: AxEnemy)

var enemy_type: String = "normal"
var hp: float = 40.0
var max_hp: float = 40.0
var move_speed: float = 30.0
var movement_multiplier: float = 1.0
var contact_damage: float = 8.0
var armor: float = 0.0
var boss: bool = false
var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false
var hit_cooldown: float = 0.0
var special_cooldown: float = 2.8
var windup: float = 0.0
var mark_position: Vector2 = Vector2.ZERO
var mark_active: bool = false
var tint: Color = Color("6c5574")
var hit_flash: float = 0.0
var animation_time: float = 0.0
var dying: bool = false
var death_time: float = 0.0
var base_scale: float = 1.0
var charge_cooldown: float = 5.5
var charge_windup: float = 0.0
var charge_time: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO
var surge_cooldown: float = 2.8
var surge_windup: float = 0.0
var surge_time: float = 0.0
var surge_direction: Vector2 = Vector2.ZERO

func configure(kind: String, difficulty: float, wave: int, color: Color, is_boss: bool = false) -> void:
    enemy_type = kind
    boss = is_boss
    tint = color
    armor = 0.0
    movement_multiplier = 1.0
    base_scale = 1.0
    surge_cooldown = randf_range(2.5, 3.3)
    surge_windup = 0.0
    surge_time = 0.0

    if boss:
        max_hp = 340.0 * difficulty
        move_speed = 23.0
        contact_damage = 22.0 * difficulty
        armor = 0.05
        charge_cooldown = randf_range(4.8, 6.0)
    elif kind == "guardian":
        max_hp = (82.0 + wave * 13.0) * difficulty
        move_speed = 17.0
        contact_damage = 14.0 * difficulty
        armor = 0.25
        base_scale = 1.10
    elif kind == "stalker":
        max_hp = (34.0 + wave * 8.0) * difficulty
        move_speed = 34.0
        contact_damage = 8.5 * difficulty
        base_scale = 0.92
    elif kind == "brute":
        max_hp = (62.0 + wave * 10.0) * difficulty
        move_speed = 20.0
        contact_damage = 12.0 * difficulty
        base_scale = 1.05
    elif kind == "runner":
        max_hp = (30.0 + wave * 9.0) * difficulty
        move_speed = 40.0
        contact_damage = 6.0 * difficulty
        base_scale = 0.93
    else:
        max_hp = (40.0 + wave * 10.0) * difficulty
        move_speed = 29.0 + wave * 2.0
        contact_damage = (7.0 + wave * 0.8) * difficulty

    hp = max_hp
    dying = false
    death_time = 0.0
    rotation = 0.0
    modulate = Color.WHITE
    scale = Vector2.ONE * base_scale
    queue_redraw()

func _physics_process(delta: float) -> void:
    animation_time += delta
    hit_cooldown = maxf(0.0, hit_cooldown - delta)
    hit_flash = maxf(0.0, hit_flash - delta * 5.8)

    if dying:
        _update_death(delta)
        return

    if boss and _update_charge(delta):
        queue_redraw()
        return

    if enemy_type == "stalker" and _update_stalker_surge(delta):
        queue_redraw()
        return

    var moving: bool = has_target and windup <= 0.0
    if moving:
        velocity = global_position.direction_to(target_position) * move_speed * movement_multiplier
        move_and_slide()
    else:
        velocity = Vector2.ZERO

    var bob_strength: float = 0.025 if boss else 0.04
    var bob_speed: float = 5.2
    if enemy_type == "runner":
        bob_speed = 8.0
    elif enemy_type == "stalker":
        bob_speed = 9.2
    elif enemy_type == "guardian":
        bob_speed = 3.8
    var bob: float = sin(animation_time * bob_speed) * bob_strength if moving else 0.0
    scale = Vector2(base_scale * (1.0 - bob), base_scale * (1.0 + bob))
    queue_redraw()

func _update_stalker_surge(delta: float) -> bool:
    if surge_windup > 0.0:
        surge_windup -= delta
        velocity = Vector2.ZERO
        scale = Vector2.ONE * base_scale * (1.0 + sin(animation_time * 28.0) * 0.05)
        if surge_windup <= 0.0:
            surge_time = 0.34
            Feedback.play("stalker", 8)
        return true

    if surge_time > 0.0:
        surge_time -= delta
        velocity = surge_direction * 102.0 * movement_multiplier
        move_and_slide()
        scale = Vector2(base_scale * 0.84, base_scale * 1.14)
        if surge_time <= 0.0:
            surge_cooldown = randf_range(2.6, 3.5)
            velocity = Vector2.ZERO
        return true

    surge_cooldown -= delta
    if surge_cooldown <= 0.0 and has_target and windup <= 0.0:
        surge_direction = global_position.direction_to(target_position)
        if surge_direction.length_squared() > 0.01 and global_position.distance_to(target_position) > 48.0:
            surge_windup = 0.22
            return true
        surge_cooldown = 0.8
    return false

func _update_death(delta: float) -> void:
    death_time -= delta
    velocity = Vector2.ZERO
    var progress: float = clampf(1.0 - death_time / 0.18, 0.0, 1.0)
    scale = Vector2.ONE * base_scale * (1.0 + progress * 0.25) * (1.0 - progress * 0.92)
    var death_tilt: float = 0.20 if enemy_type == "guardian" or enemy_type == "brute" else 0.45
    rotation = sin(progress * PI) * death_tilt
    modulate.a = 1.0 - progress
    queue_redraw()
    if death_time <= 0.0:
        killed.emit(self)

func _update_charge(delta: float) -> bool:
    if charge_windup > 0.0:
        charge_windup -= delta
        velocity = Vector2.ZERO
        scale = Vector2.ONE * base_scale * (1.0 + sin(animation_time * 22.0) * 0.045)
        if charge_windup <= 0.0:
            charge_time = 0.42
            Feedback.play("boss", 22)
        return true

    if charge_time > 0.0:
        charge_time -= delta
        velocity = charge_direction * 190.0 * movement_multiplier
        move_and_slide()
        scale = Vector2(base_scale * 0.90, base_scale * 1.12)
        if charge_time <= 0.0:
            charge_cooldown = randf_range(5.0, 6.4)
            velocity = Vector2.ZERO
        return true

    charge_cooldown -= delta
    if charge_cooldown <= 0.0 and windup <= 0.0:
        var parent_node: Node = get_parent()
        if parent_node != null:
            var candidate: Variant = parent_node.get("player")
            if candidate is AxPlayer:
                var player_ref: AxPlayer = candidate as AxPlayer
                charge_direction = global_position.direction_to(player_ref.global_position)
                if charge_direction.length_squared() > 0.01:
                    charge_windup = 0.72
                    velocity = Vector2.ZERO
                    return true
        charge_cooldown = 1.0
    return false

func set_target_position(pos: Vector2) -> void:
    if dying:
        return
    target_position = pos
    has_target = true

func clear_target() -> void:
    has_target = false

func take_damage(amount: float) -> void:
    if dying:
        return
    var actual_damage: float = maxf(0.1, amount * (1.0 - armor))
    hp -= actual_damage
    hit_flash = 1.0
    if hp <= 0.0:
        hp = 0.0
        dying = true
        death_time = 0.18
        contact_damage = 0.0
        has_target = false
        charge_windup = 0.0
        charge_time = 0.0
        surge_windup = 0.0
        surge_time = 0.0
        Feedback.play("victory" if boss else "enemy_down", 18 if boss else 0)

func _draw() -> void:
    # Modern 16-bit presentation: crisp silhouettes, integer blocks, smooth gameplay.
    var shadow_w: float = 34.0 if boss else 22.0
    if enemy_type == "guardian" and not boss:
        shadow_w = 30.0
    draw_rect(Rect2(-shadow_w * 0.5, 12, shadow_w, 5), Color(0.04, 0.04, 0.04, 0.22))

    if boss and charge_windup > 0.0:
        var charge_alpha: float = clampf(1.0 - charge_windup / 0.72, 0.0, 1.0)
        draw_line(Vector2.ZERO, charge_direction * (54.0 + charge_alpha * 26.0), Color(1.0, 0.35, 0.28, 0.35 + charge_alpha * 0.55), 4.0)
        draw_rect(Rect2(-22, -22, 44, 44), Color(1.0, 0.42, 0.25, 0.25 + charge_alpha * 0.28), false, 2.0)
    elif boss and charge_time > 0.0:
        for trail_index: int in range(3):
            var back: Vector2 = -charge_direction * float(18 + trail_index * 12)
            draw_rect(Rect2(back - Vector2(8, 8), Vector2(16, 16)), Color(0.92, 0.32, 0.25, 0.15 - trail_index * 0.035))

    if enemy_type == "stalker" and surge_windup > 0.0:
        var s: float = clampf(1.0 - surge_windup / 0.22, 0.0, 1.0)
        draw_rect(Rect2(-15 - s * 3, -17 - s * 3, 30 + s * 6, 34 + s * 6), Color(0.72, 0.52, 0.92, 0.34 + s * 0.40), false, 2.0)

    var body_color: Color = tint
    if boss:
        body_color = Color("a34e52")
    else:
        match enemy_type:
            "runner":
                body_color = Color("6c8d75").lerp(tint, 0.30)
            "brute":
                body_color = Color("7e5a48").lerp(tint, 0.26)
            "stalker":
                body_color = Color("76589a").lerp(tint, 0.22)
            "guardian":
                body_color = Color("66706f").lerp(tint, 0.18)
            _:
                body_color = Color("6e5d76").lerp(tint, 0.42)
    body_color = body_color.lightened(hit_flash * 0.34)
    var dark: Color = body_color.darkened(0.30)
    var light: Color = body_color.lightened(0.18)

    if boss:
        _draw_pixel_boss(body_color, dark, light)
    elif enemy_type == "runner":
        _draw_pixel_runner(body_color, dark, light)
    elif enemy_type == "brute":
        _draw_pixel_brute(body_color, dark, light)
    elif enemy_type == "stalker":
        _draw_pixel_stalker(body_color, dark, light)
    elif enemy_type == "guardian":
        _draw_pixel_guardian(body_color, dark, light)
    else:
        _draw_pixel_ghoul(body_color, dark, light)

    if hit_flash > 0.25:
        draw_rect(Rect2(-17, -21, 34, 39), Color(1.0, 0.90, 0.72, hit_flash * 0.42), false, 2.0)

    if not dying:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        var width: float = 54.0 if boss else (32.0 if enemy_type == "guardian" else 26.0)
        var bar_y: float = -39.0 if boss else -27.0
        var bar_color: Color = Color("cf6165") if boss else (Color("c7b56e") if enemy_type == "guardian" else Color("8f7198"))
        draw_rect(Rect2(-width / 2.0, bar_y, width, 4.0), Color(0.08, 0.08, 0.08, 0.35))
        draw_rect(Rect2(-width / 2.0, bar_y, width * ratio, 4.0), bar_color)
        if armor > 0.0 and not boss:
            draw_rect(Rect2(-width / 2.0, bar_y + 6.0, width * armor, 2.0), Color("dfca78"))

func _draw_pixel_ghoul(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-9, -12, 18, 22), dark)
    draw_rect(Rect2(-7, -14, 14, 22), body)
    draw_rect(Rect2(-5, -11, 10, 5), light)
    draw_rect(Rect2(-5, 9, 4, 7), dark)
    draw_rect(Rect2(2, 9, 4, 7), dark)
    _pixel_eyes(3.0, Color("efe8d6"))

func _draw_pixel_runner(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-7, -14, 14, 18), body)
    draw_rect(Rect2(-10, -8, 20, 9), dark)
    draw_rect(Rect2(-5, 3, 4, 12), dark)
    draw_rect(Rect2(2, 3, 4, 12), dark)
    draw_rect(Rect2(-8, 14, 7, 3), light)
    draw_rect(Rect2(2, 14, 8, 3), light)
    _pixel_eyes(3.0, Color("f6f0df"))

func _draw_pixel_brute(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-15, -12, 30, 24), dark)
    draw_rect(Rect2(-12, -15, 24, 27), body)
    draw_rect(Rect2(-18, -6, 7, 16), body)
    draw_rect(Rect2(11, -6, 7, 16), body)
    draw_colored_polygon(PackedVector2Array([Vector2(-9,-14),Vector2(-16,-23),Vector2(-4,-17)]), Color("c7b18b"))
    draw_colored_polygon(PackedVector2Array([Vector2(9,-14),Vector2(16,-23),Vector2(4,-17)]), Color("c7b18b"))
    draw_rect(Rect2(-7, 7, 14, 4), light)
    _pixel_eyes(4.0, Color("f0ddc4"))

func _draw_pixel_stalker(body: Color, dark: Color, light: Color) -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-19),Vector2(11,-7),Vector2(8,11),Vector2(0,16),Vector2(-9,10),Vector2(-11,-7)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-15),Vector2(8,-5),Vector2(6,9),Vector2(0,13),Vector2(-6,8),Vector2(-8,-5)
    ]), body)
    draw_rect(Rect2(-15, 8, 8, 3), light)
    draw_rect(Rect2(7, 8, 8, 3), light)
    draw_colored_polygon(PackedVector2Array([Vector2(-6,-12),Vector2(-12,-21),Vector2(-2,-15)]), Color("bca0d9"))
    draw_colored_polygon(PackedVector2Array([Vector2(6,-12),Vector2(12,-21),Vector2(2,-15)]), Color("bca0d9"))
    _pixel_eyes(3.0, Color("d7b8ff"))

func _draw_pixel_guardian(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-16, -14, 32, 28), dark)
    draw_rect(Rect2(-13, -11, 26, 24), body)
    draw_rect(Rect2(-15, -9, 30, 5), Color("c7c2a7"))
    draw_rect(Rect2(-12, 1, 24, 5), Color("aaa78f"))
    draw_rect(Rect2(-18, -4, 6, 17), Color("8f8d7d"))
    draw_rect(Rect2(12, -4, 6, 17), Color("8f8d7d"))
    draw_rect(Rect2(-9, 12, 7, 7), dark)
    draw_rect(Rect2(2, 12, 7, 7), dark)
    _pixel_eyes(4.0, Color("f4e6bf"))

func _draw_pixel_boss(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-24, -20, 48, 39), dark)
    draw_rect(Rect2(-20, -23, 40, 40), body)
    draw_rect(Rect2(-27, -9, 8, 22), body)
    draw_rect(Rect2(19, -9, 8, 22), body)
    draw_colored_polygon(PackedVector2Array([Vector2(-13,-21),Vector2(-26,-34),Vector2(-7,-27)]), Color("d8c39e"))
    draw_colored_polygon(PackedVector2Array([Vector2(13,-21),Vector2(26,-34),Vector2(7,-27)]), Color("d8c39e"))
    draw_rect(Rect2(-14, 5, 28, 6), light)
    draw_rect(Rect2(-12, 16, 9, 8), dark)
    draw_rect(Rect2(3, 16, 9, 8), dark)
    _pixel_eyes(7.0, Color("ffe2c8"))

func _pixel_eyes(offset: float, color: Color) -> void:
    draw_rect(Rect2(-offset - 2.0, -5, 3, 3), color)
    draw_rect(Rect2(offset - 1.0, -5, 3, 3), color)
    draw_rect(Rect2(-offset - 1.0, -4, 1, 1), Color("6b2830"))
    draw_rect(Rect2(offset, -4, 1, 1), Color("6b2830"))

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i: int in range(24):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
