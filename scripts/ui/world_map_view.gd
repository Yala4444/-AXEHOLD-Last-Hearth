class_name WorldMapView
extends Control

signal biome_selected(index: int)
signal frontier_requested

var selected_biome: int = 0
var elapsed: float = 0.0
var node_buttons: Array[Button] = []
var requirements: Array[int] = [0, 1, 3]
var node_points: Array[Vector2] = []

func _ready() -> void:
    custom_minimum_size = Vector2(0, 455)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    clip_contents = true
    _build_buttons()
    resized.connect(_layout_buttons)
    set_process(true)

func configure(index: int) -> void:
    selected_biome = clampi(index, 0, 2)
    if is_node_ready():
        _refresh_buttons()
        _layout_buttons()
        queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _build_buttons() -> void:
    for i: int in range(4):
        var button := Button.new()
        add_child(button)
        node_buttons.append(button)
        button.focus_mode = Control.FOCUS_NONE
        button.add_theme_font_size_override("font_size", 10)
        button.pressed.connect(_on_node_pressed.bind(i))
    _refresh_buttons()
    _layout_buttons()

func _refresh_buttons() -> void:
    var shards: int = int(GameState.data.get("shards", 0))
    var mastery: Array = GameState.data.get("biome_mastery", [0, 0, 0])
    var relics: Array = GameState.data.get("boss_relics", [false, false, false])
    for i: int in range(node_buttons.size()):
        var button: Button = node_buttons[i]

        if i == 3:
            var frontier_open: bool = GameState.chapter_one_complete()
            button.text = "ДАЛЬНИЙ ОЧАГ\nСИГНАЛ ОБНАРУЖЕН" if frontier_open else "ЗА ПЕПЛОМ\nЗАВЕРШИ ГЛАВУ I"
            button.disabled = not frontier_open
            var frontier_fill: Color = Color("28283a") if frontier_open else Color(0.06, 0.075, 0.08, 0.72)
            var frontier_border: Color = Color("9ea5d4") if frontier_open else Color(0.25, 0.28, 0.29, 0.46)
            button.add_theme_stylebox_override("normal", _style(frontier_fill, frontier_border, 8))
            button.add_theme_stylebox_override("hover", _style(frontier_fill.lightened(0.05), frontier_border.lightened(0.08), 8))
            button.add_theme_stylebox_override("pressed", _style(frontier_fill.darkened(0.07), frontier_border, 8))
            button.add_theme_stylebox_override("disabled", _style(frontier_fill, frontier_border, 8))
            button.add_theme_color_override("font_color", Color("e2ddf5") if frontier_open else Color("737c7e"))
            button.add_theme_color_override("font_disabled_color", Color("737c7e"))
            continue

        var biome: Dictionary = GameRules.biome(i)
        var unlocked: bool = shards >= requirements[i]
        var level: int = int(mastery[i]) if i < mastery.size() else 0
        var relic_mark: String = "РЕЛИКВИЯ" if i < relics.size() and bool(relics[i]) else "ХРАНИТЕЛЬ"
        if not unlocked:
            button.text = "%s\nНУЖНО %d ОСК." % [str(biome.get("name", "Регион")).to_upper(), requirements[i]]
        else:
            button.text = "%s\nМАСТЕРСТВО %d · %s" % [str(biome.get("name", "Регион")).to_upper(), level, relic_mark]
        button.disabled = not unlocked
        var selected: bool = selected_biome == i and unlocked
        var fill: Color = Color("2a352d") if selected else Color(0.07, 0.10, 0.11, 0.78)
        var border: Color = Color("d5ad62") if selected else Color(0.37, 0.43, 0.42, 0.62)
        if not unlocked:
            fill = Color(0.06, 0.075, 0.08, 0.72)
            border = Color(0.25, 0.28, 0.29, 0.46)
        button.add_theme_stylebox_override("normal", _style(fill, border, 8))
        button.add_theme_stylebox_override("hover", _style(fill.lightened(0.05), border.lightened(0.10), 8))
        button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.08), border, 8))
        button.add_theme_stylebox_override("disabled", _style(fill, border, 8))
        button.add_theme_color_override("font_color", Color("f0e4ca") if unlocked else Color("737c7e"))
        button.add_theme_color_override("font_disabled_color", Color("737c7e"))

