extends "res://scripts/ui/app_expedition_wow.gd"

func _build_shell() -> void:
    var background := ColorRect.new()
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("0b1218")

    shell = Control.new()
    add_child(shell)
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var margin := MarginContainer.new()
    shell.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 10)

    var main := VBoxContainer.new()
    margin.add_child(main)
    main.add_theme_constant_override("separation", 9)

    var header_panel := PanelContainer.new()
    main.add_child(header_panel)
    header_panel.custom_minimum_size = Vector2(0, 58)
    var header_style := StyleBoxFlat.new()
    header_style.bg_color = Color("111a22")
    header_style.border_color = Color(0.20, 0.28, 0.33, 0.65)
    header_style.set_border_width_all(1)
    header_style.corner_radius_top_left = 18
    header_style.corner_radius_top_right = 18
    header_style.corner_radius_bottom_left = 18
    header_style.corner_radius_bottom_right = 18
    header_style.content_margin_left = 12
    header_style.content_margin_right = 10
    header_panel.add_theme_stylebox_override("panel", header_style)

    var header := HBoxContainer.new()
    header_panel.add_child(header)
    header.add_theme_constant_override("separation", 7)

    var title_box := VBoxContainer.new()
    header.add_child(title_box)
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_box.add_theme_constant_override("separation", -2)

    var title := Label.new()
    title_box.add_child(title)
    title.text = "AXEHOLD"
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", Color("f1eadb"))

    var subtitle := Label.new()
    title_box.add_child(subtitle)
    subtitle.text = "LAST HEARTH"
    subtitle.add_theme_font_size_override("font_size", 9)
    subtitle.add_theme_color_override("font_color", Color("c7aa72"))

    coins_label = _header_pill(header, "МОН 0", Color("d5ae64"))
    shards_label = _header_pill(header, "ОСК 0", Color("d88962"))

    var settings := Button.new()
    header.add_child(settings)
    settings.text = "..."
    settings.custom_minimum_size = Vector2(42, 40)
    settings.add_theme_font_size_override("font_size", 14)
    settings.tooltip_text = "Настройки"
    settings.pressed.connect(_show_settings)

    var scroll := ScrollContainer.new()
    main.add_child(scroll)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

    body = VBoxContainer.new()
    scroll.add_child(body)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 10)

    nav = HBoxContainer.new()
    main.add_child(nav)
    nav.custom_minimum_size = Vector2(0, 58)
    nav.add_theme_constant_override("separation", 5)
    _mobile_nav_button("ЛАГ", _show_home)
    _mobile_nav_button("КАРТА", _show_map)
    _mobile_nav_button("КУЗНЯ", _show_forge)
    _mobile_nav_button("ЦЕЛИ", _show_goals)
    _mobile_nav_button("ОБЛИК", _show_collection)

func _header_pill(parent: Control, text: String, accent: Color) -> Label:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.custom_minimum_size = Vector2(58, 40)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("1c2730")
    style.border_color = Color(accent, 0.35)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.content_margin_left = 7
    style.content_margin_right = 7
    panel.add_theme_stylebox_override("panel", style)
    var label := Label.new()
    panel.add_child(label)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 10)
    label.add_theme_color_override("font_color", Color("eef2ef"))
    return label

func _mobile_nav_button(text: String, callback: Callable) -> void:
    var button := Button.new()
    nav.add_child(button)
    button.text = text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size = Vector2(0, 52)
    button.add_theme_font_size_override("font_size", 9)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("151e25")
    style.border_color = Color(0.22, 0.30, 0.34, 0.50)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    button.add_theme_stylebox_override("normal", style)
    button.pressed.connect(callback)

func _refresh_currency() -> void:
    if coins_label != null:
        coins_label.text = "МОН %d" % int(GameState.data.get("coins", 0))
    if shards_label != null:
        shards_label.text = "ОСК %d" % int(GameState.data.get("shards", 0))
