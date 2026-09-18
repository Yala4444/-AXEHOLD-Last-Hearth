class_name AxEnemy
extends CharacterBody2D

signal killed(enemy: AxEnemy)

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
    draw_rect(Rect2(-shadow_w * 0.5, 12, shadow_w, 5), Color(0.04, 0.04, 0.04, 0.22))

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

    if hit_flash > 0.25:
        draw_rect(Rect2(-17, -21, 34, 39), Color(1.0, 0.90, 0.72, hit_flash * 0.42), false, 2.0)

    if not dying:
        var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
        var width: float = 54.0 if boss else (38.0 if elite else (32.0 if enemy_type == "guardian" else 26.0))
        var bar_y: float = -39.0 if boss else (-33.0 if elite else -27.0)
        var bar_color: Color = Color("cf6165") if boss else (elite_glow if elite else (Color("c7b56e") if enemy_type == "guardian" else Color("8f7198")))
        draw_rect(Rect2(-width / 2.0, bar_y, width, 4.0), Color(0.08, 0.08, 0.08, 0.35))
        draw_rect(Rect2(-width / 2.0, bar_y, width * ratio, 4.0), bar_color)
        if armor > 0.0 and not boss:
            draw_rect(Rect2(-width / 2.0, bar_y + 6.0, width * armor, 2.0), Color("dfca78"))
        if elite and not elite_title.is_empty():
            var elite_font: Font = ThemeDB.fallback_font
            draw_string(elite_font, Vector2(-34, bar_y - 5), elite_title, HORIZONTAL_ALIGNMENT_CENTER, 68, 6, elite_glow.lightened(0.16))

func _draw_pixel_ghoul(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-9, -12, 18, 22), dark)
    draw_rect(Rect2(-7, -14, 14, 22), body)
    draw_rect(Rect2(-5, -11, 10, 5), light)
    draw_rect(Rect2(-5, 9, 4, 7), dark)
    draw_rect(Rect2(2, 9, 4, 7), dark)
    _pixel_eyes(3.0, Color("efe8d6"))

func _draw_pixel_runner(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-7, -14, 14, 18), body)
    draw_rect(Rect2(-10, -8, 20, 9), dark)
    draw_rect(Rect2(-5, 3, 4, 12), dark)
    draw_rect(Rect2(2, 3, 4, 12), dark)
    draw_rect(Rect2(-8, 14, 7, 3), light)
    draw_rect(Rect2(2, 14, 8, 3), light)
    _pixel_eyes(3.0, Color("f6f0df"))

func _draw_pixel_brute(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-15, -12, 30, 24), dark)
    draw_rect(Rect2(-12, -15, 24, 27), body)
    draw_rect(Rect2(-18, -6, 7, 16), body)
    draw_rect(Rect2(11, -6, 7, 16), body)
    draw_colored_polygon(PackedVector2Array([Vector2(-9,-14),Vector2(-16,-23),Vector2(-4,-17)]), Color("c7b18b"))
    draw_colored_polygon(PackedVector2Array([Vector2(9,-14),Vector2(16,-23),Vector2(4,-17)]), Color("c7b18b"))
    draw_rect(Rect2(-7, 7, 14, 4), light)
    _pixel_eyes(4.0, Color("f0ddc4"))

func _draw_pixel_stalker(body: Color, dark: Color, light: Color) -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-19),Vector2(11,-7),Vector2(8,11),Vector2(0,16),Vector2(-9,10),Vector2(-11,-7)
    ]), dark)
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-15),Vector2(8,-5),Vector2(6,9),Vector2(0,13),Vector2(-6,8),Vector2(-8,-5)
    ]), body)
    draw_rect(Rect2(-15, 8, 8, 3), light)
    draw_rect(Rect2(7, 8, 8, 3), light)
    draw_colored_polygon(PackedVector2Array([Vector2(-6,-12),Vector2(-12,-21),Vector2(-2,-15)]), Color("bca0d9"))
    draw_colored_polygon(PackedVector2Array([Vector2(6,-12),Vector2(12,-21),Vector2(2,-15)]), Color("bca0d9"))
    _pixel_eyes(3.0, Color("d7b8ff"))

func _draw_pixel_guardian(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-16, -14, 32, 28), dark)
    draw_rect(Rect2(-13, -11, 26, 24), body)
    draw_rect(Rect2(-15, -9, 30, 5), Color("c7c2a7"))
    draw_rect(Rect2(-12, 1, 24, 5), Color("aaa78f"))
    draw_rect(Rect2(-18, -4, 6, 17), Color("8f8d7d"))
    draw_rect(Rect2(12, -4, 6, 17), Color("8f8d7d"))
    draw_rect(Rect2(-9, 12, 7, 7), dark)
    draw_rect(Rect2(2, 12, 7, 7), dark)
    _pixel_eyes(4.0, Color("f4e6bf"))

