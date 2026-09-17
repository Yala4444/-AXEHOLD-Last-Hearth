class_name ExpeditionFX
extends Node2D

var world: GameWorld = null
var effects: Array[Dictionary] = []
var pulse_time: float = 0.0

func setup(owner_world: GameWorld) -> void:
    world = owner_world
    z_index = 4
    queue_redraw()

func burst(kind: String, position: Vector2, radius: float, duration: float = 0.55) -> void:
    effects.append({
        "type": "burst",
        "kind": kind,
        "position": position,
        "radius": radius,
        "time": duration,
        "duration": duration
    })
    queue_redraw()

func line(kind: String, from_position: Vector2, to_position: Vector2, duration: float = 0.42) -> void:
    effects.append({
        "type": "line",
        "kind": kind,
        "from": from_position,
        "to": to_position,
        "time": duration,
        "duration": duration
    })
    queue_redraw()

func _process(delta: float) -> void:
    pulse_time += delta
    for index: int in range(effects.size() - 1, -1, -1):
        var effect: Dictionary = effects[index]
        var remaining: float = float(effect.get("time", 0.0)) - delta
        if remaining <= 0.0:
            effects.remove_at(index)
        else:
            effect["time"] = remaining
            effects[index] = effect
    queue_redraw()

func _draw() -> void:
    _draw_base_danger()
    _draw_enemy_hit_sparks()
    _draw_player_feedback()
    _draw_elite_auras()
    for effect_variant: Dictionary in effects:
        _draw_effect(effect_variant)

func _draw_base_danger() -> void:
    if world == null or not is_instance_valid(world) or world.base_max_hp <= 0.0:
        return
    var ratio: float = clampf(world.base_hp / world.base_max_hp, 0.0, 1.0)
    if ratio >= 0.35:
        return
    var danger: float = 1.0 - ratio / 0.35
    var pulse: float = 0.5 + sin(pulse_time * (5.0 + danger * 4.0)) * 0.5
    var radius: float = 55.0 + pulse * 7.0
    draw_circle(world.base_position, radius, Color(0.80, 0.12, 0.10, 0.025 + danger * 0.035))
    draw_arc(world.base_position, radius, 0.0, TAU, 48, Color(1.0, 0.30, 0.24, 0.16 + danger * 0.28 + pulse * 0.10), 2.0 + danger)

func _draw_enemy_hit_sparks() -> void:
    if world == null or not is_instance_valid(world):
        return
    for enemy: AxEnemy in world.enemies:
        if not is_instance_valid(enemy) or enemy.dying or enemy.hit_flash <= 0.18:
            continue
        var intensity: float = clampf(enemy.hit_flash, 0.0, 1.0)
        var seed_angle: float = float(enemy.get_instance_id() % 17) * 0.37 + pulse_time * 0.35
        var spark_color: Color = Color(1.0, 0.90, 0.66, intensity * 0.72)
        for spark_index: int in range(5):
            var angle: float = seed_angle + TAU * float(spark_index) / 5.0
            var inner: Vector2 = enemy.global_position + Vector2(cos(angle), sin(angle)) * 13.0
            var outer: Vector2 = enemy.global_position + Vector2(cos(angle), sin(angle)) * (20.0 + intensity * 7.0)
            draw_line(inner, outer, spark_color, 1.5 + intensity)

func _draw_player_feedback() -> void:
    if world == null or not is_instance_valid(world) or world.player == null:
        return
    var viewport_size: Vector2 = world.get_viewport_rect().size
    var damage_flash: float = clampf(world.player.damage_flash, 0.0, 1.0)
    var block_flash: float = clampf(world.player.block_flash, 0.0, 1.0)

    if damage_flash > 0.02:
        var red := Color(0.72, 0.08, 0.08, damage_flash * 0.11)
        draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 26.0)), red)
        draw_rect(Rect2(Vector2(0.0, viewport_size.y - 30.0), Vector2(viewport_size.x, 30.0)), red)
        draw_rect(Rect2(Vector2.ZERO, Vector2(20.0, viewport_size.y)), red)
        draw_rect(Rect2(Vector2(viewport_size.x - 20.0, 0.0), Vector2(20.0, viewport_size.y)), red)

    if block_flash > 0.02:
        var shield_radius: float = 28.0 + (1.0 - block_flash) * 20.0
        draw_arc(world.player.global_position, shield_radius, 0.0, TAU, 44, Color(0.58, 0.88, 1.0, block_flash * 0.58), 2.5)

