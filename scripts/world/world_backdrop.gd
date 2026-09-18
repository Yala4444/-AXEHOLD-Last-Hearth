class_name WorldBackdrop
extends Node2D

var world_size: Vector2 = Vector2(1170, 2532)
var base_position: Vector2 = Vector2.ZERO
var biome: Dictionary = {}
var biome_index: int = 0
var night: bool = false

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
        bottom = Color("30483d") if biome_index < 2 else Color("57332f")

    draw_rect(Rect2(Vector2.ZERO, world_size), bottom)

    var band_h: float = 22.0
    var bands: int = int(ceil(world_size.y / band_h))
    for i: int in range(bands):
        var t: float = float(i) / float(maxi(1, bands - 1))
        draw_rect(
            Rect2(0, float(i) * band_h, world_size.x, band_h + 1.0),
            top.lerp(bottom, t)
        )

    _draw_ground_detail()
    _draw_clearing()
    _draw_world_edges()

func _draw_ground_detail() -> void:
    var tuft: Color = Color(0.18, 0.32, 0.18, 0.17) if not night else Color(0.05, 0.10, 0.10, 0.17)
    var patch: Color = Color(0.12, 0.24, 0.14, 0.09) if not night else Color(0.04, 0.08, 0.09, 0.10)

    for i: int in range(260):
        var px: float = floor(fmod(float(i * 137 + 31), world_size.x - 20.0) / 4.0) * 4.0 + 10.0
        var py: float = floor(fmod(float(i * 83 + 149), world_size.y - 20.0) / 4.0) * 4.0 + 10.0
        var point := Vector2(px, py)
        if point.distance_to(base_position) < 105.0:
            continue
        if i % 4 == 0:
            draw_rect(Rect2(px, py, 14, 4), patch)
        else:
            draw_rect(Rect2(px, py, 3, 7), tuft)
            draw_rect(Rect2(px + 4, py + 2, 2, 5), Color(tuft, tuft.a * 0.72))

    # Sparse darker forest-floor patches increase depth without becoming obstacles.
    for i: int in range(34):
        var px: float = fmod(float(i * 191 + 71), world_size.x - 90.0) + 45.0
        var py: float = fmod(float(i * 127 + 211), world_size.y - 90.0) + 45.0
        var p := Vector2(px, py)
        if p.distance_to(base_position) < 180.0:
            continue
        draw_circle(p, 24.0 + float(i % 4) * 7.0, Color(0.08, 0.17, 0.09, 0.035))

func _draw_clearing() -> void:
    var clearing: Color = Color(0.68, 0.77, 0.48, 0.27) if not night else Color(0.39, 0.46, 0.32, 0.22)
    draw_circle(base_position, 105.0, clearing)

    var path: Color = Color(0.54, 0.48, 0.31, 0.21) if not night else Color(0.29, 0.27, 0.22, 0.17)
    var bottom_y: float = minf(world_size.y, base_position.y + 430.0)
    var points := PackedVector2Array([
        Vector2(base_position.x - 19, base_position.y + 28),
        Vector2(base_position.x + 20, base_position.y + 28),
        Vector2(base_position.x + 35, bottom_y),
        Vector2(base_position.x - 38, bottom_y)
    ])
    draw_colored_polygon(points, path)

    for i: int in range(9):
        var y: float = base_position.y + 58.0 + float(i) * 41.0
        if y > bottom_y:
            break
        draw_rect(
            Rect2(base_position.x - 11 + float((i % 2) * 4), y, 20, 3),
            Color(0.36, 0.31, 0.21, 0.12)
        )

func _draw_world_edges() -> void:
    var edge: Color = Color(0.03, 0.08, 0.04, 0.20) if not night else Color(0.01, 0.025, 0.03, 0.30)
    var width: float = 34.0
    draw_rect(Rect2(0, 0, world_size.x, width), edge)
    draw_rect(Rect2(0, world_size.y - width, world_size.x, width), edge)
    draw_rect(Rect2(0, 0, width, world_size.y), edge)
    draw_rect(Rect2(world_size.x - width, 0, width, world_size.y), edge)
