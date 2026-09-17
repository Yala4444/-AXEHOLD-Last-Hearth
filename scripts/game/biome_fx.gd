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

    if hazards.is_empty():
        queue_redraw()
        return

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
    if world.phase == "night":
        if biome_index == 1:
            draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.45, 0.72, 0.92, 0.055))
            for i: int in range(18):
                var x: float = fmod(float(i * 79) + ambience_time * 8.0, viewport_size.x)
                var y: float = fmod(float(i * 47) + ambience_time * 13.0, viewport_size.y)
                draw_circle(Vector2(x, y), 1.4, Color(0.82, 0.94, 1.0, 0.28))
        elif biome_index == 2:
            draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.42, 0.12, 0.09, 0.045))
            for i: int in range(16):
                var x: float = fmod(float(i * 91) + ambience_time * 4.0, viewport_size.x)
                var y: float = viewport_size.y - fmod(float(i * 61) + ambience_time * 18.0, viewport_size.y)
                draw_circle(Vector2(x, y), 1.6, Color(1.0, 0.48, 0.25, 0.24))

    for hazard_variant: Variant in hazards:
        var hazard: Dictionary = hazard_variant
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
