class_name CampView
extends Control

signal action_requested(action: String)

var elapsed: float = 0.0
var mastery: int = 0
var relics: Array = [false, false, false]
var weapons_owned: Array = ["axes"]
var selected_weapon: String = "axes"
var wins: int = 0
var title_label: Label
var meta_label: Label
var weapon_label: Label
var action_buttons: Dictionary = {}

func _ready() -> void:
    custom_minimum_size = Vector2(0, 455)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_PASS
    _build_overlay()
    refresh()
    resized.connect(_on_resized)
    set_process(true)

func refresh() -> void:
    mastery = GameState.total_mastery()
    relics = GameState.data.get("boss_relics", [false, false, false])
    weapons_owned = GameState.data.get("weapons_owned", ["axes"])
    selected_weapon = str(GameState.data.get("selected_weapon", "axes"))
    wins = int(GameState.data.get("wins", 0))

    title_label.text = GameState.camp_title().to_upper()
    meta_label.text = "Глава %s · Мастерство %d · Реликвии %d/3" % [
        "II" if GameState.chapter_one_complete() else "I",
        mastery,
        _relic_count()
    ]
    var profile: Dictionary = WeaponRules.profile(selected_weapon)
    weapon_label.text = "%s %s" % [str(profile.get("icon", "⚔️")), str(profile.get("name", "Оружие"))]

    var arsenal_button: Button = action_buttons.get("arsenal") as Button
    if arsenal_button != null:
        arsenal_button.visible = weapons_owned.size() > 1
    _layout_overlay()
    queue_redraw()

func progress_signature() -> Dictionary:
    return {
        "title": GameState.camp_title(),
        "mastery": mastery,
        "relic_count": _relic_count(),
        "forge": mastery >= 1 or _has_relic(0),
        "arsenal": weapons_owned.size() > 1,
        "watchtower": mastery >= 5,
        "stronghold": mastery >= 9,
        "residents": _resident_count(),
        "chapter": GameState.current_chapter(),
        "weapon": selected_weapon
    }

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _on_resized() -> void:
    _layout_overlay()
    queue_redraw()

func _build_overlay() -> void:
    title_label = Label.new()
    add_child(title_label)
    title_label.add_theme_font_size_override("font_size", 16)
    title_label.add_theme_color_override("font_color", Color("f3d39a"))
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    meta_label = Label.new()
    add_child(meta_label)
    meta_label.add_theme_font_size_override("font_size", 11)
    meta_label.add_theme_color_override("font_color", Color(0.82, 0.85, 0.87, 0.86))
    meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    weapon_label = Label.new()
    add_child(weapon_label)
    weapon_label.add_theme_font_size_override("font_size", 11)
    weapon_label.add_theme_color_override("font_color", Color("e9d6b5"))
    weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    _make_action_button("forge", "КУЗНЯ")
    _make_action_button("arsenal", "АРСЕНАЛ")
    _make_action_button("goals", "ТРОФЕИ")
    _make_action_button("quests", "ЗАДАНИЯ")
    _make_action_button("chronicle", "ХРОНИКА")
    _make_action_button("map", "КАРТА")

func _make_action_button(action: String, text: String) -> void:
    var button := Button.new()
    add_child(button)
    action_buttons[action] = button
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 7)
    button.add_theme_color_override("font_color", Color("f0eadf"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.05, 0.08, 0.08, 0.62), Color(0.48, 0.52, 0.46, 0.30)))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.10, 0.15, 0.14, 0.88), Color(0.78, 0.62, 0.34, 0.80)))
    button.add_theme_stylebox_override("pressed", _button_style(Color(0.09, 0.14, 0.13, 0.94), Color("d1a862")))
    button.pressed.connect(_emit_action.bind(action))

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_left = 3
    style.corner_radius_bottom_right = 3
    return style

func _emit_action(action: String) -> void:
    action_requested.emit(action)

