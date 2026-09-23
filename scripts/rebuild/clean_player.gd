class_name AXEHOLDCleanPlayer
extends AxPlayer

const CLEAN_IDLE_FRONT_PATH := "res://assets/art/visual_v2/hero_idle_front.webp"
const CLEAN_IDLE_SIDE_PATH := "res://assets/art/visual_v2/hero_idle_side.webp"
const CLEAN_IDLE_BACK_PATH := "res://assets/art/visual_v2/hero_wanderer.webp"

const CLEAN_TOOL_PATHS := {
    "axes":"res://assets/art/visual_v2/tool_axe.webp",
    "spear":"res://assets/art/visual_v2/tool_spear.webp",
    "hammer":"res://assets/art/visual_v2/tool_hammer.webp",
    "twin_blades":"res://assets/art/visual_v2/tool_sword.webp"
}

var clean_front: Texture2D
var clean_side: Texture2D
var clean_back: Texture2D
var clean_tools: Dictionary = {}
var clean_facing: Vector2 = Vector2(0.2, 1.0)

func _ready() -> void:
    clean_front = ResourceLoader.load(CLEAN_IDLE_FRONT_PATH) as Texture2D
    clean_side = ResourceLoader.load(CLEAN_IDLE_SIDE_PATH) as Texture2D
    clean_back = ResourceLoader.load(CLEAN_IDLE_BACK_PATH) as Texture2D
    for key: String in CLEAN_TOOL_PATHS.keys():
        clean_tools[key] = ResourceLoader.load(str(CLEAN_TOOL_PATHS[key])) as Texture2D
    visual_v2_enabled = true
    movement_acceleration = 1900.0
    movement_deceleration = 2450.0
    queue_redraw()

func setup(meta_upgrades: Dictionary, skin: Dictionary) -> void:
    super.setup(meta_upgrades, skin)
    # Rebuild rule: responsiveness comes from acceleration, not from slowing
    # the hero down. The baseline is intentionally brisk for one-thumb play.
    move_speed = maxf(148.0, base_meta_speed)
    movement_acceleration = 1900.0
    movement_deceleration = 2450.0
    orbit_radius = 54.0
    queue_redraw()

func enable_visual_v2() -> void:
    visual_v2_enabled = true
    queue_redraw()

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    var source: Vector2 = velocity
    if source.length_squared() < 4.0 and move_input.length_squared() > 0.02:
        source = move_input
    if source.length_squared() > 1.0:
        clean_facing = clean_facing.lerp(source.normalized(), clampf(delta * 16.0, 0.0, 1.0)).normalized()
    queue_redraw()

func _draw() -> void:
    var speed_ratio: float = clampf(velocity.length() / maxf(1.0, move_speed), 0.0, 1.0)
    var moving: bool = speed_ratio > 0.045
    var phase: float = walk_clock * TAU
    var bob: float = sin(phase * 0.52) * 1.4 * speed_ratio
    var lean: float = sin(phase * 0.26) * 0.012 * speed_ratio

    _draw_contact_shadow(speed_ratio)

    var dir: Vector2 = clean_facing
    if absf(dir.x) > absf(dir.y) * 0.78:
        _draw_clean_texture(clean_side, Vector2(0, bob), lean, signf(dir.x), 92.0)
    elif dir.y < -0.12:
        # A real up-facing image always exists in the clean rebuild.
        _draw_clean_texture(clean_back, Vector2(0, bob - 1.0), lean * 0.6, 1.0, 96.0)
    else:
        _draw_clean_texture(clean_front, Vector2(0, bob), -lean * 0.4, 1.0, 92.0)

    _draw_orbit_weapons(moving)

    if damage_flash > 0.0:
        draw_circle(Vector2(0, -8), 31.0 + damage_flash * 5.0, Color(1.0, 0.20, 0.16, damage_flash * 0.13))
    if block_flash > 0.0:
        draw_arc(Vector2(0, -8), 35.0, 0.0, TAU, 34, Color(0.40,0.78,1.0,block_flash * 0.72), 2.2)

func _draw_contact_shadow(speed_ratio: float) -> void:
    var width: float = 25.0 - speed_ratio * 1.5
    draw_set_transform(Vector2(0, 27), 0.0, Vector2(1.0, 0.28))
    draw_circle(Vector2.ZERO, width, Color(0.025,0.035,0.025,0.26))
    draw_circle(Vector2.ZERO, width * 0.72, Color(0.01,0.015,0.01,0.20))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_clean_texture(texture: Texture2D, offset: Vector2, rot: float, mirror: float, target_height: float) -> void:
    if texture == null:
        return
    var tex_size: Vector2 = texture.get_size()
    if tex_size.y <= 0.0:
        return
    var scale_factor: float = target_height / tex_size.y
    var draw_size := Vector2(tex_size.x * scale_factor, target_height)
    var foot_y: float = 31.0
    var rect := Rect2(Vector2(-draw_size.x * 0.5, foot_y - draw_size.y), draw_size)
    var tint := Color.WHITE
    if damage_flash > 0.0:
        tint = Color.WHITE.lerp(Color(1.0,0.44,0.40), damage_flash * 0.52)
    draw_set_transform(offset, rot, Vector2(mirror, 1.0))
    draw_texture_rect(texture, rect, false, tint)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_orbit_weapons(moving: bool) -> void:
    var texture: Texture2D = clean_tools.get(weapon_style) as Texture2D
    if texture == null:
        texture = clean_tools.get("axes") as Texture2D
    if texture == null:
        return

    var count: int = clampi(axes, 1, 5)
    var radius: float = orbit_radius
    for i: int in range(count):
        var a: float = angle + TAU * float(i) / float(count)
        var pos := Vector2(cos(a), sin(a)) * radius
        var front_alpha: float = 0.95 if sin(a) >= -0.15 else 0.78
        var tex_size: Vector2 = texture.get_size()
        var target_h: float = 48.0 if weapon_style != "hammer" else 51.0
        if weapon_style == "twin_blades":
            target_h = 42.0
        var sf: float = target_h / maxf(1.0, tex_size.y)
        var size := Vector2(tex_size.x * sf, target_h)
        var pulse: float = 1.0 + (0.015 * sin(motion_time * 7.0 + float(i))) if moving else 1.0
        draw_set_transform(pos, a + PI * 0.5, Vector2.ONE * pulse)
        draw_texture_rect(texture, Rect2(-size * 0.5, size), false, Color(1,1,1,front_alpha))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
