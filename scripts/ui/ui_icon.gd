class_name UiIcon
extends Control

var kind: String = "camp"
var accent: Color = VisualSystem.TEXT_SOFT
var icon_scale: float = 1.0

func configure(value: String, color: Color = VisualSystem.TEXT_SOFT, scale_value: float = 1.0) -> void:
    kind = value
    accent = color
    icon_scale = scale_value
    custom_minimum_size = Vector2(20, 20) * icon_scale
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw() -> void:
    var c := accent
    var center := Vector2(size.x, size.y) * 0.5
    var s: float = minf(size.x, size.y) / 20.0
    draw_set_transform(center, 0.0, Vector2(s, s))
    match kind:
        "coin":
            _coin(c)
        "shard":
            _shard(c)
        "settings":
            _gear(c)
        "camp":
            _camp(c)
        "arsenal":
            _arsenal(c)
        "map":
            _map(c)
        "trophy":
            _trophy(c)
        "heart":
            _heart(c)
        "hearth":
            _hearth(c)
        "pause":
            _pause(c)
        "quest":
            _quest(c)
        "contract":
            _contract(c)
        "forge":
            _forge(c)
        "lock":
            _lock(c)
        "check":
            _check(c)
        "skull":
            _skull(c)
        "arrow":
            _arrow(c)
        "star":
            _star(c)
        _:
            draw_circle(Vector2.ZERO, 5.0, c)

func _coin(c: Color) -> void:
    draw_circle(Vector2.ZERO, 7.2, c.darkened(0.22))
    draw_circle(Vector2.ZERO, 5.6, c)
    draw_arc(Vector2.ZERO, 3.2, 0.0, TAU, 18, c.lightened(0.28), 1.2)
    draw_line(Vector2(-2.4, -1.8), Vector2(2.2, 1.8), c.darkened(0.28), 1.4)

func _shard(c: Color) -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-8),Vector2(6,-2),Vector2(4,7),Vector2(-2,9),Vector2(-7,1)
    ]), c.darkened(0.15))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-6),Vector2(4,-1),Vector2(2,6),Vector2(-2,7),Vector2(-5,1)
    ]), c)
    draw_line(Vector2(0,-5),Vector2(-1,6),c.lightened(0.28),1.1)

func _gear(c: Color) -> void:
    draw_circle(Vector2.ZERO, 6.0, c)
    draw_circle(Vector2.ZERO, 2.4, VisualSystem.BG)
    for i: int in range(8):
        var a: float = TAU * float(i) / 8.0
        var p := Vector2(cos(a), sin(a))
        draw_rect(Rect2(p * 7.2 - Vector2(1.5,1.5), Vector2(3,3)), c)

func _camp(c: Color) -> void:
    draw_line(Vector2(-7,6),Vector2(0,-6),c,2.0)
    draw_line(Vector2(0,-6),Vector2(7,6),c,2.0)
    draw_line(Vector2(-7,6),Vector2(7,6),c,2.0)
    draw_colored_polygon(PackedVector2Array([Vector2(-3,5),Vector2(0,-1),Vector2(3,5)]), c.darkened(0.18))
    draw_circle(Vector2(0,3),1.5,VisualSystem.GOLD_BRIGHT)

func _arsenal(c: Color) -> void:
    draw_line(Vector2(-6,7),Vector2(5,-6),c,2.2)
    draw_colored_polygon(PackedVector2Array([Vector2(6,-8),Vector2(7,-3),Vector2(3,-5)]),c.lightened(0.20))
    draw_line(Vector2(-6,-5),Vector2(6,7),c.darkened(0.08),2.2)
    draw_colored_polygon(PackedVector2Array([Vector2(-7,-7),Vector2(-2,-6),Vector2(-4,-2)]),c.lightened(0.18))

func _map(c: Color) -> void:
    var pts := PackedVector2Array([Vector2(-8,-6),Vector2(-2,-8),Vector2(4,-5),Vector2(8,-7),Vector2(8,7),Vector2(2,8),Vector2(-4,5),Vector2(-8,7)])
    draw_polyline(pts, c, 1.5)
    draw_line(Vector2(-2,-8),Vector2(-2,6),c,1.2)
    draw_line(Vector2(4,-5),Vector2(4,7),c,1.2)
    draw_circle(Vector2(3,-1),1.7,VisualSystem.GOLD_BRIGHT)