func _layout_overlay() -> void:
    var width: float = maxf(size.x, 320.0)
    var height: float = maxf(size.y, 455.0)
    title_label.position = Vector2(12, 10)
    title_label.size = Vector2(width - 24.0, 22)
    meta_label.position = Vector2(12, 32)
    meta_label.size = Vector2(width - 24.0, 18)

    weapon_label.position = Vector2(width * 0.5 - 88.0, height - 54.0)
    weapon_label.size = Vector2(176, 18)
    weapon_label.add_theme_font_size_override("font_size", 8)

    var chronicle: Button = action_buttons.get("chronicle") as Button
    if chronicle != null:
        chronicle.position = Vector2(width * 0.50 - 38.0, 56.0)
        chronicle.size = Vector2(76, 22)

    var forge: Button = action_buttons.get("forge") as Button
    if forge != null:
        forge.position = Vector2(width * 0.27 - 34.0, height - 128.0)
        forge.size = Vector2(68, 24)

    var arsenal: Button = action_buttons.get("arsenal") as Button
    if arsenal != null:
        arsenal.position = Vector2(width * 0.73 - 37.0, height - 128.0)
        arsenal.size = Vector2(74, 24)

    var goals: Button = action_buttons.get("goals") as Button
    if goals != null:
        goals.position = Vector2(width * 0.50 - 35.0, 181.0)
        goals.size = Vector2(70, 23)

    var quests: Button = action_buttons.get("quests") as Button
    if quests != null:
        quests.position = Vector2(width * 0.14 - 35.0, height - 187.0)
        quests.size = Vector2(70, 23)

    var map: Button = action_buttons.get("map") as Button
    if map != null:
        map.position = Vector2(width * 0.88 - 31.0, height - 113.0)
        map.size = Vector2(62, 24)

func _draw() -> void:
    var width: float = maxf(size.x, 320.0)
    var height: float = maxf(size.y, 455.0)
    var hearth_y: float = height - 155.0
    _draw_background(width, height)
    _draw_path(width)

    if mastery >= 5:
        _draw_palisade(width)
    if mastery >= 9:
        _draw_stronghold(width)

    _draw_tent(Vector2(width * 0.15, hearth_y + 6.0), 1.0 + minf(0.20, float(mastery) * 0.02))
    _draw_quest_board(Vector2(width * 0.14, hearth_y - 53.0))
    if mastery >= 1 or _has_relic(0):
        _draw_forge(Vector2(width * 0.27, hearth_y + 12.0))
    if weapons_owned.size() > 1:
        _draw_weapon_rack(Vector2(width * 0.73, hearth_y + 12.0))
    if mastery >= 5:
        _draw_watchtower(Vector2(width * 0.88, hearth_y - 35.0))

    _draw_hearth(Vector2(width * 0.50, hearth_y + 5.0))
    _draw_trophies(width)
    _draw_map_board(Vector2(width * 0.88, hearth_y + 18.0))
    _draw_wanderer(Vector2(width * 0.52, hearth_y + 68.0))
    _draw_residents(width)

