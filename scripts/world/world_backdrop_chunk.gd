class_name WorldBackdropChunk
extends Node2D

var chunk_rect: Rect2 = Rect2()
var world_size: Vector2 = Vector2.ZERO
var base_position: Vector2 = Vector2.ZERO
var biome: Dictionary = {}
var biome_index: int = 0
var night: bool = false

func setup(rect: Rect2, size: Vector2, hearth: Vector2, biome_data: Dictionary, index: int, is_night: bool) -> void:
    chunk_rect = rect
    world_size = size
    base_position = hearth
    biome = biome_data.duplicate(true)
    biome_index = index
    night = is_night
    position = rect.position
    z_index = -20
    queue_redraw()

func set_night(value: bool) -> void:
    if night == value:
        return
    night = value
    queue_redraw()

func _draw() -> void:
    if chunk_rect.size.x <= 0.0 or chunk_rect.size.y <= 0.0:
        return

    _draw_gradient()
    _draw_ground_detail()
    _draw_path_segment()
    _draw_clearing_segment()
    _draw_landmarks()
    _draw_world_edge_segment()

func _draw_gradient() -> void:
    var top: Color = Color(str(biome.get("sky", "80936c")))
    var bottom: Color = Color(str(biome.get("ground", "5e795c")))
    if night:
        top = Color("20313a") if biome_index < 2 else Color("34242a")
        bottom = Color("30483d") if biome_index < 2 else Color("57322f")

    var bands: int = 7
    var band_h: float = chunk_rect.size.y / float(bands)
    for i: int in range(bands):
        var world_y: float = chunk_rect.position.y + band_h * (float(i) + 0.5)
        var t: float = clampf(world_y / maxf(1.0, world_size.y), 0.0, 1.0)
        draw_rect(Rect2(0.0, float(i) * band_h, chunk_rect.size.x + 1.0, band_h + 1.0), top.lerp(bottom, t))

func _draw_ground_detail() -> void:
    var count: int = 18
    for i: int in range(count):
        var p := _local_detail_point(i)
        var world_p := chunk_rect.position + p
        if world_p.x < 0.0 or world_p.y < 0.0 or world_p.x > world_size.x or world_p.y > world_size.y:
            continue
        if world_p.distance_to(base_position) < 112.0:
            continue
        match biome_index:
            1:
                _draw_frost_detail(p, i)
            2:
                _draw_ash_detail(p, i)
            _:
                _draw_forest_detail(p, i)

func _local_detail_point(index: int) -> Vector2:
    var sx: int = int(floor(chunk_rect.position.x))
    var sy: int = int(floor(chunk_rect.position.y))
    var x_seed: int = abs(sx * 31 + sy * 17 + index * 137 + 53)
    var y_seed: int = abs(sx * 13 + sy * 37 + index * 83 + 97)
    return Vector2(
        8.0 + float(x_seed % maxi(1, int(chunk_rect.size.x - 16.0))),
        8.0 + float(y_seed % maxi(1, int(chunk_rect.size.y - 16.0)))
    )

func _draw_forest_detail(p: Vector2, index: int) -> void:
    var tuft: Color = Color(0.18, 0.32, 0.18, 0.17) if not night else Color(0.05, 0.10, 0.10, 0.17)
    var patch: Color = Color(0.12, 0.24, 0.14, 0.09) if not night else Color(0.04, 0.08, 0.09, 0.10)
    if index % 4 == 0:
        draw_rect(Rect2(p.x, p.y, 14, 4), patch)
    else:
        draw_rect(Rect2(p.x, p.y, 3, 7), tuft)
        draw_rect(Rect2(p.x + 4, p.y + 2, 2, 5), Color(tuft, tuft.a * 0.72))

func _draw_frost_detail(p: Vector2, index: int) -> void:
    var snow: Color = Color(0.86, 0.94, 0.95, 0.075 if not night else 0.055)
    var crack: Color = Color(0.31, 0.52, 0.58, 0.24 if not night else 0.13)
    if index % 5 == 0:
        draw_rect(Rect2(p.x, p.y, 18, 5), snow)
    elif index % 7 == 0:
        draw_line(p, p + Vector2(8, 5), crack, 1.0)
        draw_line(p + Vector2(8, 5), p + Vector2(13, 2), crack, 1.0)
    else:
        draw_rect(Rect2(p.x, p.y, 3, 5), Color(0.40, 0.61, 0.63, 0.15))

func _draw_ash_detail(p: Vector2, index: int) -> void:
    var ash: Color = Color(0.18, 0.10, 0.09, 0.13 if not night else 0.09)
    var ember: Color = Color(0.88, 0.31, 0.13, 0.12 if not night else 0.18)
    if index % 6 == 0:
        draw_circle(p, 11.0 + float(index % 3) * 4.0, ash)
    elif index % 9 == 0:
        draw_line(p, p + Vector2(10, -4), ember, 1.2)
        draw_rect(Rect2(p + Vector2(10, -5), Vector2(3, 3)), ember)
    else:
        draw_rect(Rect2(p.x, p.y, 4, 3), ash)

