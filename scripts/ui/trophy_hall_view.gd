class_name TrophyHallView
extends Control

var relics: Array = [false, false, false]
var mastery: Array = [0, 0, 0]
var elapsed: float = 0.0

func _ready() -> void:
    custom_minimum_size = Vector2(0, 278)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    relics = GameState.data.get("boss_relics", [false, false, false])
    mastery = GameState.data.get("biome_mastery", [0, 0, 0])
    set_process(true)
    queue_redraw()

func refresh() -> void:
    relics = GameState.data.get("boss_relics", [false, false, false])
    mastery = GameState.data.get("biome_mastery", [0, 0, 0])
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var w: float = maxf(size.x, 320.0)
    var h: float = maxf(size.y, 278.0)
    draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color("0f1519"))
    for i: int in range(8):
        var t: float = float(i) / 7.0
        draw_rect(Rect2(0, t * h, w, h / 7.0 + 1.0), Color("12191d").lerp(Color("29271f"), t))

    var beam: Color = Color(0.91, 0.70, 0.35, 0.025)
    draw_colored_polygon(PackedVector2Array([
        Vector2(w * 0.36, 0), Vector2(w * 0.64, 0), Vector2(w * 0.78, h), Vector2(w * 0.22, h)
    ]), beam)

    var xs: Array[float] = [w * 0.20, w * 0.50, w * 0.80]
    for i: int in range(3):
        _draw_alcove(Vector2(xs[i], h * 0.49), i)

    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(0, 23), "ЗАЛ РЕЛИКВИЙ", HORIZONTAL_ALIGNMENT_CENTER, w, 13, Color("e7c77f"))
    draw_string(font, Vector2(0, 43), "Каждая победа возвращает лагерю часть утраченной истории.", HORIZONTAL_ALIGNMENT_CENTER, w, 8, Color("99a5a5"))

func _draw_alcove(pos: Vector2, index: int) -> void:
    var owned: bool = index < relics.size() and bool(relics[index])
    var level: int = int(mastery[index]) if index < mastery.size() else 0
    var pulse: float = (sin(elapsed * 2.4 + float(index)) + 1.0) * 0.5

    draw_rect(Rect2(pos + Vector2(-43, -58), Vector2(86, 112)), Color(0.05, 0.07, 0.075, 0.54))
    draw_arc(pos + Vector2(0, -23), 40.0, PI, TAU, 20, Color(0.25, 0.28, 0.27, 0.55), 2.0)
    draw_rect(Rect2(pos + Vector2(-27, 28), Vector2(54, 13)), Color("514a3f"))
    draw_rect(Rect2(pos + Vector2(-33, 41), Vector2(66, 8)), Color("676052"))

    if owned:
        draw_circle(pos + Vector2(0, -6), 26.0 + pulse * 2.0, Color(0.90, 0.67, 0.30, 0.045))
        _draw_relic(pos + Vector2(0, -7), index)
    else:
        draw_circle(pos + Vector2(0, -7), 18.0, Color(0.08, 0.09, 0.09, 0.74))
        draw_arc(pos + Vector2(0, -7), 18.0, 0, TAU, 22, Color(0.35, 0.37, 0.36, 0.45), 2.0)
        draw_rect(Rect2(pos + Vector2(-4, -12), Vector2(8, 12)), Color(0.35, 0.37, 0.36, 0.34))
        draw_arc(pos + Vector2(0, -12), 8.0, PI, TAU, 12, Color(0.35, 0.37, 0.36, 0.34), 2.0)

    var font: Font = ThemeDB.fallback_font
    var names: Array[String] = ["КОРЕНЬ", "ИНЕЙ", "ПЕПЕЛ"]
    draw_string(font, pos + Vector2(-38, 68), names[index], HORIZONTAL_ALIGNMENT_CENTER, 76, 8, Color("e8ddc7") if owned else Color("6f7777"))
    draw_string(font, pos + Vector2(-38, 82), "МАСТ. %d" % level, HORIZONTAL_ALIGNMENT_CENTER, 76, 7, Color("bfa469") if owned else Color("596162"))

func _draw_relic(pos: Vector2, index: int) -> void:
    match index:
        1:
            var crystal := PackedVector2Array([
                pos + Vector2(0, -25), pos + Vector2(14, -5), pos + Vector2(8, 20),
                pos + Vector2(-9, 20), pos + Vector2(-15, -5)
            ])
            draw_colored_polygon(crystal, Color("89c7d8"))
            draw_polyline(crystal, Color("d8f3f7"), 2.0)
            draw_line(pos + Vector2(0, -20), pos + Vector2(-3, 15), Color(0.88, 0.97, 0.98, 0.45), 2.0)
        2:
            draw_circle(pos, 18.0, Color("a84c34"))
            draw_circle(pos, 12.0, Color("dc6b38"))
            draw_circle(pos, 6.0, Color("ffb34f"))
            draw_arc(pos, 24.0, 3.45, 5.95, 20, Color("e6a05d"), 3.0)
        _:
            draw_circle(pos, 17.0, Color("557e4b"))
            draw_line(pos + Vector2(0, 14), pos + Vector2(0, -27), Color("416d3d"), 5.0)
            draw_arc(pos + Vector2(-1, -9), 20.0, 3.30, 5.88, 18, Color("8bce72"), 3.0)
            draw_circle(pos + Vector2(8, -15), 4.0, Color("b3e792"))
