class_name AxPlayer
extends CharacterBody2D

signal died
signal damaged(amount: float, blocked: bool)
signal level_up_requested(level: int)

var target_position := Vector2.ZERO
var move_speed := 126.0
var max_hp := 100.0
var hp := 100.0
var damage := 25.0
var capacity := 20
var axes := 1
var orbit_radius := 44.0
var crit_chance := 0.05
var shield_hits := 0
var angle := 0.0
var xp := 0
var level := 1
var next_xp := 16
var inventory: Dictionary = {"wood": 0, "stone": 0, "ore": 0}
var skin_body := Color("466bc8")
var skin_cape := Color("364f9c")

func setup(meta_upgrades: Dictionary, skin: Dictionary) -> void:
    var hp_level: int = int(meta_upgrades.get("hp", 0))
    var damage_level: int = int(meta_upgrades.get("damage", 0))
    var bag_level: int = int(meta_upgrades.get("bag", 0))
    var speed_level: int = int(meta_upgrades.get("speed", 0))
    max_hp = 100.0 + hp_level * 10.0
    hp = max_hp
    damage = 25.0 * pow(1.10, damage_level)
    capacity = 20 + bag_level * 5
    move_speed = 126.0 * pow(1.04, speed_level)
    skin_body = Color(str(skin.get("body", "466bc8")))
    skin_cape = Color(str(skin.get("cape", "364f9c")))
    target_position = global_position
    queue_redraw()

func _physics_process(delta: float) -> void:
    var direction: Vector2 = global_position.direction_to(target_position)
    var distance: float = global_position.distance_to(target_position)
    if distance > 4.0:
        velocity = direction * move_speed
        move_and_slide()
    else:
        velocity = Vector2.ZERO
    angle += delta * 3.6
    queue_redraw()

func set_target(pos: Vector2) -> void:
    target_position = pos

func inventory_total() -> int:
    return int(inventory["wood"]) + int(inventory["stone"]) + int(inventory["ore"])

func add_resource(kind: String, amount: int) -> int:
    var available: int = maxi(0, capacity - inventory_total())
    var actual: int = mini(amount, available)
    inventory[kind] = int(inventory.get(kind, 0)) + actual
    return actual

func clear_inventory() -> Dictionary:
    var result: Dictionary = inventory.duplicate(true)
    inventory = {"wood": 0, "stone": 0, "ore": 0}
    return result

func take_damage(amount: float) -> void:
    if shield_hits > 0:
        shield_hits -= 1
        damaged.emit(0.0, true)
        queue_redraw()
        return
    hp = maxf(0.0, hp - amount)
    damaged.emit(amount, false)
    if hp <= 0.0:
        died.emit()

func heal(amount: float) -> void:
    hp = minf(max_hp, hp + amount)

func gain_xp(amount: int) -> void:
    xp += amount
    if xp >= next_xp:
        xp -= next_xp
        level += 1
        next_xp = int(round(next_xp * 1.38))
        level_up_requested.emit(level)

func apply_perk(id: String) -> void:
    match id:
        "axe": axes = mini(8, axes + 1)
        "damage": damage *= 1.22
        "orbit": orbit_radius *= 1.16
        "speed": move_speed *= 1.14
        "hp":
            max_hp += 25.0
            hp = minf(max_hp, hp + 35.0)
        "bag": capacity += 8
        "crit": crit_chance = minf(0.50, crit_chance + 0.12)
        "shield": shield_hits += 3
    queue_redraw()

func _draw() -> void:
    _draw_shadow_ellipse(Vector2(3, 11), Vector2(12, 5), Color(0.08, 0.12, 0.08, 0.18))
    var cape := PackedVector2Array([Vector2(-8, 2), Vector2(0, 16), Vector2(8, 2)])
    draw_colored_polygon(cape, skin_cape)
    draw_circle(Vector2.ZERO, 11.0, skin_body)
    draw_circle(Vector2(0, -8), 5.0, Color("e6be96"))
    var radius: float = orbit_radius + axes * 4.0
    for i in range(axes):
        var a: float = angle + float(i) * TAU / float(maxi(1, axes))
        var pos: Vector2 = Vector2(cos(a), sin(a)) * radius
        draw_line(pos + Vector2(-1, -8).rotated(a), pos + Vector2(1, 8).rotated(a), Color("68482f"), 4.0)
        draw_line(pos + Vector2(-7, -9).rotated(a), pos + Vector2(7, -9).rotated(a), Color("b8bec1"), 6.0)
    if shield_hits > 0:
        draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 48, Color(0.55, 0.88, 1.0, 0.82), 2.0)

func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var a: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
    draw_colored_polygon(points, color)
