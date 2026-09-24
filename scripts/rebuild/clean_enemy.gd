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
        var t: float = 0.5 + 0.5 * sin(animation_time * 18.0)
        draw_arc(Vector2(0,18), 29.0 + t * 3.0, 0.0, TAU, 28, Color(0.95,0.35,0.19,0.56), 1.8)
    elif windup > 0.0:
        draw_arc(Vector2(0,18), 24.0, 0.0, TAU, 24, Color(0.92,0.74,0.28,0.46), 1.5)

    if enemy_type == "normal":
        _draw_strip(clean_husk_strip, 6, Vector2(86,104), 23.0)
    elif enemy_type == "runner":
        _draw_strip(clean_hound_strip, 6, Vector2(112,79), 22.0)
    else:
        var key: String = "boss" if boss else enemy_type
        var texture: Texture2D = clean_art.get(key) as Texture2D
        var size := Vector2(92,108)
        match key:
            "brute":
                size = Vector2(122,128)
            "stalker":
                size = Vector2(88,126)
            "guardian":
                size = Vector2(126,132)
            "boss":
                size = Vector2(178,184)
        _draw_static(texture,size,24.0)

    # Ordinary enemies do not carry permanent UI bars. A short bar appears
    # only as hit feedback; the boss uses the dedicated HUD boss bar.
    if hp < max_hp and not dying and not boss and hit_flash > 0.025:
        var ratio: float = clampf(hp / maxf(1.0,max_hp),0.0,1.0)
        var bar_y: float = -72.0 if enemy_type in ["normal","runner"] else -92.0
        draw_rect(Rect2(-19,bar_y,38,3),Color(0.03,0.035,0.03,0.46))
        draw_rect(Rect2(-19,bar_y,38.0*ratio,3),Color("b94843"))

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

func _draw_strip(texture: Texture2D, frames: int, size: Vector2, foot_y: float) -> void:
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
    var y_offset: float = foot_y - size.y * 0.5
    draw_set_transform(Vector2(0,y_offset),0.0,Vector2(mirror,1.0))
    draw_texture_rect_region(texture,Rect2(-size*0.5,size),source,tint)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_static(texture: Texture2D, size: Vector2, foot_y: float) -> void:
    if texture == null:
        return
    var mirror: float = -1.0 if velocity.x < -0.5 else 1.0
    var tint := Color.WHITE
    if hit_flash > 0.0:
        tint = Color.WHITE.lerp(Color(1.0,0.34,0.25),hit_flash*0.68)
    var breathe: float = 1.0 + sin(animation_time * 2.1) * 0.008
    var animated_size := Vector2(size.x * breathe, size.y * breathe)
    var y_offset: float = foot_y - animated_size.y * 0.5
    draw_set_transform(Vector2(0,y_offset),0.0,Vector2(mirror,1.0))
    draw_texture_rect(texture,Rect2(-animated_size*0.5,animated_size),false,tint)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
