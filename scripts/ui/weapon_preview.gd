class_name WeaponPreview
extends Control

var weapon_id: String = "axes"
var elapsed: float = 0.0

func _ready() -> void:
    custom_minimum_size = Vector2(0, 178)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    queue_redraw()

func configure(id: String) -> void:
    weapon_id = id if WeaponRules.WEAPONS.has(id) else "axes"
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var w: float = maxf(size.x, 260.0)
    var h: float = maxf(size.y, 178.0)
    draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color("111a1d"))
    for i: int in range(9):
        var t: float = float(i) / 8.0
        draw_rect(Rect2(0, t * h, w, h / 8.0 + 1.0), Color("17252a").lerp(Color("26302b"), t))
    draw_circle(Vector2(w * 0.5, h * 0.56), 64.0, Color(0.86, 0.65, 0.30, 0.045))
    draw_circle(Vector2(w * 0.5, h * 0.56), 42.0, Color(0.86, 0.65, 0.30, 0.035))

    var hero := Vector2(w * 0.5, h * 0.62)
    _draw_hero(hero)

    var profile: Dictionary = WeaponRules.profile(weapon_id)
    var count: int = int(profile.get("axes", 1))
    var radius: float = float(profile.get("orbit_radius", 44.0)) * 0.95
    var speed: float = 1.0
    match weapon_id:
        "hammer":
            speed = 0.72
        "spear":
            speed = 0.84
        "twin_blades":
            speed = 1.28
    var base_angle: float = elapsed * 2.5 * speed

    if weapon_id == "spear":
        var angle: float = sin(elapsed * 1.9) * 0.38 - 0.45
        var dir := Vector2(cos(angle), sin(angle))
        draw_line(hero + dir * 9.0, hero + dir * 70.0, Color(0.72, 0.83, 0.72, 0.16), 4.0)
        _draw_weapon(hero + dir * 58.0, angle, 1.05)
    elif weapon_id == "hammer":
        var angle: float = base_angle
        var p := hero + Vector2(cos(angle), sin(angle)) * radius
        draw_arc(hero, radius, angle - 0.85, angle, 18, Color(0.72, 0.84, 0.94, 0.14), 6.0)
        _draw_weapon(p, angle, 1.08)
    else:
        for i: int in range(maxi(1, count)):
            var angle: float = base_angle + TAU * float(i) / float(maxi(1, count))
            var p := hero + Vector2(cos(angle), sin(angle)) * radius
            draw_arc(hero, radius, angle - 0.34, angle - 0.07, 10, Color(0.84, 0.90, 0.91, 0.12), 4.0)
            _draw_weapon(p, angle, 0.92)

func _draw_hero(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-11, 17), Vector2(23, 4)), Color(0.02, 0.03, 0.03, 0.28))
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(-8, -2), pos + Vector2(-9, 15), pos + Vector2(0, 19),
        pos + Vector2(9, 15), pos + Vector2(8, -2)
    ]), Color("334f67"))
    draw_rect(Rect2(pos + Vector2(-8, -4), Vector2(16, 15)), Color("466bc8"))
    draw_rect(Rect2(pos + Vector2(-7, 5), Vector2(14, 3)), Color("9d7144"))
    draw_rect(Rect2(pos + Vector2(-6, 10), Vector2(5, 10)), Color("26313c"))
    draw_rect(Rect2(pos + Vector2(2, 10), Vector2(5, 10)), Color("26313c"))
    draw_rect(Rect2(pos + Vector2(-7, -18), Vector2(14, 14)), Color("2d2522"))
    draw_rect(Rect2(pos + Vector2(-6, -16), Vector2(12, 11)), Color("d6a47d"))
    draw_rect(Rect2(pos + Vector2(-7, -18), Vector2(14, 4)), Color("405d8d"))

func _draw_weapon(pos: Vector2, angle: float, scale_value: float) -> void:
    var tangent := Vector2(cos(angle), sin(angle))
    var side := Vector2(-tangent.y, tangent.x)
    match weapon_id:
        "spear":
            draw_line(pos - tangent * 25.0 * scale_value, pos + tangent * 22.0 * scale_value, Color("77563a"), 4.0 * scale_value)
            var tip := PackedVector2Array([
                pos + tangent * 28.0 * scale_value,
                pos + tangent * 17.0 * scale_value + side * 7.0 * scale_value,
                pos + tangent * 17.0 * scale_value - side * 7.0 * scale_value
            ])
            draw_colored_polygon(tip, Color("b9c7b0"))
        "hammer":
            draw_line(pos - tangent * 19.0 * scale_value, pos + tangent * 13.0 * scale_value, Color("6e4c35"), 5.0 * scale_value)
            var head_center := pos + tangent * 17.0 * scale_value
            draw_line(head_center - side * 12.0 * scale_value, head_center + side * 12.0 * scale_value, Color("aebfd0"), 10.0 * scale_value)
            draw_line(head_center - side * 9.0 * scale_value, head_center + side * 9.0 * scale_value, Color("dce9f1"), 3.0 * scale_value)
        "twin_blades":
            draw_line(pos - tangent * 12.0 * scale_value, pos + tangent * 13.0 * scale_value, Color("e2a073"), 5.0 * scale_value)
            draw_line(pos - side * 7.0 * scale_value, pos + side * 7.0 * scale_value, Color("5e3e30"), 3.0 * scale_value)
        _:
            draw_line(pos - tangent * 13.0 * scale_value, pos + tangent * 10.0 * scale_value, Color("6a4932"), 5.0 * scale_value)
            var blade := pos + tangent * 11.0 * scale_value
            draw_line(blade - side * 9.0 * scale_value, blade + side * 9.0 * scale_value, Color("bfc8cb"), 7.0 * scale_value)