func _draw_background(width: float, height: float) -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), Color("0e171b"))
    for i: int in range(20):
        var t: float = float(i) / 19.0
        var color: Color = Color("18262d").lerp(Color("3f4735"), t)
        draw_rect(Rect2(0, 54.0 + t * (height - 54.0), width, (height - 54.0) / 19.0 + 1.0), color)

    var hill_back := PackedVector2Array([
        Vector2(0, 174), Vector2(width * 0.14, 120), Vector2(width * 0.31, 163),
        Vector2(width * 0.50, 106), Vector2(width * 0.70, 157), Vector2(width * 0.87, 112),
        Vector2(width, 158), Vector2(width, 265), Vector2(0, 265)
    ])
    draw_colored_polygon(hill_back, Color("213a34"))
    var hill_front := PackedVector2Array([
        Vector2(0, 224), Vector2(width * 0.18, 171), Vector2(width * 0.38, 222),
        Vector2(width * 0.58, 164), Vector2(width * 0.77, 220), Vector2(width, 178),
        Vector2(width, 310), Vector2(0, 310)
    ])
    draw_colored_polygon(hill_front, Color("2f4537"))
    draw_rect(Rect2(0, 252, width, height - 252), Color("3b4c36"))

    # Dark tree curtains at the edges frame the warm center.
    for i: int in range(5):
        var left_x: float = 13.0 + float(i) * 19.0
        var right_x: float = width - 13.0 - float(i) * 19.0
        var y: float = 173.0 + float(i % 3) * 27.0
        _draw_background_tree(Vector2(left_x, y), 0.82 + float(i % 2) * 0.18)
        _draw_background_tree(Vector2(right_x, y + 8.0), 0.78 + float((i + 1) % 2) * 0.20)

    var center := Vector2(width * 0.5, height - 150.0)
    draw_circle(center, 132.0, Color(0.95, 0.63, 0.25, 0.028))
    draw_circle(center, 82.0, Color(0.95, 0.63, 0.25, 0.034))

    for i: int in range(14):
        var x: float = fmod(31.0 + float(i) * 79.0, width)
        var y: float = 82.0 + fmod(float(i) * 41.0, 120.0)
        var pulse: float = 0.5 + sin(elapsed * 2.1 + float(i)) * 0.5
        draw_circle(Vector2(x, y), 1.0 + pulse * 0.5, Color(0.92, 0.82, 0.53, 0.12 + pulse * 0.10))

func _draw_background_tree(pos: Vector2, scale_value: float) -> void:
    draw_rect(Rect2(pos + Vector2(-3, 12) * scale_value, Vector2(6, 31) * scale_value), Color(0.10, 0.16, 0.13, 0.72))
    draw_circle(pos + Vector2(0, 0) * scale_value, 19.0 * scale_value, Color(0.08, 0.18, 0.14, 0.78))
    draw_circle(pos + Vector2(-10, 8) * scale_value, 14.0 * scale_value, Color(0.10, 0.23, 0.16, 0.72))
    draw_circle(pos + Vector2(10, 8) * scale_value, 14.0 * scale_value, Color(0.10, 0.23, 0.16, 0.72))

func _draw_path(width: float) -> void:
    var height: float = maxf(size.y, 455.0)
    var center: float = width * 0.5
    var hearth_y: float = height - 150.0
    var path := PackedVector2Array([
        Vector2(center - 24, height), Vector2(center - 38, height - 72),
        Vector2(center - 28, hearth_y + 26), Vector2(center + 29, hearth_y + 26),
        Vector2(center + 39, height - 72), Vector2(center + 24, height)
    ])
    draw_colored_polygon(path, Color(0.47, 0.39, 0.28, 0.52))
    for i: int in range(7):
        var y: float = hearth_y + 48.0 + float(i) * 18.0
        if y >= height:
            break
        var spread: float = 17.0 + float(i) * 1.7
        draw_line(Vector2(center - spread, y), Vector2(center + spread, y), Color(0.62, 0.53, 0.38, 0.18), 1.4)

func _draw_hearth(pos: Vector2) -> void:
    var pulse: float = (sin(elapsed * 3.6) + 1.0) * 0.5
    draw_circle(pos, 78.0 + pulse * 4.0, Color(1.0, 0.52, 0.18, 0.030 + pulse * 0.012))
    draw_circle(pos, 50.0 + pulse * 3.0, Color(1.0, 0.52, 0.18, 0.045 + pulse * 0.018))
    draw_circle(pos, 24.0, Color(0.20, 0.16, 0.12, 0.82))
    for i: int in range(8):
        var angle: float = TAU * float(i) / 8.0
        draw_circle(pos + Vector2(cos(angle), sin(angle)) * 22.0, 4.4, Color("7f7565"))
    draw_line(pos + Vector2(-11, 8), pos + Vector2(10, -6), Color("6f4328"), 5.0)
    draw_line(pos + Vector2(11, 8), pos + Vector2(-9, -6), Color("6f4328"), 5.0)
    var flame := PackedVector2Array([
        pos + Vector2(-8, 6), pos + Vector2(-3, -17 - pulse * 3.0),
        pos + Vector2(2, -7), pos + Vector2(8, -23 + pulse * 2.0),
        pos + Vector2(10, 7)
    ])
    draw_colored_polygon(flame, Color("ff9f3d"))
    draw_circle(pos + Vector2(1, -1), 5.0, Color("ffe486"))

