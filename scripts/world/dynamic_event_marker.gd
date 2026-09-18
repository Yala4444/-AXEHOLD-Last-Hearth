class_name DynamicEventMarker
extends Node2D

var event_type: String = "caravan_defense"
var title: String = "СОБЫТИЕ"
var time_left: float = 1.0
var duration: float = 1.0
var state: String = "active"
var elapsed: float = 0.0

func configure(kind: String, title_text: String, total_time: float) -> void:
    event_type = kind
    title = title_text
    duration = maxf(1.0, total_time)
    time_left = duration
    z_index = 4
    queue_redraw()

func set_time(value: float) -> void:
    time_left = clampf(value, 0.0, duration)
    queue_redraw()

func set_state(value: String) -> void:
    state = value
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var pulse: float = (sin(elapsed * 4.0) + 1.0) * 0.5
    var accent: Color = _accent()
    draw_circle(Vector2.ZERO, 36.0 + pulse * 2.0, Color(accent.r, accent.g, accent.b, 0.055))
    draw_arc(Vector2.ZERO, 35.0 + pulse * 2.0, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.52), 1.5)

    match event_type:
        "caravan_defense":
            _draw_caravan(accent)
        "survivor_rescue":
            _draw_survivor(accent)
        "elite_hunt":
            _draw_hunt(accent)
        "ambush":
            _draw_ambush(accent)
        "trail_cache":
            _draw_cache(accent)
        _:
            draw_circle(Vector2.ZERO, 12.0, accent)

    var ratio: float = clampf(time_left / maxf(1.0, duration), 0.0, 1.0)
    draw_rect(Rect2(-27, 33, 54, 4), Color(0.03, 0.04, 0.04, 0.66))
    var time_color: Color = Color("dfbd70") if ratio > 0.35 else Color("d7685f")
    draw_rect(Rect2(-27, 33, 54.0 * ratio, 4), time_color)

    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-46, 49), title, HORIZONTAL_ALIGNMENT_CENTER, 92, 7, Color("f1e5cc"))
    if state == "secure":
        draw_string(font, Vector2(-46, 60), "ПОДОЙДИ БЛИЖЕ", HORIZONTAL_ALIGNMENT_CENTER, 92, 7, Color("a9d8bc"))
    elif state == "chain":
        draw_string(font, Vector2(-46, 60), "СЛЕД К ДОБЫЧЕ", HORIZONTAL_ALIGNMENT_CENTER, 92, 7, Color("d8c38d"))

func _accent() -> Color:
    match event_type:
        "caravan_defense":
            return Color("d6ad68")
        "survivor_rescue":
            return Color("91c5a1")
        "elite_hunt":
            return Color("d8705d")
        "ambush":
            return Color("b78ad1")
        "trail_cache":
            return Color("d9c57e")
    return Color("d6ad68")

func _draw_caravan(accent: Color) -> void:
    draw_rect(Rect2(-23, -7, 34, 19), Color("805535"))
    draw_rect(Rect2(-19, -4, 26, 13), Color("a06d3d"))
    draw_circle(Vector2(-12, 14), 6.0, Color("40372f"))
    draw_circle(Vector2(8, 14), 6.0, Color("40372f"))
    draw_line(Vector2(11, -3), Vector2(25, -15), Color("65442f"), 4.0)
    draw_circle(Vector2(22, -19), 3.0, accent)

func _draw_survivor(accent: Color) -> void:
    draw_circle(Vector2(0, -13), 6.0, Color("c99372"))
    draw_rect(Rect2(-7, -7, 14, 18), Color("566d63"))
    draw_line(Vector2(-4, 8), Vector2(-11, 17), Color("3a4541"), 3.0)
    draw_line(Vector2(4, 8), Vector2(11, 17), Color("3a4541"), 3.0)
    draw_circle(Vector2(11, -7), 3.0, accent)

func _draw_hunt(accent: Color) -> void:
    draw_circle(Vector2.ZERO, 15.0, Color(0.13, 0.09, 0.10, 0.86))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-11,-3),Vector2(-5,-17),Vector2(0,-8),Vector2(6,-18),
        Vector2(12,-2),Vector2(7,13),Vector2(-7,13)
    ]), Color(accent.r, accent.g, accent.b, 0.78))
    draw_rect(Rect2(-6, -3, 4, 3), Color("fff0d1"))
    draw_rect(Rect2(2, -3, 4, 3), Color("fff0d1"))

func _draw_ambush(accent: Color) -> void:
    for i: int in range(4):
        var angle: float = TAU * float(i) / 4.0 + 0.35
        var p := Vector2(cos(angle), sin(angle)) * 15.0
        draw_line(p - Vector2(5, 4), p + Vector2(5, 4), Color(accent.r, accent.g, accent.b, 0.72), 3.0)
    draw_circle(Vector2.ZERO, 5.0, Color("32243a"))

func _draw_cache(accent: Color) -> void:
    draw_rect(Rect2(-16, -7, 32, 19), Color("73502f"))
    draw_rect(Rect2(-14, -5, 28, 15), Color("9b7140"))
    draw_rect(Rect2(-16, -9, 32, 6), accent.darkened(0.20))
    draw_rect(Rect2(-2, -2, 4, 8), Color("e4c77d"))
