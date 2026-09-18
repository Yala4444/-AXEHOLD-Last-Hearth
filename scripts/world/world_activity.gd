class_name WorldActivity
extends Node2D

signal resolved(activity: WorldActivity)

var activity_type: String = "chest"
var biome_index: int = 0
var finished: bool = false
var progress: float = 0.0
var required_time: float = 0.65
var hp: float = 80.0
var max_hp: float = 80.0
var focus: bool = false
var elapsed: float = 0.0
var cursed: bool = false

func configure(kind: String, index: int) -> void:
    activity_type = kind
    biome_index = index
    match kind:
        "caravan":
            required_time = 0.80
        "chest":
            cursed = randf() < 0.32
            required_time = 0.76 if cursed else 0.58
        "altar":
            required_time = 0.0
        "old_hearth":
            required_time = 1.05
        "rare_ore":
            required_time = 1.25
        "broken_tower":
            required_time = 1.10
        "wind_shrine":
            required_time = 0.90
        "wanderer_grave":
            required_time = 0.78
        "signal_fire":
            required_time = 0.95
        "infected_cache":
            required_time = 0.92
        "memory_rift":
            required_time = 0.68
        "wounded_scout":
            required_time = 1.20
        "nest":
            max_hp = 110.0
            hp = max_hp
    queue_redraw()

func set_focus(value: bool) -> void:
    if focus == value:
        return
    focus = value
    queue_redraw()

func interact(delta: float) -> bool:
    if finished or activity_type == "nest" or activity_type == "altar":
        return false
    progress = minf(1.0, progress + delta / maxf(0.05, required_time))
    queue_redraw()
    if progress >= 1.0:
        finish()
        return true
    return false

func decay_progress(delta: float) -> void:
    if finished or progress <= 0.0:
        return
    progress = maxf(0.0, progress - delta * 1.25)
    queue_redraw()

func damage(amount: float) -> bool:
    if finished or activity_type != "nest":
        return false
    hp = maxf(0.0, hp - amount)
    queue_redraw()
    if hp <= 0.0:
        finish()
        return true
    return false

func finish() -> void:
    if finished:
        return
    finished = true
    focus = false
    progress = 1.0
    resolved.emit(self)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if focus or not finished:
        queue_redraw()

func _draw() -> void:
    if finished:
        _draw_finished()
        return

    var breathe: float = (sin(elapsed * 2.8) + 1.0) * 0.5
    if focus:
        draw_circle(Vector2.ZERO, 34.0 + breathe * 2.0, Color(0.94, 0.75, 0.35, 0.07))
        draw_arc(Vector2.ZERO, 34.0 + breathe * 2.0, 0.0, TAU, 28, Color(0.94, 0.75, 0.35, 0.52), 1.5)

    match activity_type:
        "caravan":
            _draw_caravan()
        "nest":
            _draw_nest()
        "altar":
            _draw_altar()
        "old_hearth":
            _draw_old_hearth()
        "rare_ore":
            _draw_rare_ore()
        "broken_tower":
            _draw_broken_tower()
        "wind_shrine":
            _draw_wind_shrine()
        "wanderer_grave":
            _draw_wanderer_grave()
        "signal_fire":
            _draw_signal_fire()
        "infected_cache":
            _draw_infected_cache()
        "memory_rift":
            _draw_memory_rift()
        "wounded_scout":
            _draw_wounded_scout()
        _:
            _draw_chest()

    if progress > 0.0 and activity_type != "nest":
        draw_rect(Rect2(-22, 29, 44, 4), Color(0.03, 0.05, 0.04, 0.56))
        draw_rect(Rect2(-22, 29, 44 * progress, 4), Color("e0b75d"))

    if activity_type == "nest":
        var ratio: float = hp / maxf(1.0, max_hp)
        draw_rect(Rect2(-23, 30, 46, 4), Color(0.03, 0.04, 0.03, 0.52))
        draw_rect(Rect2(-23, 30, 46 * ratio, 4), Color("b55862"))

    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-31, 45), _title(), HORIZONTAL_ALIGNMENT_CENTER, 62, 7, Color("ece4cf"))

