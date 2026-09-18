class_name BiomeFX
extends Node2D

signal hazard_triggered(kind: String, position: Vector2, radius: float, damage: float)

var world: GameWorld = null
var biome_index: int = 0
var hazards: Array[Dictionary] = []
var ambience_time: float = 0.0
var night_mix: float = 0.0

func setup(world_ref: GameWorld, index: int) -> void:
    world = world_ref
    biome_index = index
    z_index = 2
    queue_redraw()

func telegraph(kind: String, position: Vector2, radius: float, delay: float, damage: float) -> void:
    hazards.append({
        "kind": kind,
        "position": position,
        "radius": radius,
        "time": delay,
        "duration": maxf(delay, 0.01),
        "damage": damage
    })
    queue_redraw()

func clear_hazards() -> void:
    hazards.clear()
    queue_redraw()

func _process(delta: float) -> void:
    ambience_time += delta
    var night_target: float = 1.0 if world != null and is_instance_valid(world) and world.phase == "night" else 0.0
    night_mix = move_toward(night_mix, night_target, delta * 1.65)
    _refresh_boss_hud()

    if not hazards.is_empty():
        var next_hazards: Array[Dictionary] = []
        for hazard_variant: Variant in hazards:
            var hazard: Dictionary = hazard_variant
            hazard["time"] = float(hazard.get("time", 0.0)) - delta
            if float(hazard["time"]) <= 0.0:
                hazard_triggered.emit(
                    str(hazard.get("kind", "ember")),
                    hazard.get("position", Vector2.ZERO) as Vector2,
                    float(hazard.get("radius", 48.0)),
                    float(hazard.get("damage", 10.0))
                )
            else:
                next_hazards.append(hazard)
        hazards = next_hazards

    queue_redraw()

func _refresh_boss_hud() -> void:
    if world == null or not is_instance_valid(world) or world.hud == null:
        return
    if world.boss_ref == null or not is_instance_valid(world.boss_ref):
        return
    var biome_data: Dictionary = GameRules.biome(biome_index)
    world.hud.show_boss(
        str(biome_data.get("boss_name", "Хранитель")),
        world.boss_ref.hp,
        world.boss_ref.max_hp
    )

func _draw() -> void:
    if world == null or not is_instance_valid(world) or world.player == null:
        return

    var viewport_size: Vector2 = world.get_viewport_rect().size
    var center: Vector2 = world.player.global_position
    if world.camera != null:
        center += world.camera.position
    var view_rect := Rect2(center - viewport_size * 0.5, viewport_size)
    _draw_biome_atmosphere(view_rect)
    _draw_phase_wash(view_rect)
    _draw_edge_vignette(view_rect)

    for hazard_variant: Variant in hazards:
        _draw_hazard(hazard_variant)

func _draw_biome_atmosphere(view_rect: Rect2) -> void:
    match biome_index:
        1:
            _draw_frost_atmosphere(view_rect)
        2:
            _draw_ash_atmosphere(view_rect)
        _:
            _draw_forest_atmosphere(view_rect)

func _draw_forest_atmosphere(view_rect: Rect2) -> void:
    var night: bool = world.phase == "night"
    var wash_alpha: float = 0.045 if night else 0.020
    draw_rect(view_rect, Color(0.20, 0.38, 0.18, wash_alpha))

    for i: int in range(14):
        var drift: float = ambience_time * (5.0 + float(i % 3))
        var x: float = view_rect.position.x + fmod(float(i * 83) + drift, view_rect.size.x + 30.0) - 15.0
        var y: float = view_rect.position.y + 72.0 + fmod(float(i * 47) + sin(ambience_time * 0.7 + float(i)) * 18.0, maxf(1.0, view_rect.size.y - 115.0))
        var pulse: float = 0.5 + sin(ambience_time * 2.8 + float(i) * 0.8) * 0.5
        var color: Color = Color(0.76, 0.95, 0.48, (0.08 + pulse * 0.13) if night else (0.025 + pulse * 0.035))
        draw_circle(Vector2(x, y), 1.2 + pulse * 0.9, color)

