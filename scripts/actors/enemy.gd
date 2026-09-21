class_name AxEnemy
extends CharacterBody2D

signal killed(enemy: AxEnemy)

const FOREST_ART_PATHS: Dictionary = {
    "normal":"res://assets/art/forgotten_forest/root_husk.png",
    "runner":"res://assets/art/forgotten_forest/briar_hound.png",
    "brute":"res://assets/art/forgotten_forest/ironroot_ravager.png",
    "stalker":"res://assets/art/forgotten_forest/hollow_seer.png",
    "guardian":"res://assets/art/forgotten_forest/oathstone_bulwark.png",
    "boss":"res://assets/art/forgotten_forest/forest_guardian.png"
}

var enemy_type: String = "normal"
var biome_index: int = 0
var hp: float = 40.0
var max_hp: float = 40.0
var move_speed: float = 30.0
var movement_multiplier: float = 1.0
var behavior_speed_multiplier: float = 1.0
var contact_damage: float = 8.0
var armor: float = 0.0
var boss: bool = false
var elite: bool = false
var elite_trait: String = ""
var elite_title: String = ""
var elite_glow: Color = Color("d9b36a")
var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false
var hit_cooldown: float = 0.0
var special_cooldown: float = 2.8
var windup: float = 0.0
var mark_position: Vector2 = Vector2.ZERO
var mark_active: bool = false
var tint: Color = Color("6c5574")
var hit_flash: float = 0.0
var animation_time: float = 0.0
var dying: bool = false
var death_time: float = 0.0
var base_scale: float = 1.0
var charge_cooldown: float = 5.5
var charge_windup: float = 0.0
var charge_time: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO
var surge_cooldown: float = 2.8
var surge_windup: float = 0.0
var surge_time: float = 0.0
var surge_direction: Vector2 = Vector2.ZERO
var visual_identity_version: int = 3
var forest_art_cache: Dictionary = {}

func configure(kind: String, difficulty: float, wave: int, color: Color, is_boss: bool = false, region_index: int = 0) -> void:
    enemy_type = kind
    biome_index = clampi(region_index, 0, 2)
    boss = is_boss
    elite = false
    elite_trait = ""
    elite_title = ""
    tint = color
    armor = 0.0
    movement_multiplier = 1.0
    behavior_speed_multiplier = 1.0
    base_scale = 1.0
    surge_cooldown = randf_range(2.5, 3.3)
    surge_windup = 0.0
    surge_time = 0.0

    if boss:
        max_hp = 340.0 * difficulty
        move_speed = 23.0
        contact_damage = 22.0 * difficulty
        armor = 0.05
        charge_cooldown = randf_range(4.8, 6.0)
    elif kind == "guardian":
        max_hp = (82.0 + wave * 13.0) * difficulty
        move_speed = 17.0
        contact_damage = 14.0 * difficulty
        armor = 0.25
        base_scale = 1.10
    elif kind == "stalker":
        max_hp = (34.0 + wave * 8.0) * difficulty
        move_speed = 34.0
        contact_damage = 8.5 * difficulty
        base_scale = 0.92
    elif kind == "brute":
        max_hp = (62.0 + wave * 10.0) * difficulty
        move_speed = 20.0
        contact_damage = 12.0 * difficulty
        base_scale = 1.05
    elif kind == "runner":
        max_hp = (30.0 + wave * 9.0) * difficulty
        move_speed = 40.0
        contact_damage = 6.0 * difficulty
        base_scale = 0.93
    else:
        max_hp = (40.0 + wave * 10.0) * difficulty
        move_speed = 29.0 + wave * 2.0
        contact_damage = (7.0 + wave * 0.8) * difficulty

    hp = max_hp
    dying = false
    death_time = 0.0
    rotation = 0.0
    modulate = Color.WHITE
    scale = Vector2.ONE * base_scale
    queue_redraw()

func visual_role_signature() -> Dictionary:
    var silhouette: String = "husk"
    var footprint: Vector2 = Vector2(22, 34)
    match enemy_type:
        "runner":
            silhouette = "low_long_limb"
            footprint = Vector2(28, 36)
        "brute":
            silhouette = "broad_horned_wedge"
            footprint = Vector2(42, 46)
        "stalker":
            silhouette = "tall_masked_crescent"
            footprint = Vector2(30, 48)
        "guardian":
            silhouette = "stone_bulwark"
            footprint = Vector2(40, 48)
        "boss":
            silhouette = "regional_colossus"
            footprint = Vector2(76, 92)
    if boss:
        silhouette = "regional_colossus"
        footprint = Vector2(76, 92)
    return {
        "version":visual_identity_version,
        "role":enemy_type,
        "silhouette":silhouette,
        "footprint":footprint,
        "biome_language":biome_index,
        "production_art":biome_index == 0
    }

