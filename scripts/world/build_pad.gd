class_name BuildPad
extends Node2D

var build_type: String = "wall"
var label: String = "ПАЛИСАД"
var effect: String = ""
var cost: Dictionary = {"wood": 12, "stone": 0, "ore": 0}
var built: bool = false
var reveal: float = 1.0
var pulse: float = 0.0
var construction_progress: float = 0.0
var affordable: bool = false
var focused: bool = false
var idle_time: float = 0.0

func configure(kind: String, title: String, new_cost: Dictionary, is_built: bool = false, effect_text: String = "") -> void:
    build_type = kind
    label = title
    effect = effect_text
    cost = new_cost.duplicate(true)
    built = is_built
    reveal = 1.0 if built else 0.0
    construction_progress = 1.0 if built else 0.0
    queue_redraw()

func set_context_state(can_afford: bool, is_focused: bool) -> void:
    if affordable == can_afford and focused == is_focused:
        return
    affordable = can_afford
    focused = is_focused
    queue_redraw()

func _process(delta: float) -> void:
    idle_time += delta
    if pulse > 0.0:
        pulse = maxf(0.0, pulse - delta * 2.8)
        queue_redraw()
    if built and reveal < 1.0:
        reveal = minf(1.0, reveal + delta * 2.8)
        scale = Vector2.ONE * (0.78 + 0.22 * _ease_out_back(reveal))
        queue_redraw()
    elif built:
        scale = Vector2.ONE
    elif affordable or focused or construction_progress > 0.0:
        queue_redraw()

func can_build(storage: Dictionary) -> bool:
    return int(storage.get("wood", 0)) >= int(cost.get("wood", 0)) \
        and int(storage.get("stone", 0)) >= int(cost.get("stone", 0)) \
        and int(storage.get("ore", 0)) >= int(cost.get("ore", 0))

func advance_construction(delta: float) -> bool:
    if built:
        return false
    construction_progress = minf(1.0, construction_progress + delta / 0.72)
    queue_redraw()
    return construction_progress >= 1.0

func reset_construction() -> void:
    if built:
        return
    var before: float = construction_progress
    construction_progress = maxf(0.0, construction_progress - 0.08)
    if not is_equal_approx(before, construction_progress):
        queue_redraw()

func consume(storage: Dictionary) -> void:
    for key: String in ["wood", "stone", "ore"]:
        storage[key] = int(storage.get(key, 0)) - int(cost.get(key, 0))
    built = true
    construction_progress = 1.0
    reveal = 0.0
    pulse = 1.0
    focused = false
    affordable = false
    queue_redraw()

func _draw() -> void:
    if built:
        _draw_built_structure()
        if pulse > 0.0:
            var p: float = 1.0 - pulse
            var radius: float = 34.0 + p * 18.0
            draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.81, 0.38, pulse * 0.62), 2.0)
        return

    _draw_world_blueprint()

func _draw_world_blueprint() -> void:
    var breathe: float = (sin(idle_time * 2.5) + 1.0) * 0.5
    var active: bool = affordable or focused
    var ring_color: Color = Color(0.91, 0.72, 0.34, 0.78) if active else Color(0.29, 0.35, 0.30, 0.48)
    var fill_color: Color = Color(0.10, 0.15, 0.12, 0.16) if not active else Color(0.95, 0.76, 0.36, 0.09 + breathe * 0.035)

    draw_circle(Vector2(2, 5), 29.0, Color(0.04, 0.06, 0.04, 0.11))
    draw_circle(Vector2.ZERO, 27.0, fill_color)
    draw_arc(Vector2.ZERO, 27.0 + (breathe * 1.2 if active else 0.0), 0.0, TAU, 28, ring_color, 1.5)

    for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
        var dir := Vector2(cos(angle), sin(angle))
        var pos := dir * 25.0
        draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), ring_color)

    _draw_blueprint_preview(Color(0.86, 0.79, 0.61, 0.72) if active else Color(0.39, 0.43, 0.36, 0.55))

    var font: Font = ThemeDB.fallback_font
    var tag_width: float = maxf(48.0, float(label.length()) * 5.2)
    var tag_rect := Rect2(-tag_width * 0.5, 31, tag_width, 15)
    draw_rect(tag_rect, Color(0.05, 0.08, 0.07, 0.76))
    draw_rect(tag_rect, Color(0.40, 0.47, 0.39, 0.45), false, 1.0)
    draw_string(font, Vector2(-tag_width * 0.5 + 2.0, 42), label, HORIZONTAL_ALIGNMENT_CENTER, tag_width - 4.0, 7, Color("efe5ca"))

    if construction_progress > 0.0:
        draw_rect(Rect2(-23, 49, 46, 4), Color(0.04, 0.06, 0.05, 0.30))
        draw_rect(Rect2(-23, 49, 46 * construction_progress, 4), Color("d8b35f"))