func _draw_frost_atmosphere(view_rect: Rect2) -> void:
    var night: bool = world.phase == "night"
    draw_rect(view_rect, Color(0.45, 0.72, 0.92, 0.060 if night else 0.030))

    for i: int in range(26 if night else 18):
        var speed: float = 18.0 + float(i % 5) * 5.5
        var x: float = view_rect.position.x + fmod(float(i * 61) + ambience_time * speed, view_rect.size.x + 40.0) - 20.0
        var y: float = view_rect.position.y + fmod(float(i * 43) + ambience_time * (13.0 + float(i % 4) * 3.0), view_rect.size.y + 20.0)
        var length: float = 4.0 + float(i % 3) * 2.2
        draw_line(Vector2(x, y), Vector2(x - length * 0.7, y + length), Color(0.86, 0.96, 1.0, 0.18 if night else 0.12), 1.2)

    for i: int in range(4):
        var fog_y: float = view_rect.position.y + 110.0 + float(i) * 145.0 + sin(ambience_time * 0.35 + float(i)) * 12.0
        draw_rect(Rect2(Vector2(view_rect.position.x, fog_y), Vector2(view_rect.size.x, 24.0)), Color(0.82, 0.93, 0.97, 0.025 + float(i % 2) * 0.012))

func _draw_ash_atmosphere(view_rect: Rect2) -> void:
    var night: bool = world.phase == "night"
    draw_rect(view_rect, Color(0.42, 0.12, 0.09, 0.055 if night else 0.030))

    for i: int in range(23 if night else 16):
        var x: float = view_rect.position.x + fmod(float(i * 79) + sin(ambience_time * 0.5 + float(i)) * 22.0, view_rect.size.x)
        var rise_speed: float = 15.0 + float(i % 5) * 4.0
        var y: float = view_rect.position.y + view_rect.size.y - fmod(float(i * 57) + ambience_time * rise_speed, view_rect.size.y + 30.0)
        var ember: bool = i % 4 == 0
        var particle_color: Color = Color(1.0, 0.45, 0.20, 0.24 if night else 0.14) if ember else Color(0.20, 0.16, 0.14, 0.18)
        draw_circle(Vector2(x, y), 1.7 if ember else 1.2, particle_color)

func _draw_phase_wash(view_rect: Rect2) -> void:
    if night_mix <= 0.001:
        return
    var color: Color
    match biome_index:
        1:
            color = Color(0.05, 0.10, 0.18, 0.10 * night_mix)
        2:
            color = Color(0.14, 0.025, 0.025, 0.11 * night_mix)
        _:
            color = Color(0.025, 0.07, 0.075, 0.12 * night_mix)
    draw_rect(view_rect, color)

func night_visual_strength() -> float:
    return night_mix

func _draw_edge_vignette(view_rect: Rect2) -> void:
    var edge_color: Color
    match biome_index:
        1:
            edge_color = Color(0.08, 0.16, 0.22, 0.050)
        2:
            edge_color = Color(0.20, 0.05, 0.03, 0.060)
        _:
            edge_color = Color(0.05, 0.12, 0.05, 0.045)

    draw_rect(Rect2(view_rect.position, Vector2(view_rect.size.x, 18.0)), edge_color)
    draw_rect(Rect2(Vector2(view_rect.position.x, view_rect.end.y - 22.0), Vector2(view_rect.size.x, 22.0)), edge_color)
    draw_rect(Rect2(view_rect.position, Vector2(12.0, view_rect.size.y)), edge_color)
    draw_rect(Rect2(Vector2(view_rect.end.x - 12.0, view_rect.position.y), Vector2(12.0, view_rect.size.y)), edge_color)

func _draw_hazard(hazard: Dictionary) -> void:
    var kind: String = str(hazard.get("kind", "ember"))
    var position: Vector2 = hazard.get("position", Vector2.ZERO) as Vector2
    var radius: float = float(hazard.get("radius", 48.0))
    var duration: float = maxf(0.01, float(hazard.get("duration", 1.0)))
    var time_left: float = maxf(0.0, float(hazard.get("time", 0.0)))
    var progress: float = clampf(1.0 - time_left / duration, 0.0, 1.0)

    var fill: Color
    var line: Color
    if kind == "frost":
        fill = Color(0.50, 0.84, 1.0, 0.08 + progress * 0.11)
        line = Color(0.72, 0.93, 1.0, 0.48 + progress * 0.42)
    else:
        fill = Color(1.0, 0.24, 0.10, 0.07 + progress * 0.14)
        line = Color(1.0, 0.48, 0.22, 0.50 + progress * 0.45)

    draw_circle(position, radius, fill)
    draw_arc(position, radius, 0.0, TAU, 56, line, 2.5 + progress * 1.8)
    draw_arc(position, radius * (0.25 + progress * 0.70), 0.0, TAU, 42, line.lightened(0.18), 2.0)