func _draw_boss_aura() -> void:
    var pulse: float = (sin(animation_time * 3.2) + 1.0) * 0.5
    var aura: Color
    match biome_index:
        1:
            aura = Color(0.52, 0.84, 0.96, 0.09 + pulse * 0.05)
        2:
            aura = Color(1.0, 0.30, 0.12, 0.10 + pulse * 0.07)
        _:
            aura = Color(0.52, 0.78, 0.36, 0.08 + pulse * 0.05)
    draw_circle(Vector2(0, -2), 38.0 + pulse * 4.0, aura)
    draw_arc(Vector2(0, -2), 31.0 + pulse * 2.0, 0.0, TAU, 28, Color(aura.r, aura.g, aura.b, aura.a * 2.8), 1.5)

func _draw_pixel_boss(body: Color, dark: Color, light: Color) -> void:
    draw_rect(Rect2(-24, -20, 48, 39), dark)
    draw_rect(Rect2(-20, -23, 40, 40), body)
    draw_rect(Rect2(-27, -9, 8, 22), body)
    draw_rect(Rect2(19, -9, 8, 22), body)
    draw_rect(Rect2(-14, 5, 28, 6), light)
    draw_rect(Rect2(-12, 16, 9, 8), dark)
    draw_rect(Rect2(3, 16, 9, 8), dark)

    match biome_index:
        1:
            # Frost Guardian: ice crown and frozen core.
            draw_colored_polygon(PackedVector2Array([
                Vector2(-16,-20),Vector2(-11,-35),Vector2(-4,-24)
            ]), Color("b9e5f2"))
            draw_colored_polygon(PackedVector2Array([
                Vector2(-4,-23),Vector2(0,-40),Vector2(6,-23)
            ]), Color("d8f4fb"))
            draw_colored_polygon(PackedVector2Array([
                Vector2(5,-24),Vector2(13,-34),Vector2(17,-19)
            ]), Color("9fd2e4"))
            draw_colored_polygon(PackedVector2Array([
                Vector2(0,-5),Vector2(7,3),Vector2(4,12),Vector2(-5,12),Vector2(-8,3)
            ]), Color("86cfe8").lightened(hit_flash * 0.28))
            draw_line(Vector2(-17, 0), Vector2(-26, 10), Color("d7f2f8"), 3.0)
            draw_line(Vector2(17, 0), Vector2(26, 10), Color("d7f2f8"), 3.0)
        2:
            # Ash Guardian: broken horns and furnace core.
            draw_colored_polygon(PackedVector2Array([
                Vector2(-13,-20),Vector2(-28,-33),Vector2(-20,-15)
            ]), Color("684239"))
            draw_colored_polygon(PackedVector2Array([
                Vector2(13,-20),Vector2(30,-29),Vector2(19,-14)
            ]), Color("684239"))
            draw_circle(Vector2(0, 3), 9.0, Color("7b2c22"))
            draw_circle(Vector2(0, 3), 5.0, Color("ff7c2f"))
            draw_rect(Rect2(-3, 11, 6, 5), Color("e14a25"))
            for i: int in range(3):
                var x: float = -9.0 + float(i) * 9.0
                draw_line(Vector2(x, -18), Vector2(x + 2, -9), Color("e26a3b"), 2.0)
        _:
            # Forest Guardian: antlers, root mantle and living heart.
            draw_colored_polygon(PackedVector2Array([Vector2(-13,-21),Vector2(-27,-34),Vector2(-18,-17)]), Color("8f7651"))
            draw_colored_polygon(PackedVector2Array([Vector2(13,-21),Vector2(27,-34),Vector2(18,-17)]), Color("8f7651"))
            draw_line(Vector2(-23,-29), Vector2(-31,-21), Color("8f7651"), 3.0)
            draw_line(Vector2(23,-29), Vector2(31,-21), Color("8f7651"), 3.0)
            draw_line(Vector2(-17, 7), Vector2(-28, 17), Color("4e6d3f"), 4.0)
            draw_line(Vector2(17, 7), Vector2(28, 17), Color("4e6d3f"), 4.0)
            draw_circle(Vector2(0, 3), 7.0, Color("6ca752"))
            draw_circle(Vector2(0, 3), 3.0, Color("b6e781"))

    _pixel_eyes(7.0, Color("ffe2c8"))

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
