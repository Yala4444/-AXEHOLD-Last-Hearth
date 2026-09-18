class_name BiomeHazardZone
extends Node2D

var hazard_kind: String = "root"
var radius: float = 32.0
var telegraph_time: float = 0.8
var active_time: float = 2.4
var time_left: float = 0.8
var state: String = "telegraph"
var spent: bool = false
var elapsed: float = 0.0

func configure(kind_id: String, zone_radius: float, warning_time: float, linger_time: float) -> void:
    hazard_kind = kind_id
    radius = zone_radius
    telegraph_time = maxf(0.05, warning_time)
    active_time = maxf(0.1, linger_time)
    time_left = telegraph_time
    state = "telegraph"
    spent = false
    z_index = 5
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    time_left -= delta
    if state == "telegraph" and time_left <= 0.0:
        state = "active"
        time_left = active_time
    elif state == "active" and time_left <= 0.0:
        state = "expired"
        queue_free()
        return
    queue_redraw()

func is_active() -> bool:
    return state == "active"

func contains_point(world_point: Vector2) -> bool:
    return global_position.distance_to(world_point) <= radius

func _draw() -> void:
    var warning_progress: float = 0.0
    if state == "telegraph":
        warning_progress = clampf(1.0 - time_left / maxf(0.05, telegraph_time), 0.0, 1.0)
    var active_alpha: float = 1.0 if state == "active" else (0.30 + warning_progress * 0.55)

    match hazard_kind:
        "ice":
            _draw_ice(active_alpha, warning_progress)
        "ember":
            _draw_ember(active_alpha, warning_progress)
        _:
            _draw_root(active_alpha, warning_progress)

func _draw_root(alpha: float, progress: float) -> void:
    var fill := Color(0.28, 0.42, 0.19, 0.06 + alpha * 0.05)
    var line := Color(0.61, 0.76, 0.39, 0.24 + alpha * 0.46)
    draw_circle(Vector2.ZERO, radius, fill)
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, line, 2.0)
    for i: int in range(7):
        var angle: float = TAU * float(i) / 7.0 + elapsed * 0.08
        var inner: Vector2 = Vector2(cos(angle), sin(angle)) * (6.0 + progress * 5.0)
        var outer: Vector2 = Vector2(cos(angle + 0.22), sin(angle + 0.22)) * (radius * 0.86)
        draw_line(inner, outer, Color(0.35, 0.24, 0.14, 0.34 + alpha * 0.30), 2.0)
    if state == "active":
        for i: int in range(5):
            var x: float = -radius * 0.60 + float(i) * radius * 0.30
            draw_line(Vector2(x, 8), Vector2(x + 4, -10 - float(i % 2) * 5.0), Color(0.46, 0.60, 0.28, 0.72), 3.0)

func _draw_ice(alpha: float, progress: float) -> void:
    var fill := Color(0.50, 0.84, 1.0, 0.045 + alpha * 0.055)
    var line := Color(0.72, 0.93, 1.0, 0.28 + alpha * 0.50)
    draw_circle(Vector2.ZERO, radius, fill)
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, line, 2.0)
    for i: int in range(6):
        var angle: float = TAU * float(i) / 6.0
        var end: Vector2 = Vector2(cos(angle), sin(angle)) * radius * (0.42 + progress * 0.40)
        draw_line(Vector2.ZERO, end, Color(0.80, 0.95, 1.0, 0.34 + alpha * 0.42), 1.5)
        draw_line(end * 0.55, end * 0.55 + Vector2(-end.y, end.x).normalized() * 8.0, Color(0.76, 0.91, 0.98, 0.28 + alpha * 0.34), 1.0)

func _draw_ember(alpha: float, progress: float) -> void:
    var fill := Color(1.0, 0.24, 0.08, 0.045 + alpha * 0.07)
    var line := Color(1.0, 0.48, 0.20, 0.30 + alpha * 0.52)
    draw_circle(Vector2.ZERO, radius, fill)
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, line, 2.3)
    draw_arc(Vector2.ZERO, radius * (0.28 + progress * 0.55), 0.0, TAU, 30, line.lightened(0.16), 1.7)
    if state == "active":
        for i: int in range(5):
            var angle: float = TAU * float(i) / 5.0 + elapsed * 0.35
            var p: Vector2 = Vector2(cos(angle), sin(angle)) * radius * 0.55
            draw_circle(p, 2.2, Color(1.0, 0.69, 0.28, 0.76))
