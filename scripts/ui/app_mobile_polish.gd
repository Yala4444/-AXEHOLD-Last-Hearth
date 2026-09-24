extends "res://scripts/ui/app_expedition_wow.gd"

var mobile_scroll: MobileScrollContainer
var nav_buttons: Dictionary = {}
var active_nav_key: String = "camp"
var menu_background: ColorRect
var menu_vignette: ColorRect
var nav_frame: PanelContainer

func _build_shell() -> void:
    menu_background = ColorRect.new()
    add_child(menu_background)
    menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_background.color = VisualSystem.BG
    menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE

    menu_vignette = ColorRect.new()
    add_child(menu_vignette)
    menu_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_vignette.color = Color(0.02, 0.035, 0.04, 0.22)
    menu_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE

    shell = Control.new()
    add_child(shell)
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var margin := MarginContainer.new()
    shell.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 7)

    var main := VBoxContainer.new()
    margin.add_child(main)
    main.add_theme_constant_override("separation", 7)

    var header := HBoxContainer.new()
    main.add_child(header)
    header.custom_minimum_size = Vector2(0, 42)
    header.add_theme_constant_override("separation", 6)

    var title_box := VBoxContainer.new()
    header.add_child(title_box)
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_box.add_theme_constant_override("separation", -4)

    var title := Label.new()
    title_box.add_child(title)
    title.text = "AXEHOLD"
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", VisualSystem.TEXT)

    var subtitle := Label.new()
    title_box.add_child(subtitle)
    subtitle.text = "FOREST SURVIVAL"
    subtitle.add_theme_font_size_override("font_size", 7)
    subtitle.add_theme_color_override("font_color", VisualSystem.GOLD)

    coins_label = _header_currency(header, "coin", VisualSystem.COIN)
    shards_label = _header_currency(header, "shard", VisualSystem.SHARD)

    var settings := Button.new()
    header.add_child(settings)
    settings.custom_minimum_size = Vector2(38, 34)
    settings.focus_mode = Control.FOCUS_NONE
    settings.add_theme_stylebox_override("normal", VisualSystem.panel(VisualSystem.SURFACE, VisualSystem.BORDER_SOFT, 5, 0, 1))
    settings.add_theme_stylebox_override("pressed", VisualSystem.panel(VisualSystem.SURFACE_3, VisualSystem.GOLD, 5, 0, 1))
    var settings_icon := UiIcon.new()
    settings.add_child(settings_icon)
    settings_icon.configure("settings", VisualSystem.TEXT_SOFT, 0.78)
    settings_icon.position = Vector2(9, 7)
    settings.pressed.connect(_show_settings)

    mobile_scroll = MobileScrollContainer.new()
    main.add_child(mobile_scroll)
    mobile_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

    body = VBoxContainer.new()
    mobile_scroll.add_child(body)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 8)

    nav_frame = PanelContainer.new()
    main.add_child(nav_frame)
    nav_frame.custom_minimum_size = Vector2(0, 58)
    nav_frame.add_theme_stylebox_override("panel", VisualSystem.panel(Color("0d161a"), Color("28363b"), 6, 4, 1))

    nav = HBoxContainer.new()
    nav_frame.add_child(nav)
    nav.add_theme_constant_override("separation", 3)
    _mobile_nav_button("camp", "ЛАГЕРЬ", "camp", _show_home)
    _mobile_nav_button("arsenal", "АРСЕНАЛ", "arsenal", _show_arsenal)
    _mobile_nav_button("map", "КАРТА", "map", _show_map)
    _mobile_nav_button("trophy", "ТРОФЕИ", "trophy", _show_goals)
    _refresh_nav_state()

func _set_menu_backdrop_visible(value: bool) -> void:
    if menu_background != null:
        menu_background.visible = value
    if menu_vignette != null:
        menu_vignette.visible = value

func _start_game() -> void:
    _set_menu_backdrop_visible(false)
    super._start_game()

func _on_game_quit() -> void:
    _set_menu_backdrop_visible(true)
    super._on_game_quit()

func _on_run_finished(result: Dictionary) -> void:
    _set_menu_backdrop_visible(true)
    super._on_run_finished(result)

func _clear_body() -> void:
    super._clear_body()
    if nav_frame != null:
        nav_frame.visible = true
    if mobile_scroll != null:
        mobile_scroll.set_deferred("scroll_vertical", 0)

func _show_settings() -> void:
    super._show_settings()
    if nav_frame != null:
        nav_frame.visible = false

func _show_result() -> void:
    super._show_result()
    if nav_frame != null:
        nav_frame.visible = false

func _show_homecoming(snapshot: Dictionary) -> void:
    super._show_homecoming(snapshot)
    if nav_frame != null:
        nav_frame.visible = false

func _panel(parent: Control) -> PanelContainer:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.add_theme_stylebox_override("panel", VisualSystem.panel(VisualSystem.SURFACE, VisualSystem.BORDER_SOFT, 5, 10, 1))
    return panel

