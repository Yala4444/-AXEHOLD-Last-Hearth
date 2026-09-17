class_name AxEnemy
extends CharacterBody2D

signal killed(enemy: AxEnemy)

var enemy_type := "normal"
var hp := 40.0
var max_hp := 40.0
var move_speed := 30.0
var contact_damage := 8.0
var boss := false
var target_position := Vector2.ZERO
var has_target := false
var hit_cooldown := 0.0
var special_cooldown := 2.8
var windup := 0.0
var mark_position := Vector2.ZERO
var mark_active := false
var tint := Color("6c5574")

func configure(kind: String, difficulty: float, wave: int, color: Color, is_boss: bool = false) -> void:
    enemy_type = kind
    boss = is_boss
    tint = color
    if boss:
        max_hp = 340.0 * difficulty
        move_speed = 23.0
        contact_damage = 22.0 * difficulty
    elif kind == "brute":
        max_hp = (62.0 + wave * 10.0) * difficulty
        move_speed = 20.0
        contact_damage = 12.0 * difficulty
    elif kind == "runner":
        max_hp = (30.0 + wave * 9.0) * difficulty
        move_speed = 40.0
        contact_damage = 6.0 * difficulty
    else:
        max_hp = (40.0 + wave * 10.0) * difficulty
        move_speed = 29.0 + wave * 2.0
        contact_damage = (7.0 + wave * 0.8) * difficulty
    hp = max_hp
    queue_redraw()

func _physics_process(delta: float) -> void:
    hit_cooldown = maxf(0.0, hit_cooldown - delta)
    if has_target and windup <= 0.0:
        velocity = global_position.direction_to(target_position) * move_speed
        move_and_slide()
    else:
        velocity = Vector2.ZERO
    queue_redraw()

func set_target_position(pos: Vector2) -> void:
    target_position = pos
    has_target = true

func clear_target() -> void:
    has_target = false

func take_damage(amount: float) -> void:
    hp -= amount
    if hp <= 0.0:
        killed.emit(self)

func _draw() -> void:
    var shadow_radii := Vector2(20.0, 7.0) if boss else Vector2(11.0, 4.0)
    _draw_shadow_ellipse(Vector2(3, 8), shadow_radii, Color(0.05, 0.05, 0.05, 0.18))
    var body_radius: float = 24.0 if boss else (13.0 if enemy_type == "brute" else 10.0)
    var body_color: Color = Color("9c4d51") if boss else tint
    draw_circle(Vector2.ZERO, body_radius, body_color)
    if boss:
        draw_colored_polygon(PackedVector2Array([Vector2(-15,-15),Vector2(-27,-30),Vector2(-7,-20)]), Color("d5c19e"))
        draw_colored_polygon(PackedVector2Array([Vector2(15,-15),Vector2(27,-30),Vector2(7,-20)]), Color("d5c19e"))
    draw_circle(Vector2(-3,-2), 1.8, Color.WHITE)
    draw_circle(Vector2(3,-2), 1.8, Color.WHITE)
    var ratio: float = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
    var width: float = 52.0 if boss else 24.0
    var y: float = -35.0 if boss else -24.0
    var bar_color: Color = Color("cf6165") if boss else Color("8f7198")
    draw_rect(Rect2(-width / 2.0, y, width, 4.0), Color(0.1,0.1,0.1,0.25))
    draw_rect(Rect2(-width / 2.0, y, width * ratio, 4.0), bar_color)

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var a: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
    draw_colored_polygon(points, color)
