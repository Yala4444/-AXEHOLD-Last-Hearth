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

func configure(kind: String, title: String, new_cost: Dictionary, is_built: bool = false, effect_text: String = "") -> void:
    build_type = kind
    label = title
    effect = effect_text
    cost = new_cost.duplicate(true)
    built = is_built
    reveal = 1.0 if built else 0.0
    construction_progress = 1.0 if built else 0.0
    queue_redraw()

func _process(delta: float) -> void:
    if pulse > 0.0:
        pulse = maxf(0.0, pulse - delta * 2.8)
        queue_redraw()
    if built and reveal < 1.0:
        reveal = minf(1.0, reveal + delta * 2.8)
        scale = Vector2.ONE * (0.72 + 0.28 * _ease_out_back(reveal))
        queue_redraw()
    elif built:
        scale = Vector2.ONE

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
    construction_progress = maxf(0.0, construction_progress - 0.08)
    queue_redraw()

func consume(storage: Dictionary) -> void:
    for key: String in ["wood", "stone", "ore"]:
        storage[key] = int(storage.get(key, 0)) - int(cost.get(key, 0))
    built = true
    construction_progress = 1.0
    reveal = 0.0
    pulse = 1.0
    queue_redraw()

func _draw() -> void:
    if built:
        _draw_built_structure()
        if pulse > 0.0:
            var p: float = 1.0 - pulse
            draw_rect(Rect2(-34.0 - p * 8.0, -34.0 - p * 8.0, 68.0 + p * 16.0, 68.0 + p * 16.0), Color(1.0, 0.82, 0.42, pulse * 0.55), false, 2.0)
        return

    # Pixel-blueprint pad: square, readable and intentionally game-like.
    draw_rect(Rect2(-30, -30, 60, 60), Color("dfcda6"))
    draw_rect(Rect2(-27, -27, 54, 54), Color("f1e3c3"))
    draw_rect(Rect2(-30, -30, 60, 60), Color("806943"), false, 2.0)
    for x: int in [-20, 20]:
        for y: int in [-20, 20]:
            draw_rect(Rect2(x - 2, y - 2, 4, 4), Color("8b744c"))

    _draw_blueprint_preview()

    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-28, -14), label, HORIZONTAL_ALIGNMENT_CENTER, 56, 8, Color("352c22"))
    var resource_text: String = "Д%d К%d Р%d" % [int(cost.get("wood", 0)), int(cost.get("stone", 0)), int(cost.get("ore", 0))]
    draw_string(font, Vector2(-28, 24), resource_text, HORIZONTAL_ALIGNMENT_CENTER, 56, 7, Color("594a36"))

    if construction_progress > 0.0:
        draw_rect(Rect2(-25, 31, 50, 4), Color(0.18, 0.16, 0.12, 0.28))
        draw_rect(Rect2(-25, 31, 50 * construction_progress, 4), Color("77a86c"))

func _draw_blueprint_preview() -> void:
    var ink := Color(0.35, 0.29, 0.21, 0.56)
    match build_type:
        "wall":
            for x: int in [-10, 0, 10]:
                draw_rect(Rect2(x - 2, -2, 4, 15), ink)
                draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -2), Vector2(x, -8), Vector2(x + 3, -2)]), ink)
            draw_rect(Rect2(-15, 4, 30, 3), ink)
        "forge":
            draw_rect(Rect2(-12, 2, 24, 12), ink)
            draw_colored_polygon(PackedVector2Array([Vector2(-15, 2), Vector2(0, -10), Vector2(15, 2)]), ink)
            draw_rect(Rect2(6, -10, 5, 10), ink)
        "turret":
            draw_rect(Rect2(-8, -2, 16, 16), ink)
            draw_rect(Rect2(-2, -14, 4, 14), ink)
            draw_rect(Rect2(-11, 14, 22, 3), ink)
        "shrine":
            draw_colored_polygon(PackedVector2Array([
                Vector2(0, -13), Vector2(7, -2), Vector2(4, 13),
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
    draw_rect(Rect2(-29, 18, 58, 6), Color(0.05, 0.06, 0.05, 0.18))
    for x: int in [-24, -16, -8, 0, 8, 16, 24]:
        draw_rect(Rect2(x - 3, -18, 6, 37), Color("765237"))
        draw_rect(Rect2(x - 2, -16, 4, 33), Color("956947"))
        draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -18), Vector2(x, -25), Vector2(x + 3, -18)]), Color("a57a51"))
    draw_rect(Rect2(-29, -7, 58, 4), Color("5b3f2d"))
    draw_rect(Rect2(-29, 8, 58, 4), Color("5b3f2d"))

func _draw_forge() -> void:
    draw_rect(Rect2(-27, 18, 54, 6), Color(0.05, 0.06, 0.05, 0.18))
    draw_rect(Rect2(-25, -10, 50, 31), Color("76543c"))
    draw_rect(Rect2(-21, -6, 42, 27), Color("8b6546"))
    draw_colored_polygon(PackedVector2Array([Vector2(-30, -10), Vector2(0, -31), Vector2(30, -10)]), Color("454248"))
    draw_rect(Rect2(12, -30, 8, 22), Color("58565b"))
    draw_rect(Rect2(-10, 3, 20, 18), Color("342a25"))
    draw_rect(Rect2(-6, 9, 12, 10), Color("ec9d45"))
    draw_rect(Rect2(-3, 12, 6, 7), Color("ffe099"))
    draw_rect(Rect2(-21, -1, 13, 4), Color("aeb9be"))

func _draw_turret() -> void:
    draw_rect(Rect2(-22, 19, 44, 5), Color(0.05, 0.06, 0.05, 0.18))
    draw_rect(Rect2(-12, -1, 24, 23), Color("626a71"))
    draw_rect(Rect2(-9, 2, 18, 17), Color("7b858c"))
    draw_rect(Rect2(-15, -13, 30, 13), Color("505960"))
    draw_rect(Rect2(-3, -31, 6, 19), Color("3c454c"))
    draw_rect(Rect2(-5, -34, 10, 4), Color("d5ad57"))

func _draw_shrine() -> void:
    draw_rect(Rect2(-23, 19, 46, 5), Color(0.05, 0.06, 0.05, 0.18))
    draw_rect(Rect2(-17, 12, 34, 8), Color("58676a"))
    var crystal := PackedVector2Array([
        Vector2(0, -31), Vector2(11, -9), Vector2(7, 15),
        Vector2(0, 22), Vector2(-7, 15), Vector2(-11, -9)
    ])
    draw_colored_polygon(crystal, Color("63adbc"))
    var inner := PackedVector2Array([
        Vector2(0, -22), Vector2(5, -7), Vector2(3, 10),
        Vector2(0, 15), Vector2(-3, 10), Vector2(-5, -7)
    ])
    draw_colored_polygon(inner, Color("c5edf1"))
    draw_rect(Rect2(-26, -3, 52, 6), Color(0.40, 0.78, 0.82, 0.10))

func _ease_out_back(t: float) -> float:
    var c1: float = 1.70158
    var c3: float = c1 + 1.0
    var u: float = t - 1.0
    return 1.0 + c3 * u * u * u + c1 * u * u
