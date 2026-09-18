class_name ResourceIcon
extends Control

var kind: String = "wood"

func configure(value: String) -> void:
    kind = value
    custom_minimum_size = Vector2(15,15)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw() -> void:
    match kind:
        "stone":
            _draw_stone()
        "ore":
            _draw_ore()
        "part":
            _draw_part()
        _:
            _draw_wood()

func _draw_wood() -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(1,9),Vector2(4,4),Vector2(12,3),Vector2(14,7),Vector2(11,12),Vector2(3,13)
    ]),Color("5c3b26"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(3,8),Vector2(5,5),Vector2(11,4),Vector2(12,7),Vector2(10,10),Vector2(4,11)
    ]),Color("8d5c35"))
    draw_line(Vector2(4,7),Vector2(11,6),Color("bc8650"),1.2)
    draw_line(Vector2(5,10),Vector2(9,9),Color("6d462b"),1.0)

func _draw_stone() -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(1,10),Vector2(3,5),Vector2(7,2),Vector2(12,4),Vector2(14,9),Vector2(10,13),Vector2(4,13)
    ]),Color("687270"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(4,6),Vector2(7,3),Vector2(11,5),Vector2(10,9),Vector2(5,10)
    ]),Color("97a19f"))
    draw_line(Vector2(5,5),Vector2(8,7),Color("c7cfcd"),1.0)

func _draw_ore() -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(1,11),Vector2(3,5),Vector2(7,2),Vector2(13,5),Vector2(14,10),Vector2(10,13),Vector2(4,13)
    ]),Color("584466"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(5,10),Vector2(6,4),Vector2(9,2),Vector2(11,6),Vector2(9,11)
    ]),Color("9c6fba"))
    draw_line(Vector2(8,4),Vector2(8,9),Color("deb9ef"),1.3)
    draw_circle(Vector2(11,7),1.5,Color("c995e2"))

func _draw_part() -> void:
    draw_circle(Vector2(7.5,7.5),5.6,Color("555d60"))
    for i: int in range(8):
        var a: float = TAU*float(i)/8.0
        var p := Vector2(7.5,7.5)+Vector2(cos(a),sin(a))*5.8
        draw_rect(Rect2(p-Vector2(1.2,1.2),Vector2(2.4,2.4)),Color("879194"))
    draw_circle(Vector2(7.5,7.5),3.5,Color("a6afb0"))
    draw_circle(Vector2(7.5,7.5),1.6,Color("30383b"))
