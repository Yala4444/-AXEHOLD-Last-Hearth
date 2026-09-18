class_name ResourceIcon
extends Control

var kind: String = "wood"

func configure(value: String) -> void:
    kind = value
    custom_minimum_size = Vector2(13, 13)
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
    draw_rect(Rect2(1, 8, 11, 3), Color("3b2a1d"))
    draw_rect(Rect2(2, 5, 9, 5), Color("7b5130"))
    draw_rect(Rect2(3, 4, 7, 2), Color("9d6b3e"))
    draw_rect(Rect2(4, 6, 2, 2), Color("c08a51"))
    draw_rect(Rect2(8, 6, 2, 2), Color("c08a51"))

func _draw_stone() -> void:
    draw_rect(Rect2(2, 9, 9, 2), Color("596161"))
    draw_rect(Rect2(1, 6, 11, 4), Color("87908f"))
    draw_rect(Rect2(3, 3, 6, 3), Color("a8b2b0"))
    draw_rect(Rect2(5, 4, 2, 2), Color("c4ccca"))

func _draw_ore() -> void:
    draw_rect(Rect2(1, 8, 11, 3), Color("55435f"))
    draw_rect(Rect2(2, 5, 9, 5), Color("75558d"))
    draw_rect(Rect2(4, 2, 5, 4), Color("a978c5"))
    draw_rect(Rect2(5, 3, 3, 2), Color("d1a6e8"))
    draw_rect(Rect2(9, 6, 2, 2), Color("bc8bd8"))

func _draw_part() -> void:
    draw_circle(Vector2(6.5, 6.5), 5.2, Color("5a5f61"))
    draw_circle(Vector2(6.5, 6.5), 3.4, Color("90989a"))
    draw_circle(Vector2(6.5, 6.5), 1.5, Color("303638"))
    for p: Vector2 in [Vector2(5.5,0), Vector2(5.5,10), Vector2(0,5.5), Vector2(10,5.5)]:
        draw_rect(Rect2(p, Vector2(3,3)), Color("b2b9b8"))
