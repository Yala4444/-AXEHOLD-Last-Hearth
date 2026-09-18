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

func configure(kind: String, index: int) -> void:
    activity_type = kind
    biome_index = index
    match kind:
        "caravan":
            required_time = 0.80
        "chest":
            required_time = 0.58
        "altar":
            required_time = 0.0
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
    draw_rect(Rect2(-15, -7, 30, 19), Color("6d4426"))
    draw_rect(Rect2(-13, -5, 26, 15), Color("9b6535"))
    draw_rect(Rect2(-15, -9, 30, 6), Color("b27b42"))
    draw_rect(Rect2(-2, -4, 4, 10), Color("d4ae5e"))

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
        _:
            draw_rect(Rect2(-14, 2, 28, 8), Color(0.34, 0.22, 0.13, 0.34))