func configure_elite(trait_id: String) -> void:
    if boss:
        return
    elite = true
    elite_trait = trait_id
    match trait_id:
        "ravenous":
            elite_title = "ГОЛОДНЫЙ"
            elite_glow = Color("db8a64")
            max_hp *= 1.35
            hp = max_hp
            move_speed *= 1.30
            contact_damage *= 1.25
            base_scale *= 1.08
        "armored":
            elite_title = "ЗАКОВАННЫЙ"
            elite_glow = Color("d8c27b")
            max_hp *= 1.80
            hp = max_hp
            move_speed *= 0.90
            contact_damage *= 1.12
            armor = minf(0.52, armor + 0.28)
            base_scale *= 1.13
        "volatile":
            elite_title = "ИСКАЖЁННЫЙ"
            elite_glow = Color("c987d6")
            max_hp *= 1.42
            hp = max_hp
            move_speed *= 1.12
            contact_damage *= 1.48
            base_scale *= 1.10
        "warlord":
            elite_title = "ВЕСТНИК ТЬМЫ"
            elite_glow = Color("e07058")
            max_hp *= 2.25
            hp = max_hp
            move_speed *= 1.05
            contact_damage *= 1.55
            armor = minf(0.55, armor + 0.12)
            base_scale *= 1.22
            charge_cooldown = randf_range(3.8, 4.8)
        "root_alpha":
            elite_title = "ВОЖАК КОРНЕЙ"
            elite_glow = Color("93bd67")
            max_hp *= 1.78
            hp = max_hp
            move_speed *= 1.10
            contact_damage *= 1.30
            armor = minf(0.50, armor + 0.08)
            base_scale *= 1.16
        "frost_reaver":
            elite_title = "БЕЛЫЙ ОХОТНИК"
            elite_glow = Color("9fdbea")
            max_hp *= 1.58
            hp = max_hp
            move_speed *= 1.28
            contact_damage *= 1.24
            base_scale *= 1.12
            surge_cooldown = 1.65
        "ash_seeder":
            elite_title = "ПЕПЕЛЬНЫЙ СЕЯТЕЛЬ"
            elite_glow = Color("ed774c")
            max_hp *= 1.88
            hp = max_hp
            move_speed *= 0.96
            contact_damage *= 1.52
            armor = minf(0.52, armor + 0.14)
            base_scale *= 1.20
        _:
            elite_title = "ЭЛИТА"
            max_hp *= 1.55
            hp = max_hp
            contact_damage *= 1.25
            base_scale *= 1.10
    scale = Vector2.ONE * base_scale
    queue_redraw()

func _physics_process(delta: float) -> void:
    animation_time += delta
    hit_cooldown = maxf(0.0, hit_cooldown - delta)
    hit_flash = maxf(0.0, hit_flash - delta * 5.8)

    if dying:
        _update_death(delta)
        return

    if (boss or (elite and elite_trait == "warlord")) and _update_charge(delta):
        queue_redraw()
        return

    if (enemy_type == "stalker" or (elite and elite_trait == "frost_reaver")) and _update_stalker_surge(delta):
        queue_redraw()
        return

    var moving: bool = has_target and windup <= 0.0
    if moving:
        velocity = global_position.direction_to(target_position) * move_speed * movement_multiplier * behavior_speed_multiplier
        move_and_slide()
    else:
        velocity = Vector2.ZERO

    var bob_strength: float = 0.025 if boss else 0.04
    var bob_speed: float = 5.2
    if enemy_type == "runner":
        bob_speed = 8.0
    elif enemy_type == "stalker":
        bob_speed = 9.2
    elif enemy_type == "guardian":
        bob_speed = 3.8
    var bob: float = sin(animation_time * bob_speed) * bob_strength if moving else 0.0
    scale = Vector2(base_scale * (1.0 - bob), base_scale * (1.0 + bob))
    queue_redraw()

