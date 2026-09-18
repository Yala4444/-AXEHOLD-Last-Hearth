class_name WorldBackdrop
extends Node2D

var world_size: Vector2 = Vector2(1450, 3200)
var base_position: Vector2 = Vector2.ZERO
var biome: Dictionary = {}
var biome_index: int = 0
var night: bool = false
var safety_pad: float = 520.0

func setup(size: Vector2, hearth: Vector2, biome_data: Dictionary, index: int) -> void:
    world_size = size
    base_position = hearth
    biome = biome_data.duplicate(true)
    biome_index = index
    z_index = -20
    queue_redraw()

func set_night(value: bool) -> void:
    if night == value:
        return
    night = value
    queue_redraw()

func _draw() -> void:
    var top: Color = Color(str(biome.get("sky", "b9cf8d")))
    var bottom: Color = Color(str(biome.get("ground", "7fa268")))
    if night:
        top = Color("20313a") if biome_index < 2 else Color("34242a")
        bottom = Color("30483d") if biome_index < 2 else Color("57322f")

    # Draw well beyond camera limits. This prevents default-clear rectangles from
    # ever becoming visible when the camera eases against a world boundary.
    var padded := Rect2(
        Vector2(-safety_pad, -safety_pad),
        world_size + Vector2.ONE * safety_pad * 2.0
    )
    draw_rect(padded, bottom)

    var band_h: float = 26.0
    var bands: int = int(ceil((world_size.y + safety_pad * 2.0) / band_h))
    for i: int in range(bands):
        var py: float = -safety_pad + float(i) * band_h
        var t: float = clampf((py + safety_pad) / maxf(1.0, world_size.y + safety_pad * 2.0), 0.0, 1.0)
        draw_rect(Rect2(-safety_pad, py, world_size.x + safety_pad * 2.0, band_h + 1.0), top.lerp(bottom, t))

    _draw_ground_detail()
    _draw_clearing()
    _draw_biome_landmarks()
    _draw_world_edges()

func _draw_ground_detail() -> void:
    match biome_index:
        1:
            _draw_frost_detail()
        2:
            _draw_ash_detail()
        _:
            _draw_forest_detail()

func _draw_forest_detail() -> void:
    var tuft: Color = Color(0.18, 0.32, 0.18, 0.17) if not night else Color(0.05, 0.10, 0.10, 0.17)
    var patch: Color = Color(0.12, 0.24, 0.14, 0.09) if not night else Color(0.04, 0.08, 0.09, 0.10)
    for i: int in range(340):
        var p := _detail_point(i, 137, 83)
        if p.distance_to(base_position) < 112.0:
            continue
        if i % 4 == 0:
            draw_rect(Rect2(p.x, p.y, 14, 4), patch)
        else:
            draw_rect(Rect2(p.x, p.y, 3, 7), tuft)
            draw_rect(Rect2(p.x + 4, p.y + 2, 2, 5), Color(tuft, tuft.a * 0.72))

func _draw_frost_detail() -> void:
    var snow: Color = Color(0.86, 0.94, 0.95, 0.12 if not night else 0.07)
    var crack: Color = Color(0.42, 0.66, 0.72, 0.16 if not night else 0.10)
    for i: int in range(300):
        var p := _detail_point(i, 151, 97)
        if p.distance_to(base_position) < 112.0:
            continue
        if i % 5 == 0:
            draw_rect(Rect2(p.x, p.y, 18, 5), snow)
        elif i % 7 == 0:
            draw_line(p, p + Vector2(8, 5), crack, 1.0)
            draw_line(p + Vector2(8, 5), p + Vector2(13, 2), crack, 1.0)
        else:
            draw_rect(Rect2(p.x, p.y, 3, 5), Color(0.55, 0.72, 0.73, 0.12))

