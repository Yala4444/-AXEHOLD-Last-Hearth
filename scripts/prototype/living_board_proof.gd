extends Node2D

const VIEW := Vector2(390.0, 844.0)
const PLAY_TOP := 104.0
const PLAY_BOTTOM := 806.0
const HERO_SPEED := 142.0
const TREE_POS := Vector2(300.0, 326.0)
const HEARTH_POS := Vector2(102.0, 630.0)
const TOWER_POS := Vector2(292.0, 646.0)

var hero_pos := Vector2(194.0, 534.0)
var hero_target := Vector2(194.0, 534.0)
var facing := 1.0
var walk_time := 0.0
var world_time := 0.0
var action_time := 0.0
var hit_stop := 0.0
var tree_hp := 4
var cargo := 0
var delivered := 0
var build_stage := 0
var state := "seek_tree"
var particles: Array[Dictionary] = []
var tokens: Array[Dictionary] = []
var ripples: Array[Dictionary] = []
var hint_label: Label
var objective_label: Label
var cargo_label: Label
var toast_label: Label
var toast_time := 0.0
var touch_active := false

func _ready() -> void:
    _build_hud()
    _set_objective("ДОБУДЬ 3 БРЕВНА", "Коснись поляны, чтобы идти к отмеченному дереву")
    queue_redraw()

func art_direction_contract() -> String:
    return "LIVING_ILLUSTRATED_BOARD_GAME_A"

func proof_loop_contract() -> PackedStringArray:
    return PackedStringArray(["move", "chop", "collect", "carry", "deliver", "build"])

func _process(delta: float) -> void:
    world_time += delta
    toast_time = maxf(0.0, toast_time - delta)
    toast_label.modulate.a = clampf(toast_time * 2.0, 0.0, 1.0)
    if hit_stop > 0.0:
        hit_stop = maxf(0.0, hit_stop - delta)
        _update_particles(delta * 0.16)
        queue_redraw()
        return
    _read_keyboard()
    _move_hero(delta)
    _update_action(delta)
    _update_tokens(delta)
    _update_particles(delta)
    _update_ripples(delta)
    _update_hud()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        touch_active = touch.pressed
        if touch.pressed:
            _set_target(touch.position)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        _set_target(drag.position)
    elif event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
            _set_target(mouse.position)

func _set_target(at: Vector2) -> void:
    if at.y < PLAY_TOP or at.y > PLAY_BOTTOM:
        return
    hero_target = Vector2(clampf(at.x, 30.0, 360.0), clampf(at.y, PLAY_TOP + 20.0, PLAY_BOTTOM - 18.0))
    ripples.append({"pos": hero_target, "life": 0.65})

func _read_keyboard() -> void:
    var axis := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if axis.length() > 0.05:
        hero_target = hero_pos + axis.normalized() * 72.0

func _move_hero(delta: float) -> void:
    if action_time > 0.0:
        return
    var offset := hero_target - hero_pos
    if offset.length() < 3.0:
        return
    var step := minf(HERO_SPEED * delta, offset.length())
    hero_pos += offset.normalized() * step
    facing = signf(offset.x) if absf(offset.x) > 2.0 else facing
    walk_time += delta * 8.6

func _update_action(delta: float) -> void:
    var at_tree := hero_pos.distance_to(TREE_POS + Vector2(-38.0, 40.0)) < 78.0
    var at_hearth := hero_pos.distance_to(HEARTH_POS + Vector2(58.0, 8.0)) < 86.0
    if state == "seek_tree" and at_tree:
        hero_target = hero_pos
        action_time = 0.82
        state = "chopping"
        hint_label.text = "Хорошая позиция — Странник замахивается сам"
    elif state == "chopping":
        action_time -= delta
        if action_time <= 0.0:
            _strike_tree()
    elif state == "carry" and at_hearth:
        hero_target = hero_pos
        state = "delivering"
        action_time = 0.55
        _set_objective("ДОСТАВКА", "Древесина летит в постройку")
    elif state == "delivering":
        action_time -= delta
        if action_time <= 0.0:
            _deliver_wood()

