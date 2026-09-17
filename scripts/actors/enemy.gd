class_name AxEnemy
extends CharacterBody2D

signal killed(enemy: AxEnemy)

var enemy_type: String = "normal"
var hp: float = 40.0
var max_hp: float = 40.0
var move_speed: float = 30.0
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
        velocity = global_position.direction_to(target_position) * move_speed
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
        velocity = surge_direction * 102.0
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
        velocity = charge_direction * 190.0
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
    var shadow_radii: Vector2 = Vector2(20.0, 7.0) if boss else Vector2(12.0, 4.5)
    if enemy_type == "guardian" and not boss:
        shadow_radii = Vector2(16.0, 5.5)
    _draw_shadow_ellipse(Vector2(3, 9), shadow_radii, Color(0.05, 0.05, 0.05, 0.18))

    if boss and charge_windup > 0.0:
        var charge_alpha: float = clampf(1.0 - charge_windup / 0.72, 0.0, 1.0)
        draw_line(Vector2.ZERO, charge_direction * (54.0 + charge_alpha * 26.0), Color(1.0, 0.35, 0.28, 0.32 + charge_alpha * 0.55), 4.0)
        draw_arc(Vector2.ZERO, 34.0 + charge_alpha * 5.0, 0.0, TAU, 44, Color(1.0, 0.45, 0.25, 0.28 + charge_alpha * 0.55), 2.5)
    elif boss and charge_time > 0.0:
        for trail_index: int in range(3):
            var back: Vector2 = -charge_direction * float(18 + trail_index * 13)
            draw_circle(back, 16.0 - trail_index * 3.0, Color(0.92, 0.32, 0.25, 0.16 - trail_index * 0.035))

    if enemy_type == "stalker" and surge_windup > 0.0:
        var stalker_charge: float = clampf(1.0 - surge_windup / 0.22, 0.0, 1.0)
        draw_arc(Vector2.ZERO, 17.0 + stalker_charge * 4.0, 0.0, TAU, 30, Color(0.78, 0.56, 1.0, 0.34 + stalker_charge * 0.46), 2.0)
    elif enemy_type == "stalker" and surge_time > 0.0:
        for trail_index: int in range(3):
            var back: Vector2 = -surge_direction * float(12 + trail_index * 9)
            draw_circle(back, 8.0 - trail_index * 1.6, Color(0.62, 0.42, 0.82, 0.18 - trail_index * 0.04))

    var body_radius: float = 24.0 if boss else 10.5
    if enemy_type == "brute" and not boss:
        body_radius = 14.0
    elif enemy_type == "runner" and not boss:
        body_radius = 9.0
    elif enemy_type == "stalker" and not boss:
        body_radius = 10.0
    elif enemy_type == "guardian" and not boss:
        body_radius = 15.0

    var body_color: Color = (Color("9c4d51") if boss else tint).lightened(hit_flash * 0.36)

    if enemy_type == "runner" and not boss:
        var runner_body := PackedVector2Array([
            Vector2(-8, -10), Vector2(8, -7), Vector2(10, 7), Vector2(2, 13), Vector2(-9, 8)
        ])
        draw_colored_polygon(runner_body, body_color)
        draw_line(Vector2(-5, 7), Vector2(-11, 16), body_color.darkened(0.12), 3.0)
        draw_line(Vector2(5, 7), Vector2(11, 15), body_color.darkened(0.12), 3.0)
    elif enemy_type == "stalker" and not boss:
        var stalker_body := PackedVector2Array([
            Vector2(0, -14), Vector2(10, -4), Vector2(7, 10), Vector2(0, 14), Vector2(-8, 8), Vector2(-10, -4)
        ])
        draw_colored_polygon(stalker_body, body_color.darkened(0.05))
        draw_line(Vector2(-6, 7), Vector2(-14, 14), body_color.darkened(0.22), 2.5)
        draw_line(Vector2(6, 7), Vector2(14, 14), body_color.darkened(0.22), 2.5)
        draw_colored_polygon(PackedVector2Array([Vector2(-7, -8), Vector2(-12, -17), Vector2(-2, -11)]), Color("b9a1d6"))
        draw_colored_polygon(PackedVector2Array([Vector2(7, -8), Vector2(12, -17), Vector2(2, -11)]), Color("b9a1d6"))
    elif enemy_type == "guardian" and not boss:
        var guardian_body := PackedVector2Array([
            Vector2(-12, -11), Vector2(12, -11), Vector2(17, 0), Vector2(10, 14), Vector2(-10, 14), Vector2(-17, 0)
        ])
        draw_colored_polygon(guardian_body, body_color.darkened(0.10))
        draw_arc(Vector2.ZERO, 18.0, -PI * 0.82, PI * 0.82, 28, Color("c9c5ad").lightened(hit_flash * 0.28), 3.0)
        draw_line(Vector2(-10, -3), Vector2(10, -3), Color(0.86, 0.83, 0.68, 0.72), 2.0)
    else:
        draw_circle(Vector2.ZERO, body_radius, body_color)

    if enemy_type == "brute" and not boss:
        draw_circle(Vector2(-11, -4), 6.0, body_color.darkened(0.09))
        draw_circle(Vector2(11, -4), 6.0, body_color.darkened(0.09))
        draw_colored_polygon(PackedVector2Array([Vector2(-10, -10), Vector2(-17, -20), Vector2(-4, -14)]), Color("baa98f"))
        draw_colored_polygon(PackedVector2Array([Vector2(10, -10), Vector2(17, -20), Vector2(4, -14)]), Color("baa98f"))

    if boss:
        var pulse: float = 0.5 + sin(animation_time * 3.2) * 0.5
        draw_circle(Vector2.ZERO, 31.0 + pulse * 2.0, Color(0.78, 0.23, 0.27, 0.06 + pulse * 0.04))
        draw_colored_polygon(PackedVector2Array([Vector2(-15, -15), Vector2(-27, -30), Vector2(-7, -20)]), Color("d5c19e"))
        draw_colored_polygon(PackedVector2Array([Vector2(15, -15), Vector2(27, -30), Vector2(7, -20)]), Color("d5c19e"))
        draw_arc(Vector2.ZERO, 19.0, PI * 0.15, PI * 0.85, 18, Color(0.98, 0.55, 0.38, 0.55), 2.0)

    var eye_offset: float = 5.0 if boss else 3.0
    var eye_color: Color = Color("d5b8ff") if enemy_type == "stalker" else Color.WHITE
    draw_circle(Vector2(-eye_offset, -2), 1.9 if boss else 1.6, eye_color)
    draw_circle(Vector2(eye_offset, -2), 1.9 if boss else 1.6, eye_color)
    if boss or enemy_type == "brute" or enemy_type == "guardian":
        draw_circle(Vector2(-eye_offset, -2), 0.8, Color("6e252c"))
        draw_circle(Vector2(eye_offset, -2), 0.8, Color("6e252c"))

    if hit_flash > 0.25:
        draw_arc(Vector2.ZERO, body_radius + 5.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.72, hit_flash * 0.45), 2.0)

    if not dying:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        var width: float = 54.0 if boss else (30.0 if enemy_type == "guardian" else 25.0)
        var bar_y: float = -37.0 if boss else -25.0
        var bar_color: Color = Color("cf6165") if boss else (Color("c7b56e") if enemy_type == "guardian" else Color("8f7198"))
        draw_rect(Rect2(-width / 2.0, bar_y, width, 4.0), Color(0.1, 0.1, 0.1, 0.25))
        draw_rect(Rect2(-width / 2.0, bar_y, width * ratio, 4.0), bar_color)
        if armor > 0.0 and not boss:
            draw_rect(Rect2(-width / 2.0, bar_y + 5.5, width * armor, 1.5), Color(0.88, 0.82, 0.56, 0.62))

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i: int in range(24):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
