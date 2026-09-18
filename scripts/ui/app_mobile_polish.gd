extends "res://scripts/ui/app_expedition_wow.gd"

var mobile_scroll: MobileScrollContainer

func _build_shell() -> void:
    var background := ColorRect.new()
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("091014")

    shell = Control.new()
    add_child(shell)
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var margin := MarginContainer.new()
    shell.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 8)

    var main := VBoxContainer.new()
    margin.add_child(main)
    main.add_theme_constant_override("separation", 8)

    var header_panel := PanelContainer.new()
    main.add_child(header_panel)
    header_panel.custom_minimum_size = Vector2(0, 50)
    header_panel.add_theme_stylebox_override("panel", _pixel_style(Color("10191d"), Color("344249"), 2, 1, 9))

    var header := HBoxContainer.new()
    header_panel.add_child(header)
    header.add_theme_constant_override("separation", 6)

    var title_box := VBoxContainer.new()
    header.add_child(title_box)
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_box.add_theme_constant_override("separation", -3)

    var title := Label.new()
    title_box.add_child(title)
    title.text = "AXEHOLD"
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", Color("f2ead8"))

    var subtitle := Label.new()
    title_box.add_child(subtitle)
    subtitle.text = "LAST HEARTH  •  V1.7 BUILDINGS + ECONOMY"
    subtitle.add_theme_font_size_override("font_size", 8)
    subtitle.add_theme_color_override("font_color", Color("c5a66b"))

    coins_label = _header_pill(header, "МОН 0", Color("d5ae64"))
    shards_label = _header_pill(header, "ОСК 0", Color("d88962"))

    var settings := Button.new()
    header.add_child(settings)
    settings.text = "НАСТ"
    settings.custom_minimum_size = Vector2(44, 40)
    settings.add_theme_font_size_override("font_size", 7)
    settings.tooltip_text = "Настройки"
    settings.add_theme_stylebox_override("normal", _pixel_style(Color("172129"), Color("3d4b52"), 1, 2, 5))
    settings.pressed.connect(_show_settings)

    mobile_scroll = MobileScrollContainer.new()
    main.add_child(mobile_scroll)
    mobile_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

    body = VBoxContainer.new()
    mobile_scroll.add_child(body)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 9)

    nav = HBoxContainer.new()
    main.add_child(nav)
    nav.custom_minimum_size = Vector2(0, 52)
    nav.add_theme_constant_override("separation", 4)
    _mobile_nav_button("ЛАГЕРЬ", _show_home)
    _mobile_nav_button("АРСЕНАЛ", _show_arsenal)
    _mobile_nav_button("КАРТА", _show_map)
    _mobile_nav_button("ТРОФЕИ", _show_goals)

func _clear_body() -> void:
    super._clear_body()
    if mobile_scroll != null:
        mobile_scroll.set_deferred("scroll_vertical", 0)

func _panel(parent: Control) -> PanelContainer:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.add_theme_stylebox_override("panel", _pixel_style(Color("141e23"), Color("303e44"), 1, 2, 11))
    return panel

func _button(parent: Control, text: String, primary: bool) -> Button:
    var button := Button.new()
    parent.add_child(button)
    button.text = _clean(text)
    button.custom_minimum_size = Vector2(0, 46)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 10)
    var normal: Color = Color("bd9251") if primary else Color("182329")
    var border: Color = Color("e0b867") if primary else Color("37464d")
    button.add_theme_stylebox_override("normal", _pixel_style(normal, border, 1, 3, 8))
    button.add_theme_stylebox_override("hover", _pixel_style(normal.lightened(0.07), border.lightened(0.10), 1, 3, 8))
    button.add_theme_stylebox_override("pressed", _pixel_style(normal.darkened(0.12), border.darkened(0.10), 1, 3, 8))
    button.add_theme_color_override("font_color", Color("16191b") if primary else Color("eef1eb"))
    return button

func _section(title_text: String, description: String) -> void:
    var marker := Label.new()
    body.add_child(marker)
    marker.text = _clean(title_text).to_upper()
    marker.add_theme_font_size_override("font_size", 16)
    marker.add_theme_color_override("font_color", Color("e5c47e"))
    var desc := Label.new()
    body.add_child(desc)
    desc.text = _clean(description)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 10)
    desc.add_theme_color_override("font_color", Color("9eabb0"))

func _stat(parent: Control, title_text: String, value_text: String) -> void:
    var panel := _panel(parent)
    panel.custom_minimum_size = Vector2(170, 68)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 2)
    var title := Label.new()
    box.add_child(title)
    title.text = _clean(title_text).to_upper()
    title.add_theme_font_size_override("font_size", 8)
    title.add_theme_color_override("font_color", Color("9fa9ad"))
    var value := Label.new()
    box.add_child(value)
    value.text = _clean(value_text)
    value.add_theme_font_size_override("font_size", 18)
    value.add_theme_color_override("font_color", Color("f0eadb"))

func _header_pill(parent: Control, text: String, accent: Color) -> Label:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.custom_minimum_size = Vector2(57, 40)
    panel.add_theme_stylebox_override("panel", _pixel_style(Color("1b262e"), Color(accent, 0.48), 1, 2, 6))
    var label := Label.new()
    panel.add_child(label)
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 9)
    label.add_theme_color_override("font_color", Color("eef2ef"))
    return label

func _mobile_nav_button(text: String, callback: Callable) -> void:
    var button := Button.new()
    nav.add_child(button)
    button.text = text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size = Vector2(0, 46)
    button.add_theme_font_size_override("font_size", 7)
    button.add_theme_stylebox_override("normal", _pixel_style(Color("141d23"), Color("303d45"), 1, 2, 4))
    button.add_theme_stylebox_override("pressed", _pixel_style(Color("293840"), Color("bd9858"), 1, 2, 4))
    button.pressed.connect(callback)

func _refresh_currency() -> void:
    if coins_label != null:
        coins_label.text = "МОН %d" % int(GameState.data.get("coins", 0))
    if shards_label != null:
        shards_label.text = "ОСК %d" % int(GameState.data.get("shards", 0))

func _clean(value: String) -> String:
    var sanitizer: Node = get_tree().root.get_node_or_null("UISanitizer")
    if sanitizer != null and sanitizer.has_method("clean_text"):
        return str(sanitizer.call("clean_text", value))
    return value

func _pixel_style(fill: Color, border: Color, radius: int, border_width: int, margin: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
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
