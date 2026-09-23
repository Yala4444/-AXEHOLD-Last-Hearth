class_name ResourceSpot
extends Node2D

const FOREST_ART_PATHS: Dictionary = {
    "tree":"res://assets/art/forgotten_forest/harvest_tree.png",
    "rock":"res://assets/art/forgotten_forest/stone_deposit.png",
    "ore":"res://assets/art/forgotten_forest/ore_deposit.png"
}
const PRODUCTION_TREE_STRIP_PATH: String = "res://assets/art/vertical_slice_i/tree_damage.webp"
const PRODUCTION_TREE_FRAMES: int = 4

var resource_type: String = "tree"
var hp: float = 52.0
var max_hp: float = 52.0
var variant: int = 0
var radius: float = 15.0
var hit_pulse: float = 0.0
var hit_gate: float = 0.0
var wobble_phase: float = 0.0
var biome_index: int = 0
var visual_identity_version: int = 3
var visual_gate_enabled: bool = false
var forest_art_cache: Dictionary = {}

func configure(kind: String, v: int = 0, biome: int = 0) -> void:
    resource_type = kind
    variant = v
    biome_index = biome
    match kind:
        "tree":
            max_hp = 52.0
            radius = 20.0
        "rock":
            max_hp = 72.0
            radius = 18.0
        "ore":
            max_hp = 98.0
            radius = 17.0
    hp = max_hp
    queue_redraw()

func set_visual_gate(value: bool) -> void:
    visual_gate_enabled = value
    queue_redraw()

func visual_identity_profile() -> Dictionary:
    return {
        "version":visual_identity_version,
        "resource":resource_type,
        "biome":biome_index,
        "production_art":biome_index == 0
    }

func damage_stage() -> int:
    var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
    if ratio <= 0.32:
        return 2
    if ratio <= 0.66:
        return 1
    return 0

func _process(delta: float) -> void:
    hit_gate = maxf(0.0, hit_gate - delta)
    if hit_pulse > 0.0:
        hit_pulse = maxf(0.0, hit_pulse - delta * 5.5)
        wobble_phase += delta * 34.0
        var squash: float = sin(wobble_phase) * hit_pulse * 0.055
        scale = Vector2(1.0 + squash, 1.0 - squash)
        queue_redraw()
    else:
        scale = scale.lerp(Vector2.ONE, minf(1.0, delta * 14.0))

func damage(amount: float) -> bool:
    hp -= amount
    if hit_gate <= 0.0:
        hit_gate = 0.11
        hit_pulse = 1.0
        wobble_phase = 0.0
    if hp <= 0.0:
        Feedback.play("ore" if resource_type == "ore" else "harvest", 8)
    queue_redraw()
    return hp <= 0.0

func _draw() -> void:
    var flash: float = hit_pulse * 0.28
    if biome_index == 0:
        _draw_illustrated_resource(flash)
    elif resource_type == "tree":
        _draw_tree(flash)
    elif resource_type == "rock":
        _draw_rock(flash)
    else:
        _draw_ore(flash)

    if hp < max_hp:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        var bar_y: float = -24.0
        if biome_index == 0:
            bar_y = -145.0 if resource_type == "tree" else (-57.0 if resource_type == "ore" else -43.0)
        draw_rect(Rect2(-14, bar_y, 28, 4), Color(0.08, 0.08, 0.08, 0.32))
        draw_rect(Rect2(-14, bar_y, 28 * ratio, 4), Color("72a66d"))