func _strike_tree() -> void:
    tree_hp -= 1
    hit_stop = 0.075
    _burst(TREE_POS + Vector2(-24.0, 26.0), Color("e9b75f"), 9, 88.0)
    _burst(TREE_POS + Vector2(-14.0, 10.0), Color("89a84d"), 5, 54.0)
    if tree_hp > 0:
        action_time = 0.82
        state = "chopping"
        _toast("УДАР %d/4" % (4 - tree_hp))
    else:
        state = "collecting"
        _toast("ДЕРЕВО ПОВАЛЕНО")
        for i: int in range(3):
            tokens.append({
                "pos": TREE_POS + Vector2(-30.0 + i * 24.0, 50.0 + (i % 2) * 8.0),
                "from": TREE_POS + Vector2(-30.0 + i * 24.0, 50.0 + (i % 2) * 8.0),
                "target": hero_pos + Vector2(0.0, -18.0),
                "t": -float(i) * 0.14,
                "mode": "collect"
            })
        _set_objective("СБОР", "Брёвна сами укладываются в рюкзак")

func _deliver_wood() -> void:
    var count := cargo
    cargo = 0
    for i: int in range(count):
        tokens.append({
            "pos": hero_pos + Vector2(0.0, -18.0),
            "from": hero_pos + Vector2(0.0, -18.0),
            "target": TOWER_POS,
            "t": -float(i) * 0.12,
            "mode": "deliver"
        })
    action_time = 0.0

func _update_tokens(delta: float) -> void:
    for i: int in range(tokens.size() - 1, -1, -1):
        var token: Dictionary = tokens[i]
        token["t"] = float(token["t"]) + delta * 1.85
        var t: float = float(token["t"])
        if t < 0.0:
            tokens[i] = token
            continue
        var eased := clampf(t, 0.0, 1.0)
        var from: Vector2 = token["from"]
        var target: Vector2 = hero_pos + Vector2(0.0, -20.0) if str(token["mode"]) == "collect" else token["target"]
        token["pos"] = from.lerp(target, eased) + Vector2(0.0, -sin(eased * PI) * 42.0)
        tokens[i] = token
        if t >= 1.0:
            var mode := str(token["mode"])
            tokens.remove_at(i)
            if mode == "collect":
                cargo += 1
                _burst(hero_pos + Vector2(0.0, -20.0), Color("ffd36a"), 4, 32.0)
                if cargo == 3:
                    state = "carry"
                    _set_objective("ОТНЕСИ ДРЕВЕСИНУ", "Вернись к тёплому Очагу слева внизу")
                    hero_target = HEARTH_POS + Vector2(64.0, 4.0)
            else:
                delivered += 1
                build_stage = delivered
                _burst(TOWER_POS, Color("ffd87b"), 7, 58.0)
                if delivered >= 3:
                    state = "complete"
                    _set_objective("ПЕРВАЯ БАШНЯ ГОТОВА", "Мир изменился благодаря твоему действию")
                    _toast("РУБЕЖ УКРЕПЛЁН")

func _update_particles(delta: float) -> void:
    for i: int in range(particles.size() - 1, -1, -1):
        var p: Dictionary = particles[i]
        p["life"] = float(p["life"]) - delta
        if float(p["life"]) <= 0.0:
            particles.remove_at(i)
            continue
        p["vel"] = Vector2(p["vel"]) + Vector2(0.0, 120.0) * delta
        p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
        particles[i] = p

func _update_ripples(delta: float) -> void:
    for i: int in range(ripples.size() - 1, -1, -1):
        ripples[i]["life"] = float(ripples[i]["life"]) - delta
        if float(ripples[i]["life"]) <= 0.0:
            ripples.remove_at(i)