func _button(parent: Control, text: String, primary: bool) -> Button:
    var button := Button.new()
    parent.add_child(button)
    button.text = _clean(text)
    button.custom_minimum_size = Vector2(0, 44)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 10)
    button.add_theme_stylebox_override("normal", VisualSystem.button(primary, false))
    button.add_theme_stylebox_override("hover", VisualSystem.panel((VisualSystem.GOLD if primary else VisualSystem.SURFACE_2).lightened(0.045), VisualSystem.GOLD_BRIGHT if primary else VisualSystem.BORDER, 5, 9, 1))
    button.add_theme_stylebox_override("pressed", VisualSystem.button(primary, true))
    button.add_theme_stylebox_override("disabled", VisualSystem.panel(Color("11181c"), Color("263238"), 5, 9, 1))
    button.add_theme_color_override("font_color", Color("171a1c") if primary else VisualSystem.TEXT)
    button.add_theme_color_override("font_disabled_color", VisualSystem.TEXT_MUTED)
    return button

func _section(title_text: String, description: String) -> void:
    var group := VBoxContainer.new()
    body.add_child(group)
    group.add_theme_constant_override("separation", 2)

    var marker := Label.new()
    group.add_child(marker)
    marker.text = _clean(title_text).to_upper()
    marker.add_theme_font_size_override("font_size", 14)
    marker.add_theme_color_override("font_color", VisualSystem.GOLD_BRIGHT)

    if not description.strip_edges().is_empty():
        var desc := Label.new()
        group.add_child(desc)
        desc.text = _clean(description)
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.add_theme_font_size_override("font_size", 9)
        desc.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)

func _stat(parent: Control, title_text: String, value_text: String) -> void:
    var panel := _panel(parent)
    panel.custom_minimum_size = Vector2(158, 60)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 0)
    var title := Label.new()
    box.add_child(title)
    title.text = _clean(title_text).to_upper()
    title.add_theme_font_size_override("font_size", 7)
    title.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)
    var value := Label.new()
    box.add_child(value)
    value.text = _clean(value_text)
    value.add_theme_font_size_override("font_size", 16)
    value.add_theme_color_override("font_color", VisualSystem.TEXT)

func _header_currency(parent: Control, icon_kind: String, accent: Color) -> Label:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.custom_minimum_size = Vector2(60, 34)
    panel.add_theme_stylebox_override("panel", VisualSystem.chip(accent))

    var row := HBoxContainer.new()
    panel.add_child(row)
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 3)

    var icon := UiIcon.new()
    row.add_child(icon)
    icon.configure(icon_kind, accent, 0.68)

    var label := Label.new()
    row.add_child(label)
    label.text = "0"
    label.add_theme_font_size_override("font_size", 9)
    label.add_theme_color_override("font_color", VisualSystem.TEXT)
    return label

func _mobile_nav_button(key: String, label_text: String, icon_kind: String, callback: Callable) -> void:
    var button := Button.new()
    nav.add_child(button)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size = Vector2(0, 48)
    button.focus_mode = Control.FOCUS_NONE
    button.text = ""

    var icon := UiIcon.new()
    button.add_child(icon)
    icon.name = "Icon"
    icon.configure(icon_kind, VisualSystem.TEXT_MUTED, 0.72)
    icon.position = Vector2(0, 3)
    icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
    icon.position.x = -7

    var label := Label.new()
    button.add_child(label)
    label.name = "Label"
    label.text = label_text
    label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    label.offset_top = -18
    label.offset_bottom = -2
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 7)
    label.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    button.pressed.connect(func() -> void:
        active_nav_key = key
        _refresh_nav_state()
        callback.call()
    )
    nav_buttons[key] = button

func _refresh_nav_state() -> void:
    for key_variant: Variant in nav_buttons.keys():
        var key: String = str(key_variant)
        var button: Button = nav_buttons.get(key) as Button
        if button == null:
            continue
        var selected: bool = key == active_nav_key
        button.add_theme_stylebox_override("normal", VisualSystem.panel(
            Color(VisualSystem.GOLD, 0.08) if selected else Color(0,0,0,0),
            Color(VisualSystem.GOLD, 0.26) if selected else Color(0,0,0,0),
            5, 0, 1 if selected else 0
        ))
        button.add_theme_stylebox_override("pressed", VisualSystem.panel(Color(VisualSystem.GOLD, 0.13), Color(VisualSystem.GOLD, 0.36), 5, 0, 1))
        var icon: UiIcon = button.get_node_or_null("Icon") as UiIcon
        if icon != null:
            icon.accent = VisualSystem.GOLD_BRIGHT if selected else VisualSystem.TEXT_MUTED
            icon.queue_redraw()
        var label: Label = button.get_node_or_null("Label") as Label
        if label != null:
            label.add_theme_color_override("font_color", VisualSystem.GOLD_BRIGHT if selected else VisualSystem.TEXT_MUTED)

func _refresh_currency() -> void:
    if coins_label != null:
        coins_label.text = str(int(GameState.data.get("coins", 0)))
    if shards_label != null:
        shards_label.text = str(int(GameState.data.get("shards", 0)))

func _show_home() -> void:
    active_nav_key = "camp"
    _refresh_nav_state()
    super._show_home()

func _show_arsenal() -> void:
    active_nav_key = "arsenal"
    _refresh_nav_state()
    super._show_arsenal()

func _show_map() -> void:
    active_nav_key = "map"
    _refresh_nav_state()
    super._show_map()

func _show_goals() -> void:
    active_nav_key = "trophy"
    _refresh_nav_state()
    super._show_goals()

func _clean(value: String) -> String:
    var sanitizer: Node = get_tree().root.get_node_or_null("UISanitizer")
    if sanitizer != null and sanitizer.has_method("clean_text"):
        return str(sanitizer.call("clean_text", value))
    return value