func _draw_elite_auras() -> void:
    if world == null or not is_instance_valid(world):
        return
    for enemy: AxEnemy in world.enemies:
        if not is_instance_valid(enemy) or enemy.dying or not bool(enemy.get_meta("expedition_elite", false)):
            continue
        var pulse: float = 0.5 + sin(pulse_time * 4.8 + float(enemy.get_instance_id() % 7)) * 0.5
        var radius: float = (34.0 if enemy.boss else 20.0) + pulse * 2.5
        draw_circle(enemy.global_position, radius, Color(0.95, 0.68, 0.24, 0.035 + pulse * 0.025))
        draw_arc(enemy.global_position, radius, 0.0, TAU, 36, Color(1.0, 0.76, 0.32, 0.38 + pulse * 0.28), 2.0)
        var crown_y: float = -31.0 if enemy.boss else -22.0
        var crown := PackedVector2Array([
            enemy.global_position + Vector2(-6.0, crown_y + 4.0),
            enemy.global_position + Vector2(-3.0, crown_y - 3.0),
            enemy.global_position + Vector2(0.0, crown_y + 1.0),
            enemy.global_position + Vector2(3.0, crown_y - 3.0),
            enemy.global_position + Vector2(6.0, crown_y + 4.0)
        ])
        draw_polyline(crown, Color(1.0, 0.82, 0.38, 0.86), 2.0)

func _draw_effect(effect: Dictionary) -> void:
    var duration: float = maxf(0.01, float(effect.get("duration", 0.5)))
    var remaining: float = clampf(float(effect.get("time", 0.0)), 0.0, duration)
    var alpha: float = remaining / duration
    var progress: float = 1.0 - alpha
    var kind: String = str(effect.get("kind", "axes"))
    var color: Color = _effect_color(kind)

    if str(effect.get("type", "burst")) == "line":
        var from_position: Vector2 = effect.get("from", Vector2.ZERO)
        var to_position: Vector2 = effect.get("to", Vector2.ZERO)
        draw_line(from_position, to_position, Color(color.r, color.g, color.b, alpha * 0.72), 5.0 - progress * 2.0)
        var direction: Vector2 = from_position.direction_to(to_position)
        var normal := Vector2(-direction.y, direction.x)
        draw_line(from_position + normal * 4.0, to_position + normal * 4.0, Color(color.r, color.g, color.b, alpha * 0.22), 2.0)
        draw_line(from_position - normal * 4.0, to_position - normal * 4.0, Color(color.r, color.g, color.b, alpha * 0.18), 1.5)
        draw_circle(to_position, 8.0 + progress * 9.0, Color(color.r, color.g, color.b, alpha * 0.14))
        draw_arc(to_position, 8.0 + progress * 9.0, 0.0, TAU, 22, Color(color.r, color.g, color.b, alpha * 0.66), 1.8)
        return

    var position: Vector2 = effect.get("position", Vector2.ZERO)
    var radius: float = float(effect.get("radius", 70.0))
    var animated_radius: float = radius * (0.35 + progress * 0.72)
    draw_circle(position, animated_radius, Color(color.r, color.g, color.b, alpha * 0.06))
    draw_arc(position, animated_radius, 0.0, TAU, 48, Color(color.r, color.g, color.b, alpha * 0.76), 3.0)
    draw_arc(position, maxf(8.0, animated_radius * 0.72), progress * 1.5, progress * 1.5 + PI * 1.45, 32, Color(1.0, 1.0, 1.0, alpha * 0.32), 1.5)

    for spark_index: int in range(10):
        var angle: float = TAU * float(spark_index) / 10.0 + progress * 0.8
        var inner_radius: float = animated_radius * 0.66
        var outer_radius: float = animated_radius * (0.82 + float(spark_index % 3) * 0.07)
        var from_point: Vector2 = position + Vector2(cos(angle), sin(angle)) * inner_radius
        var to_point: Vector2 = position + Vector2(cos(angle), sin(angle)) * outer_radius
        draw_line(from_point, to_point, Color(color.r, color.g, color.b, alpha * 0.46), 1.5)

func _effect_color(kind: String) -> Color:
    match kind:
        "spear":
            return Color("8fcf86")
        "hammer":
            return Color("9cdcf0")
        "twin_blades":
            return Color("f19a68")
        "elite":
            return Color("f0bd58")
        "risk":
            return Color("d76a68")
    return Color("f1cf78")