func _update_stalker_surge(delta: float) -> bool:
    if surge_windup > 0.0:
        surge_windup -= delta
        velocity = Vector2.ZERO
        scale = Vector2.ONE * base_scale * (1.0 + sin(animation_time * 28.0) * 0.05)
        if surge_windup <= 0.0:
            surge_time = 0.34
            Feedback.play("stalker", 8)
        return true

    if surge_time > 0.0:
        surge_time -= delta
        velocity = surge_direction * 102.0 * movement_multiplier
        move_and_slide()
        scale = Vector2(base_scale * 0.84, base_scale * 1.14)
        if surge_time <= 0.0:
            surge_cooldown = randf_range(2.6, 3.5)
            velocity = Vector2.ZERO
        return true

    surge_cooldown -= delta
    if surge_cooldown <= 0.0 and has_target and windup <= 0.0:
        surge_direction = global_position.direction_to(target_position)
        if surge_direction.length_squared() > 0.01 and global_position.distance_to(target_position) > 48.0:
            surge_windup = 0.22
            return true
        surge_cooldown = 0.8
    return false

func _update_death(delta: float) -> void:
    death_time -= delta
    velocity = Vector2.ZERO
    var progress: float = clampf(1.0 - death_time / 0.18, 0.0, 1.0)
    scale = Vector2.ONE * base_scale * (1.0 + progress * 0.25) * (1.0 - progress * 0.92)
    var death_tilt: float = 0.20 if enemy_type == "guardian" or enemy_type == "brute" else 0.45
    rotation = sin(progress * PI) * death_tilt
    modulate.a = 1.0 - progress
    queue_redraw()
    if death_time <= 0.0:
        killed.emit(self)

func _update_charge(delta: float) -> bool:
    if charge_windup > 0.0:
        charge_windup -= delta
        velocity = Vector2.ZERO
        scale = Vector2.ONE * base_scale * (1.0 + sin(animation_time * 22.0) * 0.045)
        if charge_windup <= 0.0:
            charge_time = 0.42
            Feedback.play("boss", 22)
        return true

    if charge_time > 0.0:
        charge_time -= delta
        velocity = charge_direction * 190.0 * movement_multiplier
        move_and_slide()
        scale = Vector2(base_scale * 0.90, base_scale * 1.12)
        if charge_time <= 0.0:
            charge_cooldown = randf_range(5.0, 6.4)
            velocity = Vector2.ZERO
        return true

    charge_cooldown -= delta
    if charge_cooldown <= 0.0 and windup <= 0.0:
        var parent_node: Node = get_parent()
        if parent_node != null:
            var candidate: Variant = parent_node.get("player")
            if candidate is AxPlayer:
                var player_ref: AxPlayer = candidate as AxPlayer
                charge_direction = global_position.direction_to(player_ref.global_position)
                if charge_direction.length_squared() > 0.01:
                    charge_windup = 0.72
                    velocity = Vector2.ZERO
                    return true
        charge_cooldown = 1.0
    return false

func set_target_position(pos: Vector2) -> void:
    if dying:
        return
    target_position = pos
    has_target = true

func clear_target() -> void:
    has_target = false

func take_damage(amount: float) -> void:
    if dying:
        return
    var actual_damage: float = maxf(0.1, amount * (1.0 - armor))
    hp -= actual_damage
    hit_flash = 1.0
    if hp <= 0.0:
        hp = 0.0
        dying = true
        death_time = 0.18
        contact_damage = 0.0
        has_target = false
        charge_windup = 0.0
        charge_time = 0.0
        surge_windup = 0.0
        surge_time = 0.0
        Feedback.play("victory" if boss else "enemy_down", 18 if boss else 0)

