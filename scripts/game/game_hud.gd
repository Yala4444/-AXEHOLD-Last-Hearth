class_name GameHud
extends CanvasLayer

signal action_requested(action: String)

var root: Control
var hp_label: Label
var base_label: Label
var wave_label: Label
var phase_label: Label
var phase_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var backpack_label: Label
var storage_label: Label
var objective_label: Label
var status_label: Label
var status_panel: PanelContainer
var build_panel: PanelContainer
var build_title: Label
var build_effect: Label
var build_cost: Label
var boss_panel: PanelContainer
var boss_label: Label
var boss_bar: ProgressBar
var banner: Label
var flash: ColorRect
var modal: ColorRect
var modal_box: VBoxContainer
var status_time: float = 0.0

func _ready() -> void:
    layer = 60
    _build()
    get_viewport().size_changed.connect(_layout)
    _layout()

func _process(delta: float) -> void:
    if status_time > 0.0:
        status_time -= delta
        if status_time <= 0.0 and status_panel != null:
            var tween := create_tween()
            tween.tween_property(status_panel, "modulate:a", 0.0, 0.20)
            tween.tween_callback(func() -> void:
                if status_panel != null:
                    status_panel.visible = false
            )

func _build() -> void:
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var hp_panel := _panel(root, Rect2(), Color(0.05, 0.08, 0.09, 0.90), 3, Color("7b4b44"))
    hp_panel.name = "HeroPanel"
    hp_label = _make_label(hp_panel, "HP 100", 10, Color("f3ded8"), HORIZONTAL_ALIGNMENT_CENTER)

    var phase_panel := _panel(root, Rect2(), Color(0.05, 0.08, 0.09, 0.90), 3, Color("53646b"))
    phase_panel.name = "PhasePanel"
    phase_label = _make_label(phase_panel, "ДЕНЬ 1", 10, Color("f2ead8"), HORIZONTAL_ALIGNMENT_CENTER)
    phase_bar = ProgressBar.new()
    phase_panel.add_child(phase_bar)
    phase_bar.show_percentage = false
    _style_progress(phase_bar, Color("1d292d"), Color("d4aa55"), 1)
    xp_bar = ProgressBar.new()
    phase_panel.add_child(xp_bar)
    xp_bar.show_percentage = false
    _style_progress(xp_bar, Color("1a2227"), Color("7189bd"), 1)
    level_label = Label.new()
    phase_panel.add_child(level_label)
    level_label.add_theme_font_size_override("font_size", 7)
    level_label.add_theme_color_override("font_color", Color("aab6d3"))
    wave_label = Label.new()
    phase_panel.add_child(wave_label)
    wave_label.add_theme_font_size_override("font_size", 7)
    wave_label.add_theme_color_override("font_color", Color("d0c4df"))

    var base_panel := _panel(root, Rect2(), Color(0.05, 0.08, 0.09, 0.90), 3, Color("8b7046"))
    base_panel.name = "BasePanel"
    base_label = _make_label(base_panel, "ОЧАГ 270", 9, Color("f3e4c1"), HORIZONTAL_ALIGNMENT_CENTER)

    var pause := Button.new()
    root.add_child(pause)
    pause.name = "PauseButton"
    pause.text = "II"
    pause.focus_mode = Control.FOCUS_NONE
    pause.add_theme_font_size_override("font_size", 10)
    pause.add_theme_stylebox_override("normal", _box_style(Color(0.05, 0.08, 0.09, 0.90), 3, Color("46535a"), 1, 0))
    pause.add_theme_stylebox_override("pressed", _box_style(Color("11181c"), 3, Color("708087"), 1, 0))
    pause.add_theme_color_override("font_color", Color("dce5e6"))
    pause.pressed.connect(func() -> void: action_requested.emit("pause"))

    var backpack_panel := _panel(root, Rect2(), Color(0.06, 0.11, 0.11, 0.88), 3, Color("44625b"))
    backpack_panel.name = "BackpackPanel"
    backpack_label = _make_label(backpack_panel, "РЮКЗАК 0/24    Д 0  К 0  Р 0", 8, Color("e2f0e8"), HORIZONTAL_ALIGNMENT_LEFT)

    var storage_panel := _panel(root, Rect2(), Color(0.10, 0.09, 0.06, 0.88), 3, Color("6c583b"))
    storage_panel.name = "StoragePanel"
    storage_label = _make_label(storage_panel, "СКЛАД    Д 0  К 0  Р 0", 8, Color("f0e4c9"), HORIZONTAL_ALIGNMENT_LEFT)

    objective_label = Label.new()
    root.add_child(objective_label)
    objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    objective_label.add_theme_font_size_override("font_size", 8)
    objective_label.add_theme_color_override("font_color", Color(0.10, 0.16, 0.12, 0.78))
    objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    boss_panel = _panel(root, Rect2(), Color(0.11, 0.04, 0.05, 0.94), 3, Color("7f4247"))
    boss_panel.visible = false
    boss_label = _make_label(boss_panel, "ХРАНИТЕЛЬ", 9, Color("ffd6b4"), HORIZONTAL_ALIGNMENT_CENTER)
    boss_bar = ProgressBar.new()
    boss_panel.add_child(boss_bar)
    boss_bar.show_percentage = false
    _style_progress(boss_bar, Color("311519"), Color("cb5b5d"), 1)

    banner = Label.new()
    root.add_child(banner)
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 17)
    banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.60))
    banner.add_theme_constant_override("shadow_offset_x", 2)
    banner.add_theme_constant_override("shadow_offset_y", 2)
    banner.modulate.a = 0.0
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

    status_panel = _panel(root, Rect2(), Color(0.04, 0.07, 0.07, 0.88), 3, Color(0.38, 0.47, 0.44, 0.60))
    status_panel.visible = false
    status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status_label = _make_label(status_panel, "", 8, Color("e6ece7"), HORIZONTAL_ALIGNMENT_CENTER)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    build_panel = _panel(root, Rect2(), Color(0.035, 0.055, 0.055, 0.96), 3, Color("627269"))
    build_panel.visible = false
    build_title = Label.new()
    build_panel.add_child(build_title)
    build_title.add_theme_font_size_override("font_size", 10)
    build_title.add_theme_color_override("font_color", Color("f2d58b"))
    build_effect = Label.new()
    build_panel.add_child(build_effect)
    build_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    build_effect.add_theme_font_size_override("font_size", 8)
    build_effect.add_theme_color_override("font_color", Color("d9e1dc"))
    build_cost = Label.new()
    build_panel.add_child(build_cost)
    build_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    build_cost.add_theme_font_size_override("font_size", 8)

    flash = ColorRect.new()
    root.add_child(flash)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(1, 0, 0, 0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

    modal = ColorRect.new()
    root.add_child(modal)
    modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal.color = Color(0.015, 0.025, 0.027, 0.74)
    modal.visible = false
    modal.mouse_filter = Control.MOUSE_FILTER_STOP

    var center := CenterContainer.new()
    modal.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var modal_panel := PanelContainer.new()
    center.add_child(modal_panel)
    modal_panel.custom_minimum_size = Vector2(330, 0)
    modal_panel.add_theme_stylebox_override("panel", _box_style(Color("10191d"), 4, Color("536269"), 1, 16))

    modal_box = VBoxContainer.new()
    modal_panel.add_child(modal_box)
    modal_box.add_theme_constant_override("separation", 9)

func _layout() -> void:
    if root == null:
        return
    var size := get_viewport().get_visible_rect().size
    var width: float = size.x
    var margin: float = 8.0
    var gap: float = 5.0
    var pause_w: float = 34.0
    var hp_w: float = 72.0
    var base_w: float = 82.0
    var phase_w: float = width - margin * 2.0 - gap * 3.0 - pause_w - hp_w - base_w

    var hp_panel := root.get_node("HeroPanel") as PanelContainer
    var phase_panel := root.get_node("PhasePanel") as PanelContainer
    var base_panel := root.get_node("BasePanel") as PanelContainer
    var pause := root.get_node("PauseButton") as Button
    var backpack_panel := root.get_node("BackpackPanel") as PanelContainer
    var storage_panel := root.get_node("StoragePanel") as PanelContainer

    hp_panel.position = Vector2(margin, 8)
    hp_panel.size = Vector2(hp_w, 37)
    phase_panel.position = Vector2(margin + hp_w + gap, 8)
    phase_panel.size = Vector2(phase_w, 37)
    base_panel.position = Vector2(margin + hp_w + gap + phase_w + gap, 8)
    base_panel.size = Vector2(base_w, 37)
    pause.position = Vector2(width - margin - pause_w, 8)
    pause.size = Vector2(pause_w, 37)

    phase_label.position = Vector2(5, 2)
    phase_label.size = Vector2(phase_w - 10, 14)
    phase_bar.position = Vector2(7, 20)
    phase_bar.size = Vector2(phase_w - 14, 5)
    xp_bar.position = Vector2(34, 29)
    xp_bar.size = Vector2(maxf(32.0, phase_w - 42), 3)
    level_label.position = Vector2(7, 26)
    level_label.size = Vector2(27, 9)
    wave_label.position = Vector2(phase_w - 46, 26)
    wave_label.size = Vector2(39, 9)
    wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    var half: float = (width - margin * 2.0 - gap) * 0.5
    backpack_panel.position = Vector2(margin, 50)
    backpack_panel.size = Vector2(half, 38)
    storage_panel.position = Vector2(margin + half + gap, 50)
    storage_panel.size = Vector2(half, 38)

    backpack_label.position = Vector2(8, 6)
    backpack_label.size = Vector2(half - 16, 26)
    storage_label.position = Vector2(8, 6)
    storage_label.size = Vector2(half - 16, 26)

    objective_label.position = Vector2(margin, 91)
    objective_label.size = Vector2(width - margin * 2.0, 23)

    boss_panel.position = Vector2(42, 120)
    boss_panel.size = Vector2(width - 84, 38)
    boss_label.position = Vector2(8, 2)
    boss_label.size = Vector2(width - 100, 14)
    boss_bar.position = Vector2(9, 23)
    boss_bar.size = Vector2(width - 102, 6)

    banner.position = Vector2(18, 164)
    banner.size = Vector2(width - 36, 38)

    status_panel.position = Vector2(62, 116)
    status_panel.size = Vector2(width - 124, 31)
    status_label.position = Vector2(8, 4)
    status_label.size = Vector2(width - 140, 23)

    build_panel.position = Vector2(width - 196, size.y - 154)
    build_panel.size = Vector2(188, 98)
    build_title.position = Vector2(9, 6)
    build_title.size = Vector2(170, 16)
    build_effect.position = Vector2(9, 27)
    build_effect.size = Vector2(170, 39)
    build_cost.position = Vector2(9, 70)
    build_cost.size = Vector2(170, 20)

func update_stats(hero_hp: float, base_hp: float, bag: int, capacity: int, wave: int, phase: String, phase_value: float, xp: int, next_xp: int, level: int, storage: Dictionary, enemies_left: int, inventory: Dictionary = {}) -> void:
    hp_label.text = "HP %d" % int(ceil(hero_hp))
    base_label.text = "ОЧАГ %d" % int(ceil(maxf(base_hp, 0.0)))
    wave_label.text = "%d/3" % wave
    if phase == "day":
        phase_label.text = "ДО НОЧИ  %d С" % int(ceil(phase_value))
        phase_bar.value = clampf(phase_value / maxf(1.0, GameRules.day_duration(wave)) * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color("1d292d"), Color("d4aa55"), 1)
        objective_label.text = "ДОБЫЧА  >  ОЧАГ  >  СТРОЙКА"
    else:
        phase_label.text = "НОЧЬ %d   ВРАГОВ %d" % [wave, enemies_left]
        phase_bar.value = clampf(float(enemies_left) / float(maxi(1, 8 + wave * 4)) * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color("202532"), Color("8970b3"), 1)
        objective_label.text = "ЗАЩИЩАЙ ОЧАГ"

    xp_bar.value = clampf(float(xp) / float(maxi(1, next_xp)) * 100.0, 0.0, 100.0)
    level_label.text = "L%d" % level
    backpack_label.text = "РЮКЗАК %d/%d\nД %d   К %d   Р %d" % [
        bag, capacity,
        int(inventory.get("wood", 0)), int(inventory.get("stone", 0)), int(inventory.get("ore", 0))
    ]
    storage_label.text = "СКЛАД ОЧАГА\nД %d   К %d   Р %d" % [
        int(storage.get("wood", 0)), int(storage.get("stone", 0)), int(storage.get("ore", 0))
    ]

func set_build_context(title: String, effect: String, cost: Dictionary, storage: Dictionary, ready: bool, progress: float = 0.0) -> void:
    build_panel.visible = true
    build_title.text = _safe(title)
    build_effect.text = _safe(effect)
    var wood_need: int = maxi(0, int(cost.get("wood", 0)) - int(storage.get("wood", 0)))
    var stone_need: int = maxi(0, int(cost.get("stone", 0)) - int(storage.get("stone", 0)))
    var ore_need: int = maxi(0, int(cost.get("ore", 0)) - int(storage.get("ore", 0)))
    if ready:
        build_cost.text = "СТРОИТСЯ %d%%" % int(clampf(progress, 0.0, 1.0) * 100.0) if progress > 0.01 else "МОЖНО СТРОИТЬ"
        build_cost.add_theme_color_override("font_color", Color("9ad5a8"))
    else:
        build_cost.text = "НУЖНО  Д%d  К%d  Р%d" % [wood_need, stone_need, ore_need]
        build_cost.add_theme_color_override("font_color", Color("e6a08c"))

func set_built_context(title: String, effect: String) -> void:
    build_panel.visible = true
    build_title.text = _safe(title + "  |  АКТИВНО")
    build_effect.text = _safe(effect)
    build_cost.text = "РАБОТАЕТ"
    build_cost.add_theme_color_override("font_color", Color("9ad5a8"))

func hide_build_context() -> void:
    build_panel.visible = false

func set_status(text: String) -> void:
    if text.strip_edges().is_empty():
        return
    status_label.text = _safe(text)
    status_panel.visible = true
    status_panel.modulate.a = 1.0
    status_time = 2.7

func show_banner(text: String, color: Color = Color("f4d79a")) -> void:
    banner.text = _safe(text)
    banner.add_theme_color_override("font_color", color)
    banner.modulate.a = 0.0
    banner.scale = Vector2(0.93, 0.93)
    banner.pivot_offset = banner.size * 0.5
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(banner, "modulate:a", 1.0, 0.12)
    tween.tween_property(banner, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(0.62)
    tween.chain().set_parallel(true)
    tween.tween_property(banner, "modulate:a", 0.0, 0.20)
    tween.tween_property(banner, "scale", Vector2(1.03, 1.03), 0.20)

func show_boss(name: String, hp: float, max_hp: float) -> void:
    boss_panel.visible = true
    boss_label.text = _safe(name.to_upper())
    boss_bar.value = clampf(hp / maxf(1.0, max_hp) * 100.0, 0.0, 100.0)

func hide_boss() -> void:
    boss_panel.visible = false

func damage_feedback(blocked: bool) -> void:
    flash.color = Color(0.35, 0.75, 1.0, 0.13) if blocked else Color(0.95, 0.16, 0.16, 0.16)
    var tween: Tween = create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.22)

func show_modal(icon: String, title: String, body_text: String, buttons: Array) -> void:
    modal.visible = true
    modal.modulate.a = 0.0
    for child: Node in modal_box.get_children():
        child.queue_free()

    var safe_icon: String = _safe(icon)
    if not safe_icon.strip_edges().is_empty():
        var icon_label := Label.new()
        icon_label.text = safe_icon
        icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon_label.add_theme_font_size_override("font_size", 15)
        modal_box.add_child(icon_label)

    var title_label := Label.new()
    title_label.text = _safe(title)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 18)
    title_label.add_theme_color_override("font_color", Color("f4e3bf"))
    modal_box.add_child(title_label)

    var body_label := Label.new()
    body_label.text = _safe(body_text)
    body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 10)
    body_label.add_theme_color_override("font_color", Color("cbd5d6"))
    modal_box.add_child(body_label)

    for spec_variant: Variant in buttons:
        var spec: Dictionary = spec_variant as Dictionary
        var button := Button.new()
        button.text = _safe(str(spec.get("text", "OK")))
        button.custom_minimum_size = Vector2(0, 44)
        button.focus_mode = Control.FOCUS_NONE
        _style_button(button, modal_box.get_child_count() <= 2)
        var action: String = str(spec.get("action", "close"))
        button.pressed.connect(func() -> void: action_requested.emit(action))
        modal_box.add_child(button)

    var tween := create_tween()
    tween.tween_property(modal, "modulate:a", 1.0, 0.12)