func _draw_illustrated_resource(flash: float) -> void:
    if biome_index != 0:
        return
    var cache_key: String = "tree_production" if resource_type == "tree" and visual_gate_enabled else resource_type
    var texture: Texture2D = forest_art_cache.get(cache_key) as Texture2D
    if texture == null:
        var path: String = PRODUCTION_TREE_STRIP_PATH if cache_key == "tree_production" else str(FOREST_ART_PATHS.get(resource_type, FOREST_ART_PATHS["tree"]))
        texture = ResourceLoader.load(path) as Texture2D
        forest_art_cache[cache_key] = texture

    # MASTER P2: resources were far too close to hero scale, especially trees.
    # Bring them toward the agreed reference ratios while keeping mobile
    # readability and harvest reach comfortable.
    var size := Vector2(132, 158)
    var y_offset: float = -61.0
    var shadow_radius := Vector2(37.0, 9.2)
    match resource_type:
        "rock":
            size = Vector2(70, 66)
            y_offset = -13.0
            shadow_radius = Vector2(24.0, 6.0)
        "ore":
            size = Vector2(76, 84)
            y_offset = -21.0
            shadow_radius = Vector2(25.0, 6.4)
    if texture == null:
        return

    # MASTER P2: resource roots/bases must merge into terrain, not merely cast a
    # shadow. Draw a soil contact patch, then a darker contact shadow, then grass
    # and debris around the silhouette before the painted resource itself.
    var shadow_alpha: float = 0.34 if visual_gate_enabled else 0.21
    var shadow_y: float = 20.0 if resource_type == "tree" else 16.0
    if visual_gate_enabled:
        _draw_grounding_skirt(shadow_y, shadow_radius)
    _draw_shadow_ellipse(Vector2(0, shadow_y), shadow_radius, Color(0.018, 0.024, 0.018, shadow_alpha))
    if visual_gate_enabled:
        draw_arc(Vector2(0, shadow_y - 1.0), shadow_radius.x * 0.72, 0.18, PI - 0.18, 16, Color(0.70, 0.77, 0.55, 0.07), 1.0)

    var mirror: float = -1.0 if variant % 2 == 1 else 1.0
    var stage: int = damage_stage()
    var damage_dull: float = 0.07 * float(stage)
    var tint_color := Color.WHITE.darkened(damage_dull).lerp(Color(1.0, 0.72, 0.58), flash * 0.62)
    draw_set_transform(Vector2(0, y_offset), 0.0, Vector2(mirror, 1.0))
    if resource_type == "tree" and visual_gate_enabled:
        # MASTER P2: use the already-approved painted pine damage strip instead
        # of the old gnarled harvest tree. Damage now changes the actual tree art,
        # not only a crack overlay.
        var frame_width: float = float(texture.get_width()) / float(PRODUCTION_TREE_FRAMES)
        var frame_height: float = float(texture.get_height())
        var ratio: float = clampf(hp / maxf(1.0,max_hp),0.0,1.0)
        var frame_index: int = 0
        if ratio <= 0.12:
            frame_index = 3
        elif ratio <= 0.32:
            frame_index = 2
        elif ratio <= 0.66:
            frame_index = 1
        var source := Rect2(frame_width * float(frame_index), 0.0, frame_width, frame_height)
        draw_texture_rect_region(texture, Rect2(-size * 0.5, size), source, tint_color)
    else:
        draw_texture_rect(texture, Rect2(-size * 0.5, size), false, tint_color)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    if visual_gate_enabled and stage > 0 and resource_type != "tree":
        _draw_damage_state(stage, mirror)

func _draw_grounding_skirt(shadow_y: float, shadow_radius: Vector2) -> void:
    var soil_radius := Vector2(shadow_radius.x * 1.10, shadow_radius.y * 1.55)
    _draw_shadow_ellipse(Vector2(0, shadow_y + 0.8), soil_radius, Color(0.34,0.24,0.13,0.13))
    _draw_shadow_ellipse(Vector2(0, shadow_y + 0.2), Vector2(soil_radius.x * 0.72, soil_radius.y * 0.72), Color(0.18,0.27,0.13,0.10))

    var grass := Color(0.24,0.42,0.20,0.50)
    var dry := Color(0.48,0.35,0.18,0.38)
    var extent: float = shadow_radius.x * 0.82
    for i: int in range(6):
        var t: float = float(i) / 5.0
        var x: float = lerpf(-extent, extent, t)
        var y: float = shadow_y + 1.0 + float((i * 7) % 4)
        var lean: float = -1.5 if i % 2 == 0 else 1.5
        draw_line(Vector2(x,y+5), Vector2(x+lean,y-1), grass, 1.2)
        if i % 2 == 0:
            draw_line(Vector2(x+3,y+3), Vector2(x+7,y+1), dry, 1.0)
    if resource_type != "tree":
        draw_circle(Vector2(-extent * 0.72, shadow_y + 2.0), 1.8, Color(0.45,0.43,0.35,0.48))
        draw_circle(Vector2(extent * 0.64, shadow_y + 1.0), 1.4, Color(0.51,0.48,0.38,0.42))
    else:
        # Root shoulders visually sink the large tree into the soil.
        draw_line(Vector2(-10, shadow_y-1), Vector2(-24, shadow_y+6), Color(0.24,0.16,0.09,0.58), 3.0)
        draw_line(Vector2(9, shadow_y-1), Vector2(23, shadow_y+5), Color(0.24,0.16,0.09,0.55), 3.0)