func _title() -> String:
    match activity_type:
        "caravan":
            return "КАРАВАН"
        "nest":
            return "ГНЕЗДО"
        "altar":
            return "АЛТАРЬ"
        "old_hearth":
            return "ПОГАСШИЙ ОЧАГ"
        "rare_ore":
            return "РЕДКАЯ РУДА"
        "broken_tower":
            return "СЛОМАННАЯ БАШНЯ"
        "wind_shrine":
            return "СВЯТИЛИЩЕ ВЕТРА"
        "wanderer_grave":
            return "МОГИЛА"
        "signal_fire":
            return "СИГНАЛ"
        "infected_cache":
            return "ЗАРАЖЁННЫЙ СКЛАД"
        "memory_rift":
            return "РАЗЛОМ ПАМЯТИ"
        "wounded_scout":
            return "РАЗВЕДЧИЦА"
        _:
            return "ТАЙНИК"

func _draw_caravan() -> void:
    draw_rect(Rect2(-24, 5, 48, 7), Color(0.04, 0.05, 0.04, 0.16))
    draw_rect(Rect2(-20, -12, 35, 22), Color("70472c"))
    draw_rect(Rect2(-16, -9, 27, 16), Color("9a6437"))
    draw_line(Vector2(15, -7), Vector2(28, -19), Color("5c3c29"), 5.0)
    draw_circle(Vector2(-12, 13), 7.0, Color("3f342c"))
    draw_circle(Vector2(10, 13), 7.0, Color("3f342c"))
    draw_circle(Vector2(-12, 13), 3.0, Color("8a7962"))
    draw_circle(Vector2(10, 13), 3.0, Color("8a7962"))

func _draw_chest() -> void:
    draw_rect(Rect2(-17, 11, 34, 5), Color(0.04, 0.05, 0.04, 0.16))
    if cursed:
        var pulse: float = (sin(elapsed * 4.0) + 1.0) * 0.5
        draw_circle(Vector2.ZERO, 27.0 + pulse * 2.0, Color(0.62, 0.20, 0.42, 0.08 + pulse * 0.04))
        draw_arc(Vector2.ZERO, 24.0 + pulse * 2.0, 0.0, TAU, 24, Color(0.76, 0.36, 0.62, 0.48), 1.5)
    draw_rect(Rect2(-15, -7, 30, 19), Color("5e3340") if cursed else Color("6d4426"))
    draw_rect(Rect2(-13, -5, 26, 15), Color("874557") if cursed else Color("9b6535"))
    draw_rect(Rect2(-15, -9, 30, 6), Color("a85a73") if cursed else Color("b27b42"))
    draw_rect(Rect2(-2, -4, 4, 10), Color("e09abd") if cursed else Color("d4ae5e"))

func _draw_nest() -> void:
    var dark := Color("412d42") if biome_index != 2 else Color("3a2425")
    var mid := Color("715176") if biome_index != 2 else Color("753d39")
    draw_circle(Vector2(0, 5), 24.0, Color(0.04, 0.04, 0.04, 0.14))
    draw_circle(Vector2.ZERO, 20.0, dark)
    draw_circle(Vector2(-6, -5), 11.0, mid)
    draw_circle(Vector2(8, 4), 10.0, mid.darkened(0.08))
    for i: int in range(5):
        var angle: float = TAU * float(i) / 5.0 + elapsed * 0.08
        draw_circle(Vector2(cos(angle), sin(angle)) * 15.0, 2.2, Color("bd87c5"))

func _draw_altar() -> void:
    var glow := Color("d08c52") if biome_index != 1 else Color("79b6c6")
    draw_circle(Vector2.ZERO, 27.0, Color(glow, 0.08))
    draw_rect(Rect2(-14, 12, 28, 7), Color("55544c"))
    draw_rect(Rect2(-9, -11, 18, 25), Color("6f6d62"))
    draw_rect(Rect2(-4, -20, 8, 11), glow.darkened(0.12))
    draw_circle(Vector2(0, -21), 4.0, Color(glow, 0.76))