func _draw() -> void:
    # Modern 16-bit presentation: crisp silhouettes, integer blocks, smooth gameplay.
    var shadow_w: float = 34.0 if boss else (28.0 if elite else 22.0)
    if enemy_type == "guardian" and not boss:
        shadow_w = 30.0
    _draw_shadow_ellipse(Vector2(0, 15), Vector2(shadow_w * 0.52, 4.8), Color(0.03, 0.035, 0.035, 0.28))

    if elite and not boss:
        var elite_pulse: float = (sin(animation_time * 4.8) + 1.0) * 0.5
        draw_circle(Vector2(0, -2), 27.0 + elite_pulse * 2.0, Color(elite_glow.r, elite_glow.g, elite_glow.b, 0.055 + elite_pulse * 0.025))
        draw_arc(Vector2(0, -2), 24.0 + elite_pulse, 0.0, TAU, 24, Color(elite_glow.r, elite_glow.g, elite_glow.b, 0.58), 1.5)
        for pip_index: int in range(3):
            var pip_angle: float = -2.45 + float(pip_index) * 0.40
            draw_circle(Vector2(cos(pip_angle), sin(pip_angle)) * 27.0 + Vector2(0, -2), 2.0, elite_glow)

    if (boss or (elite and elite_trait == "warlord")) and charge_windup > 0.0:
        var charge_alpha: float = clampf(1.0 - charge_windup / 0.72, 0.0, 1.0)
        draw_line(Vector2.ZERO, charge_direction * (54.0 + charge_alpha * 26.0), Color(1.0, 0.35, 0.28, 0.35 + charge_alpha * 0.55), 4.0)
        draw_rect(Rect2(-22, -22, 44, 44), Color(1.0, 0.42, 0.25, 0.25 + charge_alpha * 0.28), false, 2.0)
    elif (boss or (elite and elite_trait == "warlord")) and charge_time > 0.0:
        for trail_index: int in range(3):
            var back: Vector2 = -charge_direction * float(18 + trail_index * 12)
            draw_rect(Rect2(back - Vector2(8, 8), Vector2(16, 16)), Color(0.92, 0.32, 0.25, 0.15 - trail_index * 0.035))

    if enemy_type == "stalker" and surge_windup > 0.0:
        var s: float = clampf(1.0 - surge_windup / 0.22, 0.0, 1.0)
        draw_rect(Rect2(-15 - s * 3, -17 - s * 3, 30 + s * 6, 34 + s * 6), Color(0.72, 0.52, 0.92, 0.34 + s * 0.40), false, 2.0)

    var body_color: Color = tint
    if boss:
        body_color = Color("a34e52")
    else:
        match enemy_type:
            "runner":
                body_color = Color("6c8d75").lerp(tint, 0.30)
            "brute":
                body_color = Color("7e5a48").lerp(tint, 0.26)
            "stalker":
                body_color = Color("76589a").lerp(tint, 0.22)
            "guardian":
                body_color = Color("66706f").lerp(tint, 0.18)
            _:
                body_color = Color("6e5d76").lerp(tint, 0.42)
    body_color = body_color.lightened(hit_flash * 0.34)
    var dark: Color = body_color.darkened(0.30)
    var light: Color = body_color.lightened(0.18)

    if biome_index != 0:
        if boss:
            _draw_boss_aura()
            _draw_pixel_boss(body_color, dark, light)
        elif enemy_type == "runner":
            _draw_pixel_runner(body_color, dark, light)
        elif enemy_type == "brute":
            _draw_pixel_brute(body_color, dark, light)
        elif enemy_type == "stalker":
            _draw_pixel_stalker(body_color, dark, light)
        elif enemy_type == "guardian":
            _draw_pixel_guardian(body_color, dark, light)
        else:
            _draw_pixel_ghoul(body_color, dark, light)
        if not boss:
            _draw_biome_identity()
    elif boss:
        _draw_boss_aura()

    _draw_illustrated_forest_identity()

    if hit_flash > 0.25 and biome_index != 0:
        draw_rect(Rect2(-17, -21, 34, 39), Color(1.0, 0.90, 0.72, hit_flash * 0.42), false, 2.0)

    if not dying:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        var width: float = 92.0 if boss and biome_index == 0 else (54.0 if boss else (38.0 if elite else (32.0 if enemy_type == "guardian" else 26.0)))
        var art_bar_y: float = -55.0
        match enemy_type:
            "runner":
                art_bar_y = -42.0
            "brute", "guardian":
                art_bar_y = -54.0
            "stalker":
                art_bar_y = -59.0
        var bar_y: float = (-102.0 if boss else art_bar_y) if biome_index == 0 else (-39.0 if boss else (-33.0 if elite else -27.0))
        var bar_color: Color = Color("cf6165") if boss else (elite_glow if elite else (Color("c7b56e") if enemy_type == "guardian" else Color("8f7198")))
        draw_rect(Rect2(-width / 2.0, bar_y, width, 4.0), Color(0.08, 0.08, 0.08, 0.35))
        draw_rect(Rect2(-width / 2.0, bar_y, width * ratio, 4.0), bar_color)
        if armor > 0.0 and not boss:
            draw_rect(Rect2(-width / 2.0, bar_y + 6.0, width * armor, 2.0), Color("dfca78"))
        if elite and not elite_title.is_empty():
            var elite_font: Font = ThemeDB.fallback_font
            draw_string(elite_font, Vector2(-34, bar_y - 5), elite_title, HORIZONTAL_ALIGNMENT_CENTER, 68, 6, elite_glow.lightened(0.16))