func _layout_buttons() -> void:
    var w: float = maxf(size.x, 330.0)
    var h: float = maxf(size.y, 455.0)
    node_points = [
        Vector2(w * 0.34, h * 0.76),
        Vector2(w * 0.68, h * 0.54),
        Vector2(w * 0.37, h * 0.32),
        Vector2(w * 0.69, h * 0.11)
    ]
    for i: int in range(mini(node_buttons.size(), node_points.size())):
        var p: Vector2 = node_points[i]
        var button: Button = node_buttons[i]
        if i == 0 or i == 2:
            button.position = p + Vector2(30, -29)
        else:
            button.position = p + Vector2(-176, -29)
        button.size = Vector2(146, 58)

func _on_node_pressed(index: int) -> void:
    if index == 3:
        if GameState.chapter_one_complete():
            frontier_requested.emit()
        return

    var shards: int = int(GameState.data.get("shards", 0))
    if shards < requirements[index]:
        return
    selected_biome = index
    _refresh_buttons()
    queue_redraw()
    biome_selected.emit(index)

func _draw() -> void:
    var w: float = maxf(size.x, 330.0)
    var h: float = maxf(size.y, 455.0)
    draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color("10181c"))
    for i: int in range(12):
        var t: float = float(i) / 11.0
        draw_rect(Rect2(0, t * h, w, h / 11.0 + 1.0), Color("172229").lerp(Color("28362f"), t))

    _draw_distant_ridges(w, h)
    if node_points.size() != 4:
        _layout_buttons()

    var path_color := Color(0.76, 0.64, 0.39, 0.34)
    var hearth := Vector2(w * 0.50, h * 0.91)
    draw_line(hearth, node_points[0], path_color, 3.0)
    draw_line(node_points[0], node_points[1], path_color, 3.0)
    draw_line(node_points[1], node_points[2], path_color, 3.0)
    var frontier_path: Color = Color(0.64, 0.67, 0.90, 0.42) if GameState.chapter_one_complete() else Color(0.35, 0.38, 0.42, 0.20)
    draw_line(node_points[2], node_points[3], frontier_path, 2.0)
    for i: int in range(20):
        var a: float = float(i) / 19.0
        var p: Vector2
        if a < 0.34:
            p = hearth.lerp(node_points[0], a / 0.34)
        elif a < 0.67:
            p = node_points[0].lerp(node_points[1], (a - 0.34) / 0.33)
        else:
            p = node_points[1].lerp(node_points[2], (a - 0.67) / 0.33)
        draw_circle(p, 1.8, Color(0.90, 0.77, 0.48, 0.44))

    _draw_hearth(hearth)
    _draw_biome_node(node_points[0], 0)
    _draw_biome_node(node_points[1], 1)
    _draw_biome_node(node_points[2], 2)
    _draw_frontier_node(node_points[3])

    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(w * 0.5 - 76, h - 14), "ПОСЛЕДНИЙ ОЧАГ", HORIZONTAL_ALIGNMENT_CENTER, 152, 9, Color("e4c985"))

func _draw_distant_ridges(w: float, h: float) -> void:
    var ridge := PackedVector2Array([
        Vector2(0, h * 0.33), Vector2(w * 0.14, h * 0.25), Vector2(w * 0.28, h * 0.32),
        Vector2(w * 0.48, h * 0.21), Vector2(w * 0.62, h * 0.31), Vector2(w * 0.82, h * 0.20),
        Vector2(w, h * 0.29), Vector2(w, h * 0.65), Vector2(0, h * 0.65)
    ])
    draw_colored_polygon(ridge, Color(0.09, 0.18, 0.18, 0.52))
    var lower := PackedVector2Array([
        Vector2(0, h * 0.55), Vector2(w * 0.18, h * 0.45), Vector2(w * 0.38, h * 0.56),
        Vector2(w * 0.59, h * 0.41), Vector2(w * 0.76, h * 0.53), Vector2(w, h * 0.43),
        Vector2(w, h), Vector2(0, h)
    ])
    draw_colored_polygon(lower, Color(0.12, 0.24, 0.20, 0.54))