func _draw_tent(pos: Vector2, scale_value: float) -> void:
    var w: float = 35.0 * scale_value
    var h: float = 39.0 * scale_value
    var tent := PackedVector2Array([
        pos + Vector2(-w, h * 0.45),
        pos + Vector2(0, -h),
        pos + Vector2(w, h * 0.45)
    ])
    draw_colored_polygon(tent, Color("7a6849"))
    draw_polyline(tent, Color("aa956d"), 2.0)
    draw_line(pos + Vector2(0, -h), pos + Vector2(0, h * 0.45), Color("4d3d2c"), 2.0)
    var entrance := PackedVector2Array([
        pos + Vector2(-8, h * 0.44), pos + Vector2(0, -2), pos + Vector2(8, h * 0.44)
    ])
    draw_colored_polygon(entrance, Color("2d2a25"))

func _draw_forge(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-29, -23), Vector2(58, 40)), Color("514b43"))
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(-34, -23), pos + Vector2(0, -43), pos + Vector2(34, -23)
    ]), Color("342e2a"))
    draw_rect(Rect2(pos + Vector2(15, -52), Vector2(10, 32)), Color("51473f"))
    var smoke_y: float = fmod(elapsed * 9.0, 22.0)
    draw_circle(pos + Vector2(20, -60 - smoke_y), 5.5, Color(0.62, 0.65, 0.64, 0.16))
    draw_circle(pos + Vector2(16, -72 - smoke_y * 0.7), 7.0, Color(0.62, 0.65, 0.64, 0.10))
    draw_rect(Rect2(pos + Vector2(-12, 1), Vector2(24, 11)), Color("302b27"))
    draw_circle(pos + Vector2(0, 5), 5.5, Color("ff7b37"))
    draw_circle(pos + Vector2(0, 5), 10.0, Color(1.0, 0.35, 0.08, 0.12))

func _draw_weapon_rack(pos: Vector2) -> void:
    draw_line(pos + Vector2(-28, 18), pos + Vector2(-23, -31), Color("5e412b"), 5.0)
    draw_line(pos + Vector2(28, 18), pos + Vector2(23, -31), Color("5e412b"), 5.0)
    draw_line(pos + Vector2(-27, -17), pos + Vector2(27, -17), Color("79563a"), 5.0)
    draw_line(pos + Vector2(-31, 16), pos + Vector2(31, 16), Color("79563a"), 4.0)
    _draw_weapon_icon(selected_weapon, pos + Vector2(0, -10), 0.82)

func _draw_weapon_icon(id: String, pos: Vector2, scale_value: float) -> void:
    if id == "spear":
        draw_line(pos + Vector2(-19, 22) * scale_value, pos + Vector2(19, -22) * scale_value, Color("77563a"), 4.0 * scale_value)
        var tip := PackedVector2Array([
            pos + Vector2(19, -22) * scale_value,
            pos + Vector2(10, -19) * scale_value,
            pos + Vector2(18, -11) * scale_value
        ])
        draw_colored_polygon(tip, Color("b9c7b0"))
    elif id == "hammer":
        draw_line(pos + Vector2(-12, 22) * scale_value, pos + Vector2(10, -17) * scale_value, Color("6e4c35"), 5.0 * scale_value)
        draw_rect(Rect2(pos + Vector2(-2, -27) * scale_value, Vector2(30, 14) * scale_value), Color("aebfd0"))
        draw_rect(Rect2(pos + Vector2(2, -24) * scale_value, Vector2(22, 4) * scale_value), Color("dce9f1"))
    elif id == "twin_blades":
        draw_line(pos + Vector2(-19, 20) * scale_value, pos + Vector2(-3, -20) * scale_value, Color("e2a073"), 5.0 * scale_value)
        draw_line(pos + Vector2(19, 20) * scale_value, pos + Vector2(3, -20) * scale_value, Color("e2a073"), 5.0 * scale_value)
        draw_line(pos + Vector2(-21, 7) * scale_value, pos + Vector2(-9, 11) * scale_value, Color("5e3e30"), 3.0 * scale_value)
        draw_line(pos + Vector2(21, 7) * scale_value, pos + Vector2(9, 11) * scale_value, Color("5e3e30"), 3.0 * scale_value)
    else:
        draw_line(pos + Vector2(-16, 20) * scale_value, pos + Vector2(8, -14) * scale_value, Color("6a4932"), 5.0 * scale_value)
        draw_line(pos + Vector2(0, -16) * scale_value, pos + Vector2(17, -22) * scale_value, Color("bfc8cb"), 7.0 * scale_value)