func _draw_damage_state(stage: int, mirror: float) -> void:
    var severe: bool = stage >= 2
    match resource_type:
        "tree":
            # The trunk is the gameplay-readable damage surface; the crown stays
            # recognizable so a wounded tree never looks like a different prop.
            var crack := Color(0.22, 0.12, 0.07, 0.78)
            var x: float = 4.0 * mirror
            draw_line(Vector2(x, -8), Vector2(-2.0 * mirror, 2), crack, 2.0)
            draw_line(Vector2(-2.0 * mirror, 2), Vector2(5.0 * mirror, 12), crack, 1.7)
            if severe:
                draw_line(Vector2(-2.0 * mirror, 2), Vector2(-7.0 * mirror, 8), crack, 1.5)
                draw_line(Vector2(5.0 * mirror, 12), Vector2(1.0 * mirror, 20), crack, 1.5)
                draw_circle(Vector2(-19.0 * mirror, -34), 2.3, Color(0.47, 0.31, 0.16, 0.72))
                draw_circle(Vector2(17.0 * mirror, -24), 1.8, Color(0.51, 0.34, 0.18, 0.64))
        "rock":
            var crack := Color(0.18, 0.20, 0.20, 0.82)
            draw_line(Vector2(-8, -14), Vector2(-2, -5), crack, 1.7)
            draw_line(Vector2(-2, -5), Vector2(6, 0), crack, 1.5)
            draw_line(Vector2(6, 0), Vector2(11, 8), crack, 1.4)
            if severe:
                draw_line(Vector2(-2, -5), Vector2(-10, 5), crack, 1.5)
                draw_line(Vector2(6, 0), Vector2(1, 13), crack, 1.4)
                draw_rect(Rect2(18, 7, 4, 3), Color(0.54, 0.58, 0.57, 0.74))
                draw_rect(Rect2(-22, 10, 3, 3), Color(0.47, 0.51, 0.50, 0.68))
        "ore":
            var crack := Color(0.31, 0.20, 0.39, 0.86)
            var glow := Color(0.79, 0.56, 0.92, 0.30 if stage == 1 else 0.44)
            draw_line(Vector2(-7, -21), Vector2(-2, -10), crack, 1.6)
            draw_line(Vector2(-2, -10), Vector2(4, -3), crack, 1.5)
            draw_circle(Vector2(3, -8), 13.0 if severe else 9.0, glow)
            if severe:
                draw_line(Vector2(4, -3), Vector2(9, 8), crack, 1.4)
                draw_rect(Rect2(19, -1, 4, 5), Color(0.70, 0.47, 0.83, 0.80))
                draw_rect(Rect2(-20, 8, 3, 4), Color(0.61, 0.40, 0.75, 0.72))

func _draw_tree(flash: float) -> void:
    _draw_shadow_ellipse(Vector2(0, 17), Vector2(16, 4.5), Color(0.03, 0.04, 0.03, 0.20))
    var trunk: Color = Color("6c4a32").lightened(flash * 0.30)
    var bark_dark: Color = trunk.darkened(0.22)
    var s: float = 1.0 + float(variant % 3) * 0.05

    # Tapered trunk reads much less like a placeholder rectangle.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-5, 18), Vector2(-4, -2), Vector2(-1, -9),
        Vector2(4, -7), Vector2(5, 18)
    ]), bark_dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-3, 17), Vector2(-2, -3), Vector2(0, -8),
        Vector2(3, -6), Vector2(3, 17)
    ]), trunk)
    draw_line(Vector2(-1, 2), Vector2(2, 11), trunk.lightened(0.16), 1.2)

    if biome_index == 2:
        # Ash trees are silhouettes with ember wounds and broken limbs.
        var charred := Color("332723").lightened(flash * 0.18)
        draw_line(Vector2(-1,-3), Vector2(-14,-16), charred, 4.2)
        draw_line(Vector2(1,-7), Vector2(14,-18), charred, 4.2)
        if variant % 2 == 0:
            draw_line(Vector2(-8,-11), Vector2(-16,-7), charred, 2.8)
        else:
            draw_line(Vector2(8,-13), Vector2(16,-8), charred, 2.8)
        draw_circle(Vector2(1,-1), 3.2, Color(0.82,0.26,0.11,0.32 + flash))
        draw_line(Vector2(0,-2), Vector2(1,6), Color(0.94,0.36,0.15,0.24 + flash), 1.5)
        return

    var crown: Color
    if biome_index == 1:
        var cold: Array[Color] = [Color("527b72"),Color("648a80"),Color("476c68")]
        crown = cold[variant % cold.size()].lightened(flash)
    else:
        var greens: Array[Color] = [Color("447b4d"),Color("548d52"),Color("3d6f45")]
        crown = greens[variant % greens.size()].lightened(flash)

    var crown_dark := crown.darkened(0.18)
    var crown_light := crown.lightened(0.10)
    var y_shift: float = -2.0 if variant % 2 == 0 else 1.0

    # Layered canopy clusters: same resource readability, much richer silhouette.
    draw_circle(Vector2(-9*s,-9+y_shift), 11.0*s, crown_dark)
    draw_circle(Vector2(8*s,-11+y_shift), 12.0*s, crown_dark)
    draw_circle(Vector2(0,-18+y_shift), 13.0*s, crown)
    draw_circle(Vector2(-14*s,-2+y_shift), 8.5*s, crown)
    draw_circle(Vector2(14*s,-3+y_shift), 8.5*s, crown)
    draw_circle(Vector2(-3,-8+y_shift), 13.5*s, crown)
    draw_circle(Vector2(8,-5+y_shift), 10.0*s, crown_light)

    if biome_index == 1:
        draw_arc(Vector2(0,-18+y_shift), 13.0*s, 3.35, 5.95, 14, Color(0.89,0.96,0.96,0.58), 2.0)
        draw_line(Vector2(-16,-4),Vector2(-5,-4),Color(0.90,0.97,0.98,0.40),1.5)
    else:
        draw_circle(Vector2(-7,-17+y_shift), 2.1, Color(0.80,0.91,0.61,0.20))
        draw_circle(Vector2(11,-7+y_shift), 1.8, Color(0.74,0.88,0.55,0.18))

