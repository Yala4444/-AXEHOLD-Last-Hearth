class_name CoreFX
extends Node2D

var particles: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var pulses: Array[Dictionary] = []
var pickups: Array[Dictionary] = []

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

    for i: int in range(pickups.size() - 1, -1, -1):
        var pickup: Dictionary = pickups[i]
        pickup["life"] = float(pickup["life"]) - delta
        if float(pickup["life"]) <= 0.0:
            pickups.remove_at(i)
            continue
        var duration: float = maxf(0.001, float(pickup["duration"]))
        var t: float = clampf(1.0 - float(pickup["life"]) / duration, 0.0, 1.0)
        var start: Vector2 = pickup["start"] as Vector2
        var control: Vector2 = pickup["control"] as Vector2
        var target: Vector2 = pickup["target"] as Vector2
        var a: Vector2 = start.lerp(control, t)
        var b: Vector2 = control.lerp(target, t)
        pickup["pos"] = a.lerp(b, t)
        pickups[i] = pickup

    if not particles.is_empty() or not popups.is_empty() or not pulses.is_empty() or not pickups.is_empty():
        queue_redraw()

func harvest(kind: String, pos: Vector2, amount: int, target: Vector2) -> void:
    var color: Color = _resource_color(kind)
    for i: int in range(7):
        var angle: float = TAU * float(i) / 7.0 + randf_range(-0.25, 0.25)
        var speed: float = randf_range(32.0, 66.0)
        _particle(pos, Vector2(cos(angle), sin(angle)) * speed + Vector2(0, -16), color, randf_range(0.28, 0.42), randf_range(1.8, 3.2), 72.0, 2.6)

    var token_count: int = clampi(int(ceil(float(amount) / 2.0)), 2, 5)
    for i: int in range(token_count):
        var start: Vector2 = pos + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
        var arc: Vector2 = start.lerp(target, 0.5) + Vector2(randf_range(-18.0, 18.0), randf_range(-42.0, -24.0))
        _pickup(start, target, arc, color.lightened(0.08), 0.30 + float(i) * 0.035, 4.0)

    _popup(pos + Vector2(0, -18), "+%d %s" % [amount, _resource_short(kind)], color.lightened(0.22), 0.62)

func deposit(inventory: Dictionary, from_pos: Vector2, target: Vector2) -> void:
    var total: int = int(inventory.get("wood", 0)) + int(inventory.get("stone", 0)) + int(inventory.get("ore", 0))
    var kinds: Array[String] = ["wood", "stone", "ore"]
    var token_index: int = 0
    for kind: String in kinds:
        var amount: int = int(inventory.get(kind, 0))
        if amount <= 0:
            continue
        var token_count: int = clampi(int(ceil(float(amount) / 4.0)), 1, 5)
        for _i: int in range(token_count):
            var start: Vector2 = from_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 5.0))
            var control: Vector2 = start.lerp(target, 0.5) + Vector2(randf_range(-20.0, 20.0), -34.0 - randf_range(0.0, 18.0))
            _pickup(start, target, control, _resource_color(kind), 0.30 + float(token_index) * 0.018, 4.2)
            token_index += 1

    _pulse(target, 22.0, 68.0, Color(0.93, 0.73, 0.31, 0.58), 0.48)
    _popup(target + Vector2(0, -26), "СКЛАД +%d" % total, Color("ffe0a0"), 0.82)

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

func spear_thrust(from_pos: Vector2, to_pos: Vector2) -> void:
    var delta: Vector2 = to_pos - from_pos
    var length: float = delta.length()
    if length <= 1.0:
        return
    var direction: Vector2 = delta / length
    var side := Vector2(-direction.y, direction.x)
    for i: int in range(9):
        var t: float = float(i + 1) / 10.0
        var pos: Vector2 = from_pos.lerp(to_pos, t)
        _particle(pos, side * randf_range(-18.0, 18.0), Color("a8d49f"), 0.16 + t * 0.08, 2.0 + t * 1.2, 0.0, 5.0)
    _particle(to_pos, direction * 28.0, Color("e0f0d6"), 0.22, 4.0, 0.0, 5.0)

func hammer_slam(pos: Vector2, radius: float) -> void:
    _pulse(pos, 15.0, radius, Color(0.52, 0.80, 0.94, 0.58), 0.32)
    for i: int in range(16):
        var angle: float = TAU * float(i) / 16.0
        var direction := Vector2(cos(angle), sin(angle))
        _particle(pos + direction * 10.0, direction * randf_range(42.0, 82.0), Color("b8d8e8"), 0.28, randf_range(1.8, 3.2), 26.0, 3.2)

func blade_flurry(pos: Vector2, direction: Vector2, combo: int) -> void:
    var dir: Vector2 = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
    var side := Vector2(-dir.y, dir.x)
    var count: int = 5 + mini(5, combo)
    for i: int in range(count):
        var sign_value: float = -1.0 if i % 2 == 0 else 1.0
        var start: Vector2 = pos + dir * randf_range(8.0, 20.0) + side * sign_value * randf_range(2.0, 10.0)
        _particle(start, dir * randf_range(36.0, 70.0) + side * sign_value * randf_range(18.0, 42.0), Color("f0a06f"), 0.18, 2.2, 0.0, 5.0)

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

func _pickup(start: Vector2, target: Vector2, control: Vector2, color: Color, duration: float, size: float) -> void:
    pickups.append({
        "start": start,
        "pos": start,
        "target": target,
        "control": control,
        "color": color,
        "life": duration,
        "duration": duration,
        "size": size
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

    for pickup: Dictionary in pickups:
        var pos: Vector2 = pickup["pos"] as Vector2
        var color: Color = pickup["color"] as Color
        var life: float = float(pickup["life"])
        var duration: float = maxf(0.001, float(pickup["duration"]))
        var alpha: float = clampf(life / duration, 0.0, 1.0)
        color.a *= minf(1.0, alpha * 1.8)
        var size: float = float(pickup["size"])
        draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), color)
        draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), color.lightened(0.22), false, 1.0)

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
