class_name FieldObjectiveMarker
extends Node2D

var objective_type: String = "survey"
var title: String = "РАЗВЕДКА"
var time_left: float = 20.0
var max_time: float = 20.0
var progress: float = 0.0
var elapsed: float = 0.0
var accent: Color = Color("d5a652")

func configure(kind: String, label: String, duration: float, color: Color) -> void:
    objective_type = kind
    title = label
    time_left = duration
    max_time = duration
    accent = color
    queue_redraw()

func update_state(remaining: float, ratio: float) -> void:
    time_left = maxf(0.0, remaining)
    progress = clampf(ratio, 0.0, 1.0)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var pulse: float = (sin(elapsed * 4.2) + 1.0) * 0.5
    draw_circle(Vector2.ZERO, 35.0 + pulse * 3.0, Color(accent, 0.045 + pulse * 0.025))
    draw_arc(Vector2.ZERO, 31.0 + pulse * 2.0, 0.0, TAU, 28, Color(accent, 0.55), 2.0)

    match objective_type:
        "salvage":
            _draw_salvage()
        "purge":
            _draw_purge()
        _:
            _draw_beacon()

    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(-52, 49), title, HORIZONTAL_ALIGNMENT_CENTER, 104, 8, Color("f0e7d3"))
    draw_string(font, Vector2(-26, 61), "%dс" % int(ceil(time_left)), HORIZONTAL_ALIGNMENT_CENTER, 52, 7, Color(accent, 0.90))

    if objective_type != "purge":
        draw_rect(Rect2(-25, 67, 50, 4), Color(0.03,0.05,0.05,0.62))
        if progress > 0.0:
            draw_rect(Rect2(-25, 67, 50.0 * progress, 4), accent)

func _draw_beacon() -> void:
    draw_rect(Rect2(-3, -16, 6, 27), Color("5a5142"))
    draw_circle(Vector2(0,-18), 7.0, Color(accent,0.28))
    draw_circle(Vector2(0,-18), 3.5, accent)
    draw_line(Vector2(-10,10),Vector2(10,10),Color("75644a"),3.0)
    draw_line(Vector2(-7,10),Vector2(0,2),Color("75644a"),2.0)
    draw_line(Vector2(7,10),Vector2(0,2),Color("75644a"),2.0)

func _draw_salvage() -> void:
    draw_rect(Rect2(-18,-8,36,20), Color("4f463b"))
    draw_rect(Rect2(-15,-5,30,14), Color("76634a"))
    draw_line(Vector2(-15,0),Vector2(15,0),Color("a58b61"),2.0)
    draw_rect(Rect2(-3,-8,6,20), Color("3f3932"))
    draw_circle(Vector2(10,-5),3.0,accent)
    draw_line(Vector2(-20,15),Vector2(18,15),Color(0.03,0.04,0.04,0.28),4.0)

func _draw_purge() -> void:
    draw_circle(Vector2.ZERO, 18.0, Color(0.17,0.08,0.10,0.74))
    for i: int in range(6):
        var a: float = TAU * float(i) / 6.0 + elapsed * 0.15
        var p := Vector2(cos(a),sin(a))*16.0
        draw_circle(p,2.5,accent)
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-13),Vector2(5,-3),Vector2(13,0),Vector2(5,3),
        Vector2(0,13),Vector2(-5,3),Vector2(-13,0),Vector2(-5,-3)
    ]),Color(accent,0.38))