func _burst(at: Vector2, color: Color, count: int, speed: float) -> void:
    for i: int in range(count):
        var angle := randf_range(-PI, 0.1)
        particles.append({
            "pos": at,
            "vel": Vector2(cos(angle), sin(angle)) * randf_range(speed * 0.45, speed),
            "life": randf_range(0.34, 0.72),
            "max": 0.72,
            "color": color,
            "size": randf_range(2.0, 5.5)
        })

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 20
    add_child(layer)

    var top := PanelContainer.new()
    layer.add_child(top)
    top.position = Vector2(10.0, 10.0)
    top.size = Vector2(370.0, 78.0)
    top.add_theme_stylebox_override("panel", _panel(Color("fff8df"), Color("b78a4e"), 18, 2))
    var row := HBoxContainer.new()
    top.add_child(row)
    row.add_theme_constant_override("separation", 9)
    var back := Button.new()
    row.add_child(back)
    back.text = "‹"
    back.custom_minimum_size = Vector2(44.0, 48.0)
    back.focus_mode = Control.FOCUS_NONE
    back.add_theme_font_size_override("font_size", 28)
    back.add_theme_color_override("font_color", Color("5d432d"))
    back.add_theme_stylebox_override("normal", _panel(Color("f5e4b9"), Color("c99d61"), 22, 1))
    back.add_theme_stylebox_override("pressed", _panel(Color("e8cd91"), Color("9c7041"), 22, 2))
    back.pressed.connect(_return_home)
    var copy := VBoxContainer.new()
    row.add_child(copy)
    copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    copy.add_theme_constant_override("separation", 1)
    objective_label = Label.new()
    copy.add_child(objective_label)
    objective_label.text = "ДОБУДЬ 3 БРЕВНА"
    objective_label.add_theme_font_size_override("font_size", 12)
    objective_label.add_theme_color_override("font_color", Color("493b2b"))
    hint_label = Label.new()
    copy.add_child(hint_label)
    hint_label.text = "Коснись поляны, чтобы идти"
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.add_theme_font_size_override("font_size", 8)
    hint_label.add_theme_color_override("font_color", Color("78654c"))
    cargo_label = Label.new()
    row.add_child(cargo_label)
    cargo_label.custom_minimum_size = Vector2(58.0, 44.0)
    cargo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cargo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    cargo_label.text = "БРЁВНА\n0 / 3"
    cargo_label.add_theme_font_size_override("font_size", 8)
    cargo_label.add_theme_color_override("font_color", Color("75472b"))
    cargo_label.add_theme_stylebox_override("normal", _panel(Color("f3dfad"), Color("c08d4e"), 10, 1))

    toast_label = Label.new()
    layer.add_child(toast_label)
    toast_label.position = Vector2(74.0, 112.0)
    toast_label.size = Vector2(242.0, 36.0)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size", 10)
    toast_label.add_theme_color_override("font_color", Color("fff4ce"))
    toast_label.add_theme_stylebox_override("normal", _panel(Color(0.20, 0.28, 0.16, 0.92), Color(0.96, 0.78, 0.40, 0.62), 16, 1))
    toast_label.modulate.a = 0.0

    var footer := Label.new()
    layer.add_child(footer)
    footer.position = Vector2(84.0, 808.0)
    footer.size = Vector2(222.0, 26.0)
    footer.text = "ЖИВАЯ ИЛЛЮСТРИРОВАННАЯ ИГРА · A"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 7)
    footer.add_theme_color_override("font_color", Color("ede0b7"))
    footer.add_theme_stylebox_override("normal", _panel(Color(0.17, 0.23, 0.13, 0.78), Color(0.9, 0.75, 0.4, 0.32), 13, 1))

func _set_objective(title: String, hint: String) -> void:
    if objective_label != null:
        objective_label.text = title
    if hint_label != null:
        hint_label.text = hint

func _update_hud() -> void:
    if cargo_label != null:
        cargo_label.text = "БРЁВНА\n%d / 3" % cargo

func _toast(text: String) -> void:
    toast_label.text = text
    toast_time = 1.3

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 10.0
    style.content_margin_right = 10.0
    style.content_margin_top = 7.0
    style.content_margin_bottom = 7.0
    return style

func _return_home() -> void:
    get_tree().change_scene_to_file("res://scenes/app.tscn")

func _draw() -> void:
    _draw_ground()
    _draw_water()
    _draw_paths()
    _draw_scenery()
    _draw_hearth()
    _draw_tower()
    _draw_tree()
    _draw_target_marker()
    _draw_hero()
    _draw_tokens()
    _draw_particles()