func _draw_quest_board(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-18, -16), Vector2(36, 26)), Color("5d412c"))
    draw_rect(Rect2(pos + Vector2(-15, -13), Vector2(30, 20)), Color("8b6945"))
    draw_rect(Rect2(pos + Vector2(-9, -9), Vector2(18, 12)), Color("c8b98f"))
    draw_line(pos + Vector2(-4, -5), pos + Vector2(5, -5), Color("62584a"), 1.0)
    draw_line(pos + Vector2(-4, -1), pos + Vector2(7, -1), Color("62584a"), 1.0)
    draw_rect(Rect2(pos + Vector2(-2, 10), Vector2(4, 15)), Color("5d412c"))

func _draw_map_board(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-20, 12), Vector2(40, 5)), Color(0.03, 0.04, 0.03, 0.20))
    draw_rect(Rect2(pos + Vector2(-17, -18), Vector2(34, 29)), Color("4f3928"))
    draw_rect(Rect2(pos + Vector2(-14, -15), Vector2(28, 23)), Color("b69a68"))
    draw_line(pos + Vector2(-10, -8), pos + Vector2(8, 3), Color("6d805b"), 2.0)
    draw_line(pos + Vector2(0, -11), pos + Vector2(10, -5), Color("80615b"), 2.0)
    draw_circle(pos + Vector2(7, 2), 2.2, Color("b4493f"))
    draw_rect(Rect2(pos + Vector2(-2, 10), Vector2(4, 14)), Color("60432c"))

func _draw_trophies(width: float) -> void:
    var positions: Array[Vector2] = [
        Vector2(width * 0.39, 134),
        Vector2(width * 0.50, 120),
        Vector2(width * 0.61, 134)
    ]
    for i: int in range(3):
        var pos: Vector2 = positions[i]
        draw_rect(Rect2(pos + Vector2(-9, 10), Vector2(18, 24)), Color("4d463c"))
        draw_rect(Rect2(pos + Vector2(-14, 31), Vector2(28, 5)), Color("686054"))
        if not _has_relic(i):
            draw_circle(pos, 7.0, Color(0.15, 0.17, 0.17, 0.62))
            draw_arc(pos, 7.0, 0, TAU, 20, Color(0.43, 0.45, 0.44, 0.48), 1.5)
            continue
        if i == 0:
            draw_circle(pos, 8.0, Color("77ba62"))
            draw_line(pos + Vector2(0, 7), pos + Vector2(0, -12), Color("4e7f40"), 3.0)
            draw_arc(pos + Vector2(0, -4), 10.0, 3.3, 6.0, 12, Color("91dc76"), 2.0)
        elif i == 1:
            var crystal := PackedVector2Array([
                pos + Vector2(0, -13), pos + Vector2(9, -2), pos + Vector2(5, 10),
                pos + Vector2(-6, 10), pos + Vector2(-10, -2)
            ])
            draw_colored_polygon(crystal, Color("9ddff4"))
            draw_polyline(crystal, Color("d9f5ff"), 1.5)
        else:
            draw_circle(pos, 9.0, Color("d35a35"))
            draw_circle(pos, 5.0, Color("ff9b4a"))
            draw_arc(pos, 13.0, 3.5, 5.9, 16, Color("f2b46e"), 2.0)

