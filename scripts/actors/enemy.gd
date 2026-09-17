class_name AxEnemy
extends CharacterBody2D

signal killed(enemy: AxEnemy)

var enemy_type: String = "normal"
var hp: float = 40.0
var max_hp: float = 40.0
var move_speed: float = 30.0
var contact_damage: float = 8.0
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

func configure(kind: String, difficulty: float, wave: int, color: Color, is_boss: bool = false) -> void:
    enemy_type = kind
    boss = is_boss
    tint = color
    if boss:
        max_hp = 340.0 * difficulty
        move_speed = 23.0
        contact_damage = 22.0 * difficulty
        base_scale = 1.0
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
        base_scale = 1.0
    hp = max_hp
    scale = Vector2.ONE * base_scale
    queue_redraw()

func _physics_process(delta: float) -> void:
    animation_time += delta
    hit_cooldown = maxf(0.0, hit_cooldown - delta)
    hit_flash = maxf(0.0, hit_flash - delta * 5.8)

    if dying:
        death_time -= delta
        velocity = Vector2.ZERO
        var progress: float = clampf(1.0 - death_time / 0.18, 0.0, 1.0)
        scale = Vector2.ONE * base_scale * (1.0 + progress * 0.25) * (1.0 - progress * 0.92)
        rotation = sin(progress * PI) * (0.45 if enemy_type != "brute" else 0.22)
        modulate.a = 1.0 - progress
        queue_redraw()
        if death_time <= 0.0:
            killed.emit(self)
        return

    var moving: bool = has_target and windup <= 0.0
    if moving:
        velocity = global_position.direction_to(target_position) * move_speed
        move_and_slide()
    else:
        velocity = Vector2.ZERO

    var bob_strength: float = 0.025 if boss else 0.04
    var bob_speed: float = 5.2 if enemy_type == "brute" else (8.0 if enemy_type == "runner" else 6.4)
    var bob: float = sin(animation_time * bob_speed) * bob_strength if moving else 0.0
    scale = Vector2(base_scale * (1.0 - bob), base_scale * (1.0 + bob))
    queue_redraw()

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
    hp -= amount
    hit_flash = 1.0
    if hp <= 0.0:
        hp = 0.0
        dying = true
        death_time = 0.18
        contact_damage = 0.0
        has_target = false
        Feedback.play("victory" if boss else "enemy_down", 18 if boss else 0)

func _draw() -> void:
    var shadow_radii: Vector2 = Vector2(20.0, 7.0) if boss else Vector2(12.0, 4.5)
    _draw_shadow_ellipse(Vector2(3, 9), shadow_radii, Color(0.05, 0.05, 0.05, 0.18))

    var body_radius: float = 24.0 if boss else (14.0 if enemy_type == "brute" else (9.0 if enemy_type == "runner" else 10.5))
    var body_color: Color = (Color("9c4d51") if boss else tint).lightened(hit_flash * 0.36)

    if enemy_type == "runner" and not boss:
        var runner_body: PackedVector2Array = PackedVector2Array([
            Vector2(-8, -10), Vector2(8, -7), Vector2(10, 7), Vector2(2, 13), Vector2(-9, 8)
        ])
        draw_colored_polygon(runner_body, body_color)
        draw_line(Vector2(-5, 7), Vector2(-11, 16), body_color.darkened(0.12), 3.0)
        draw_line(Vector2(5, 7), Vector2(11, 15), body_color.darkened(0.12), 3.0)
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
    draw_circle(Vector2(-eye_offset, -2), 1.9 if boss else 1.6, Color.WHITE)
    draw_circle(Vector2(eye_offset, -2), 1.9 if boss else 1.6, Color.WHITE)
    if boss or enemy_type == "brute":
        draw_circle(Vector2(-eye_offset, -2), 0.8, Color("6e252c"))
        draw_circle(Vector2(eye_offset, -2), 0.8, Color("6e252c"))

    if hit_flash > 0.25:
        draw_arc(Vector2.ZERO, body_radius + 5.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.72, hit_flash * 0.45), 2.0)

    if not dying:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        var width: float = 54.0 if boss else 25.0
        var bar_y: float = -37.0 if boss else -25.0
        var bar_color: Color = Color("cf6165") if boss else Color("8f7198")
        draw_rect(Rect2(-width / 2.0, bar_y, width, 4.0), Color(0.1, 0.1, 0.1, 0.25))
        draw_rect(Rect2(-width / 2.0, bar_y, width * ratio, 4.0), bar_color)

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(24):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