func _draw_ground() -> void:
    draw_rect(Rect2(Vector2.ZERO, VIEW), Color("8fb76b"))
    draw_rect(Rect2(0.0, PLAY_TOP, 390.0, PLAY_BOTTOM - PLAY_TOP), Color("9fc979"))
    for y: int in range(126, 806, 34):
        for x: int in range(14, 390, 38):
            var n := sin(float(x) * 0.071 + float(y) * 0.043)
            var pos := Vector2(float(x) + n * 7.0, float(y) + cos(float(x + y)) * 3.0)
            var tint := Color("83ad65") if n > 0.0 else Color("b4d78e")
            draw_line(pos, pos + Vector2(2.0, -5.0), Color(tint, 0.46), 1.2)
    draw_circle(Vector2(202.0, 442.0), 108.0, Color(0.83, 0.88, 0.52, 0.16))
    draw_circle(HEARTH_POS, 126.0, Color(1.0, 0.82, 0.36, 0.08))

func _draw_water() -> void:
    var river := PackedVector2Array([
        Vector2(0, 185), Vector2(52, 174), Vector2(92, 194), Vector2(130, 230),
        Vector2(143, 285), Vector2(128, 342), Vector2(92, 383), Vector2(56, 424),
        Vector2(36, 478), Vector2(45, 526), Vector2(78, 567), Vector2(111, 592),
        Vector2(119, 620), Vector2(91, 634), Vector2(58, 611), Vector2(22, 573), Vector2(0, 556)
    ])
    draw_colored_polygon(river, Color("72b6a3"))
    draw_polyline(river, Color("d7e8bd"), 4.0, true)
    for y: float in [214.0, 286.0, 372.0, 475.0, 548.0]:
        var x := 72.0 + sin(y * 0.04) * 28.0
        draw_arc(Vector2(x, y), 18.0, 0.2, 2.7, 16, Color(0.82, 0.95, 0.86, 0.48), 1.5)

func _draw_paths() -> void:
    var path := PackedVector2Array([
        Vector2(176, 810), Vector2(174, 744), Vector2(153, 684), Vector2(142, 615),
        Vector2(170, 551), Vector2(217, 493), Vector2(244, 431), Vector2(269, 367), Vector2(299, 318)
    ])
    draw_polyline(path, Color("d7bd78"), 47.0, true)
    draw_polyline(path, Color("e9d69b"), 35.0, true)
    var branch := PackedVector2Array([Vector2(147, 645), Vector2(205, 661), Vector2(292, 646)])
    draw_polyline(branch, Color("d7bd78"), 37.0, true)
    draw_polyline(branch, Color("ead79c"), 27.0, true)
    for p: Vector2 in path:
        draw_circle(p + Vector2(9.0, 3.0), 2.2, Color(0.55, 0.41, 0.22, 0.22))

func _draw_scenery() -> void:
    _draw_canopy(Vector2(22, 132), 48.0, Color("3f7445"))
    _draw_canopy(Vector2(365, 150), 54.0, Color("3e7548"))
    _draw_canopy(Vector2(355, 772), 63.0, Color("467d45"))
    _draw_canopy(Vector2(18, 757), 49.0, Color("4d844b"))
    _draw_canopy(Vector2(344, 493), 38.0, Color("568c4d"))
    _draw_bush(Vector2(226, 182), 1.0)
    _draw_bush(Vector2(194, 310), 0.8)
    _draw_bush(Vector2(332, 592), 0.75)
    _draw_bush(Vector2(66, 686), 0.72)
    _draw_rock(Vector2(205, 709), 1.0)
    _draw_rock(Vector2(332, 236), 0.8)
    for p: Vector2 in [Vector2(173,196), Vector2(238,267), Vector2(348,389), Vector2(212,596), Vector2(54,535), Vector2(253,759)]:
        _draw_flower(p)

func _draw_canopy(at: Vector2, radius: float, tint: Color) -> void:
    draw_circle(at + Vector2(4, 10), radius * 0.86, Color(0.18, 0.30, 0.18, 0.24))
    for i: int in range(9):
        var a := TAU * float(i) / 9.0
        var pos := at + Vector2(cos(a), sin(a)) * radius * 0.42
        draw_circle(pos, radius * 0.45, tint.lightened(0.04 * float(i % 3)))
    draw_circle(at + Vector2(-10, -9), radius * 0.34, tint.lightened(0.16))
    draw_arc(at, radius * 0.78, 0.0, TAU, 30, Color(0.16, 0.30, 0.14, 0.5), 2.0)

