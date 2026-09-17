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
    custom_minimum_size = Vector2(0, 362)
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
    meta_label.text = "Мастерство %d · Реликвии %d/3 · Победы %d" % [mastery, _relic_count(), wins]
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

    _make_action_button("forge", "⚒ Кузница")
    _make_action_button("arsenal", "⚔ Арсенал")
    _make_action_button("goals", "🏆 Трофеи")
    _make_action_button("map", "🗺 Карта")

func _make_action_button(action: String, text: String) -> void:
    var button := Button.new()
    add_child(button)
    action_buttons[action] = button
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 11)
    button.add_theme_color_override("font_color", Color("f0eadf"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.11, 0.13, 0.76), Color(0.38, 0.45, 0.48, 0.42)))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.18, 0.19, 0.94), Color(0.70, 0.56, 0.34, 0.85)))
    button.add_theme_stylebox_override("pressed", _button_style(Color(0.09, 0.15, 0.15, 1.0), Color("d1a862")))
    button.pressed.connect(_emit_action.bind(action))

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    return style

func _emit_action(action: String) -> void:
    action_requested.emit(action)

func _layout_overlay() -> void:
    var width: float = maxf(size.x, 320.0)
    title_label.position = Vector2(12, 12)
    title_label.size = Vector2(width - 24.0, 24)
    meta_label.position = Vector2(12, 37)
    meta_label.size = Vector2(width - 24.0, 20)
    weapon_label.position = Vector2(width * 0.5 - 92.0, 261)
    weapon_label.size = Vector2(184, 22)

    var visible_actions: Array[String] = ["forge"]
    if weapons_owned.size() > 1:
        visible_actions.append("arsenal")
    visible_actions.append("goals")
    visible_actions.append("map")
    var gap: float = 6.0
    var button_width: float = (width - 24.0 - gap * float(visible_actions.size() - 1)) / float(visible_actions.size())
    for i: int in range(visible_actions.size()):
        var id: String = visible_actions[i]
        var button: Button = action_buttons[id] as Button
        button.position = Vector2(12.0 + float(i) * (button_width + gap), 310)
        button.size = Vector2(button_width, 38)

func _draw() -> void:
    var width: float = maxf(size.x, 320.0)
    var height: float = maxf(size.y, 362.0)
    _draw_background(width, height)
    _draw_path(width)

    if mastery >= 5:
        _draw_palisade(width)
    if mastery >= 9:
        _draw_stronghold(width)

    _draw_tent(Vector2(width * 0.18, 215.0), 1.0 + minf(0.20, float(mastery) * 0.02))
    if mastery >= 1 or _has_relic(0):
        _draw_forge(Vector2(width * 0.27, 224.0))
    if weapons_owned.size() > 1:
        _draw_weapon_rack(Vector2(width * 0.74, 222.0))
    if mastery >= 5:
        _draw_watchtower(Vector2(width * 0.88, 179.0))

    _draw_hearth(Vector2(width * 0.50, 225.0))
    _draw_trophies(width)
    _draw_residents(width)

func _draw_background(width: float, height: float) -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), Color("111a20"))
    for i: int in range(18):
        var t: float = float(i) / 17.0
        var color: Color = Color("22343c").lerp(Color("4b4a39"), t)
        draw_rect(Rect2(0, 58.0 + t * 155.0, width, 10.0), color)

    var hill_back := PackedVector2Array([
        Vector2(0, 160), Vector2(width * 0.16, 118), Vector2(width * 0.33, 154),
        Vector2(width * 0.52, 112), Vector2(width * 0.72, 150), Vector2(width * 0.88, 105),
        Vector2(width, 146), Vector2(width, 230), Vector2(0, 230)
    ])
    draw_colored_polygon(hill_back, Color("263f38"))
    draw_rect(Rect2(0, 185, width, height - 185), Color("3f513a"))
    draw_rect(Rect2(0, 245, width, height - 245), Color("364733"))

    for i: int in range(10):
        var x: float = fmod(31.0 + float(i) * 79.0, width)
        var y: float = 86.0 + fmod(float(i) * 31.0, 68.0)
        draw_circle(Vector2(x, y), 1.1, Color(0.92, 0.88, 0.69, 0.28))

func _draw_path(width: float) -> void:
    var center: float = width * 0.5
    var path := PackedVector2Array([
        Vector2(center - 23, 352), Vector2(center - 35, 285), Vector2(center - 26, 246),
        Vector2(center + 27, 246), Vector2(center + 36, 285), Vector2(center + 23, 352)
    ])
    draw_colored_polygon(path, Color(0.47, 0.39, 0.28, 0.52))
    for i: int in range(7):
        var y: float = 263.0 + float(i) * 12.0
        var spread: float = 16.0 + float(i) * 1.8
        draw_line(Vector2(center - spread, y), Vector2(center + spread, y), Color(0.62, 0.53, 0.38, 0.23), 1.5)

func _draw_hearth(pos: Vector2) -> void:
    var pulse: float = (sin(elapsed * 3.6) + 1.0) * 0.5
    draw_circle(pos, 41.0 + pulse * 3.0, Color(1.0, 0.52, 0.18, 0.055 + pulse * 0.025))
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
    for i: int in range(14):
        var x: float = 12.0 + float(i) * ((width - 24.0) / 13.0)
        var y: float = 257.0 + sin(float(i) * 1.8) * 3.0
        draw_line(Vector2(x, y), Vector2(x, y - 28), Color("58432f"), 6.0)
        var tip := PackedVector2Array([
            Vector2(x - 3, y - 27), Vector2(x, y - 34), Vector2(x + 3, y - 27)
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
    var center: Vector2 = Vector2(width * 0.50, 184)
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

func _draw_residents(width: float) -> void:
    var positions: Array[Vector2] = [
        Vector2(width * 0.34, 248), Vector2(width * 0.66, 250),
        Vector2(width * 0.12, 263), Vector2(width * 0.83, 265),
        Vector2(width * 0.42, 276), Vector2(width * 0.58, 277)
    ]
    var count: int = mini(_resident_count(), positions.size())
    for i: int in range(count):
        _draw_resident(positions[i], i)

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
    if mastery >= 9:
        return 6
    if mastery >= 5:
        return 4
    if mastery >= 2:
        return 2
    if mastery >= 1:
        return 1
    return 0

func _relic_count() -> int:
    var count: int = 0
    for value: Variant in relics:
        if bool(value):
            count += 1
    return count

func _has_relic(index: int) -> bool:
    return index >= 0 and index < relics.size() and bool(relics[index])