func _draw_illustrated_forest_identity() -> void:
    if biome_index != 0:
        return
    var art_role: String = "boss" if boss else enemy_type
    if not FOREST_ART_PATHS.has(art_role):
        art_role = "normal"
    var texture: Texture2D = forest_art_cache.get(art_role) as Texture2D
    if texture == null:
        texture = ResourceLoader.load(str(FOREST_ART_PATHS[art_role])) as Texture2D
        forest_art_cache[art_role] = texture
    var size := Vector2(58, 64)
    var y_offset: float = -10.0
    match enemy_type:
        "runner":
            size = Vector2(72, 62)
            y_offset = -7.0
        "brute":
            size = Vector2(82, 86)
            y_offset = -14.0
        "stalker":
            size = Vector2(58, 91)
            y_offset = -17.0
        "guardian":
            size = Vector2(84, 88)
            y_offset = -15.0
        "boss":
            size = Vector2(164, 173)
            y_offset = -35.0
    if boss:
        size = Vector2(164, 173)
        y_offset = -35.0
    if texture == null:
        return
    var moving: bool = velocity.length_squared() > 16.0
    var pace: float = 3.6 if boss else (8.4 if enemy_type == "runner" else 5.4)
    var breathe: float = sin(animation_time * pace)
    var squash: float = (0.018 if moving else 0.008) * breathe
    var tilt: float = 0.0
    if enemy_type == "runner" and moving:
        tilt = -0.035 * breathe
    elif enemy_type == "stalker":
        tilt = 0.018 * breathe
    var art_tint := Color.WHITE.lerp(Color(1.0, 0.66, 0.54), clampf(hit_flash, 0.0, 1.0) * 0.82)
    if elite and not boss:
        art_tint = art_tint.lerp(elite_glow.lightened(0.30), 0.14)
    draw_set_transform(Vector2(0, y_offset), tilt, Vector2(1.0 - squash, 1.0 + squash))
    draw_texture_rect(texture, Rect2(-size * 0.5, size), false, art_tint)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_pixel_ghoul(body: Color, dark: Color, light: Color) -> void:
    # Basic husk: hunched, asymmetrical, obviously corrupted.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-8,-11),Vector2(-3,-17),Vector2(6,-15),Vector2(10,-8),
        Vector2(8,8),Vector2(2,14),Vector2(-7,10),Vector2(-11,-2)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-5,-10),Vector2(0,-14),Vector2(5,-12),Vector2(7,-5),
        Vector2(5,8),Vector2(0,11),Vector2(-5,7),Vector2(-7,-2)
    ]), body)
    draw_line(Vector2(-5,5),Vector2(-10,15),dark,4.0)
    draw_line(Vector2(4,7),Vector2(8,16),dark,4.0)
    draw_line(Vector2(-7,-1),Vector2(-14,7),body.darkened(0.08),4.0)
    draw_line(Vector2(7,-3),Vector2(13,2),body.darkened(0.08),4.0)
    draw_rect(Rect2(-5,-10,10,4),light)
    draw_line(Vector2(-2,2),Vector2(5,5),light.darkened(0.18),1.4)
    _pixel_eyes(3.2, Color("f3e7d0"))

func _draw_pixel_runner(body: Color, dark: Color, light: Color) -> void:
    # Runner: low forward silhouette with long limbs and swept ears.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-9,-9),Vector2(-2,-17),Vector2(7,-14),Vector2(11,-6),
        Vector2(7,7),Vector2(2,10),Vector2(-7,6),Vector2(-12,-1)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-6,-8),Vector2(0,-14),Vector2(6,-11),Vector2(8,-5),
        Vector2(5,5),Vector2(0,7),Vector2(-5,4),Vector2(-8,-1)
    ]), body)
    draw_colored_polygon(PackedVector2Array([Vector2(-4,-12),Vector2(-11,-22),Vector2(-1,-16)]),light.darkened(0.12))
    draw_colored_polygon(PackedVector2Array([Vector2(4,-12),Vector2(12,-20),Vector2(2,-15)]),light.darkened(0.12))
    draw_line(Vector2(-5,5),Vector2(-13,14),dark,4.0)
    draw_line(Vector2(2,7),Vector2(10,16),dark,4.0)
    draw_line(Vector2(-11,14),Vector2(-17,14),light,2.0)
    draw_line(Vector2(10,16),Vector2(16,16),light,2.0)
    _pixel_eyes(3.1, Color("f5efd9"))

