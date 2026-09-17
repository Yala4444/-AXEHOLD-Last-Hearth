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

    var top := HBoxContainer.new()
    root.add_child(top)
    top.position = Vector2(10, 10)
    top.size = Vector2(370, 48)
    top.add_theme_constant_override("separation", 6)
    hp_label = _chip(top, "❤️ 100")
    base_label = _chip(top, "🔥 270")
    bag_label = _chip(top, "🎒 0/20")
    wave_label = _chip(top, "🌙 0/3")

    var phase_panel := _panel(root, Rect2(10, 64, 370, 54))
    phase_label = Label.new()
    phase_panel.add_child(phase_label)
    phase_label.position = Vector2(10, 5)
    phase_label.size = Vector2(350, 18)
    phase_label.add_theme_font_size_override("font_size", 11)
    phase_bar = ProgressBar.new()
    phase_panel.add_child(phase_bar)
    phase_bar.position = Vector2(10, 25)
    phase_bar.size = Vector2(350, 8)
    phase_bar.show_percentage = false
    xp_bar = ProgressBar.new()
    phase_panel.add_child(xp_bar)
    xp_bar.position = Vector2(35, 39)
    xp_bar.size = Vector2(300, 6)
    xp_bar.show_percentage = false
    level_label = Label.new()
    phase_panel.add_child(level_label)
    level_label.position = Vector2(4, 34)
    level_label.size = Vector2(32, 15)
    level_label.add_theme_font_size_override("font_size", 9)

    boss_panel = _panel(root, Rect2(42, 126, 306, 48))
    boss_panel.visible = false
    boss_label = Label.new()
    boss_panel.add_child(boss_label)
    boss_label.text = "👑 ХРАНИТЕЛЬ"
    boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_label.position = Vector2(8, 3)
    boss_label.size = Vector2(290, 18)
    boss_label.add_theme_font_size_override("font_size", 11)
    boss_bar = ProgressBar.new()
    boss_panel.add_child(boss_bar)
    boss_bar.position = Vector2(10, 25)
    boss_bar.size = Vector2(286, 8)
    boss_bar.show_percentage = false

    banner = Label.new()
    root.add_child(banner)
    banner.position = Vector2(20, 184)
    banner.size = Vector2(350, 42)
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 20)
    banner.modulate.a = 0.0
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

    resources_label = Label.new()
    root.add_child(resources_label)
    resources_label.position = Vector2(12, 742)
    resources_label.size = Vector2(235, 28)
    resources_label.add_theme_font_size_override("font_size", 13)

    status_label = Label.new()
    root.add_child(status_label)
    status_label.position = Vector2(12, 775)
    status_label.size = Vector2(255, 55)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 11)
    status_label.modulate = Color(0.92, 0.92, 0.94)

    var leave := Button.new()
    root.add_child(leave)
    leave.text = "⌂"
    leave.position = Vector2(282, 775)
    leave.size = Vector2(44, 44)
    leave.pressed.connect(func(): action_requested.emit("quit"))
    var pause := Button.new()
    root.add_child(pause)
    pause.text = "Ⅱ"
    pause.position = Vector2(335, 775)
    pause.size = Vector2(44, 44)
    pause.pressed.connect(func(): action_requested.emit("pause"))

    flash = ColorRect.new()
    root.add_child(flash)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(1, 0, 0, 0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

    modal = ColorRect.new()
    root.add_child(modal)
    modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal.color = Color(0.03, 0.05, 0.08, 0.65)
    modal.visible = false
    modal.mouse_filter = Control.MOUSE_FILTER_STOP
    var center := CenterContainer.new()
    modal.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var modal_panel := PanelContainer.new()
    center.add_child(modal_panel)
    modal_panel.custom_minimum_size = Vector2(330, 0)
    modal_panel.add_theme_stylebox_override("panel", _box_style(Color(0.08,0.10,0.13,0.98), 20))
    modal_box = VBoxContainer.new()
    modal_panel.add_child(modal_box)
    modal_box.add_theme_constant_override("separation", 9)

func update_stats(hero_hp: float, base_hp: float, bag: int, capacity: int, wave: int, phase: String, phase_value: float, xp: int, next_xp: int, level: int, storage: Dictionary, enemies_left: int) -> void:
    hp_label.text = "❤️ %d" % int(ceil(hero_hp))
    base_label.text = "🔥 %d" % int(ceil(maxf(base_hp, 0.0)))
    bag_label.text = "🎒 %d/%d" % [bag, capacity]
    wave_label.text = "🌙 %d/3" % wave
    if phase == "day":
        phase_label.text = "До ночи · %d сек" % int(ceil(phase_value))
        phase_bar.value = clampf(phase_value / 28.0 * 100.0, 0.0, 100.0)
    else:
        phase_label.text = "Ночь %d · врагов %d" % [wave, enemies_left]
        phase_bar.value = clampf(float(enemies_left) / float(maxi(1, 9 + wave * 4)) * 100.0, 0.0, 100.0)
    xp_bar.value = clampf(float(xp) / float(maxi(1, next_xp)) * 100.0, 0.0, 100.0)
    level_label.text = "Lv.%d" % level
    resources_label.text = "🪵%d   🪨%d   ⛏%d" % [storage.get("wood",0), storage.get("stone",0), storage.get("ore",0)]

func set_status(text: String) -> void:
    status_label.text = text

func show_banner(text: String, color: Color = Color("f4d79a")) -> void:
    banner.text = text
    banner.add_theme_color_override("font_color", color)
    banner.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(banner, "modulate:a", 1.0, 0.18)
    tween.tween_interval(1.0)
    tween.tween_property(banner, "modulate:a", 0.0, 0.35)

func show_boss(name: String, hp: float, max_hp: float) -> void:
    boss_panel.visible = true
    boss_label.text = "👑 " + name.to_upper()
    boss_bar.value = clampf(hp / maxf(1.0, max_hp) * 100.0, 0.0, 100.0)

func hide_boss() -> void:
    boss_panel.visible = false

func damage_feedback(blocked: bool) -> void:
    flash.color = Color(0.35,0.75,1.0,0.15) if blocked else Color(0.95,0.16,0.16,0.20)
    var tween := create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.24)

