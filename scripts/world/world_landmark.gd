class_name WorldLandmark
extends Node2D

var kind: String = "stump"
var biome_index: int = 0
var variant: int = 0

func configure(new_kind: String, index: int, new_variant: int = 0) -> void:
    kind = new_kind
    biome_index = index
    variant = new_variant
    z_index = -2
    queue_redraw()

func _draw() -> void:
    match kind:
        "ruin":
            _draw_ruin()
        "bones":
            _draw_bones()
        "sign":
            _draw_sign()
        "firepit":
            _draw_firepit()
        "dead_tree":
            _draw_dead_tree()
        "ice":
            _draw_ice()
        _:
            _draw_stump()

func _draw_stump() -> void:
    draw_rect(Rect2(-9, 5, 18, 5), Color(0.05, 0.06, 0.04, 0.12))
    draw_rect(Rect2(-6, -5, 12, 12), Color("68472d"))
    draw_rect(Rect2(-7, -7, 14, 5), Color("9a7247"))
    draw_rect(Rect2(-3, -6, 6, 2), Color("c39a65"))

func _draw_ruin() -> void:
    var stone := Color("69716c") if biome_index != 1 else Color("799398")
    draw_rect(Rect2(-17, 8, 35, 5), Color(0.04, 0.05, 0.04, 0.14))
    draw_rect(Rect2(-14, -6, 10, 16), stone.darkened(0.18))
    draw_rect(Rect2(-3, -13, 12, 23), stone)
    draw_rect(Rect2(9, -3, 8, 13), stone.darkened(0.08))
    draw_rect(Rect2(-1, -10, 5, 4), stone.lightened(0.15))

func _draw_bones() -> void:
    var bone := Color("c7bea6")
    draw_line(Vector2(-12, 5), Vector2(11, -5), bone, 3.0)
    draw_line(Vector2(-10, -6), Vector2(12, 6), bone, 3.0)
    draw_circle(Vector2(-12, 5), 3.0, bone)
    draw_circle(Vector2(11, -5), 3.0, bone)

func _draw_sign() -> void:
    draw_rect(Rect2(-2, -11, 4, 24), Color("5c4028"))
    draw_rect(Rect2(-13, -13, 25, 9), Color("7f5a36"))
    draw_rect(Rect2(-10, -11, 15, 2), Color("a77a4b"))

func _draw_firepit() -> void:
    for i: int in range(7):
        var angle: float = TAU * float(i) / 7.0
        draw_circle(Vector2(cos(angle), sin(angle)) * 10.0, 3.2, Color("67665e"))
    draw_rect(Rect2(-5, -2, 10, 4), Color("3e2b21"))
    draw_rect(Rect2(-2, -5, 4, 5), Color(0.77, 0.33, 0.15, 0.45))

func _draw_dead_tree() -> void:
    draw_rect(Rect2(-4, -18, 8, 32), Color("33251f"))
    draw_line(Vector2(0, -10), Vector2(-13, -19), Color("33251f"), 5.0)
    draw_line(Vector2(1, -4), Vector2(14, -14), Color("33251f"), 4.0)

func _draw_ice() -> void:
    var ice := PackedVector2Array([
        Vector2(-13, 9), Vector2(-7, -8), Vector2(0, -16),
        Vector2(7, -7), Vector2(13, 10)
    ])
    draw_colored_polygon(ice, Color(0.56, 0.79, 0.84, 0.54))
    draw_line(Vector2(-1, -12), Vector2(-4, 7), Color(0.84, 0.95, 0.96, 0.48), 1.0)