func _draw_path_segment() -> void:
    var start_y: float = base_position.y + 28.0
    var end_y: float = minf(world_size.y, base_position.y + 520.0)
    var y0: float = maxf(chunk_rect.position.y, start_y)
    var y1: float = minf(chunk_rect.end.y, end_y)
    if y1 <= y0:
        return

    var t0: float = clampf((y0 - start_y) / maxf(1.0, end_y - start_y), 0.0, 1.0)
    var t1: float = clampf((y1 - start_y) / maxf(1.0, end_y - start_y), 0.0, 1.0)
    var half0: float = lerpf(22.0, 44.0, t0)
    var half1: float = lerpf(22.0, 44.0, t1)
    var center_x: float = base_position.x - chunk_rect.position.x
    var local_y0: float = y0 - chunk_rect.position.y
    var local_y1: float = y1 - chunk_rect.position.y
    var points := PackedVector2Array([
        Vector2(center_x - half0, local_y0),
        Vector2(center_x + half0, local_y0),
        Vector2(center_x + half1, local_y1),
        Vector2(center_x - half1, local_y1)
    ])
    var path_color: Color = Color(0.54, 0.48, 0.31, 0.21) if biome_index != 1 else Color(0.57, 0.69, 0.68, 0.16)
    if night:
        path_color.a *= 0.82
    draw_colored_polygon(points, path_color)

func _draw_clearing_segment() -> void:
    if not chunk_rect.grow(130.0).has_point(base_position):
        return
    var clearing: Color
    if biome_index == 1:
        clearing = Color(0.63, 0.76, 0.74, 0.14) if not night else Color(0.28, 0.39, 0.42, 0.18)
    elif biome_index == 2:
        clearing = Color(0.55, 0.38, 0.28, 0.18) if not night else Color(0.30, 0.19, 0.18, 0.20)
    else:
        clearing = Color(0.68, 0.77, 0.48, 0.27) if not night else Color(0.39, 0.46, 0.32, 0.22)
    draw_circle(base_position - chunk_rect.position, 116.0, clearing)

func _draw_landmarks() -> void:
    var sx: int = int(floor(chunk_rect.position.x))
    var sy: int = int(floor(chunk_rect.position.y))
    var selector: int = abs(sx * 7 + sy * 11)
    if selector % 3 != 0:
        return
    var p := Vector2(chunk_rect.size.x * 0.58, chunk_rect.size.y * 0.43)
    var world_p := chunk_rect.position + p
    if world_p.x < 60.0 or world_p.y < 60.0 or world_p.x > world_size.x - 60.0 or world_p.y > world_size.y - 60.0:
        return
    if world_p.distance_to(base_position) < 210.0:
        return
    match biome_index:
        1:
            draw_line(p + Vector2(-14, 8), p + Vector2(12, -10), Color(0.63, 0.82, 0.86, 0.24), 2.0)
            draw_line(p + Vector2(-8, -6), p + Vector2(8, 10), Color(0.76, 0.92, 0.94, 0.18), 1.0)
        2:
            draw_rect(Rect2(p - Vector2(3, 16), Vector2(6, 30)), Color(0.16, 0.11, 0.10, 0.32))
            draw_line(p + Vector2(0, -9), p + Vector2(12, -18), Color(0.19, 0.12, 0.10, 0.30), 3.0)
        _:
            draw_rect(Rect2(p - Vector2(14, 4), Vector2(28, 8)), Color(0.28, 0.22, 0.16, 0.20))
            draw_circle(p + Vector2(-9, 0), 5.0, Color(0.24, 0.18, 0.14, 0.20))

func _draw_world_edge_segment() -> void:
    var edge: Color = Color(0.03, 0.08, 0.04, 0.18) if not night else Color(0.01, 0.025, 0.03, 0.26)
    if biome_index == 1:
        edge = Color(0.08, 0.17, 0.20, 0.16 if not night else 0.24)
    elif biome_index == 2:
        edge = Color(0.16, 0.05, 0.04, 0.18 if not night else 0.26)

    var width: float = 40.0
    var world_left: float = chunk_rect.position.x
    var world_top: float = chunk_rect.position.y
    var world_right: float = chunk_rect.end.x
    var world_bottom: float = chunk_rect.end.y

    if world_left <= 0.0 and world_right >= 0.0:
        draw_rect(Rect2(-world_left, 0.0, width, chunk_rect.size.y), edge)
    if world_right >= world_size.x and world_left <= world_size.x:
        draw_rect(Rect2(world_size.x - world_left - width, 0.0, width, chunk_rect.size.y), edge)
    if world_top <= 0.0 and world_bottom >= 0.0:
        draw_rect(Rect2(0.0, -world_top, chunk_rect.size.x, width), edge)
    if world_bottom >= world_size.y and world_top <= world_size.y:
        draw_rect(Rect2(0.0, world_size.y - world_top - width, chunk_rect.size.x, width), edge)