func _draw_bush(at: Vector2, scale: float) -> void:
    draw_circle(at + Vector2(3, 5) * scale, 23.0 * scale, Color(0.18, 0.30, 0.14, 0.22))
    for o: Vector2 in [Vector2(-14,3), Vector2(0,-7), Vector2(15,2), Vector2(2,10)]:
        draw_circle(at + o * scale, 13.0 * scale, Color("5c954f"))
    draw_circle(at + Vector2(-5,-9) * scale, 6.0 * scale, Color("87b95f"))

func _draw_rock(at: Vector2, scale: float) -> void:
    var points := PackedVector2Array([Vector2(-16,8), Vector2(-11,-8), Vector2(3,-14), Vector2(16,-4), Vector2(13,11), Vector2(-4,15)])
    for i: int in range(points.size()):
        points[i] = at + points[i] * scale
    draw_colored_polygon(points, Color("81947c"))
    draw_polyline(points, Color("556b59"), 2.0, true)
    draw_line(at + Vector2(-8,-5) * scale, at + Vector2(4,-9) * scale, Color("b7c4a1"), 2.0)

func _draw_flower(at: Vector2) -> void:
    var c := Color("fff0a5") if int(at.x) % 2 == 0 else Color("f3a0a4")
    draw_line(at, at + Vector2(0, 7), Color("4f7b42"), 1.0)
    for i: int in range(5):
        draw_circle(at + Vector2.from_angle(TAU * i / 5.0) * 3.2, 2.0, c)
    draw_circle(at, 1.5, Color("d99a3a"))

func _draw_hearth() -> void:
    var pulse := 1.0 + sin(world_time * 5.0) * 0.04
    draw_circle(HEARTH_POS + Vector2(0, 7), 52.0, Color(0.18, 0.24, 0.12, 0.22))
    draw_circle(HEARTH_POS, 44.0, Color("8a6840"))
    draw_circle(HEARTH_POS, 37.0, Color("d2b06c"))
    for i: int in range(9):
        var p := HEARTH_POS + Vector2.from_angle(TAU * i / 9.0) * 34.0
        draw_circle(p, 8.0, Color("6d5840"))
        draw_circle(p + Vector2(-2,-2), 4.0, Color("a58b60"))
    draw_line(HEARTH_POS + Vector2(-20,9), HEARTH_POS + Vector2(19,-10), Color("704226"), 8.0)
    draw_line(HEARTH_POS + Vector2(-18,-10), HEARTH_POS + Vector2(20,10), Color("704226"), 8.0)
    var flame := PackedVector2Array([
        HEARTH_POS + Vector2(-15,13), HEARTH_POS + Vector2(-13,-7) * pulse,
        HEARTH_POS + Vector2(-4,-28) * pulse, HEARTH_POS + Vector2(2,-9),
        HEARTH_POS + Vector2(12,-23) * pulse, HEARTH_POS + Vector2(17,12)
    ])
    draw_colored_polygon(flame, Color("f08b35"))
    draw_colored_polygon(PackedVector2Array([HEARTH_POS+Vector2(-7,11),HEARTH_POS+Vector2(0,-16)*pulse,HEARTH_POS+Vector2(8,11)]), Color("ffd76a"))
    for i: int in range(3):
        var spark := HEARTH_POS + Vector2(-8 + i * 8, -34 - fmod(world_time * (18 + i * 4) + i * 11, 22.0))
        draw_circle(spark, 2.0, Color(1.0, 0.77, 0.28, 0.7))