func _trophy(c: Color) -> void:
    draw_rect(Rect2(-4,-7,8,8),c)
    draw_arc(Vector2(-5,-4),4.0,1.5,4.8,10,c,1.5)
    draw_arc(Vector2(5,-4),4.0,-1.65,1.65,10,c,1.5)
    draw_line(Vector2(0,1),Vector2(0,6),c,2.0)
    draw_rect(Rect2(-5,6,10,2),c)

func _heart(c: Color) -> void:
    draw_circle(Vector2(-3,-2),3.8,c)
    draw_circle(Vector2(3,-2),3.8,c)
    draw_colored_polygon(PackedVector2Array([Vector2(-6,-1),Vector2(6,-1),Vector2(0,8)]),c)

func _hearth(c: Color) -> void:
    draw_line(Vector2(-6,6),Vector2(6,-2),c.darkened(0.28),2.0)
    draw_line(Vector2(6,6),Vector2(-6,-2),c.darkened(0.28),2.0)
    draw_colored_polygon(PackedVector2Array([Vector2(-4,4),Vector2(-1,-5),Vector2(1,-1),Vector2(4,-7),Vector2(6,4)]),c)
    draw_circle(Vector2(1,2),2.0,c.lightened(0.25))

func _pause(c: Color) -> void:
    draw_rect(Rect2(-5,-7,3,14),c)
    draw_rect(Rect2(2,-7,3,14),c)

func _quest(c: Color) -> void:
    draw_rect(Rect2(-6,-7,12,14),c.darkened(0.20))
    draw_rect(Rect2(-4,-5,8,10),VisualSystem.SURFACE_3)
    for y: float in [-2.5,0.5,3.5]:
        draw_line(Vector2(-2.5,y),Vector2(3.0,y),c,1.0)

func _contract(c: Color) -> void:
    draw_rect(Rect2(-7,-6,14,12),c.darkened(0.18))
    draw_rect(Rect2(-5,-4,10,8),VisualSystem.SURFACE_2)
    draw_line(Vector2(-3,-1),Vector2(3,-1),c,1.1)
    draw_circle(Vector2(3,3),2.1,VisualSystem.RED)

func _forge(c: Color) -> void:
    draw_line(Vector2(-6,6),Vector2(5,-5),c,2.6)
    draw_line(Vector2(-1,-4),Vector2(6,3),c.darkened(0.18),3.0)
    draw_rect(Rect2(-7,5,12,2.5),c)

func _lock(c: Color) -> void:
    draw_rect(Rect2(-6,-1,12,8),c)
    draw_arc(Vector2(0,-1),5.0,PI,TAU,14,c,2.0)
    draw_circle(Vector2(0,3),1.4,VisualSystem.BG)

func _check(c: Color) -> void:
    draw_line(Vector2(-7,0),Vector2(-2,5),c,2.5)
    draw_line(Vector2(-2,5),Vector2(7,-5),c,2.5)

func _skull(c: Color) -> void:
    draw_circle(Vector2(0,-1),6.0,c)
    draw_rect(Rect2(-4,3,8,4),c)
    draw_circle(Vector2(-2.2,-1),1.4,VisualSystem.BG)
    draw_circle(Vector2(2.2,-1),1.4,VisualSystem.BG)
    draw_rect(Rect2(-1,2,2,2),VisualSystem.BG)

func _arrow(c: Color) -> void:
    draw_line(Vector2(-7,0),Vector2(5,0),c,2.2)
    draw_colored_polygon(PackedVector2Array([Vector2(7,0),Vector2(2,-5),Vector2(2,5)]),c)

func _star(c: Color) -> void:
    var points := PackedVector2Array()
    for i: int in range(10):
        var a: float = -PI/2.0 + float(i) * PI / 5.0
        var r: float = 7.0 if i % 2 == 0 else 3.0
        points.append(Vector2(cos(a),sin(a))*r)
    draw_colored_polygon(points,c)