func _draw_pixel_brute(body: Color, dark: Color, light: Color) -> void:
    # Brute: broad wedge, massive shoulders, tiny head.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-20,-7),Vector2(-13,-18),Vector2(-5,-22),Vector2(6,-21),
        Vector2(15,-16),Vector2(21,-6),Vector2(18,13),Vector2(8,19),
        Vector2(-9,19),Vector2(-19,12)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-15,-5),Vector2(-10,-15),Vector2(-3,-18),Vector2(5,-17),
        Vector2(12,-12),Vector2(16,-3),Vector2(13,11),Vector2(5,15),
        Vector2(-6,15),Vector2(-14,9)
    ]), body)
    draw_circle(Vector2(-16,-3),6.0,body.darkened(0.08))
    draw_circle(Vector2(16,-3),6.0,body.darkened(0.08))
    draw_colored_polygon(PackedVector2Array([Vector2(-8,-16),Vector2(-18,-25),Vector2(-4,-20)]),Color("c8b38d"))
    draw_colored_polygon(PackedVector2Array([Vector2(8,-16),Vector2(18,-25),Vector2(4,-20)]),Color("c8b38d"))
    draw_rect(Rect2(-7,-11,14,5),light)
    draw_line(Vector2(-10,6),Vector2(10,6),light.darkened(0.18),2.0)
    draw_line(Vector2(-8,15),Vector2(-11,22),dark,5.0)
    draw_line(Vector2(8,15),Vector2(11,22),dark,5.0)
    _pixel_eyes(4.0, Color("f2dec0"))

func _draw_pixel_stalker(body: Color, dark: Color, light: Color) -> void:
    # Stalker: tall crescent silhouette, blades/ears and luminous mask.
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-23),Vector2(11,-13),Vector2(14,-2),Vector2(10,13),
        Vector2(1,19),Vector2(-10,13),Vector2(-14,-2),Vector2(-10,-13)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-18),Vector2(8,-10),Vector2(10,-2),Vector2(7,10),
        Vector2(0,14),Vector2(-7,9),Vector2(-9,-2),Vector2(-7,-10)
    ]), body)
    draw_colored_polygon(PackedVector2Array([Vector2(-7,-13),Vector2(-15,-24),Vector2(-3,-17)]),Color("b89bd5"))
    draw_colored_polygon(PackedVector2Array([Vector2(7,-13),Vector2(15,-24),Vector2(3,-17)]),Color("b89bd5"))
    draw_line(Vector2(-9,8),Vector2(-18,15),light,3.0)
    draw_line(Vector2(9,8),Vector2(18,15),light,3.0)
    draw_arc(Vector2(0,-5),7.0,0.2,PI-0.2,14,light.lightened(0.14),1.5)
    _pixel_eyes(3.2, Color("e1c7ff"))

func _draw_pixel_guardian(body: Color, dark: Color, light: Color) -> void:
    # Heavy ancient construct, visibly different from living mobs.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-17,-15),Vector2(-8,-22),Vector2(8,-22),Vector2(17,-14),
        Vector2(20,8),Vector2(12,19),Vector2(-12,19),Vector2(-20,8)
    ]), Color("4e5350"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-13,-12),Vector2(-6,-18),Vector2(7,-18),Vector2(13,-11),
        Vector2(15,6),Vector2(8,14),Vector2(-8,14),Vector2(-15,6)
    ]), body)
    draw_circle(Vector2(-15,-2),6.0,Color("77766a"))
    draw_circle(Vector2(15,-2),6.0,Color("77766a"))
    draw_rect(Rect2(-10,-10,20,5),light)
    draw_rect(Rect2(-11,1,22,4),Color("aaa78f"))
    draw_line(Vector2(-6,14),Vector2(-9,22),dark,6.0)
    draw_line(Vector2(6,14),Vector2(9,22),dark,6.0)
    draw_circle(Vector2(0,7),4.0,Color("d0ba72"))
    _pixel_eyes(4.2, Color("f4e6bf"))

