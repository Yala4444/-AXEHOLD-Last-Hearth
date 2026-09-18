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

func _ready() -> void:
    _build()

func _build() -> void:
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var top: HBoxContainer = HBoxContainer.new()
    root.add_child(top)
    top.position = Vector2(9, 9)
    top.size = Vector2(372, 44)
    top.add_theme_constant_override("separation", 5)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hp_label = _chip(top, "HP 100", Color("d4655b"))
    base_label = _chip(top, "ОЧАГ 270", Color("e3a14f"))
    wave_label = _chip(top, "НОЧЬ 0/3", Color("9080b4"))

    var pause: Button = Button.new()
    top.add_child(pause)
    pause.text = "II"
    pause.custom_minimum_size = Vector2(38, 40)
    pause.tooltip_text = "Пауза"
    _style_button(pause, false)
    pause.pressed.connect(func() -> void: action_requested.emit("pause"))

    var phase_panel: PanelContainer = _panel(root, Rect2(9, 58, 372, 54), Color("162127"), 5, Color("344047"))
    phase_label = Label.new()
    phase_panel.add_child(phase_label)
    phase_label.position = Vector2(10, 4)
    phase_label.size = Vector2(352, 18)
    phase_label.add_theme_font_size_override("font_size", 11)
    phase_label.add_theme_color_override("font_color", Color("e7e3d5"))

    phase_bar = ProgressBar.new()
    phase_panel.add_child(phase_bar)
    phase_bar.position = Vector2(10, 25)
    phase_bar.size = Vector2(352, 7)
    phase_bar.show_percentage = false
    _style_progress(phase_bar, Color("263138"), Color("d9a94f"), 1)

    xp_bar = ProgressBar.new()
    phase_panel.add_child(xp_bar)
    xp_bar.position = Vector2(48, 39)
    xp_bar.size = Vector2(314, 5)
    xp_bar.show_percentage = false
    _style_progress(xp_bar, Color("202930"), Color("7286c7"), 1)

    level_label = Label.new()
    phase_panel.add_child(level_label)
    level_label.position = Vector2(10, 34)
    level_label.size = Vector2(38, 15)
    level_label.add_theme_font_size_override("font_size", 8)
    level_label.add_theme_color_override("font_color", Color("b4bdd7"))

    var backpack_panel: PanelContainer = _panel(root, Rect2(9, 119, 181, 72), Color("17242a"), 5, Color("40515a"))
    var bp_title := Label.new()
    backpack_panel.add_child(bp_title)
    bp_title.text = "РЮКЗАК"
    bp_title.position = Vector2(9, 5)
    bp_title.size = Vector2(160, 17)
    bp_title.add_theme_font_size_override("font_size", 9)
    bp_title.add_theme_color_override("font_color", Color("9ec9ba"))
    backpack_label = Label.new()
    backpack_panel.add_child(backpack_label)
    backpack_label.position = Vector2(9, 24)
    backpack_label.size = Vector2(162, 40)
    backpack_label.add_theme_font_size_override("font_size", 10)
    backpack_label.add_theme_color_override("font_color", Color("f1eddf"))

    var storage_panel: PanelContainer = _panel(root, Rect2(199, 119, 182, 72), Color("201f1b"), 5, Color("544b3d"))
    var st_title := Label.new()
    storage_panel.add_child(st_title)
    st_title.text = "СКЛАД ОЧАГА"
    st_title.position = Vector2(9, 5)
    st_title.size = Vector2(164, 17)
    st_title.add_theme_font_size_override("font_size", 9)
    st_title.add_theme_color_override("font_color", Color("d8bd80"))
    storage_label = Label.new()
    storage_panel.add_child(storage_label)
    storage_label.position = Vector2(9, 24)
    storage_label.size = Vector2(164, 40)
    storage_label.add_theme_font_size_override("font_size", 10)
    storage_label.add_theme_color_override("font_color", Color("f1eddf"))

    objective_label = Label.new()
    root.add_child(objective_label)
    objective_label.position = Vector2(14, 198)
    objective_label.size = Vector2(362, 30)
    objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_label.add_theme_font_size_override("font_size", 9)
    objective_label.add_theme_color_override("font_color", Color(0.16, 0.20, 0.16, 0.82))

    boss_panel = _panel(root, Rect2(45, 232, 300, 48), Color("32191d"), 4, Color("754349"))
    boss_panel.visible = false
    boss_label = Label.new()
    boss_panel.add_child(boss_label)
    boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_label.position = Vector2(8, 3)
    boss_label.size = Vector2(284, 18)
    boss_label.add_theme_font_size_override("font_size", 10)
    boss_label.add_theme_color_override("font_color", Color("ffd6b4"))
    boss_bar = ProgressBar.new()
    boss_panel.add_child(boss_bar)
    boss_bar.position = Vector2(10, 27)
    boss_bar.size = Vector2(280, 7)
    boss_bar.show_percentage = false
    _style_progress(boss_bar, Color("3a171b"), Color("cb5b5d"), 1)

    banner = Label.new()
    root.add_child(banner)
    banner.position = Vector2(20, 285)
    banner.size = Vector2(350, 43)
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 18)
    banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
    banner.add_theme_constant_override("shadow_offset_x", 2)
    banner.add_theme_constant_override("shadow_offset_y", 2)
    banner.modulate.a = 0.0
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

    build_panel = _panel(root, Rect2(162, 638, 219, 143), Color(0.035, 0.052, 0.060, 0.94), 5, Color("4d5b5d"))
    build_panel.visible = false
    build_title = Label.new()
    build_panel.add_child(build_title)
    build_title.position = Vector2(10, 7)
    build_title.size = Vector2(199, 20)
    build_title.add_theme_font_size_override("font_size", 11)
    build_title.add_theme_color_override("font_color", Color("f0cf83"))
    build_effect = Label.new()
    build_panel.add_child(build_effect)
    build_effect.position = Vector2(10, 31)
    build_effect.size = Vector2(199, 58)
    build_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    build_effect.add_theme_font_size_override("font_size", 9)
    build_effect.add_theme_color_override("font_color", Color("d6dedb"))
    build_cost = Label.new()
    build_panel.add_child(build_cost)
    build_cost.position = Vector2(10, 96)
    build_cost.size = Vector2(199, 38)
    build_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    build_cost.add_theme_font_size_override("font_size", 9)

    status_label = Label.new()
    root.add_child(status_label)
    status_label.position = Vector2(164, 792)
    status_label.size = Vector2(174, 38)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    status_label.add_theme_font_size_override("font_size", 8)
    status_label.add_theme_color_override("font_color", Color("33413e"))

    var leave: Button = Button.new()
    root.add_child(leave)
    leave.text = "ВЫХОД"
    leave.position = Vector2(339, 792)
    leave.size = Vector2(42, 36)
    leave.add_theme_font_size_override("font_size", 7)
    _style_button(leave, false)
    leave.pressed.connect(func() -> void: action_requested.emit("quit"))

    flash = ColorRect.new()
    root.add_child(flash)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(1, 0, 0, 0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

    modal = ColorRect.new()
    root.add_child(modal)
    modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal.color = Color(0.018, 0.028, 0.043, 0.80)
    modal.visible = false
    modal.mouse_filter = Control.MOUSE_FILTER_STOP

    var center: CenterContainer = CenterContainer.new()
    modal.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var modal_panel: PanelContainer = PanelContainer.new()
    center.add_child(modal_panel)
    modal_panel.custom_minimum_size = Vector2(336, 0)
    modal_panel.add_theme_stylebox_override("panel", _box_style(Color("121b21"), 6, Color("4a575d")))

    modal_box = VBoxContainer.new()
    modal_panel.add_child(modal_box)
    modal_box.add_theme_constant_override("separation", 10)

func update_stats(hero_hp: float, base_hp: float, bag: int, capacity: int, wave: int, phase: String, phase_value: float, xp: int, next_xp: int, level: int, storage: Dictionary, enemies_left: int, inventory: Dictionary = {}) -> void:
    hp_label.text = "HP %d" % int(ceil(hero_hp))
    base_label.text = "ОЧАГ %d" % int(ceil(maxf(base_hp, 0.0)))
    wave_label.text = "НОЧЬ %d/3" % wave
    if phase == "day":
        phase_label.text = "ДЕНЬ %d  •  ДО НОЧИ %d СЕК" % [wave + 1, int(ceil(phase_value))]
        phase_bar.value = clampf(phase_value / maxf(1.0, GameRules.day_duration(wave)) * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color("263138"), Color("d9a94f"), 1)
        objective_label.text = "ДОБЫВАЙ  →  ВЕРНИСЬ К ОЧАГУ  →  ПОСТРОЙ ЗАЩИТУ"
    else:
        phase_label.text = "НОЧЬ %d  •  ОСТАЛОСЬ ВРАГОВ: %d" % [wave, enemies_left]
        phase_bar.value = clampf(float(enemies_left) / float(maxi(1, 8 + wave * 4)) * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color("202532"), Color("8970b3"), 1)
        objective_label.text = "ЗАЩИТИ ОЧАГ. ПОСТРОЙКИ РАБОТАЮТ ВМЕСТЕ С ТОБОЙ."

    xp_bar.value = clampf(float(xp) / float(maxi(1, next_xp)) * 100.0, 0.0, 100.0)
    level_label.text = "LV %d" % level
    backpack_label.text = "%d/%d\nДЕР %d   КАМ %d   РУД %d" % [
        bag, capacity,
        int(inventory.get("wood", 0)), int(inventory.get("stone", 0)), int(inventory.get("ore", 0))
    ]
    storage_label.text = "НА БАЗЕ\nДЕР %d   КАМ %d   РУД %d" % [
        int(storage.get("wood", 0)), int(storage.get("stone", 0)), int(storage.get("ore", 0))
    ]

func set_build_context(title: String, effect: String, cost: Dictionary, storage: Dictionary, ready: bool, progress: float = 0.0) -> void:
    build_panel.visible = true
    build_title.text = title
    build_effect.text = effect
    var wood_need: int = maxi(0, int(cost.get("wood", 0)) - int(storage.get("wood", 0)))
    var stone_need: int = maxi(0, int(cost.get("stone", 0)) - int(storage.get("stone", 0)))
    var ore_need: int = maxi(0, int(cost.get("ore", 0)) - int(storage.get("ore", 0)))
    if ready:
        if progress <= 0.01:
            build_cost.text = "РЕСУРСОВ ХВАТАЕТ • ПОДОЙДИ БЛИЖЕ"
        else:
            build_cost.text = "СТРОИТСЯ... %d%%" % int(clampf(progress, 0.0, 1.0) * 100.0)
        build_cost.add_theme_color_override("font_color", Color("8ed3a8"))
    else:
        build_cost.text = "НЕ ХВАТАЕТ:  Д %d  К %d  Р %d" % [wood_need, stone_need, ore_need]
        build_cost.add_theme_color_override("font_color", Color("e6a08c"))

func set_built_context(title: String, effect: String) -> void:
    build_panel.visible = true
    build_title.text = title + "  •  РАБОТАЕТ"
    build_effect.text = effect
    build_cost.text = "АКТИВНО"
    build_cost.add_theme_color_override("font_color", Color("8ed3a8"))

func hide_build_context() -> void:
    build_panel.visible = false

func set_status(text: String) -> void:
    status_label.text = _safe(text)

func show_banner(text: String, color: Color = Color("f4d79a")) -> void:
    banner.text = _safe(text)
    banner.add_theme_color_override("font_color", color)
    banner.modulate.a = 0.0
    banner.scale = Vector2(0.92, 0.92)
    banner.pivot_offset = banner.size * 0.5
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(banner, "modulate:a", 1.0, 0.14)
    tween.tween_property(banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(0.74)
    tween.chain().set_parallel(true)
    tween.tween_property(banner, "modulate:a", 0.0, 0.24)
    tween.tween_property(banner, "scale", Vector2(1.03, 1.03), 0.24)

func show_boss(name: String, hp: float, max_hp: float) -> void:
    boss_panel.visible = true
    boss_label.text = name.to_upper()
    boss_bar.value = clampf(hp / maxf(1.0, max_hp) * 100.0, 0.0, 100.0)

func hide_boss() -> void:
    boss_panel.visible = false

func damage_feedback(blocked: bool) -> void:
    flash.color = Color(0.35, 0.75, 1.0, 0.15) if blocked else Color(0.95, 0.16, 0.16, 0.20)
    var tween: Tween = create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.24)

func show_modal(icon: String, title: String, body_text: String, buttons: Array) -> void:
    modal.visible = true
    modal.modulate.a = 0.0
    for child: Node in modal_box.get_children():
        child.queue_free()

    var safe_icon: String = _safe(icon)
    if not safe_icon.strip_edges().is_empty():
        var icon_label: Label = Label.new()
        icon_label.text = safe_icon
        icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon_label.add_theme_font_size_override("font_size", 18)
        modal_box.add_child(icon_label)

    var title_label: Label = Label.new()
    title_label.text = _safe(title)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 18)
    title_label.add_theme_color_override("font_color", Color("f6ead0"))
    modal_box.add_child(title_label)

    var body_label: Label = Label.new()
    body_label.text = _safe(body_text)
    body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 11)
    body_label.add_theme_color_override("font_color", Color("cdd4da"))
    modal_box.add_child(body_label)

    for spec_variant: Variant in buttons:
        var spec: Dictionary = spec_variant as Dictionary
        var button: Button = Button.new()
        button.text = _safe(str(spec.get("text", "OK")))
        button.custom_minimum_size = Vector2(0, 47)
        _style_button(button, modal_box.get_child_count() <= 2)
        var action: String = str(spec.get("action", "close"))
        button.pressed.connect(func() -> void: action_requested.emit(action))
        modal_box.add_child(button)

    var tween: Tween = create_tween()
    tween.tween_property(modal, "modulate:a", 1.0, 0.14)

