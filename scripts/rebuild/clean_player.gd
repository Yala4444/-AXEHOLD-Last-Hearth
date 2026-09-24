class_name AXEHOLDCleanPlayer
extends AxPlayer

# The clean rebuild now delegates presentation to AxPlayer's production
# Visual V2 animator instead of maintaining a second, static three-pose hero.
# That animator already normalizes every frame to one foot baseline, uses
# dedicated idle art, plays walk cycles, mirrors left/right safely, and keeps
# orbit weapons as separate gameplay objects.

var production_ready: bool = false

func _ready() -> void:
    enable_visual_v2()
    visual_identity_version = 5
    movement_acceleration = 1900.0
    movement_deceleration = 2450.0
    production_ready = _production_frames_ready()
    queue_redraw()

func setup(meta_upgrades: Dictionary, skin: Dictionary) -> void:
    super.setup(meta_upgrades, skin)
    if not visual_v2_enabled:
        enable_visual_v2()

    # Responsiveness comes from acceleration, not from slowing the hero down.
    move_speed = maxf(148.0, base_meta_speed)
    movement_acceleration = 1900.0
    movement_deceleration = 2450.0
    orbit_radius = 49.0
    axes = clampi(axes, 1, 5)
    production_ready = _production_frames_ready()
    queue_redraw()

func enable_visual_v2() -> void:
    super.enable_visual_v2()
    # C7 / production lock: the hero and weapons are separate layers.
    # AxPlayer's Visual V2 renderer already draws the body first and splits the
    # orbit into back/front passes, so weapons never become baked hero art.
    visual_v2_enabled = true
    production_ready = _production_frames_ready()
    queue_redraw()

func _production_frames_ready() -> bool:
    if visual_v2_idle_frames.get("front") == null:
        return false
    if visual_v2_idle_frames.get("side") == null:
        return false
    if visual_v2_frames.get("back_a") == null or visual_v2_frames.get("back_b") == null:
        return false
    if visual_v2_side_walk.size() < 6:
        return false
    if visual_v2_front_walk.size() < 4:
        return false
    if visual_v2_back_walk.size() < 4:
        return false
    return true

func apply_perk(id: String) -> void:
    super.apply_perk(id)
    # C7 visual/gameplay lock: never let the orbit become a weapon fan.
    axes = clampi(axes, 1, 5)
    queue_redraw()

func _visual_v2_orbit_count() -> int:
    return mini(5, super._visual_v2_orbit_count())


func _draw_visual_v2_orbit(front_pass: bool, ring_radius: float) -> void:
    var count: int = _visual_v2_orbit_count()
    var texture: Texture2D = _visual_v2_weapon_texture()
    if texture == null:
        return
    var action_ratio: float = weapon_action_ratio()
    for i: int in range(count):
        var weapon_angle: float = angle + float(i) * TAU / float(count)
        var weapon_distance: float = ring_radius
        if weapon_style == "spear" and weapon_action_time > 0.0:
            weapon_angle = weapon_action_direction.angle()
            weapon_distance += action_ratio * 18.0
        elif weapon_style == "hammer" and weapon_action_time > 0.0:
            weapon_angle = weapon_action_direction.angle()
            weapon_distance += action_ratio * 8.0

        var weapon_pos := Vector2(cos(weapon_angle), sin(weapon_angle)) * weapon_distance
        if (weapon_pos.y >= 0.0) != front_pass:
            continue

        # Production FX stay quiet during normal rotation. A slightly stronger
        # accent is only allowed while a weapon performs its own action.
        var trail_alpha: float = 0.055 + action_ratio * 0.10
        var trail_color := Color(0.96, 0.72, 0.30, trail_alpha)
        if weapon_style == "hammer":
            trail_color = Color(0.25, 0.88, 0.91, trail_alpha)
        elif weapon_style == "spear":
            trail_color = Color(0.52, 0.78, 0.34, trail_alpha)
        elif weapon_style == "twin_blades":
            trail_color = Color(0.96, 0.46, 0.28, trail_alpha)

        draw_arc(Vector2.ZERO, weapon_distance, weapon_angle - 0.26, weapon_angle - 0.06, 7, trail_color, 2.0)

        var weapon_size := Vector2(47, 47)
        if weapon_style == "spear":
            weapon_size = Vector2(29, 68)
        elif weapon_style == "hammer":
            weapon_size = Vector2(53, 53)
        elif weapon_style == "twin_blades":
            weapon_size = Vector2(44, 44)

        draw_set_transform(weapon_pos, weapon_angle + PI * 0.30, Vector2.ONE)
        draw_texture_rect(texture, Rect2(-weapon_size * 0.5, weapon_size), false, Color.WHITE)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
