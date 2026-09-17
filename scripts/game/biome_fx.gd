class_name BiomeFX
extends Node2D

signal hazard_triggered(kind: String, position: Vector2, radius: float, damage: float)

var world: GameWorld = null
var biome_index: int = 0
var hazards: Array[Dictionary] = []
var ambience_time: float = 0.0

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
    if world == null or not is_instance_valid(world):
        return

    var viewport_size: Vector2 = world.get_viewport_rect().size
    _draw_biome_atmosphere(viewport_size)
    _draw_edge_vignette(viewport_size)

    for hazard_variant: Variant in hazards:
        _draw_hazard(hazard_variant)

func _draw_biome_atmosphere(viewport_size: Vector2) -> void:
    match biome_index:
        1:
            _draw_frost_atmosphere(viewport_size)
        2:
            _draw_ash_atmosphere(viewport_size)
        _:
            _draw_forest_atmosphere(viewport_size)

func _draw_forest_atmosphere(viewport_size: Vector2) -> void:
    var night: bool = world.phase == "night"
    var wash_alpha: float = 0.045 if night else 0.026
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.20, 0.38, 0.18, wash_alpha))

    for i: int in range(14):
        var drift: float = ambience_time * (5.0 + float(i % 3))
        var x: float = fmod(float(i * 83) + drift, viewport_size.x + 30.0) - 15.0
        var y: float = 112.0 + fmod(float(i * 47) + sin(ambience_time * 0.7 + float(i)) * 18.0, maxf(1.0, viewport_size.y - 185.0))
        var pulse: float = 0.5 + sin(ambience_time * 2.8 + float(i) * 0.8) * 0.5
        var color: Color = Color(0.76, 0.95, 0.48, (0.08 + pulse * 0.13) if night else (0.035 + pulse * 0.04))
        draw_circle(Vector2(x, y), 1.2 + pulse * 0.9, color)

    for i: int in range(5):
        var y_line: float = viewport_size.y - 90.0 - float(i) * 34.0
        var sway: float = sin(ambience_time * 0.55 + float(i)) * 8.0
        draw_arc(Vector2(28.0 + float(i) * 86.0 + sway, y_line), 22.0, PI * 1.05, PI * 1.78, 16, Color(0.20, 0.32, 0.14, 0.10), 2.0)

func _draw_frost_atmosphere(viewport_size: Vector2) -> void:
    var night: bool = world.phase == "night"
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.45, 0.72, 0.92, 0.065 if night else 0.035))

    for i: int in range(26 if night else 18):
        var speed: float = 18.0 + float(i % 5) * 5.5
        var x: float = fmod(float(i * 61) + ambience_time * speed, viewport_size.x + 40.0) - 20.0
        var y: float = fmod(float(i * 43) + ambience_time * (13.0 + float(i % 4) * 3.0), viewport_size.y + 20.0)
        var length: float = 4.0 + float(i % 3) * 2.2
        draw_line(Vector2(x, y), Vector2(x - length * 0.7, y + length), Color(0.86, 0.96, 1.0, 0.18 if night else 0.12), 1.2)

    for i: int in range(4):
        var fog_y: float = 150.0 + float(i) * 145.0 + sin(ambience_time * 0.35 + float(i)) * 12.0
        draw_rect(Rect2(Vector2(0.0, fog_y), Vector2(viewport_size.x, 24.0)), Color(0.82, 0.93, 0.97, 0.025 + float(i % 2) * 0.012))

func _draw_ash_atmosphere(viewport_size: Vector2) -> void:
    var night: bool = world.phase == "night"
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.42, 0.12, 0.09, 0.060 if night else 0.033))

    for i: int in range(23 if night else 16):
        var x: float = fmod(float(i * 79) + sin(ambience_time * 0.5 + float(i)) * 22.0, viewport_size.x)
        var rise_speed: float = 15.0 + float(i % 5) * 4.0
        var y: float = viewport_size.y - fmod(float(i * 57) + ambience_time * rise_speed, viewport_size.y + 30.0)
        var ember: bool = i % 4 == 0
        var particle_color: Color = Color(1.0, 0.45, 0.20, 0.24 if night else 0.14) if ember else Color(0.20, 0.16, 0.14, 0.18)
        draw_circle(Vector2(x, y), 1.7 if ember else 1.2, particle_color)

    for i: int in range(4):
        var heat_y: float = viewport_size.y - 120.0 - float(i) * 118.0
        var offset: float = sin(ambience_time * 1.2 + float(i)) * 10.0
        draw_arc(Vector2(viewport_size.x * 0.5 + offset, heat_y), viewport_size.x * 0.42, PI * 1.08, PI * 1.92, 34, Color(1.0, 0.46, 0.24, 0.025), 3.0)

func _draw_edge_vignette(viewport_size: Vector2) -> void:
    var edge_color: Color
    match biome_index:
        1:
            edge_color = Color(0.08, 0.16, 0.22, 0.055)
        2:
            edge_color = Color(0.20, 0.05, 0.03, 0.065)
        _:
            edge_color = Color(0.05, 0.12, 0.05, 0.050)
    draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 20.0)), edge_color)
    draw_rect(Rect2(Vector2(0.0, viewport_size.y - 24.0), Vector2(viewport_size.x, 24.0)), edge_color)
    draw_rect(Rect2(Vector2.ZERO, Vector2(14.0, viewport_size.y)), edge_color)
    draw_rect(Rect2(Vector2(viewport_size.x - 14.0, 0.0), Vector2(14.0, viewport_size.y)), edge_color)

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
