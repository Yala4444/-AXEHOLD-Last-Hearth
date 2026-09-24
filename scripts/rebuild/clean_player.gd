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
