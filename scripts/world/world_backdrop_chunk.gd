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
    if selector % 2 != 0:
        return

    var p := Vector2(
        chunk_rect.size.x * (0.34 + float(selector % 5) * 0.08),
        chunk_rect.size.y * (0.31 + float((selector / 3) % 5) * 0.09)
    )
    var world_p := chunk_rect.position + p
    if world_p.x < 70.0 or world_p.y < 70.0 or world_p.x > world_size.x - 70.0 or world_p.y > world_size.y - 70.0:
        return

    var distance: float = world_p.distance_to(base_position)
    if distance < 220.0:
        return

    var variant: int = selector % 6
    var landmark_scale: float = clampf(0.84 + distance / maxf(world_size.length(), 1.0) * 0.72, 0.84, 1.22)
    if selector % 11 == 0:
        landmark_scale *= 1.18

    match biome_index:
        1:
            _draw_frost_landmark(p, variant, landmark_scale)
        2:
            _draw_ash_landmark(p, variant, landmark_scale)
        _:
            _draw_forest_landmark(p, variant, landmark_scale)

func _draw_forest_landmark(p: Vector2, variant: int, s: float) -> void:
    var wood := Color(0.26, 0.19, 0.13, 0.62 if not night else 0.46)
    var stone := Color(0.34, 0.37, 0.31, 0.54 if not night else 0.42)
    var moss := Color(0.28, 0.43, 0.24, 0.48 if not night else 0.30)
    match variant:
        0:
            # Fallen caravan wheel and broken axle.
            draw_circle(p + Vector2(-10, 4) * s, 12.0 * s, Color(0.10, 0.08, 0.06, 0.18))
            draw_arc(p + Vector2(-10, 0) * s, 10.0 * s, 0.0, TAU, 16, wood, 3.0 * s)
            draw_line(p + Vector2(-20, 0) * s, p + Vector2(1, 0) * s, wood, 2.0 * s)
            draw_line(p + Vector2(-10, -10) * s, p + Vector2(-10, 10) * s, wood, 2.0 * s)
            draw_line(p + Vector2(-2, 1) * s, p + Vector2(22, -11) * s, wood.darkened(0.12), 4.0 * s)
        1:
            # Old road marker swallowed by roots.
            draw_rect(Rect2(p + Vector2(-8, -22) * s, Vector2(16, 35) * s), stone)
            draw_rect(Rect2(p + Vector2(-5, -18) * s, Vector2(10, 4) * s), stone.lightened(0.14))
            draw_line(p + Vector2(-18, 12) * s, p + Vector2(18, -1) * s, moss, 4.0 * s)
            draw_line(p + Vector2(-12, 16) * s, p + Vector2(10, 5) * s, moss.darkened(0.08), 3.0 * s)
        2:
            # Ruined arch from the old Hearth road.
            draw_rect(Rect2(p + Vector2(-23, -8) * s, Vector2(7, 30) * s), stone)
            draw_rect(Rect2(p + Vector2(16, -8) * s, Vector2(7, 30) * s), stone)
            draw_line(p + Vector2(-20, -8) * s, p + Vector2(18, -17) * s, stone.lightened(0.08), 7.0 * s)
            draw_line(p + Vector2(-13, -10) * s, p + Vector2(6, 7) * s, moss, 3.0 * s)
        3:
            # Abandoned camp remains.
            draw_line(p + Vector2(-20, 9) * s, p + Vector2(20, -7) * s, wood, 5.0 * s)
            draw_line(p + Vector2(-18, -6) * s, p + Vector2(18, 11) * s, wood.darkened(0.10), 5.0 * s)
            draw_rect(Rect2(p + Vector2(9, -20) * s, Vector2(13, 9) * s), Color(0.38, 0.30, 0.20, 0.50))
        4:
            # Root-covered shrine.
            draw_rect(Rect2(p + Vector2(-10, -19) * s, Vector2(20, 33) * s), stone.darkened(0.06))
            draw_circle(p + Vector2(0, -7) * s, 5.0 * s, Color(0.53, 0.68, 0.40, 0.48))
            draw_arc(p + Vector2(0, -6) * s, 15.0 * s, 2.9, 6.1, 16, moss, 3.0 * s)
        _:
            # Half-collapsed cabin silhouette.
            draw_rect(Rect2(p + Vector2(-24, -5) * s, Vector2(42, 24) * s), wood.darkened(0.18))
            draw_colored_polygon(PackedVector2Array([
                p + Vector2(-28, -5) * s,
                p + Vector2(-3, -24) * s,
                p + Vector2(22, -5) * s
            ]), wood.darkened(0.32))
            draw_rect(Rect2(p + Vector2(-4, 5) * s, Vector2(10, 14) * s), Color(0.06, 0.07, 0.06, 0.32))

