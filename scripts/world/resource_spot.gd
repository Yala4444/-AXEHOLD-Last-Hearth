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
    queue_redraw()
    return hp <= 0.0

func _draw() -> void:
    var flash: float = hit_pulse * 0.28
    if resource_type == "tree":
        _draw_shadow_ellipse(Vector2(5, 12), Vector2(14, 6), Color(0.08, 0.12, 0.06, 0.15))
        draw_rect(Rect2(-4, 5, 8, 16), Color("735037").lightened(flash * 0.5))
        var greens: Array[Color] = [Color("4d8950"), Color("5d9757"), Color("407b47")]
        var crown: Color = greens[variant % greens.size()].lightened(flash)
        draw_circle(Vector2(0, -4), 15, crown)
        draw_circle(Vector2(-10, 1), 10, crown.darkened(0.03))
        draw_circle(Vector2(10, 1), 10, crown.lightened(0.025))
        draw_line(Vector2(-5, -12), Vector2(-2, -5), Color(1, 1, 1, flash * 0.7), 1.5)
    elif resource_type == "rock":
        var rock_color: Color = Color("8a9093").lightened(flash)
        draw_colored_polygon(PackedVector2Array([Vector2(-13, 8), Vector2(-8, -11), Vector2(4, -14), Vector2(14, 3), Vector2(6, 12)]), rock_color)
        draw_line(Vector2(-3, -10), Vector2(4, 1), Color(0.72, 0.76, 0.78, 0.7), 1.4)
        draw_line(Vector2(4, 1), Vector2(10, 5), Color(0.55, 0.59, 0.61, 0.7), 1.2)
    else:
        var ore_color: Color = Color("8669a0").lightened(flash)
        draw_colored_polygon(PackedVector2Array([Vector2(-13, 8), Vector2(-8, -11), Vector2(4, -14), Vector2(14, 3), Vector2(6, 12)]), ore_color)
        draw_circle(Vector2(3, -3), 4, Color("caa9e2").lightened(flash))
        draw_circle(Vector2(-5, 3), 2.5, Color("b48ed0"))
        if hit_pulse > 0.1:
            draw_circle(Vector2(8, -8), 2.0 + hit_pulse * 2.0, Color(0.86, 0.72, 1.0, hit_pulse * 0.7))

    if hp < max_hp:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        draw_rect(Rect2(-14, -24, 28, 4), Color(0.1, 0.1, 0.1, 0.22))
        draw_rect(Rect2(-14, -24, 28 * ratio, 4), Color("72a66d"))

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(24):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
