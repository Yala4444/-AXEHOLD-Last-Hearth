class_name WorldLandmark
extends Node2D

const ANCIENT_TREE_ART_PATH: String = "res://assets/art/forgotten_forest/ancient_sentinel_tree.png"

var kind: String = "stump"
var biome_index: int = 0
var variant: int = 0
var visual_identity_version: int = 3
var ancient_tree_art: Texture2D

func configure(new_kind: String, index: int, new_variant: int = 0) -> void:
    kind = new_kind
    biome_index = index
    variant = new_variant
    z_index = -2
    queue_redraw()

func visual_identity_profile() -> Dictionary:
    return {"version":visual_identity_version, "kind":kind, "biome":biome_index}

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
        "ancient_tree":
            _draw_ancient_tree()
        "root_arch":
            _draw_root_arch()
        "fallen_totem":
            _draw_fallen_totem()
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

func _draw_ancient_tree() -> void:
    if ancient_tree_art == null:
        ancient_tree_art = ResourceLoader.load(ANCIENT_TREE_ART_PATH) as Texture2D
    if ancient_tree_art != null:
        var art_scale: float = 0.90 + float(variant) * 0.08
        var art_size := Vector2(160, 180) * art_scale
        var mirror: float = -1.0 if variant == 1 else 1.0
        draw_set_transform(Vector2(0, 4), 0.0, Vector2(mirror, 1.0))
        draw_texture_rect(ancient_tree_art, Rect2(-art_size.x * 0.5, -art_size.y + 25.0, art_size.x, art_size.y), false)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        return
    var shadow := Color(0.02,0.04,0.025,0.18)
    var bark := Color("3f3324")
    var bark_light := Color("665039")
    var moss := Color("405e35")
    draw_circle(Vector2(0,18),24.0,shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-13,18),Vector2(-10,-19),Vector2(-4,-40),Vector2(4,-42),
        Vector2(11,-20),Vector2(14,18),Vector2(6,27),Vector2(-7,26)
    ]),bark)
    draw_line(Vector2(-5,-18),Vector2(-26,-31),bark,7.0)
    draw_line(Vector2(5,-23),Vector2(27,-37),bark,6.0)
    draw_line(Vector2(-18,-27),Vector2(-27,-43),bark_light,4.0)
    draw_line(Vector2(18,-31),Vector2(31,-23),bark_light,4.0)
    draw_line(Vector2(-9,5),Vector2(9,-11),bark_light,2.0)
    draw_circle(Vector2(5,-6),4.0,Color(0.72,0.38,0.16,0.62))
    draw_arc(Vector2(0,-16),29.0,3.2,6.0,18,moss,5.0)

func _draw_root_arch() -> void:
    var root := Color("4b3927")
    var root_light := Color("70583a")
    var moss := Color("45643a")
    draw_circle(Vector2(0,13),28.0,Color(0.02,0.04,0.02,0.14))
    draw_arc(Vector2(0,7),28.0,PI,TAU,22,root,8.0)
    draw_arc(Vector2(0,7),21.0,PI,TAU,18,root_light,3.0)
    draw_line(Vector2(-28,7),Vector2(-35,23),root,7.0)
    draw_line(Vector2(28,7),Vector2(36,22),root,7.0)
    draw_line(Vector2(-12,-13),Vector2(-19,-26),root_light,3.0)
    draw_line(Vector2(9,-15),Vector2(18,-28),root_light,3.0)
    draw_arc(Vector2(-2,-1),25.0,3.5,5.4,12,moss,2.4)

func _draw_fallen_totem() -> void:
    var wood := Color("59412b")
    var carving := Color("a57a49")
    draw_line(Vector2(-27,11),Vector2(25,-10),Color(0.02,0.03,0.02,0.18),9.0)
    draw_line(Vector2(-25,6),Vector2(24,-15),wood,10.0)
    draw_circle(Vector2(20,-14),7.0,wood.darkened(0.12))
    draw_line(Vector2(-8,-1),Vector2(-1,-4),carving,2.0)
    draw_line(Vector2(2,-6),Vector2(9,-9),carving,2.0)
    draw_circle(Vector2(20,-14),2.2,Color("d39b4e"))
    draw_line(Vector2(-17,3),Vector2(-21,14),Color("3d5d35"),3.0)