func _draw_ash_detail() -> void:
    var ash: Color = Color(0.18, 0.10, 0.09, 0.13 if not night else 0.09)
    var ember: Color = Color(0.88, 0.31, 0.13, 0.12 if not night else 0.18)
    for i: int in range(310):
        var p := _detail_point(i, 163, 109)
        if p.distance_to(base_position) < 112.0:
            continue
        if i % 6 == 0:
            draw_circle(p, 11.0 + float(i % 3) * 4.0, ash)
        elif i % 9 == 0:
            draw_line(p, p + Vector2(10, -4), ember, 1.2)
            draw_rect(Rect2(p + Vector2(10, -5), Vector2(3, 3)), ember)
        else:
            draw_rect(Rect2(p.x, p.y, 4, 3), ash)

func _detail_point(index: int, ax: int, ay: int) -> Vector2:
    return Vector2(
        fmod(float(index * ax + 31), world_size.x - 24.0) + 12.0,
        fmod(float(index * ay + 149), world_size.y - 24.0) + 12.0
    )

func _draw_clearing() -> void:
    var clearing: Color
    if biome_index == 1:
        clearing = Color(0.74, 0.86, 0.82, 0.20) if not night else Color(0.33, 0.45, 0.48, 0.18)
    elif biome_index == 2:
        clearing = Color(0.55, 0.38, 0.28, 0.18) if not night else Color(0.30, 0.19, 0.18, 0.20)
    else:
        clearing = Color(0.68, 0.77, 0.48, 0.27) if not night else Color(0.39, 0.46, 0.32, 0.22)
    draw_circle(base_position, 116.0, clearing)

    var path: Color = Color(0.54, 0.48, 0.31, 0.21) if biome_index != 1 else Color(0.57, 0.69, 0.68, 0.16)
    if night:
        path.a *= 0.82
    var bottom_y: float = minf(world_size.y, base_position.y + 520.0)
    var points := PackedVector2Array([
        Vector2(base_position.x - 21, base_position.y + 28),
        Vector2(base_position.x + 22, base_position.y + 28),
        Vector2(base_position.x + 42, bottom_y),
        Vector2(base_position.x - 44, bottom_y)
    ])
    draw_colored_polygon(points, path)

func _draw_biome_landmarks() -> void:
    # Decorative anchors only. Interactive points are created by WorldActivityDirector.
    for i: int in range(18):
        var p := Vector2(
            fmod(float(i * 293 + 181), world_size.x - 180.0) + 90.0,
            fmod(float(i * 211 + 337), world_size.y - 180.0) + 90.0
        )
        if p.distance_to(base_position) < 210.0:
            continue
        match biome_index:
            1:
                if i % 3 == 0:
                    draw_line(p + Vector2(-14, 8), p + Vector2(12, -10), Color(0.63, 0.82, 0.86, 0.24), 2.0)
                    draw_line(p + Vector2(-8, -6), p + Vector2(8, 10), Color(0.76, 0.92, 0.94, 0.18), 1.0)
            2:
                if i % 3 == 0:
                    draw_rect(Rect2(p - Vector2(3, 16), Vector2(6, 30)), Color(0.16, 0.11, 0.10, 0.32))
                    draw_line(p + Vector2(0, -9), p + Vector2(12, -18), Color(0.19, 0.12, 0.10, 0.30), 3.0)
            _:
                if i % 3 == 0:
                    draw_rect(Rect2(p - Vector2(14, 4), Vector2(28, 8)), Color(0.28, 0.22, 0.16, 0.20))
                    draw_circle(p + Vector2(-9, 0), 5.0, Color(0.24, 0.18, 0.14, 0.20))

func _draw_world_edges() -> void:
    var edge: Color = Color(0.03, 0.08, 0.04, 0.18) if not night else Color(0.01, 0.025, 0.03, 0.26)
    if biome_index == 1:
        edge = Color(0.08, 0.17, 0.20, 0.16 if not night else 0.24)
    elif biome_index == 2:
        edge = Color(0.16, 0.05, 0.04, 0.18 if not night else 0.26)
    var width: float = 40.0
    draw_rect(Rect2(0, 0, world_size.x, width), edge)
    draw_rect(Rect2(0, world_size.y - width, world_size.x, width), edge)
    draw_rect(Rect2(0, 0, width, world_size.y), edge)
    draw_rect(Rect2(world_size.x - width, 0, width, world_size.y), edge)
