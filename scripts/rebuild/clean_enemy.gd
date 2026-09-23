class_name AXEHOLDCleanEnemy
extends AxEnemy

const HUSK_STRIP_PATH := "res://assets/art/vertical_slice_i/husk_walk.webp"
const HOUND_STRIP_PATH := "res://assets/art/vertical_slice_i/hound_run.webp"

var clean_husk_strip: Texture2D
var clean_hound_strip: Texture2D
var clean_art: Dictionary = {}

func _ready() -> void:
    clean_husk_strip = ResourceLoader.load(HUSK_STRIP_PATH) as Texture2D
    clean_hound_strip = ResourceLoader.load(HOUND_STRIP_PATH) as Texture2D
    for key: String in FOREST_ART_PATHS.keys():
        clean_art[key] = ResourceLoader.load(str(FOREST_ART_PATHS[key])) as Texture2D
    visual_gate_enabled = true

func configure(kind: String, difficulty: float, wave: int, color: Color, is_boss: bool = false, region_index: int = 0) -> void:
    super.configure(kind,difficulty,wave,color,is_boss,region_index)
    visual_gate_enabled = true
    biome_index = 0
    if boss:
        base_scale = 1.15
    elif enemy_type == "brute" or enemy_type == "guardian":
        base_scale *= 1.08
    scale = Vector2.ONE * base_scale
    queue_redraw()

func _draw() -> void:
    _draw_grounding()

    if charge_windup > 0.0:
        var t: float = 0.5 + 0.5 * sin(animation_time * 22.0)
        draw_arc(Vector2(0,16), 33.0 + t * 4.0, 0.0, TAU, 32, Color(0.95,0.35,0.19,0.68), 2.2)
    elif windup > 0.0:
        draw_arc(Vector2(0,16), 27.0, 0.0, TAU, 28, Color(0.92,0.74,0.28,0.54), 1.8)

    if enemy_type == "normal":
        _draw_strip(clean_husk_strip, 6, Vector2(83,91), -27.0)
    elif enemy_type == "runner":
        _draw_strip(clean_hound_strip, 6, Vector2(92,68), -13.0)
    else:
        var key: String = "boss" if boss else enemy_type
        var texture: Texture2D = clean_art.get(key) as Texture2D
        var size := Vector2(92,98)
        var yoff: float = -27.0
        match key:
            "brute":
                size = Vector2(124,112)
                yoff = -31.0
            "stalker":
                size = Vector2(98,110)
                yoff = -33.0
            "guardian":
                size = Vector2(118,118)
                yoff = -35.0
            "boss":
                size = Vector2(174,156)
                yoff = -48.0
        _draw_static(texture,size,yoff)

    if hp < max_hp and not dying:
        var ratio: float = clampf(hp / maxf(1.0,max_hp),0.0,1.0)
        var bar_y: float = -70.0 if not boss else -106.0
        draw_rect(Rect2(-21,bar_y,42,4),Color(0.03,0.035,0.03,0.52))
        draw_rect(Rect2(-21,bar_y,42.0*ratio,4),Color("b94843"))

func _draw_grounding() -> void:
    var rx: float = 25.0
    var ry: float = 7.0
    if boss:
        rx = 48.0
        ry = 12.0
    elif enemy_type == "brute" or enemy_type == "guardian":
        rx = 33.0
        ry = 9.0
    draw_set_transform(Vector2(0,19),0.0,Vector2(1.0,ry/rx))
    draw_circle(Vector2.ZERO,rx,Color(0.015,0.02,0.015,0.29))
    draw_circle(Vector2.ZERO,rx*0.76,Color(0.12,0.09,0.05,0.15))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_strip(texture: Texture2D, frames: int, size: Vector2, y_offset: float) -> void:
    if texture == null:
        return
    var frame_w: float = texture.get_width() / float(frames)
    var frame_h: float = texture.get_height()
    var frame: int = int(floor(animation_time * (8.0 if enemy_type == "runner" else 6.0))) % frames
    var source := Rect2(frame_w * frame,0,frame_w,frame_h)
    var mirror: float = -1.0 if velocity.x < -0.5 else 1.0
    var tint := Color.WHITE
    if hit_flash > 0.0:
        tint = Color.WHITE.lerp(Color(1.0,0.36,0.28),hit_flash*0.72)
    draw_set_transform(Vector2(0,y_offset),0.0,Vector2(mirror,1.0))
    draw_texture_rect_region(texture,Rect2(-size*0.5,size),source,tint)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_static(texture: Texture2D, size: Vector2, y_offset: float) -> void:
    if texture == null:
        return
    var mirror: float = -1.0 if velocity.x < -0.5 else 1.0
    var tint := Color.WHITE
    if hit_flash > 0.0:
        tint = Color.WHITE.lerp(Color(1.0,0.34,0.25),hit_flash*0.68)
    draw_set_transform(Vector2(0,y_offset),0.0,Vector2(mirror,1.0))
    draw_texture_rect(texture,Rect2(-size*0.5,size),false,tint)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