func _draw_frost_landmark(p: Vector2, variant: int, s: float) -> void:
    var ice := Color(0.61, 0.83, 0.88, 0.54 if not night else 0.42)
    var pale := Color(0.80, 0.94, 0.96, 0.60 if not night else 0.46)
    var stone := Color(0.35, 0.45, 0.47, 0.52)
    match variant:
        0:
            # Crystal cluster.
            for i: int in range(3):
                var offset := Vector2(float(i - 1) * 11.0, float(abs(i - 1)) * 5.0) * s
                draw_colored_polygon(PackedVector2Array([
                    p + offset + Vector2(0, -25) * s,
                    p + offset + Vector2(8, -4) * s,
                    p + offset + Vector2(4, 15) * s,
                    p + offset + Vector2(-6, 14) * s,
                    p + offset + Vector2(-9, -4) * s
                ]), ice.lightened(float(i) * 0.05))
                draw_line(p + offset + Vector2(0, -20) * s, p + offset + Vector2(1, 10) * s, pale, 1.5 * s)
        1:
            # Frozen road arch.
            draw_rect(Rect2(p + Vector2(-22, -5) * s, Vector2(7, 29) * s), stone)
            draw_rect(Rect2(p + Vector2(15, -5) * s, Vector2(7, 29) * s), stone)
            draw_line(p + Vector2(-19, -7) * s, p + Vector2(17, -15) * s, pale.darkened(0.12), 6.0 * s)
            draw_line(p + Vector2(-9, -10) * s, p + Vector2(8, 10) * s, ice, 2.0 * s)
        2:
            # Frozen cart.
            draw_rect(Rect2(p + Vector2(-20, -8) * s, Vector2(35, 18) * s), Color(0.30, 0.28, 0.24, 0.46))
            draw_circle(p + Vector2(-12, 13) * s, 7.0 * s, Color(0.22, 0.24, 0.24, 0.50))
            draw_circle(p + Vector2(10, 13) * s, 7.0 * s, Color(0.22, 0.24, 0.24, 0.50))
            draw_line(p + Vector2(-22, -12) * s, p + Vector2(18, -12) * s, pale, 3.0 * s)
        3:
            # Ice-bound cairn.
            draw_rect(Rect2(p + Vector2(-15, 5) * s, Vector2(30, 10) * s), stone.darkened(0.06))
            draw_rect(Rect2(p + Vector2(-10, -7) * s, Vector2(20, 11) * s), stone)
            draw_rect(Rect2(p + Vector2(-5, -19) * s, Vector2(10, 11) * s), pale.darkened(0.18))
        4:
            # Frozen memorial spear.
            draw_line(p + Vector2(0, 18) * s, p + Vector2(0, -25) * s, Color(0.30, 0.25, 0.22, 0.58), 4.0 * s)
            draw_colored_polygon(PackedVector2Array([
                p + Vector2(0, -31) * s,
                p + Vector2(-7, -20) * s,
                p + Vector2(7, -20) * s
            ]), pale)
            draw_line(p + Vector2(-13, 10) * s, p + Vector2(14, 4) * s, ice, 2.0 * s)
        _:
            # Deep ice fissure.
            draw_line(p + Vector2(-27, -9) * s, p + Vector2(-10, -1) * s, Color(0.25, 0.47, 0.55, 0.58), 3.0 * s)
            draw_line(p + Vector2(-10, -1) * s, p + Vector2(3, 15) * s, Color(0.25, 0.47, 0.55, 0.58), 3.0 * s)
            draw_line(p + Vector2(3, 15) * s, p + Vector2(25, 5) * s, pale, 2.0 * s)

