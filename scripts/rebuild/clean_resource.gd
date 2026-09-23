class_name AXEHOLDCleanResource
extends ResourceSpot

const TREE_STRIP_PATH := "res://assets/art/vertical_slice_i/tree_damage.webp"
const ROCK_PATH := "res://assets/art/forgotten_forest/stone_deposit.png"
const ORE_PATH := "res://assets/art/forgotten_forest/ore_deposit.png"

var clean_tree_strip: Texture2D
var clean_rock: Texture2D
var clean_ore: Texture2D

func _ready() -> void:
    clean_tree_strip = ResourceLoader.load(TREE_STRIP_PATH) as Texture2D
    clean_rock = ResourceLoader.load(ROCK_PATH) as Texture2D
    clean_ore = ResourceLoader.load(ORE_PATH) as Texture2D
    visual_gate_enabled = true

func configure(kind: String, v: int = 0, biome: int = 0) -> void:
    super.configure(kind, v, biome)
    visual_gate_enabled = true
    match resource_type:
        "tree":
            radius = 31.0
            max_hp = 64.0
        "rock":
            radius = 24.0
            max_hp = 82.0
        "ore":
            radius = 25.0
            max_hp = 112.0
    hp = max_hp
    queue_redraw()

func _draw() -> void:
    _draw_ground_socket()
    var flash: float = hit_pulse * 0.24
    match resource_type:
        "tree":
            _draw_tree_resource(flash)
        "rock":
            _draw_static_resource(clean_rock, Vector2(78,72), -16.0, flash)
        "ore":
            _draw_static_resource(clean_ore, Vector2(82,92), -24.0, flash)

    if hp < max_hp:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        var y: float = -104.0 if resource_type == "tree" else (-56.0 if resource_type == "ore" else -43.0)
        draw_rect(Rect2(-17, y, 34, 4), Color(0.03,0.04,0.03,0.46))
        draw_rect(Rect2(-17, y, 34.0 * ratio, 4), Color("7fb875"))

func _draw_ground_socket() -> void:
    var variant_scale: float = 0.92 + float(variant % 3) * 0.08
    var rx: float = (36.0 if resource_type == "tree" else 27.0) * variant_scale
    var ry: float = (9.0 if resource_type == "tree" else 7.0) * variant_scale
    draw_set_transform(Vector2(0, 18), 0.0, Vector2(1.0, ry / rx))
    draw_circle(Vector2.ZERO, rx, Color(0.03,0.04,0.025,0.25))
    draw_circle(Vector2.ZERO, rx * 0.82, Color(0.23,0.17,0.09,0.15))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

    var soil := Color(0.31,0.22,0.12,0.24)
    draw_circle(Vector2(-18,17),2.2,soil)
    draw_circle(Vector2(15,20),1.8,soil)
    draw_circle(Vector2(23,15),1.3,soil)

    var grass := Color(0.25,0.42,0.18,0.48)
    for x: float in [-27.0,-21.0,20.0,27.0]:
        draw_line(Vector2(x,18), Vector2(x + signf(x) * -2.0, 10), grass, 1.3)
        draw_line(Vector2(x + 2.0,18), Vector2(x + signf(x) * 3.0, 12), grass, 1.0)

func _draw_tree_resource(flash: float) -> void:
    if clean_tree_strip == null:
        return
    var frame_w: float = clean_tree_strip.get_width() / 4.0
    var frame_h: float = clean_tree_strip.get_height()
    var ratio: float = clampf(hp / maxf(1.0,max_hp),0.0,1.0)
    var frame: int = 0
    if ratio <= 0.24:
        frame = 3
    elif ratio <= 0.52:
        frame = 2
    elif ratio <= 0.77:
        frame = 1
    var source := Rect2(frame_w * frame, 0.0, frame_w, frame_h)
    var scale_variant: float = 0.90 + float(variant % 3) * 0.08
    var size := Vector2(112,148) * scale_variant
    var mirror: float = -1.0 if variant % 2 == 1 else 1.0
    var tint := Color.WHITE.lerp(Color(1.0,0.72,0.58), flash)
    var y_offset: float = 27.0 - size.y * 0.5
    draw_set_transform(Vector2(0,y_offset),0.0,Vector2(mirror,1.0))
    draw_texture_rect_region(clean_tree_strip,Rect2(-size*0.5,size),source,tint)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_static_resource(texture: Texture2D, size: Vector2, y_offset: float, flash: float) -> void:
    if texture == null:
        return
    var scale_variant: float = 0.94 + float(variant % 3) * 0.05
    size *= scale_variant
    y_offset = 22.0 - size.y * 0.5
    var mirror: float = -1.0 if variant % 2 == 1 else 1.0
    var tint := Color.WHITE.lerp(Color(1.0,0.72,0.58), flash)
    draw_set_transform(Vector2(0,y_offset),0.0,Vector2(mirror,1.0))
    draw_texture_rect(texture,Rect2(-size*0.5,size),false,tint)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