func _draw_tower() -> void:
    draw_circle(TOWER_POS + Vector2(0,8), 38.0, Color(0.20,0.25,0.13,0.2))
    draw_arc(TOWER_POS, 29.0, 0.0, TAU, 34, Color("af8552"), 4.0)
    draw_arc(TOWER_POS, 23.0, 0.0, TAU, 34, Color(0.95,0.84,0.58,0.55), 2.0)
    if build_stage >= 1:
        draw_line(TOWER_POS + Vector2(-18,12), TOWER_POS + Vector2(-18,-25), Color("70462a"), 9.0)
        draw_circle(TOWER_POS + Vector2(-18,-25), 5.0, Color("b8783e"))
    if build_stage >= 2:
        draw_line(TOWER_POS + Vector2(18,12), TOWER_POS + Vector2(18,-25), Color("70462a"), 9.0)
        draw_circle(TOWER_POS + Vector2(18,-25), 5.0, Color("b8783e"))
        draw_line(TOWER_POS + Vector2(-22,-17), TOWER_POS + Vector2(22,-17), Color("9c6334"), 8.0)
    if build_stage >= 3:
        var deck := PackedVector2Array([TOWER_POS+Vector2(-29,-20),TOWER_POS+Vector2(0,-35),TOWER_POS+Vector2(29,-20),TOWER_POS+Vector2(0,-6)])
        draw_colored_polygon(deck, Color("b7773b"))
        draw_polyline(deck, Color("684229"), 3.0, true)
        draw_line(TOWER_POS + Vector2(0,-34), TOWER_POS + Vector2(0,-62), Color("745037"), 3.0)
        draw_colored_polygon(PackedVector2Array([TOWER_POS+Vector2(1,-62),TOWER_POS+Vector2(23,-55),TOWER_POS+Vector2(1,-47)]), Color("d86546"))

func _draw_tree() -> void:
    var recoil := 0.0
    if state == "chopping" and action_time < 0.18:
        recoil = sin(action_time * 80.0) * 3.0
    var at := TREE_POS + Vector2(recoil, 0)
    if tree_hp <= 0:
        draw_circle(at + Vector2(5, 25), 26.0, Color(0.18,0.25,0.13,0.22))
        draw_rect(Rect2(at + Vector2(-14,15), Vector2(28,17)), Color("81502f"))
        _ellipse(at + Vector2(0,15), Vector2(16,8), Color("d29a55"))
        draw_circle(at + Vector2(0,15), 7.0, Color("9d6638"), false, 2.0)
        return
    _ellipse(at + Vector2(4, 38), Vector2(45, 17), Color(0.18,0.25,0.13,0.22))
    draw_colored_polygon(PackedVector2Array([at+Vector2(-14,40),at+Vector2(-10,-15),at+Vector2(11,-16),at+Vector2(17,41)]), Color("80502f"))
    draw_line(at + Vector2(-4,30), at + Vector2(2,-12), Color("b77b43"), 5.0)
    if tree_hp < 4:
        draw_line(at + Vector2(-14,22), at + Vector2(1,15), Color("f0c06b"), 4.0)
        draw_line(at + Vector2(-14,22), at + Vector2(1,28), Color("5f3826"), 3.0)
    var canopy_color := Color("4f8745")
    for i: int in range(11):
        var a := TAU * float(i) / 11.0
        var p := at + Vector2(cos(a) * 35.0, sin(a) * 27.0 - 30.0)
        draw_circle(p, 25.0, canopy_color.lightened(0.035 * float(i % 3)))
    draw_circle(at + Vector2(-12,-47), 19.0, Color("78a957"))
    draw_arc(at + Vector2(0,-30), 46.0, 0.0, TAU, 32, Color(0.18,0.34,0.16,0.7), 2.5)

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i: int in range(25):
        var a := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
    draw_colored_polygon(points, color)

func _draw_target_marker() -> void:
    for ripple_variant: Dictionary in ripples:
        var life: float = float(ripple_variant["life"])
        var radius := 10.0 + (0.65 - life) * 25.0
        draw_arc(ripple_variant["pos"], radius, 0.0, TAU, 28, Color(1.0,0.92,0.62,life), 2.0)
    if state == "seek_tree" or state == "chopping":
        var pulse := 5.0 + sin(world_time * 4.0) * 2.0
        draw_arc(TREE_POS + Vector2(0,42), 50.0 + pulse, 0.2, PI - 0.2, 24, Color(1.0,0.86,0.36,0.76), 3.0)
    elif state == "carry":
        draw_arc(HEARTH_POS, 57.0 + sin(world_time*4.0)*3.0, 0.0, TAU, 30, Color(1.0,0.79,0.31,0.7), 3.0)