func _draw_ash_landmark(p: Vector2, variant: int, s: float) -> void:
    var char := Color(0.13, 0.09, 0.08, 0.66 if not night else 0.54)
    var iron := Color(0.33, 0.30, 0.29, 0.58)
    var ember := Color(0.94, 0.29, 0.12, 0.44 if not night else 0.62)
    match variant:
        0:
            # Ruined forge with anvil.
            draw_rect(Rect2(p + Vector2(-24, -5) * s, Vector2(44, 22) * s), char)
            draw_rect(Rect2(p + Vector2(-6, -18) * s, Vector2(9, 19) * s), iron)
            draw_rect(Rect2(p + Vector2(-12, -21) * s, Vector2(24, 7) * s), iron.lightened(0.10))
            draw_circle(p + Vector2(17, 7) * s, 3.5 * s, ember)
        1:
            # Charred tree with ember wound.
            draw_rect(Rect2(p + Vector2(-4, -23) * s, Vector2(8, 43) * s), char)
            draw_line(p + Vector2(0, -12) * s, p + Vector2(-17, -24) * s, char, 5.0 * s)
            draw_line(p + Vector2(1, -9) * s, p + Vector2(18, -19) * s, char, 5.0 * s)
            draw_rect(Rect2(p + Vector2(-2, -5) * s, Vector2(4, 11) * s), ember)
        2:
            # Furnace stack.
            draw_rect(Rect2(p + Vector2(-12, -28) * s, Vector2(24, 43) * s), iron.darkened(0.14))
            draw_rect(Rect2(p + Vector2(-16, 8) * s, Vector2(32, 9) * s), char)
            draw_rect(Rect2(p + Vector2(-5, -15) * s, Vector2(10, 8) * s), ember.darkened(0.20))
        3:
            # Molten fissure.
            draw_line(p + Vector2(-29, -7) * s, p + Vector2(-9, 2) * s, ember.darkened(0.10), 4.0 * s)
            draw_line(p + Vector2(-9, 2) * s, p + Vector2(5, -5) * s, Color(1.0, 0.48, 0.18, ember.a), 4.0 * s)
            draw_line(p + Vector2(5, -5) * s, p + Vector2(27, 9) * s, ember, 4.0 * s)
        4:
            # Broken war standard.
            draw_line(p + Vector2(-3, 18) * s, p + Vector2(0, -25) * s, iron, 4.0 * s)
            draw_colored_polygon(PackedVector2Array([
                p + Vector2(0, -23) * s,
                p + Vector2(20, -16) * s,
                p + Vector2(5, -7) * s
            ]), Color(0.32, 0.13, 0.11, 0.56))
            draw_circle(p + Vector2(3, -18) * s, 2.5 * s, ember)
        _:
            # Collapsed smelter pipework.
            draw_rect(Rect2(p + Vector2(-23, -10) * s, Vector2(16, 28) * s), iron.darkened(0.18))
            draw_line(p + Vector2(-8, -2) * s, p + Vector2(18, -15) * s, iron, 7.0 * s)
            draw_line(p + Vector2(15, -16) * s, p + Vector2(24, 8) * s, iron.darkened(0.10), 6.0 * s)
            draw_circle(p + Vector2(-15, 4) * s, 3.0 * s, ember)

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