func show_modal(icon: String, title: String, body: String, buttons: Array) -> void:
    modal.visible = true
    for child in modal_box.get_children():
        child.queue_free()
    var icon_label := Label.new()
    icon_label.text = icon
    icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon_label.add_theme_font_size_override("font_size", 30)
    modal_box.add_child(icon_label)
    var title_label := Label.new()
    title_label.text = title
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 20)
    modal_box.add_child(title_label)
    var body_label := Label.new()
    body_label.text = body
    body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 12)
    body_label.modulate = Color(0.82,0.84,0.88)
    modal_box.add_child(body_label)
    for spec in buttons:
        var button := Button.new()
        button.text = str(spec.get("text", "OK"))
        button.custom_minimum_size = Vector2(0, 46)
        var action := str(spec.get("action", "close"))
        button.pressed.connect(func(): action_requested.emit(action))
        modal_box.add_child(button)

func hide_modal() -> void:
    modal.visible = false

func modal_open() -> bool:
    return modal != null and modal.visible

func _chip(parent: Control, text: String) -> Label:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _box_style(Color(0.06,0.08,0.10,0.84), 12))
    var label := Label.new()
    panel.add_child(label)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 10)
    return label

func _panel(parent: Control, rect: Rect2) -> PanelContainer:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.position = rect.position
    panel.size = rect.size
    panel.add_theme_stylebox_override("panel", _box_style(Color(0.06,0.08,0.10,0.84), 14))
    return panel

func _box_style(color: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color(0.22,0.26,0.30,0.8)
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