func _draw_hearth(pos: Vector2) -> void:
    var pulse: float = (sin(elapsed * 3.4) + 1.0) * 0.5
    draw_circle(pos, 35.0 + pulse * 3.0, Color(1.0, 0.53, 0.18, 0.07))
    draw_circle(pos, 18.0, Color("28231d"))
    draw_line(pos + Vector2(-8, 7), pos + Vector2(8, -5), Color("6f4328"), 4.0)
    draw_line(pos + Vector2(8, 7), pos + Vector2(-7, -5), Color("6f4328"), 4.0)
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(-6, 5), pos + Vector2(-2, -12 - pulse * 3.0),
        pos + Vector2(2, -5), pos + Vector2(6, -16 + pulse * 2.0), pos + Vector2(8, 5)
    ]), Color("f39a3d"))
    draw_circle(pos + Vector2(1, 0), 4.0, Color("ffe486"))

func _draw_biome_node(pos: Vector2, index: int) -> void:
    var selected: bool = index == selected_biome
    var pulse: float = (sin(elapsed * 2.4 + float(index)) + 1.0) * 0.5
    draw_circle(pos, 29.0 + (pulse * 2.0 if selected else 0.0), Color(0.83, 0.67, 0.35, 0.06 if selected else 0.025))
    draw_circle(pos, 22.0, Color("182125"))
    draw_arc(pos, 22.0, 0.0, TAU, 30, Color("d1aa61") if selected else Color("667174"), 2.0)
    match index:
        1:
            var peak := PackedVector2Array([
                pos + Vector2(-14, 10), pos + Vector2(-3, -14), pos + Vector2(4, -3),
                pos + Vector2(10, -18), pos + Vector2(16, 10)
            ])
            draw_colored_polygon(peak, Color("8bb0ba"))
            draw_line(pos + Vector2(-3, -14), pos + Vector2(1, -4), Color("d7edf1"), 2.0)
        2:
            draw_rect(Rect2(pos + Vector2(-3, -14), Vector2(6, 25)), Color("5a382f"))
            draw_line(pos + Vector2(0, -7), pos + Vector2(-11, -17), Color("6c4136"), 4.0)
            draw_line(pos + Vector2(0, -2), pos + Vector2(12, -12), Color("6c4136"), 4.0)
            draw_circle(pos + Vector2(8, 8), 3.0, Color("d96837"))
        _:
            draw_rect(Rect2(pos + Vector2(-3, 3), Vector2(6, 13)), Color("60442e"))
            draw_circle(pos + Vector2(0, -3), 13.0, Color("42684b"))
            draw_circle(pos + Vector2(-8, 1), 8.0, Color("507a55"))
            draw_circle(pos + Vector2(8, 1), 8.0, Color("507a55"))

func _draw_frontier_node(pos: Vector2) -> void:
    var unlocked: bool = GameState.chapter_one_complete()
    var pulse: float = (sin(elapsed * 3.1) + 1.0) * 0.5
    var glow: Color = Color("a8b2f0") if unlocked else Color("596067")
    draw_circle(pos, 29.0 + (pulse * 3.0 if unlocked else 0.0), Color(glow, 0.07 if unlocked else 0.025))
    draw_circle(pos, 22.0, Color("171923"))
    draw_arc(pos, 22.0, 0.0, TAU, 30, Color(glow, 0.82 if unlocked else 0.42), 2.0)
    if unlocked:
        draw_circle(pos, 6.0 + pulse * 2.0, Color("f0c679"))
        draw_circle(pos, 12.0 + pulse * 2.0, Color(0.66, 0.70, 0.94, 0.10))
        draw_line(pos + Vector2(-13, 11), pos + Vector2(13, -11), Color(0.66, 0.70, 0.94, 0.36), 1.0)
    else:
        draw_line(pos + Vector2(-7, -7), pos + Vector2(7, 7), Color("62686c"), 3.0)
        draw_line(pos + Vector2(7, -7), pos + Vector2(-7, 7), Color("62686c"), 3.0)

func _style(fill: Color, border: Color, margin: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_left = 3
    style.corner_radius_bottom_right = 3
    style.content_margin_left = margin
    style.content_margin_right = margin
    style.content_margin_top = margin
    style.content_margin_bottom = margin
    return style