func hide_modal() -> void:
    modal.visible = false

func modal_open() -> bool:
    return modal != null and modal.visible

func _safe(text: String) -> String:
    var sanitizer: Node = get_tree().root.get_node_or_null("UISanitizer")
    if sanitizer != null and sanitizer.has_method("clean_text"):
        return str(sanitizer.call("clean_text", text))
    return text

func _make_label(parent: Control, text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
    var label := Label.new()
    parent.add_child(label)
    label.text = text
    label.horizontal_alignment = align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label

func _panel(parent: Control, rect: Rect2, color: Color, radius: int, border_color: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.position = rect.position
    panel.size = rect.size
    panel.add_theme_stylebox_override("panel", _box_style(color, radius, border_color, 1, 0))
    return panel

func _style_progress(bar: ProgressBar, track: Color, fill_color: Color, radius: int) -> void:
    var background := StyleBoxFlat.new()
    background.bg_color = track
    background.corner_radius_top_left = radius
    background.corner_radius_top_right = radius
    background.corner_radius_bottom_left = radius
    background.corner_radius_bottom_right = radius
    var fill := StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.corner_radius_top_left = radius
    fill.corner_radius_top_right = radius
    fill.corner_radius_bottom_left = radius
    fill.corner_radius_bottom_right = radius
    bar.add_theme_stylebox_override("background", background)
    bar.add_theme_stylebox_override("fill", fill)

func _style_button(button: Button, primary: bool) -> void:
    var normal_color: Color = Color("c79a50") if primary else Color("182329")
    var pressed_color: Color = normal_color.darkened(0.14)
    button.add_theme_stylebox_override("normal", _box_style(normal_color, 3, Color("58656a"), 1, 8))
    button.add_theme_stylebox_override("pressed", _box_style(pressed_color, 3, Color("374248"), 1, 8))
    button.add_theme_color_override("font_color", Color("171b1d") if primary else Color("e8edef"))

func _box_style(color: Color, radius: int, border_color: Color, border_width: int, margin: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border_color
    style.set_border_width_all(border_width)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = margin
    style.content_margin_right = margin
    style.content_margin_top = margin
    style.content_margin_bottom = margin
    return style
