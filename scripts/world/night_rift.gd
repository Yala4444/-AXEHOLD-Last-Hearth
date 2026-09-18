class_name NightRift
extends Node2D

signal destroyed(rift: NightRift)

var world: GameWorld
var hp: float = 120.0
var max_hp: float = 120.0
var reinforcement_time: float = 5.8
var elapsed: float = 0.0
var dying: bool = false

func setup(world_ref: GameWorld, wave: int) -> void:
    world = world_ref
    var difficulty: float = float(world.biome.get("difficulty", 1.0))
    max_hp = (105.0 + float(wave) * 32.0) * difficulty
    hp = max_hp
    reinforcement_time = maxf(4.8, 6.6 - float(wave) * 0.45)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if dying:
        scale = scale.lerp(Vector2(0.12, 0.12), clampf(delta * 11.0, 0.0, 1.0))
        modulate.a = maxf(0.0, modulate.a - delta * 5.5)
        if modulate.a <= 0.03:
            queue_free()
        return

    if world == null or not is_instance_valid(world) or world.phase != "night" or world.finishing:
        queue_free()
        return

    if world.player != null and is_instance_valid(world.player):
        var reach: float = world.player.orbit_radius + world.player.axes * 4.0 + 22.0
        if world.player.global_position.distance_to(global_position) <= reach:
            take_damage(world.player.damage * delta * 0.92)

    reinforcement_time -= delta
    if reinforcement_time <= 0.0:
        reinforcement_time = randf_range(5.5, 7.0)
        world.spawn_reinforcement("runner" if randf() < 0.55 else "")
        if world.hud != null:
            world.hud.set_status("Разлом зовёт подкрепление. Уничтожь его, чтобы остановить поток.")

    queue_redraw()

func take_damage(amount: float) -> void:
    if dying:
        return
    hp = maxf(0.0, hp - amount)
    if hp <= 0.0:
        dying = true
        destroyed.emit(self)
        Feedback.play("victory", 12)
    queue_redraw()

func _draw() -> void:
    var pulse: float = (sin(elapsed * 4.5) + 1.0) * 0.5
    var core := Color("7b436f")
    var edge := Color("bc79a7")
    draw_circle(Vector2(2, 5), 34.0, Color(0.02, 0.02, 0.03, 0.22))
    draw_circle(Vector2.ZERO, 31.0 + pulse * 2.0, Color(core, 0.16))
    draw_arc(Vector2.ZERO, 28.0 + pulse * 3.0, 0.0, TAU, 30, Color(edge, 0.82), 2.0)
    draw_arc(Vector2.ZERO, 18.0 + pulse * 1.5, -elapsed * 1.7, TAU - elapsed * 1.7, 22, Color("482542"), 5.0)

    for i: int in range(6):
        var a: float = elapsed * (0.45 + float(i % 2) * 0.12) + TAU * float(i) / 6.0
        var p := Vector2(cos(a), sin(a)) * (13.0 + float(i % 3) * 4.0)
        draw_circle(p, 2.0 + float(i % 2), Color(edge, 0.55))

    var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
    draw_rect(Rect2(-25, 36, 50, 4), Color(0.03, 0.03, 0.04, 0.62))
    draw_rect(Rect2(-25, 36, 50.0 * ratio, 4), Color("c56b96"))

    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-34, 53), "РАЗЛОМ", HORIZONTAL_ALIGNMENT_CENTER, 68, 7, Color("efd8e8"))
