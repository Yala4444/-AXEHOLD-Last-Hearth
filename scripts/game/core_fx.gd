class_name CoreFX
extends Node2D

var particles: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var pulses: Array[Dictionary] = []

func _ready() -> void:
    z_index = 70
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    for i: int in range(particles.size() - 1, -1, -1):
        var p: Dictionary = particles[i]
        p["life"] = float(p["life"]) - delta
        if float(p["life"]) <= 0.0:
            particles.remove_at(i)
            continue
        p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
        var velocity: Vector2 = Vector2(p["vel"])
        velocity.y += float(p.get("gravity", 0.0)) * delta
        velocity *= maxf(0.0, 1.0 - delta * float(p.get("drag", 0.0)))
        p["vel"] = velocity
        particles[i] = p

    for i: int in range(popups.size() - 1, -1, -1):
        var popup: Dictionary = popups[i]
        popup["life"] = float(popup["life"]) - delta
        if float(popup["life"]) <= 0.0:
            popups.remove_at(i)
            continue
        popup["pos"] = Vector2(popup["pos"]) + Vector2(0, -16.0) * delta
        popups[i] = popup

    for i: int in range(pulses.size() - 1, -1, -1):
        var pulse: Dictionary = pulses[i]
        pulse["life"] = float(pulse["life"]) - delta
        if float(pulse["life"]) <= 0.0:
            pulses.remove_at(i)
            continue
        pulses[i] = pulse

    if not particles.is_empty() or not popups.is_empty() or not pulses.is_empty():
        queue_redraw()

func harvest(kind: String, pos: Vector2, amount: int) -> void:
    var color: Color = _resource_color(kind)
    for i: int in range(9):
        var angle: float = TAU * float(i) / 9.0 + randf_range(-0.25, 0.25)
        var speed: float = randf_range(34.0, 72.0)
        _particle(pos, Vector2(cos(angle), sin(angle)) * speed + Vector2(0, -18), color, randf_range(0.34, 0.52), randf_range(2.0, 4.0), 74.0, 2.4)
    _popup(pos + Vector2(0, -18), "+%d %s" % [amount, _resource_short(kind)], color.lightened(0.22), 0.72)

func deposit(inventory: Dictionary, pos: Vector2) -> void:
    var total: int = int(inventory.get("wood", 0)) + int(inventory.get("stone", 0)) + int(inventory.get("ore", 0))
    for i: int in range(14):
        var angle: float = TAU * float(i) / 14.0 + randf_range(-0.18, 0.18)
        _particle(pos, Vector2(cos(angle), sin(angle)) * randf_range(30.0, 66.0), Color("e0ba68"), 0.52, randf_range(2.0, 4.0), -8.0, 3.0)
    _pulse(pos, 26.0, 78.0, Color(0.93, 0.73, 0.31, 0.64), 0.55)
    _popup(pos + Vector2(0, -40), "СКЛАД +%d" % total, Color("ffe0a0"), 0.88)

func build_complete(pos: Vector2, title: String) -> void:
    for i: int in range(22):
        var angle: float = TAU * float(i) / 22.0
        var palette: Array[Color] = [Color("f3ce78"), Color("d59252"), Color("efe0af")]
        _particle(pos + Vector2(randf_range(-9.0, 9.0), randf_range(-8.0, 8.0)), Vector2(cos(angle), sin(angle)) * randf_range(48.0, 94.0), palette[i % palette.size()], 0.70, randf_range(2.0, 4.0), 48.0, 2.6)
    _pulse(pos, 28.0, 92.0, Color(1.0, 0.80, 0.35, 0.72), 0.72)
    _popup(pos + Vector2(0, -42), title, Color("ffe4a3"), 1.0)

func enemy_hit(pos: Vector2, crit: bool = false) -> void:
    var color: Color = Color("fff1b0") if crit else Color("efc07d")
    var count: int = 8 if crit else 4
    for i: int in range(count):
        _particle(pos, Vector2(randf_range(-48.0, 48.0), randf_range(-56.0, 12.0)), color, 0.22 if not crit else 0.34, randf_range(1.5, 3.0), 84.0, 3.5)

func hearth_hit(pos: Vector2) -> void:
    for i: int in range(8):
        _particle(pos + Vector2(randf_range(-18.0, 18.0), randf_range(-10.0, 10.0)), Vector2(randf_range(-34.0, 34.0), randf_range(-48.0, -12.0)), Color("d66c58"), 0.35, randf_range(2.0, 4.0), 92.0, 2.8)
    _pulse(pos, 34.0, 62.0, Color(0.88, 0.24, 0.18, 0.48), 0.34)

func turret_hit(pos: Vector2) -> void:
    for i: int in range(6):
        _particle(pos, Vector2(randf_range(-42.0, 42.0), randf_range(-42.0, 42.0)), Color("ffd36e"), 0.28, randf_range(1.5, 3.0), 0.0, 4.0)

func _particle(pos: Vector2, vel: Vector2, color: Color, life: float, size: float, gravity: float, drag: float) -> void:
    particles.append({
        "pos": pos,
        "vel": vel,
        "color": color,
        "life": life,
        "max_life": life,
        "size": size,
        "gravity": gravity,
        "drag": drag
    })

func _popup(pos: Vector2, text: String, color: Color, life: float) -> void:
    popups.append({
        "pos": pos,
        "text": text,
        "color": color,
        "life": life,
        "max_life": life
    })

func _pulse(pos: Vector2, start_radius: float, end_radius: float, color: Color, life: float) -> void:
    pulses.append({
        "pos": pos,
        "start": start_radius,
        "end": end_radius,
        "color": color,
        "life": life,
        "max_life": life
    })

func _draw() -> void:
    for p: Dictionary in pulses:
        var life: float = float(p["life"])
        var max_life: float = maxf(0.001, float(p["max_life"]))
        var t: float = 1.0 - life / max_life
        var radius: float = lerpf(float(p["start"]), float(p["end"]), t)
        var color: Color = Color(p["color"])
        color.a *= (1.0 - t)
        draw_arc(Vector2(p["pos"]), radius, 0.0, TAU, 40, color, 2.0)

    for p: Dictionary in particles:
        var life: float = float(p["life"])
        var max_life: float = maxf(0.001, float(p["max_life"]))
        var alpha: float = clampf(life / max_life, 0.0, 1.0)
        var color: Color = Color(p["color"])
        color.a *= alpha
        var size: float = float(p["size"])
        var pos: Vector2 = Vector2(p["pos"])
        draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), color)

    var font: Font = ThemeDB.fallback_font
    for popup: Dictionary in popups:
        var life: float = float(popup["life"])
        var max_life: float = maxf(0.001, float(popup["max_life"]))
        var alpha: float = clampf(life / max_life, 0.0, 1.0)
        var color: Color = Color(popup["color"])
        color.a *= alpha
        var pos: Vector2 = Vector2(popup["pos"])
        draw_string(font, pos + Vector2(-42, 0), str(popup["text"]), HORIZONTAL_ALIGNMENT_CENTER, 84, 9, color)

func _resource_color(kind: String) -> Color:
    match kind:
        "wood":
            return Color("b9854e")
        "stone":
            return Color("aab5b3")
        "ore":
            return Color("b583d1")
    return Color.WHITE

func _resource_short(kind: String) -> String:
    match kind:
        "wood":
            return "ДЕР"
        "stone":
            return "КАМ"
        "ore":
            return "РУД"
    return "РЕС"