func _draw_palisade(width: float) -> void:
    var height: float = maxf(size.y, 455.0)
    var base_y: float = height - 76.0
    for i: int in range(14):
        var x: float = 12.0 + float(i) * ((width - 24.0) / 13.0)
        if absf(x - width * 0.5) < 42.0:
            continue
        var y: float = base_y + sin(float(i) * 1.8) * 3.0
        draw_line(Vector2(x, y), Vector2(x, y - 29), Color("58432f"), 6.0)
        var tip := PackedVector2Array([
            Vector2(x - 3, y - 28), Vector2(x, y - 35), Vector2(x + 3, y - 28)
        ])
        draw_colored_polygon(tip, Color("6a5037"))

func _draw_watchtower(pos: Vector2) -> void:
    draw_line(pos + Vector2(-16, 44), pos + Vector2(-11, -17), Color("5c412d"), 6.0)
    draw_line(pos + Vector2(16, 44), pos + Vector2(11, -17), Color("5c412d"), 6.0)
    draw_rect(Rect2(pos + Vector2(-24, -24), Vector2(48, 20)), Color("684c33"))
    var roof := PackedVector2Array([
        pos + Vector2(-30, -24), pos + Vector2(0, -42), pos + Vector2(30, -24)
    ])
    draw_colored_polygon(roof, Color("3c332b"))
    draw_line(pos + Vector2(-18, 11), pos + Vector2(18, 11), Color("6e5136"), 4.0)

func _draw_stronghold(width: float) -> void:
    var height: float = maxf(size.y, 455.0)
    var center: Vector2 = Vector2(width * 0.50, height - 220.0)
    draw_rect(Rect2(center + Vector2(-59, -44), Vector2(118, 57)), Color("474944"))
    draw_rect(Rect2(center + Vector2(-67, -53), Vector2(24, 68)), Color("3b403d"))
    draw_rect(Rect2(center + Vector2(43, -53), Vector2(24, 68)), Color("3b403d"))
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-63, -53), center + Vector2(-55, -67), center + Vector2(-47, -53)
    ]), Color("585d56"))
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(47, -53), center + Vector2(55, -67), center + Vector2(63, -53)
    ]), Color("585d56"))
    draw_rect(Rect2(center + Vector2(-10, -17), Vector2(20, 30)), Color("242a28"))

func _draw_wanderer(pos: Vector2) -> void:
    var bob: float = sin(elapsed * 2.0) * 0.7
    pos.y += bob
    draw_rect(Rect2(pos + Vector2(-8, 12), Vector2(17, 4)), Color(0.02, 0.03, 0.03, 0.22))
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(-6, -1), pos + Vector2(-7, 12), pos + Vector2(0, 16),
        pos + Vector2(7, 12), pos + Vector2(6, -1)
    ]), Color("344f73"))
    draw_rect(Rect2(pos + Vector2(-6, -3), Vector2(12, 12)), Color("4b6fc1"))
    draw_rect(Rect2(pos + Vector2(-5, 7), Vector2(10, 3)), Color("956d43"))
    draw_rect(Rect2(pos + Vector2(-5, -14), Vector2(10, 11)), Color("d4a077"))
    draw_rect(Rect2(pos + Vector2(-6, -16), Vector2(12, 4)), Color("3d5685"))
    draw_rect(Rect2(pos + Vector2(-5, 10), Vector2(4, 9)), Color("28343d"))
    draw_rect(Rect2(pos + Vector2(2, 10), Vector2(4, 9)), Color("28343d"))