func _draw_old_hearth() -> void:
    var pulse: float = (sin(elapsed * 2.7) + 1.0) * 0.5
    for i: int in range(8):
        var a: float = TAU * float(i) / 8.0
        var p := Vector2(cos(a), sin(a)) * 16.0
        draw_rect(Rect2(p - Vector2(3, 2), Vector2(6, 4)), Color("66675f"))
    draw_line(Vector2(-8, 5), Vector2(8, -4), Color("4c3324"), 4.0)
    draw_line(Vector2(8, 5), Vector2(-7, -4), Color("59402a"), 4.0)
    draw_circle(Vector2.ZERO, 24.0 + pulse * 2.0, Color(0.90, 0.62, 0.28, 0.025))

func _draw_rare_ore() -> void:
    var pulse: float = (sin(elapsed * 4.2) + 1.0) * 0.5
    draw_circle(Vector2.ZERO, 28.0 + pulse * 2.0, Color(0.58, 0.34, 0.72, 0.07))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-18, 14), Vector2(-12, -8), Vector2(-3, -17),
        Vector2(3, -7), Vector2(11, -19), Vector2(18, 14)
    ]), Color("75588d"))
    draw_line(Vector2(-8, 9), Vector2(-3, -11), Color("c4a7d8"), 2.0)
    draw_line(Vector2(7, 8), Vector2(11, -13), Color("d4b4e8"), 2.0)

func _draw_broken_tower() -> void:
    draw_rect(Rect2(-16, 8, 32, 6), Color(0.04, 0.05, 0.04, 0.16))
    draw_rect(Rect2(-9, -17, 18, 29), Color("5f594d"))
    draw_rect(Rect2(-13, -22, 26, 7), Color("777064"))
    draw_line(Vector2(-4, -22), Vector2(7, -32), Color("6a4a32"), 4.0)
    draw_line(Vector2(7, -32), Vector2(15, -27), Color("6a4a32"), 3.0)

func _draw_wind_shrine() -> void:
    var pulse: float = (sin(elapsed * 3.8) + 1.0) * 0.5
    draw_circle(Vector2.ZERO, 27.0 + pulse * 2.0, Color(0.47, 0.74, 0.77, 0.06))
    draw_rect(Rect2(-12, 11, 24, 6), Color("555f5d"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, -22), Vector2(11, -4), Vector2(4, 11),
        Vector2(-5, 11), Vector2(-12, -4)
    ]), Color("82adb2"))
    draw_line(Vector2(-2, -17), Vector2(2, 6), Color("d2ecef"), 2.0)

func _draw_wanderer_grave() -> void:
    draw_rect(Rect2(-19, 10, 38, 5), Color(0.04, 0.05, 0.04, 0.16))
    draw_rect(Rect2(-9, -18, 18, 29), Color("55575a"))
    draw_arc(Vector2(0, -18), 9.0, PI, TAU, 14, Color("777b7f"), 3.0)
    draw_line(Vector2(-4, -8), Vector2(4, -8), Color("999a94"), 2.0)
    draw_line(Vector2(0, -12), Vector2(0, -4), Color("999a94"), 2.0)

func _draw_signal_fire() -> void:
    draw_rect(Rect2(-17, 10, 34, 5), Color(0.04, 0.05, 0.04, 0.16))
    draw_line(Vector2(-10, 8), Vector2(10, -4), Color("6b482e"), 4.0)
    draw_line(Vector2(10, 8), Vector2(-9, -4), Color("6b482e"), 4.0)
    draw_rect(Rect2(-2, -25, 4, 22), Color("595950"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, -25), Vector2(17, -19), Vector2(0, -13)
    ]), Color("a0754b"))

func _draw_infected_cache() -> void:
    var pulse: float = (sin(elapsed * 5.1) + 1.0) * 0.5
    draw_circle(Vector2.ZERO, 28.0 + pulse * 2.0, Color(0.28, 0.46, 0.22, 0.07))
    draw_rect(Rect2(-17, -10, 34, 22), Color("4b4a32"))
    draw_rect(Rect2(-14, -7, 28, 16), Color("6d6842"))
    for i: int in range(5):
        var a: float = TAU * float(i) / 5.0 + elapsed * 0.15
        draw_circle(Vector2(cos(a), sin(a)) * 14.0, 2.0, Color("86a55b"))