func _draw_biome_identity() -> void:
    # Anatomy communicates combat role; these restrained overlays communicate
    # the region without turning enemies into simple palette swaps.
    match biome_index:
        1:
            var frost := Color(0.70, 0.91, 0.96, 0.78)
            draw_colored_polygon(PackedVector2Array([
                Vector2(-8,-14), Vector2(-4,-25), Vector2(0,-15)
            ]), frost)
            draw_colored_polygon(PackedVector2Array([
                Vector2(7,-11), Vector2(13,-20), Vector2(10,-8)
            ]), frost.darkened(0.08))
            draw_line(Vector2(-5,6), Vector2(5,-2), Color(frost, 0.42), 1.4)
        2:
            var ember := Color("ef7140")
            draw_line(Vector2(-6,-8), Vector2(-1,1), ember, 1.8)
            draw_line(Vector2(-1,1), Vector2(-5,9), ember.darkened(0.10), 1.6)
            draw_line(Vector2(5,-4), Vector2(1,5), Color(1.0,0.46,0.20,0.70), 1.4)
            draw_circle(Vector2(0,8), 2.2, Color(1.0,0.58,0.24,0.55))
        _:
            var root := Color("493b28")
            draw_line(Vector2(-6,8), Vector2(-14,18), root, 2.6)
            draw_line(Vector2(5,9), Vector2(14,17), root, 2.6)
            draw_line(Vector2(-10,15), Vector2(-17,13), root.darkened(0.10), 1.8)
            if enemy_type in ["brute", "guardian"]:
                draw_line(Vector2(-9,-14), Vector2(-17,-25), root.lightened(0.10), 2.4)
                draw_line(Vector2(9,-14), Vector2(18,-23), root.lightened(0.10), 2.4)
            draw_circle(Vector2(0,5), 2.0, Color(0.67,0.18,0.12,0.75))

func _draw_boss_aura() -> void:
    var pulse: float = (sin(animation_time * 3.2) + 1.0) * 0.5
    var aura: Color
    match biome_index:
        1:
            aura = Color(0.52,0.84,0.96,0.09 + pulse*0.05)
        2:
            aura = Color(1.0,0.30,0.12,0.10 + pulse*0.07)
        _:
            aura = Color(0.52,0.78,0.36,0.08 + pulse*0.05)
    draw_circle(Vector2(0,-3), 48.0 + pulse*5.0, aura)
    draw_arc(Vector2(0,-3), 39.0 + pulse*3.0, 0.0, TAU, 36, Color(aura.r,aura.g,aura.b,aura.a*2.6), 2.0)

func _draw_pixel_boss(body: Color, dark: Color, light: Color) -> void:
    # Bosses share scale, not anatomy. Each biome gets a distinct silhouette.
    match biome_index:
        1:
            _draw_frost_boss(body,dark,light)
        2:
            _draw_ash_boss(body,dark,light)
        _:
            _draw_forest_boss(body,dark,light)

func _draw_forest_boss(body: Color, dark: Color, light: Color) -> void:
    var bark := Color("544b36").lightened(hit_flash*0.16)
    var moss := Color("547b48")
    # Wide, asymmetric root mantle makes the Guardian recognizable before its
    # attacks begin and gives it a true set-piece scale.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-34,-17),Vector2(-24,-31),Vector2(-10,-26),Vector2(0,-40),
        Vector2(13,-30),Vector2(32,-24),Vector2(39,-7),Vector2(31,18),
        Vector2(16,34),Vector2(-8,36),Vector2(-30,25),Vector2(-41,2)
    ]),Color("342f24"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-22,-19),Vector2(-12,-31),Vector2(0,-35),Vector2(13,-30),
        Vector2(24,-18),Vector2(27,8),Vector2(16,26),Vector2(0,31),
        Vector2(-17,25),Vector2(-28,7)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-17,-17),Vector2(-9,-26),Vector2(0,-29),Vector2(10,-25),
        Vector2(18,-15),Vector2(20,7),Vector2(11,20),Vector2(0,24),
        Vector2(-12,19),Vector2(-21,6)
    ]), bark)
    # Antlers and roots.
    draw_line(Vector2(-12,-25),Vector2(-32,-47),Color("8b7652"),4.5)
    draw_line(Vector2(-24,-38),Vector2(-40,-34),Color("8b7652"),3.2)
    draw_line(Vector2(-30,-45),Vector2(-27,-57),Color("8b7652"),2.6)
    draw_line(Vector2(12,-25),Vector2(34,-42),Color("8b7652"),4.2)
    draw_line(Vector2(27,-36),Vector2(43,-28),Color("8b7652"),3.0)
    draw_line(Vector2(-18,13),Vector2(-34,27),moss,5.0)
    draw_line(Vector2(18,13),Vector2(34,27),moss,5.0)
    # Living core.
    draw_circle(Vector2(0,3),10.0,Color("365f37"))
    draw_circle(Vector2(0,3),6.0,Color("6faa55"))
    draw_circle(Vector2(0,3),2.5,Color("c0ec91"))
    draw_line(Vector2(-12,-8),Vector2(12,-8),moss.darkened(0.08),3.0)
    # Bone mask and a single ember gaze keep the face iconic at phone scale.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-11,-22),Vector2(0,-29),Vector2(12,-21),Vector2(8,-9),
        Vector2(0,-5),Vector2(-8,-10)
    ]),Color("c2b99b"))
    draw_line(Vector2(-5,-18),Vector2(6,-16),Color("40392d"),2.0)
    draw_circle(Vector2(4,-17),2.3,Color("f0a044"))
    for mushroom: Vector2 in [Vector2(-24,-18),Vector2(-19,-24),Vector2(22,-16)]:
        draw_circle(mushroom,4.0,Color("9a5f45"))
        draw_line(mushroom + Vector2(0,2),mushroom + Vector2(0,7),Color("cab991"),2.0)