func _draw_blueprint_preview(ink: Color) -> void:
    match build_type:
        "wall":
            for x: int in [-10, 0, 10]:
                draw_rect(Rect2(x - 2, -5, 4, 15), ink)
                draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -5), Vector2(x, -11), Vector2(x + 3, -5)]), ink)
            draw_rect(Rect2(-15, 2, 30, 3), ink)
        "forge":
            draw_rect(Rect2(-11, 2, 22, 11), ink)
            draw_colored_polygon(PackedVector2Array([Vector2(-14, 2), Vector2(0, -10), Vector2(14, 2)]), ink)
            draw_rect(Rect2(6, -10, 5, 10), ink)
        "turret":
            draw_rect(Rect2(-8, -1, 16, 15), ink)
            draw_rect(Rect2(-2, -15, 4, 14), ink)
            draw_rect(Rect2(-11, 14, 22, 3), ink)
        "shrine":
            draw_colored_polygon(PackedVector2Array([
                Vector2(0, -14), Vector2(7, -2), Vector2(4, 13),
                Vector2(0, 17), Vector2(-4, 13), Vector2(-7, -2)
            ]), ink)

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

func _draw_wall() -> void:
    draw_rect(Rect2(-31, 18, 62, 6), Color(0.04, 0.05, 0.04, 0.22))
    for x: int in [-24, -16, -8, 0, 8, 16, 24]:
        draw_rect(Rect2(x - 3, -18, 6, 38), Color("533821"))
        draw_rect(Rect2(x - 2, -17, 4, 35), Color("8d633b"))
        draw_rect(Rect2(x - 1, -16, 2, 31), Color("a87b4b"))
        draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -18), Vector2(x, -25), Vector2(x + 3, -18)]), Color("b58c59"))
    draw_rect(Rect2(-29, -7, 58, 4), Color("4a321f"))
    draw_rect(Rect2(-29, 8, 58, 4), Color("4a321f"))

func _draw_forge() -> void:
    draw_rect(Rect2(-29, 19, 58, 6), Color(0.04, 0.05, 0.04, 0.23))
    draw_rect(Rect2(-25, -10, 50, 31), Color("4f3728"))
    draw_rect(Rect2(-21, -6, 42, 27), Color("79543a"))
    draw_rect(Rect2(-17, -3, 34, 24), Color("8d6848"))
    draw_colored_polygon(PackedVector2Array([Vector2(-30, -10), Vector2(0, -31), Vector2(30, -10)]), Color("34353a"))
    draw_rect(Rect2(12, -30, 8, 22), Color("48494e"))
    draw_rect(Rect2(-10, 3, 20, 18), Color("2c2522"))
    draw_rect(Rect2(-7, 8, 14, 11), Color("b95a2d"))
    draw_rect(Rect2(-4, 11, 8, 8), Color("f2a74a"))
    draw_rect(Rect2(-2, 13, 4, 6), Color("ffe0a1"))
    draw_rect(Rect2(-22, -1, 14, 5), Color("879096"))
    draw_rect(Rect2(-20, 0, 10, 2), Color("c7d0d3"))

func _draw_turret() -> void:
    draw_rect(Rect2(-23, 19, 46, 6), Color(0.04, 0.05, 0.04, 0.23))
    draw_rect(Rect2(-13, -1, 26, 23), Color("454f55"))
    draw_rect(Rect2(-10, 2, 20, 17), Color("67747a"))
    draw_rect(Rect2(-15, -13, 30, 13), Color("343e44"))
    draw_rect(Rect2(-3, -32, 6, 20), Color("293238"))
    draw_rect(Rect2(-5, -35, 10, 5), Color("d6a64d"))
    draw_rect(Rect2(-2, -34, 4, 3), Color("ffe3a1"))

func _draw_shrine() -> void:
    var glow: float = (sin(idle_time * 3.0) + 1.0) * 0.5
    draw_circle(Vector2(0, -2), 30.0 + glow * 2.0, Color(0.35, 0.77, 0.80, 0.05 + glow * 0.035))
    draw_rect(Rect2(-24, 19, 48, 6), Color(0.04, 0.05, 0.04, 0.22))
    draw_rect(Rect2(-17, 12, 34, 8), Color("48575c"))
    draw_rect(Rect2(-14, 14, 28, 4), Color("6f7d81"))
    var crystal := PackedVector2Array([
        Vector2(0, -31), Vector2(11, -9), Vector2(7, 15),
        Vector2(0, 22), Vector2(-7, 15), Vector2(-11, -9)
    ])
    draw_colored_polygon(crystal, Color("4f99a5"))
    var inner := PackedVector2Array([
        Vector2(0, -22), Vector2(5, -7), Vector2(3, 10),
        Vector2(0, 15), Vector2(-3, 10), Vector2(-5, -7)
    ])
    draw_colored_polygon(inner, Color("c8f1ef"))
    draw_line(Vector2(-2, -20), Vector2(-4, 9), Color(1.0, 1.0, 1.0, 0.48), 1.5)

func _ease_out_back(t: float) -> float:
    var c1: float = 1.70158
    var c3: float = c1 + 1.0
    var u: float = t - 1.0
    return 1.0 + c3 * u * u * u + c1 * u * u