func _draw_rock(flash: float) -> void:
    _draw_shadow_ellipse(Vector2(0, 10), Vector2(15, 4.0), Color(0.03,0.04,0.04,0.18))
    var rock_color: Color = Color("7e8788")
    if biome_index == 1:
        rock_color = Color("78979d")
    elif biome_index == 2:
        rock_color = Color("554d4c")
    rock_color = rock_color.lightened(flash)

    var pts := PackedVector2Array([
        Vector2(-14,7),Vector2(-11,-5),Vector2(-4,-13),
        Vector2(7,-11),Vector2(14,-3),Vector2(12,7),
        Vector2(5,12),Vector2(-7,11)
    ])
    draw_colored_polygon(pts, rock_color.darkened(0.08))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-10,-4),Vector2(-4,-11),Vector2(4,-9),Vector2(7,-1),Vector2(0,4),Vector2(-8,3)
    ]), rock_color.lightened(0.12))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,4),Vector2(7,-1),Vector2(12,7),Vector2(5,11),Vector2(-2,8)
    ]), rock_color.darkened(0.18))
    draw_line(Vector2(-4,-10),Vector2(0,4),rock_color.lightened(0.22),1.2)
    draw_line(Vector2(0,4),Vector2(-7,9),rock_color.darkened(0.28),1.0)

    if biome_index == 1:
        draw_line(Vector2(-7,-3),Vector2(6,7),Color(0.82,0.95,0.98,0.48),1.2)
        draw_line(Vector2(1,-8),Vector2(5,-3),Color(0.86,0.97,1.0,0.36),1.0)
    elif biome_index == 2:
        draw_line(Vector2(5,-5),Vector2(2,5),Color(0.82,0.28,0.13,0.30),1.4)
        draw_circle(Vector2(4,1),1.8,Color(0.95,0.42,0.18,0.28))

func _draw_ore(flash: float) -> void:
    _draw_shadow_ellipse(Vector2(0, 11), Vector2(15, 4.2), Color(0.03,0.03,0.04,0.20))
    var base: Color = Color("554560")
    var crystal: Color = Color("a779bf")
    var bright: Color = Color("d7b6e8")
    if biome_index == 1:
        base = Color("506f7a")
        crystal = Color("85bdcb")
        bright = Color("d2f1f5")
    elif biome_index == 2:
        base = Color("5d3935")
        crystal = Color("c95f3c")
        bright = Color("ffb36b")
    base = base.lightened(flash)

    draw_colored_polygon(PackedVector2Array([
        Vector2(-14,9),Vector2(-11,-4),Vector2(-3,-10),Vector2(8,-8),
        Vector2(14,2),Vector2(8,11),Vector2(-6,12)
    ]),base)

    var offsets: Array[Vector2] = [Vector2(-6,1),Vector2(2,-3),Vector2(8,3)]
    var heights: Array[float] = [14.0,20.0,11.0]
    for i: int in range(3):
        var p: Vector2 = offsets[i]
        var h: float = heights[i] + float((variant+i)%2)*3.0
        var shard := PackedVector2Array([
            p + Vector2(0,-h),
            p + Vector2(5,-4),
            p + Vector2(3,7),
            p + Vector2(-4,7),
            p + Vector2(-5,-4)
        ])
        draw_colored_polygon(shard, crystal.lightened(float(i)*0.035 + flash))
        draw_line(p+Vector2(0,-h+3),p+Vector2(-1,5),bright,1.2)

    if hit_pulse > 0.1:
        for i: int in range(3):
            var a: float = -1.6 + float(i)*0.7
            draw_circle(Vector2(cos(a),sin(a))*18.0,1.6,Color(bright,hit_pulse*0.76))

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i: int in range(24):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
