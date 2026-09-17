class_name ResourceSpot
extends Node2D

var resource_type := "tree"
var hp := 52.0
var max_hp := 52.0
var variant := 0
var radius := 15.0

func configure(kind: String, v: int = 0) -> void:
    resource_type = kind
    variant = v
    match kind:
        "tree":
            max_hp = 52.0
            radius = 15.0
        "rock":
            max_hp = 72.0
            radius = 14.0
        "ore":
            max_hp = 98.0
            radius = 13.0
    hp = max_hp
    queue_redraw()

func damage(amount: float) -> bool:
    hp -= amount
    queue_redraw()
    return hp <= 0.0

func _draw() -> void:
    if resource_type == "tree":
        draw_ellipse(Vector2(5, 12), Vector2(14, 6), Color(0.08,0.12,0.06,0.15))
        draw_rect(Rect2(-4,5,8,16), Color("735037"))
        var greens := [Color("4d8950"), Color("5d9757"), Color("407b47")]
        var c: Color = greens[variant % greens.size()]
        draw_circle(Vector2(0,-4),15,c)
        draw_circle(Vector2(-10,1),10,c)
        draw_circle(Vector2(10,1),10,c)
    elif resource_type == "rock":
        draw_colored_polygon(PackedVector2Array([Vector2(-13,8),Vector2(-8,-11),Vector2(4,-14),Vector2(14,3),Vector2(6,12)]), Color("8a9093"))
    else:
        draw_colored_polygon(PackedVector2Array([Vector2(-13,8),Vector2(-8,-11),Vector2(4,-14),Vector2(14,3),Vector2(6,12)]), Color("8669a0"))
        draw_circle(Vector2(3,-3),4,Color("caa9e2"))
    if hp < max_hp:
        var ratio := clamp(hp/max_hp,0.0,1.0)
        draw_rect(Rect2(-14,-24,28,4),Color(0.1,0.1,0.1,0.2))
        draw_rect(Rect2(-14,-24,28*ratio,4),Color("72a66d"))

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var a := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
    draw_colored_polygon(points, color)