func hide_modal() -> void:
    modal.visible = false

func modal_open() -> bool:
    return modal != null and modal.visible

func _safe(text: String) -> String:
    var sanitizer: Node = get_tree().root.get_node_or_null("UISanitizer")
    if sanitizer != null and sanitizer.has_method("clean_text"):
        return str(sanitizer.call("clean_text", text))
    return text

func _chip(parent: Control, text: String, accent: Color) -> Label:
    var panel: PanelContainer = PanelContainer.new()
    parent.add_child(panel)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _box_style(Color("151f25"), 4, Color(accent, 0.50)))
    var label: Label = Label.new()
    panel.add_child(label)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 9)
    label.add_theme_color_override("font_color", Color("edf2f4"))
    return label

func _panel(parent: Control, rect: Rect2, color: Color, radius: int, border_color: Color) -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    parent.add_child(panel)
    panel.position = rect.position
    panel.size = rect.size
    panel.add_theme_stylebox_override("panel", _box_style(color, radius, border_color))
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
    var normal_color: Color = Color("d5aa5a") if primary else Color("182127")
    var pressed_color: Color = Color("b98b43") if primary else Color("0f161a")
    button.add_theme_stylebox_override("normal", _box_style(normal_color, 4, Color("4b5559")))
    button.add_theme_stylebox_override("hover", _box_style(normal_color.lightened(0.08), 4, Color("69757a")))
    button.add_theme_stylebox_override("pressed", _box_style(pressed_color, 4, Color("343d42")))
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
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    return style