func _draw_memory_rift() -> void:
    var pulse: float = (sin(elapsed * 3.0) + 1.0) * 0.5
    draw_circle(Vector2.ZERO, 30.0 + pulse * 4.0, Color(0.48, 0.59, 0.76, 0.05))
    draw_arc(Vector2.ZERO, 24.0 + pulse * 2.0, elapsed * 0.5, TAU + elapsed * 0.5, 28, Color(0.55, 0.67, 0.88, 0.50), 2.0)
    draw_arc(Vector2.ZERO, 14.0, -elapsed * 0.8, TAU - elapsed * 0.8, 22, Color(0.76, 0.82, 0.95, 0.44), 2.0)

func _draw_wounded_scout() -> void:
    draw_rect(Rect2(-18, 12, 36, 5), Color(0.04, 0.05, 0.04, 0.16))
    draw_circle(Vector2(-1, -13), 6.0, Color("c99472"))
    draw_rect(Rect2(-7, -7, 14, 18), Color("526b62"))
    draw_line(Vector2(-5, 1), Vector2(-15, 10), Color("c99472"), 3.0)
    draw_line(Vector2(5, 2), Vector2(14, 8), Color("c99472"), 3.0)
    draw_rect(Rect2(3, -4, 5, 8), Color("8f4b49"))

func _draw_finished() -> void:
    match activity_type:
        "nest":
            draw_circle(Vector2.ZERO, 18.0, Color(0.18, 0.11, 0.15, 0.30))
            draw_rect(Rect2(-15, 4, 30, 5), Color(0.20, 0.13, 0.15, 0.35))
        "caravan":
            draw_rect(Rect2(-18, 4, 36, 5), Color(0.25, 0.18, 0.12, 0.28))
            draw_rect(Rect2(-13, -3, 12, 8), Color(0.36, 0.23, 0.14, 0.42))
        "altar":
            draw_rect(Rect2(-10, 5, 20, 5), Color(0.30, 0.29, 0.25, 0.30))
        "old_hearth":
            var pulse: float = (sin(elapsed * 4.0) + 1.0) * 0.5
            draw_circle(Vector2.ZERO, 30.0 + pulse * 2.0, Color(1.0, 0.55, 0.18, 0.06))
            for i: int in range(8):
                var a: float = TAU * float(i) / 8.0
                var p := Vector2(cos(a), sin(a)) * 16.0
                draw_rect(Rect2(p - Vector2(3, 2), Vector2(6, 4)), Color("77776a"))
            draw_colored_polygon(PackedVector2Array([
                Vector2(-5, 5), Vector2(-1, -8 - pulse * 2.0), Vector2(2, -2),
                Vector2(5, -11 + pulse), Vector2(7, 5)
            ]), Color("f39a3d"))
            draw_circle(Vector2(1, 1), 3.0, Color("ffe486"))
        "broken_tower":
            draw_rect(Rect2(-11, 3, 22, 7), Color(0.28, 0.28, 0.25, 0.34))
        "signal_fire":
            draw_circle(Vector2(0, 1), 11.0, Color(1.0, 0.55, 0.18, 0.08))
            draw_colored_polygon(PackedVector2Array([
                Vector2(-4, 6), Vector2(-1, -8), Vector2(2, -2), Vector2(5, -10), Vector2(7, 6)
            ]), Color("f29a3c"))
        "wounded_scout":
            draw_rect(Rect2(-10, 5, 20, 5), Color(0.23, 0.28, 0.25, 0.28))
        "memory_rift":
            draw_circle(Vector2.ZERO, 15.0, Color(0.42, 0.52, 0.68, 0.10))
        "rare_ore":
            draw_rect(Rect2(-13, 4, 26, 7), Color(0.36, 0.28, 0.43, 0.32))
        "wind_shrine":
            draw_rect(Rect2(-10, 5, 20, 5), Color(0.28, 0.37, 0.38, 0.30))
        "wanderer_grave":
            draw_rect(Rect2(-8, -5, 16, 16), Color(0.28, 0.29, 0.30, 0.30))
        "infected_cache":
            draw_rect(Rect2(-14, 2, 28, 8), Color(0.25, 0.28, 0.17, 0.34))
        _:
            draw_rect(Rect2(-14, 2, 28, 8), Color(0.34, 0.22, 0.13, 0.34))
