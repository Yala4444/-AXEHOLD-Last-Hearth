class_name GameHud
extends CanvasLayer

signal action_requested(action: String)

var root: Control
var hp_label: Label
var base_label: Label
var bag_label: Label
var wave_label: Label
var phase_label: Label
var phase_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var resources_label: Label
var status_label: Label
var boss_panel: PanelContainer
var boss_label: Label
var boss_bar: ProgressBar
var banner: Label
var flash: ColorRect
var modal: ColorRect
var modal_box: VBoxContainer

func _ready() -> void:
    _build()

func _build() -> void:
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var top: HBoxContainer = HBoxContainer.new()
    root.add_child(top)
    top.position = Vector2(10, 10)
    top.size = Vector2(370, 48)
    top.add_theme_constant_override("separation", 6)
    hp_label = _chip(top, "❤️ 100", Color("d86767"))
    base_label = _chip(top, "🔥 270", Color("e5a251"))
    bag_label = _chip(top, "🎒 0/20", Color("8fa9d8"))
    wave_label = _chip(top, "🌙 0/3", Color("9d8bc0"))

    var phase_panel: PanelContainer = _panel(root, Rect2(10, 64, 370, 58), Color(0.035, 0.052, 0.065, 0.91), 15)
    phase_label = Label.new()
    phase_panel.add_child(phase_label)
    phase_label.position = Vector2(11, 5)
    phase_label.size = Vector2(348, 18)
    phase_label.add_theme_font_size_override("font_size", 11)
    phase_label.add_theme_color_override("font_color", Color("dce5e8"))

    phase_bar = ProgressBar.new()
    phase_panel.add_child(phase_bar)
    phase_bar.position = Vector2(10, 25)
    phase_bar.size = Vector2(350, 9)
    phase_bar.show_percentage = false
    _style_progress(phase_bar, Color(0.18, 0.23, 0.25, 0.92), Color("e1b35f"), 5)

    xp_bar = ProgressBar.new()
    phase_panel.add_child(xp_bar)
    xp_bar.position = Vector2(42, 42)
    xp_bar.size = Vector2(316, 6)
    xp_bar.show_percentage = false
    _style_progress(xp_bar, Color(0.14, 0.18, 0.22, 0.88), Color("6f88d9"), 3)

    level_label = Label.new()
    phase_panel.add_child(level_label)
    level_label.position = Vector2(8, 37)
    level_label.size = Vector2(34, 15)
    level_label.add_theme_font_size_override("font_size", 9)
    level_label.add_theme_color_override("font_color", Color("aeb9d8"))

    boss_panel = _panel(root, Rect2(42, 132, 306, 51), Color(0.12, 0.045, 0.052, 0.94), 16)
    boss_panel.visible = false
    boss_label = Label.new()
    boss_panel.add_child(boss_label)
    boss_label.text = "👑 ХРАНИТЕЛЬ"
    boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_label.position = Vector2(8, 3)
    boss_label.size = Vector2(290, 19)
    boss_label.add_theme_font_size_override("font_size", 11)
    boss_label.add_theme_color_override("font_color", Color("ffd0b3"))
    boss_bar = ProgressBar.new()
    boss_panel.add_child(boss_bar)
    boss_bar.position = Vector2(10, 27)
    boss_bar.size = Vector2(286, 9)
    boss_bar.show_percentage = false
    _style_progress(boss_bar, Color(0.18, 0.06, 0.07, 1), Color("cf6165"), 5)

    banner = Label.new()
    root.add_child(banner)
    banner.position = Vector2(20, 190)
    banner.size = Vector2(350, 46)
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 21)
    banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
    banner.add_theme_constant_override("shadow_offset_x", 1)
    banner.add_theme_constant_override("shadow_offset_y", 2)
    banner.modulate.a = 0.0
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var bottom_panel: PanelContainer = _panel(root, Rect2(9, 733, 372, 101), Color(0.035, 0.052, 0.065, 0.92), 18)

    resources_label = Label.new()
    bottom_panel.add_child(resources_label)
    resources_label.position = Vector2(12, 7)
    resources_label.size = Vector2(240, 27)
    resources_label.add_theme_font_size_override("font_size", 13)
    resources_label.add_theme_color_override("font_color", Color("f0dcad"))

    status_label = Label.new()
    bottom_panel.add_child(status_label)
    status_label.position = Vector2(12, 38)
    status_label.size = Vector2(244, 51)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 10)
    status_label.add_theme_color_override("font_color", Color("d3d9de"))

    var leave: Button = Button.new()
    bottom_panel.add_child(leave)
    leave.text = "⌂"
    leave.tooltip_text = "В лагерь"
    leave.position = Vector2(273, 39)
    leave.size = Vector2(40, 42)
    _style_button(leave, false)
    leave.pressed.connect(func() -> void: action_requested.emit("quit"))

    var pause: Button = Button.new()
    bottom_panel.add_child(pause)
    pause.text = "Ⅱ"
    pause.tooltip_text = "Пауза"
    pause.position = Vector2(320, 39)
    pause.size = Vector2(40, 42)
    _style_button(pause, false)
    pause.pressed.connect(func() -> void: action_requested.emit("pause"))

    flash = ColorRect.new()
    root.add_child(flash)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(1, 0, 0, 0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

    modal = ColorRect.new()
    root.add_child(modal)
    modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal.color = Color(0.018, 0.028, 0.043, 0.76)
    modal.visible = false
    modal.mouse_filter = Control.MOUSE_FILTER_STOP

    var center: CenterContainer = CenterContainer.new()
    modal.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var modal_panel: PanelContainer = PanelContainer.new()
    center.add_child(modal_panel)
    modal_panel.custom_minimum_size = Vector2(336, 0)
    modal_panel.add_theme_stylebox_override("panel", _box_style(Color(0.055, 0.072, 0.09, 0.99), 22, Color(0.28, 0.33, 0.37, 0.9)))

    modal_box = VBoxContainer.new()
    modal_panel.add_child(modal_box)
    modal_box.add_theme_constant_override("separation", 10)

func update_stats(hero_hp: float, base_hp: float, bag: int, capacity: int, wave: int, phase: String, phase_value: float, xp: int, next_xp: int, level: int, storage: Dictionary, enemies_left: int) -> void:
    hp_label.text = "❤️ %d" % int(ceil(hero_hp))
    base_label.text = "🔥 %d" % int(ceil(maxf(base_hp, 0.0)))
    bag_label.text = "🎒 %d/%d" % [bag, capacity]
    wave_label.text = "🌙 %d/3" % wave
    if phase == "day":
        phase_label.text = "☀  До ночи · %d сек" % int(ceil(phase_value))
        phase_bar.value = clampf(phase_value / 28.0 * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color(0.18, 0.23, 0.25, 0.92), Color("e1b35f"), 5)
    else:
        phase_label.text = "🌙  Ночь %d · осталось %d" % [wave, enemies_left]
        phase_bar.value = clampf(float(enemies_left) / float(maxi(1, 9 + wave * 4)) * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color(0.14, 0.16, 0.22, 0.94), Color("8c72bc"), 5)
    xp_bar.value = clampf(float(xp) / float(maxi(1, next_xp)) * 100.0, 0.0, 100.0)
    level_label.text = "Lv.%d" % level
    resources_label.text = "🪵 %d     🪨 %d     ⛏ %d" % [int(storage.get("wood", 0)), int(storage.get("stone", 0)), int(storage.get("ore", 0))]

func set_status(text: String) -> void:
    status_label.text = text

func show_banner(text: String, color: Color = Color("f4d79a")) -> void:
    banner.text = text
    banner.add_theme_color_override("font_color", color)
    banner.modulate.a = 0.0
    banner.scale = Vector2(0.92, 0.92)
    banner.pivot_offset = banner.size * 0.5
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(banner, "modulate:a", 1.0, 0.17)
    tween.tween_property(banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(0.86)
    tween.chain().set_parallel(true)
    tween.tween_property(banner, "modulate:a", 0.0, 0.30)
    tween.tween_property(banner, "scale", Vector2(1.04, 1.04), 0.30)

func show_boss(name: String, hp: float, max_hp: float) -> void:
    if not boss_panel.visible:
        boss_panel.visible = true
        boss_panel.modulate.a = 0.0
        boss_panel.scale = Vector2(0.94, 0.94)
        boss_panel.pivot_offset = boss_panel.size * 0.5
        var tween: Tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(boss_panel, "modulate:a", 1.0, 0.20)
        tween.tween_property(boss_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    boss_label.text = "👑 " + name.to_upper()
    boss_bar.value = clampf(hp / maxf(1.0, max_hp) * 100.0, 0.0, 100.0)

func hide_boss() -> void:
    boss_panel.visible = false

func damage_feedback(blocked: bool) -> void:
    flash.color = Color(0.35, 0.75, 1.0, 0.17) if blocked else Color(0.95, 0.16, 0.16, 0.22)
    var tween: Tween = create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.26)

func show_modal(icon: String, title: String, body_text: String, buttons: Array) -> void:
    modal.visible = true
    modal.modulate.a = 0.0
    for child: Node in modal_box.get_children():
        child.queue_free()

    var icon_label: Label = Label.new()
    icon_label.text = icon
    icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon_label.add_theme_font_size_override("font_size", 32)
    modal_box.add_child(icon_label)

    var title_label: Label = Label.new()
    title_label.text = title
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 20)
    title_label.add_theme_color_override("font_color", Color("f6ead0"))
    modal_box.add_child(title_label)

    var body_label: Label = Label.new()
    body_label.text = body_text
    body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 12)
    body_label.add_theme_color_override("font_color", Color("cdd4da"))
    modal_box.add_child(body_label)

    for spec_variant: Variant in buttons:
        var spec: Dictionary = spec_variant as Dictionary
        var button: Button = Button.new()
        button.text = str(spec.get("text", "OK"))
        button.custom_minimum_size = Vector2(0, 47)
        _style_button(button, modal_box.get_child_count() == 3)
        var action: String = str(spec.get("action", "close"))
        button.pressed.connect(func() -> void: action_requested.emit(action))
        modal_box.add_child(button)

    var tween: Tween = create_tween()
    tween.tween_property(modal, "modulate:a", 1.0, 0.16)