func _draw_hero() -> void:
    var moving := hero_pos.distance_to(hero_target) > 4.0 and action_time <= 0.0
    var stride := sin(walk_time) if moving else 0.0
    var bob := absf(sin(walk_time)) * 2.3 if moving else sin(world_time * 2.0) * 0.7
    var attack := 0.0
    if state == "chopping":
        var phase := clampf(1.0 - action_time / 0.82, 0.0, 1.0)
        attack = sin(phase * PI) * 1.4
    var at := hero_pos + Vector2(0, -bob)
    _ellipse(hero_pos + Vector2(0,15), Vector2(22,9), Color(0.16,0.22,0.12,0.28))
    draw_set_transform(at, 0.0, Vector2(facing, 1.0))
    draw_line(Vector2(-7,10), Vector2(-9 + stride*5.0,25), Color("453328"), 7.0)
    draw_line(Vector2(7,10), Vector2(9 - stride*5.0,25), Color("453328"), 7.0)
    draw_circle(Vector2(-10 + stride*5.0,26), 5.0, Color("2d2926"))
    draw_circle(Vector2(10 - stride*5.0,26), 5.0, Color("2d2926"))
    var cloak := PackedVector2Array([Vector2(-17,-15),Vector2(-23,15+stride*2),Vector2(-5,21),Vector2(1,8),Vector2(16,19),Vector2(18,-12)])
    draw_colored_polygon(cloak, Color("b9573f"))
    draw_polyline(cloak, Color("74352f"), 2.0, true)
    draw_colored_polygon(PackedVector2Array([Vector2(-13,-14),Vector2(13,-14),Vector2(16,11),Vector2(0,17),Vector2(-15,10)]), Color("496557"))
    draw_line(Vector2(-12,-8), Vector2(12,7), Color("c49352"), 4.0)
    draw_circle(Vector2(0,-20), 13.0, Color("d5aa72"))
    draw_colored_polygon(PackedVector2Array([Vector2(-15,-25),Vector2(-8,-39),Vector2(7,-42),Vector2(16,-25),Vector2(11,-14),Vector2(-12,-14)]), Color("a64b38"))
    draw_polyline(PackedVector2Array([Vector2(-15,-25),Vector2(-8,-39),Vector2(7,-42),Vector2(16,-25)]), Color("6d332d"), 2.0)
    draw_circle(Vector2(6,-21), 2.4, Color("f2c96f"))
    draw_line(Vector2(12,-5), Vector2(21 + attack*10.0,-1-attack*12.0), Color("d1a36f"), 6.0)
    var hand := Vector2(22 + attack*10.0,-2-attack*12.0)
    draw_line(hand, hand + Vector2(13,-14).rotated(-attack), Color("6a4329"), 4.0)
    var axe_head := hand + Vector2(13,-14).rotated(-attack)
    draw_colored_polygon(PackedVector2Array([axe_head+Vector2(-2,-7),axe_head+Vector2(11,-4),axe_head+Vector2(8,5),axe_head+Vector2(-3,4)]), Color("d5ddd0"))
    draw_polyline(PackedVector2Array([axe_head+Vector2(-2,-7),axe_head+Vector2(11,-4),axe_head+Vector2(8,5),axe_head+Vector2(-3,4)]), Color("56665f"), 1.5, true)
    if cargo > 0:
        draw_rect(Rect2(Vector2(-21,-4),Vector2(10,21)), Color("795033"))
        for i: int in range(cargo):
            draw_line(Vector2(-20+i*3,-5), Vector2(-20+i*3,-17), Color("a86d39"), 3.0)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_tokens() -> void:
    for token: Dictionary in tokens:
        var at: Vector2 = token["pos"]
        _ellipse(at + Vector2(0,4), Vector2(11,4), Color(0.18,0.22,0.12,0.18))
        draw_line(at + Vector2(-10,0), at + Vector2(10,0), Color("9f6436"), 8.0)
        draw_circle(at + Vector2(-10,0), 4.0, Color("d09550"))
        draw_circle(at + Vector2(-10,0), 2.0, Color("82502e"), false, 1.0)

func _draw_particles() -> void:
    for p: Dictionary in particles:
        var alpha := clampf(float(p["life"]) / float(p["max"]), 0.0, 1.0)
        draw_circle(p["pos"], float(p["size"]) * alpha, Color(Color(p["color"]), alpha))