func _draw_frost_boss(body: Color, dark: Color, light: Color) -> void:
    var ice := Color("8bbfce").lightened(hit_flash*0.18)
    var bright := Color("d7f1f6")
    draw_colored_polygon(PackedVector2Array([
        Vector2(-23,-15),Vector2(-16,-30),Vector2(-7,-28),Vector2(0,-43),
        Vector2(8,-29),Vector2(18,-32),Vector2(25,-14),Vector2(23,12),
        Vector2(13,27),Vector2(0,31),Vector2(-14,26),Vector2(-25,10)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-17,-13),Vector2(-11,-24),Vector2(0,-31),Vector2(12,-24),
        Vector2(18,-12),Vector2(17,10),Vector2(9,21),Vector2(0,24),
        Vector2(-10,20),Vector2(-18,9)
    ]), ice)
    # Crown / ice blades.
    for spike: PackedVector2Array in [
        PackedVector2Array([Vector2(-15,-23),Vector2(-23,-44),Vector2(-7,-28)]),
        PackedVector2Array([Vector2(-5,-28),Vector2(0,-50),Vector2(6,-28)]),
        PackedVector2Array([Vector2(9,-26),Vector2(23,-45),Vector2(16,-20)])
    ]:
        draw_colored_polygon(spike,bright)
    draw_line(Vector2(-19,0),Vector2(-34,14),bright,4.0)
    draw_line(Vector2(19,0),Vector2(34,14),bright,4.0)
    # Crystal heart.
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-8),Vector2(9,3),Vector2(5,15),Vector2(-5,15),Vector2(-10,3)
    ]),Color("67b8d1"))
    draw_line(Vector2(0,-5),Vector2(0,11),bright,2.0)
    _pixel_eyes(8.0,Color("effcff"))

func _draw_ash_boss(body: Color, dark: Color, light: Color) -> void:
    var iron := Color("5a3631").lightened(hit_flash*0.16)
    var ember := Color("ff7c32")
    draw_colored_polygon(PackedVector2Array([
        Vector2(-25,-15),Vector2(-18,-31),Vector2(-5,-35),Vector2(8,-33),
        Vector2(21,-25),Vector2(29,-9),Vector2(26,14),Vector2(15,28),
        Vector2(0,31),Vector2(-17,26),Vector2(-29,10)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-19,-13),Vector2(-13,-25),Vector2(-4,-29),Vector2(8,-27),
        Vector2(17,-19),Vector2(21,-7),Vector2(19,11),Vector2(10,21),
        Vector2(0,24),Vector2(-12,20),Vector2(-22,8)
    ]),iron)
    # Broken horns.
    draw_colored_polygon(PackedVector2Array([Vector2(-13,-25),Vector2(-32,-42),Vector2(-24,-18)]),Color("7a5144"))
    draw_colored_polygon(PackedVector2Array([Vector2(14,-23),Vector2(34,-36),Vector2(24,-14)]),Color("7a5144"))
    # Furnace vents / cracks.
    draw_circle(Vector2(0,4),11.0,Color("72291f"))
    draw_circle(Vector2(0,4),6.0,ember)
    draw_circle(Vector2(0,4),2.4,Color("ffd06a"))
    for x: float in [-12.0,-4.0,5.0,13.0]:
        draw_line(Vector2(x,-17),Vector2(x + 3, -7),Color("e65d35"),2.0)
    draw_line(Vector2(-18,13),Vector2(-27,24),Color("8d4434"),5.0)
    draw_line(Vector2(18,13),Vector2(28,24),Color("8d4434"),5.0)
    _pixel_eyes(8.0,Color("ffe1c0"))

func _pixel_eyes(offset: float, color: Color) -> void:
    draw_rect(Rect2(-offset - 2.0, -5, 3, 3), color)
    draw_rect(Rect2(offset - 1.0, -5, 3, 3), color)
    draw_rect(Rect2(-offset - 1.0, -4, 1, 1), Color("6b2830"))
    draw_rect(Rect2(offset, -4, 1, 1), Color("6b2830"))

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i: int in range(24):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