func hide_modal() -> void:
    modal.visible = false

func modal_open() -> bool:
    return modal != null and modal.visible

func _chip(parent: Control, text: String, accent: Color) -> Label:
    var panel: PanelContainer = PanelContainer.new()
    parent.add_child(panel)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _box_style(Color(0.045, 0.064, 0.078, 0.92), 13, Color(accent, 0.28)))
    var label: Label = Label.new()
    panel.add_child(label)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 10)
    label.add_theme_color_override("font_color", Color("edf2f4"))
    return label

func _panel(parent: Control, rect: Rect2, color: Color, radius: int) -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    parent.add_child(panel)
    panel.position = rect.position
    panel.size = rect.size
    panel.add_theme_stylebox_override("panel", _box_style(color, radius, Color(0.22, 0.27, 0.31, 0.78)))
    return panel

func _style_progress(bar: ProgressBar, track: Color, fill_color: Color, radius: int) -> void:
    var background: StyleBoxFlat = StyleBoxFlat.new()
    background.bg_color = track
    background.corner_radius_top_left = radius
    background.corner_radius_top_right = radius
    background.corner_radius_bottom_left = radius
    background.corner_radius_bottom_right = radius
    var fill: StyleBoxFlat = StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.corner_radius_top_left = radius
    fill.corner_radius_top_right = radius
    fill.corner_radius_bottom_left = radius
    fill.corner_radius_bottom_right = radius
    bar.add_theme_stylebox_override("background", background)
    bar.add_theme_stylebox_override("fill", fill)

func _style_button(button: Button, primary: bool) -> void:
    var normal_color: Color = Color("d5aa5a") if primary else Color(0.10, 0.13, 0.16, 0.96)
    var hover_color: Color = Color("e0b765") if primary else Color(0.14, 0.18, 0.21, 0.98)
    var pressed_color: Color = Color("bd9045") if primary else Color(0.075, 0.095, 0.115, 1.0)
    button.add_theme_stylebox_override("normal", _box_style(normal_color, 12, Color(0.30, 0.34, 0.38, 0.75)))
    button.add_theme_stylebox_override("hover", _box_style(hover_color, 12, Color(0.45, 0.50, 0.54, 0.80)))
    button.add_theme_stylebox_override("pressed", _box_style(pressed_color, 12, Color(0.24, 0.28, 0.31, 0.9)))
    button.add_theme_color_override("font_color", Color("202427") if primary else Color("e8edef"))
    button.add_theme_color_override("font_hover_color", Color("202427") if primary else Color.WHITE)

func _box_style(color: Color, radius: int, border_color: Color) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border_color
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style
