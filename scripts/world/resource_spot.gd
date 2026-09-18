class_name ResourceSpot
extends Node2D

var resource_type: String = "tree"
var hp: float = 52.0
var max_hp: float = 52.0
var variant: int = 0
var radius: float = 15.0
var hit_pulse: float = 0.0
var hit_gate: float = 0.0
var wobble_phase: float = 0.0

func configure(kind: String, v: int = 0) -> void:
    resource_type = kind
    variant = v
    match kind:
        "tree":
            max_hp = 52.0
            radius = 15.0
        "rock":
            max_hp = 72.0
            radius = 14.0
        "ore":
            max_hp = 98.0
            radius = 13.0
    hp = max_hp
    queue_redraw()

func _process(delta: float) -> void:
    hit_gate = maxf(0.0, hit_gate - delta)
    if hit_pulse > 0.0:
        hit_pulse = maxf(0.0, hit_pulse - delta * 5.5)
        wobble_phase += delta * 34.0
        var squash: float = sin(wobble_phase) * hit_pulse * 0.055
        scale = Vector2(1.0 + squash, 1.0 - squash)
        queue_redraw()
    else:
        scale = scale.lerp(Vector2.ONE, minf(1.0, delta * 14.0))

func damage(amount: float) -> bool:
    hp -= amount
    if hit_gate <= 0.0:
        hit_gate = 0.11
        hit_pulse = 1.0
        wobble_phase = 0.0
    if hp <= 0.0:
        Feedback.play("ore" if resource_type == "ore" else "harvest", 8)
    queue_redraw()
    return hp <= 0.0

func _draw() -> void:
    var flash: float = hit_pulse * 0.28
    if resource_type == "tree":
        draw_rect(Rect2(-13, 14, 28, 5), Color(0.06, 0.08, 0.05, 0.16))
        draw_rect(Rect2(-4, 3, 8, 18), Color("704d35").lightened(flash * 0.4))
        var greens: Array[Color] = [Color("4d8950"), Color("5d9757"), Color("407b47")]
        var crown: Color = greens[variant % greens.size()].lightened(flash)
        draw_rect(Rect2(-12, -12, 24, 17), crown.darkened(0.08))
        draw_rect(Rect2(-17, -6, 34, 13), crown)
        draw_rect(Rect2(-10, -17, 20, 7), crown.lightened(0.08))
        draw_rect(Rect2(-7, -14, 5, 5), Color(0.75, 0.90, 0.70, 0.18 + flash * 0.5))
    elif resource_type == "rock":
        var rock_color: Color = Color("858c91").lightened(flash)
        draw_rect(Rect2(-13, 8, 27, 6), Color(0.06, 0.07, 0.07, 0.14))
        draw_colored_polygon(PackedVector2Array([
            Vector2(-13, 8), Vector2(-10, -7), Vector2(-3, -13),
            Vector2(8, -10), Vector2(14, 1), Vector2(8, 11), Vector2(-7, 12)
        ]), rock_color)
        draw_rect(Rect2(-5, -9, 5, 11), rock_color.lightened(0.16))
        draw_rect(Rect2(4, 0, 6, 4), rock_color.darkened(0.15))
    else:
        var ore_color: Color = Color("79578f").lightened(flash)
        draw_rect(Rect2(-13, 8, 27, 6), Color(0.06, 0.05, 0.08, 0.14))
        draw_colored_polygon(PackedVector2Array([
            Vector2(-13, 8), Vector2(-10, -8), Vector2(-2, -14),
            Vector2(10, -9), Vector2(14, 2), Vector2(7, 12), Vector2(-7, 11)
        ]), ore_color)
        draw_rect(Rect2(-4, -8, 6, 7), Color("c4a1df").lightened(flash))
        draw_rect(Rect2(5, 0, 5, 5), Color("b187cb"))
        draw_rect(Rect2(-8, 3, 4, 4), Color("9f78bd"))
        if hit_pulse > 0.1:
            draw_rect(Rect2(9, -10, 4, 4), Color(0.86, 0.72, 1.0, hit_pulse * 0.75))

    if hp < max_hp:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        draw_rect(Rect2(-14, -24, 28, 4), Color(0.08, 0.08, 0.08, 0.32))
        draw_rect(Rect2(-14, -24, 28 * ratio, 4), Color("72a66d"))

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(24):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
