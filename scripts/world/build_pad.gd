class_name BuildPad
extends Node2D

var build_type: String = "wall"
var label: String = "ЗАБОР"
var cost: Dictionary = {"wood": 16, "stone": 0, "ore": 0}
var built: bool = false
var reveal: float = 1.0
var pulse: float = 0.0

func configure(kind: String, title: String, new_cost: Dictionary, is_built: bool = false) -> void:
    build_type = kind
    label = title
    cost = new_cost.duplicate(true)
    built = is_built
    reveal = 1.0 if built else 0.0
    queue_redraw()

func _process(delta: float) -> void:
    if pulse > 0.0:
        pulse = maxf(0.0, pulse - delta * 2.8)
        queue_redraw()
    if built and reveal < 1.0:
        reveal = minf(1.0, reveal + delta * 2.5)
        scale = Vector2.ONE * (0.72 + 0.28 * _ease_out_back(reveal))
        queue_redraw()
    elif built:
        scale = Vector2.ONE

func can_build(storage: Dictionary) -> bool:
    return int(storage.get("wood", 0)) >= int(cost.get("wood", 0)) \
        and int(storage.get("stone", 0)) >= int(cost.get("stone", 0)) \
        and int(storage.get("ore", 0)) >= int(cost.get("ore", 0))

func consume(storage: Dictionary) -> void:
    for key: String in ["wood", "stone", "ore"]:
        storage[key] = int(storage.get(key, 0)) - int(cost.get(key, 0))
    built = true
    reveal = 0.0
    pulse = 1.0
    queue_redraw()

func _draw() -> void:
    if built:
        _draw_built_structure()
        if pulse > 0.0:
            draw_arc(Vector2.ZERO, 31.0 + (1.0 - pulse) * 16.0, 0.0, TAU, 48, Color(1.0, 0.82, 0.42, pulse * 0.75), 2.5)
        return

    draw_circle(Vector2.ZERO, 29.0, Color(0.96, 0.88, 0.72, 0.68))
    draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 48, Color("9e8151"), 2.0)
    for i: int in range(4):
        var angle: float = float(i) * TAU / 4.0 + PI * 0.25
        var a: Vector2 = Vector2(cos(angle), sin(angle)) * 22.0
        var b: Vector2 = Vector2(cos(angle), sin(angle)) * 28.0
        draw_line(a, b, Color("806840"), 2.0)
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-25, 1), label, HORIZONTAL_ALIGNMENT_CENTER, 50, 8, Color("40372e"))
    var resource_text: String = "🪵%d  🪨%d  ⛏%d" % [int(cost.get("wood", 0)), int(cost.get("stone", 0)), int(cost.get("ore", 0))]
    draw_string(font, Vector2(-31, 15), resource_text, HORIZONTAL_ALIGNMENT_CENTER, 62, 7, Color("5a4c3a"))

func _draw_built_structure() -> void:
    match build_type:
        "wall":
            _draw_wall()
        "forge":
            _draw_forge()
        "turret":
            _draw_turret()
        "shrine":
            _draw_shrine()
        _:
            draw_circle(Vector2.ZERO, 26.0, Color("6c9460"))

func _draw_wall() -> void:
    draw_ellipse_shadow(Vector2(2, 13), Vector2(31, 8))
    for x: float in [-20.0, -10.0, 0.0, 10.0, 20.0]:
        draw_rect(Rect2(Vector2(x - 3.5, -19), Vector2(7, 37)), Color("79583a"))
        var tip: PackedVector2Array = PackedVector2Array([
            Vector2(x - 4, -19), Vector2(x, -27), Vector2(x + 4, -19)
        ])
        draw_colored_polygon(tip, Color("8c6846"))
    draw_line(Vector2(-25, -8), Vector2(25, -8), Color("a47a50"), 4.0)
    draw_line(Vector2(-25, 8), Vector2(25, 8), Color("60452e"), 4.0)

func _draw_forge() -> void:
    draw_ellipse_shadow(Vector2(3, 17), Vector2(30, 8))
    draw_rect(Rect2(Vector2(-25, -13), Vector2(50, 33)), Color("77563d"))
    var roof: PackedVector2Array = PackedVector2Array([
        Vector2(-31, -13), Vector2(0, -34), Vector2(31, -13)
    ])
    draw_colored_polygon(roof, Color("4f4540"))
    draw_rect(Rect2(Vector2(12, -31), Vector2(8, 21)), Color("535052"))
    draw_rect(Rect2(Vector2(-11, 2), Vector2(22, 18)), Color("3a302a"))
    draw_circle(Vector2(0, 10), 7.0, Color("f2a44e"))
    draw_circle(Vector2(0, 10), 3.5, Color("ffe19a"))
    draw_line(Vector2(-17, -4), Vector2(-5, 8), Color("b5bdc0"), 4.0)

func _draw_turret() -> void:
    draw_ellipse_shadow(Vector2(2, 17), Vector2(25, 7))
    draw_rect(Rect2(Vector2(-13, -2), Vector2(26, 24)), Color("697077"))
    draw_circle(Vector2(0, -7), 15.0, Color("747d85"))
    draw_circle(Vector2(0, -7), 8.0, Color("4d565e"))
    draw_rect(Rect2(Vector2(-3, -31), Vector2(6, 26)), Color("454d54"))
    draw_circle(Vector2(0, -33), 4.0, Color("d5ae59"))
    draw_arc(Vector2.ZERO, 30.0, PI * 1.08, PI * 1.92, 24, Color(0.85, 0.72, 0.38, 0.4), 2.0)

func _draw_shrine() -> void:
    draw_ellipse_shadow(Vector2(2, 16), Vector2(26, 7))
    draw_circle(Vector2.ZERO, 27.0, Color(0.32, 0.50, 0.52, 0.18))
    draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 48, Color(0.55, 0.82, 0.88, 0.7), 2.0)
    var crystal: PackedVector2Array = PackedVector2Array([
        Vector2(0, -30), Vector2(12, -8), Vector2(7, 17), Vector2(0, 25), Vector2(-7, 17), Vector2(-12, -8)
    ])
    draw_colored_polygon(crystal, Color("75bed0"))
    var inner: PackedVector2Array = PackedVector2Array([
        Vector2(0, -23), Vector2(6, -6), Vector2(3, 12), Vector2(0, 17), Vector2(-3, 12), Vector2(-6, -6)
    ])
    draw_colored_polygon(inner, Color("c6f1f4"))
    draw_circle(Vector2.ZERO, 36.0, Color(0.45, 0.85, 0.90, 0.05))

func draw_ellipse_shadow(center: Vector2, radii: Vector2) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(28):
        var angle: float = TAU * float(i) / 28.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, Color(0.06, 0.08, 0.06, 0.18))

func _ease_out_back(t: float) -> float:
    var c1: float = 1.70158
    var c3: float = c1 + 1.0
    var u: float = t - 1.0
    return 1.0 + c3 * u * u * u + c1 * u * u