func _draw_residents(width: float) -> void:
    var height: float = maxf(size.y, 455.0)
    var named_positions: Dictionary = {
        "mira":Vector2(width * 0.34, height - 104.0),
        "thorn":Vector2(width * 0.66, height - 102.0)
    }
    var residents: Dictionary = GameState.data.get("residents", {})
    var named_count: int = 0

    for resident_id: String in ResidentRules.ids():
        var resident: Dictionary = residents.get(resident_id, {})
        if not bool(resident.get("unlocked", false)):
            continue
        named_count += 1
        var named_pos: Vector2 = named_positions.get(resident_id, Vector2(width * 0.5, height - 100.0))
        _draw_named_resident(named_pos, resident_id)

    var ambient_positions: Array[Vector2] = [
        Vector2(width * 0.12, height - 84.0), Vector2(width * 0.84, height - 82.0),
        Vector2(width * 0.40, height - 65.0), Vector2(width * 0.61, height - 64.0)
    ]
    var ambient_count: int = maxi(0, mini(_resident_count() - named_count, ambient_positions.size()))
    for i: int in range(ambient_count):
        _draw_resident(ambient_positions[i], i + named_count)

func _draw_named_resident(pos: Vector2, resident_id: String) -> void:
    var phase_offset: float = 0.0 if resident_id == "mira" else 1.7
    var bob: float = sin(elapsed * 2.2 + phase_offset) * 1.0
    pos.y += bob

    if resident_id == "mira":
        draw_circle(pos + Vector2(0, -12), 4.5, Color("d5a47f"))
        draw_line(pos + Vector2(0, -7), pos + Vector2(0, 8), Color("5f8068"), 8.0)
        draw_line(pos + Vector2(-2, 6), pos + Vector2(-6, 14), Color("313b38"), 3.0)
        draw_line(pos + Vector2(2, 6), pos + Vector2(6, 14), Color("313b38"), 3.0)
        draw_line(pos + Vector2(-6, -5), pos + Vector2(7, -8), Color("a98d61"), 2.0)
        draw_rect(Rect2(pos + Vector2(5, -11), Vector2(4, 6)), Color("c18d58"))
    else:
        draw_circle(pos + Vector2(0, -12), 4.7, Color("c89b76"))
        draw_line(pos + Vector2(0, -7), pos + Vector2(0, 8), Color("8a654e"), 8.0)
        draw_line(pos + Vector2(-2, 6), pos + Vector2(-6, 14), Color("363536"), 3.0)
        draw_line(pos + Vector2(2, 6), pos + Vector2(6, 14), Color("363536"), 3.0)
        draw_line(pos + Vector2(5, -4), pos + Vector2(13, 8), Color("6b4933"), 3.0)
        draw_rect(Rect2(pos + Vector2(10, -1), Vector2(8, 5)), Color("9ca3a0"))


func _draw_resident(pos: Vector2, index: int) -> void:
    var bob: float = sin(elapsed * 2.2 + float(index) * 1.7) * 1.0
    pos.y += bob
    var colors: Array[Color] = [Color("6f8f72"), Color("8d6b58"), Color("667f9c"), Color("9a8559")]
    var coat: Color = colors[index % colors.size()]
    draw_circle(pos + Vector2(0, -11), 4.3, Color("d7ad86"))
    draw_line(pos + Vector2(0, -6), pos + Vector2(0, 7), coat, 7.0)
    draw_line(pos + Vector2(-2, 6), pos + Vector2(-5, 14), Color("343b3a"), 3.0)
    draw_line(pos + Vector2(2, 6), pos + Vector2(5, 14), Color("343b3a"), 3.0)

func _resident_count() -> int:
    var progression_count: int = 0
    if mastery >= 9:
        progression_count = 6
    elif mastery >= 5:
        progression_count = 4
    elif mastery >= 2:
        progression_count = 2
    elif mastery >= 1:
        progression_count = 1

    var rescued_count: int = 0
    var residents: Dictionary = GameState.data.get("residents", {})
    for resident_variant: Variant in residents.values():
        var resident: Dictionary = resident_variant as Dictionary
        if bool(resident.get("unlocked", false)):
            rescued_count += 1
    return maxi(progression_count, rescued_count)

func _relic_count() -> int:
    var count: int = 0
    for value: Variant in relics:
        if bool(value):
            count += 1
    return count

func _has_relic(index: int) -> bool:
    return index >= 0 and index < relics.size() and bool(relics[index])
