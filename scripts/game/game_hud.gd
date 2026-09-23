class_name GameHud
extends CanvasLayer

signal action_requested(action: String)

var root: Control
var hp_label: Label
var base_label: Label
var wave_label: Label
var phase_label: Label
var hp_bar: ProgressBar
var base_bar: ProgressBar
var phase_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var backpack_label: Label
var storage_label: Label
var storage_wood_label: Label
var storage_stone_label: Label
var storage_ore_label: Label
var storage_part_label: Label
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
var modal_panel: PanelContainer
var modal_box: VBoxContainer
var status_time: float = 0.0
var status_priority: int = 0
var status_generation: int = 0
var banner_queue: Array[Dictionary] = []
var banner_running: bool = false
var banner_current_text: String = ""
var visual_gate_enabled: bool = false

func _ready() -> void:
    layer = 60
    _build()
    get_viewport().size_changed.connect(_layout)
    _layout()

func set_visual_gate(value: bool) -> void:
    visual_gate_enabled = value
    if root == null:
        return

    var hp_panel := root.get_node_or_null("HeroPanel") as PanelContainer
    var phase_panel := root.get_node_or_null("PhasePanel") as PanelContainer
    var base_panel := root.get_node_or_null("BasePanel") as PanelContainer
    var storage_panel := root.get_node_or_null("StoragePanel") as PanelContainer
    var pause := root.get_node_or_null("PauseButton") as Button

    if visual_gate_enabled:
        modal.color = Color(0.006,0.012,0.014,0.86)
        modal_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color(0.025,0.035,0.034,0.96), Color(0.56,0.46,0.27,0.55), 9, 16, 1))
        # Release-look HUD: keep the same information and controls, but let the
        # world breathe. The three critical panels stay readable while their
        # surfaces become lighter and less "debug-dashboard" like.
        if hp_panel != null:
            hp_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color(0.025,0.038,0.040,0.72), Color(0.47,0.25,0.23,0.34), 6, 0, 1))
        if phase_panel != null:
            phase_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color(0.025,0.038,0.040,0.70), Color(0.31,0.36,0.34,0.30), 6, 0, 1))
        if base_panel != null:
            base_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color(0.030,0.040,0.034,0.72), Color(0.48,0.38,0.22,0.34), 6, 0, 1))
        if storage_panel != null:
            storage_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color(0.030,0.040,0.034,0.58), Color(0.38,0.33,0.23,0.24), 6, 0, 1))
        if pause != null:
            pause.add_theme_stylebox_override("normal", VisualSystem.panel(Color(0.025,0.038,0.040,0.66), Color(0.31,0.36,0.34,0.28), 6, 0, 1))
        objective_label.add_theme_color_override("font_color", Color("decfa4"))
        objective_label.add_theme_font_size_override("font_size", 7)
        status_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color(0.025,0.040,0.037,0.76), Color(0.38,0.46,0.39,0.28), 7, 0, 1))
        build_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color(0.025,0.040,0.037,0.82), Color(0.45,0.48,0.38,0.34), 7, 0, 1))
    _layout()

func _process(delta: float) -> void:
    if status_time > 0.0:
        status_time -= delta
        if status_time <= 0.0 and status_panel != null and status_panel.visible:
            var generation: int = status_generation
            var tween := create_tween()
            tween.tween_property(status_panel, "modulate:a", 0.0, 0.16)
            tween.tween_callback(func() -> void:
                if status_panel != null and generation == status_generation and status_time <= 0.0:
                    status_panel.visible = false
                    status_priority = 0
            )

func _build() -> void:
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var hp_panel := _panel(root, Color(0.035, 0.055, 0.060, 0.86), Color(0.50, 0.25, 0.23, 0.52))
    hp_panel.name = "HeroPanel"
    var hp_content := Control.new()
    hp_panel.add_child(hp_content)
    hp_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var heart_icon := UiIcon.new()
    hp_content.add_child(heart_icon)
    heart_icon.configure("heart", VisualSystem.RED, 0.62)
    heart_icon.position = Vector2(6, 4)
    hp_label = _make_label(hp_content, "100", 9, VisualSystem.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
    hp_bar = ProgressBar.new()
    hp_content.add_child(hp_bar)
    hp_bar.show_percentage = false
    _style_progress(hp_bar, Color("1b2022"), VisualSystem.RED, 2)

    var phase_panel := _panel(root, Color(0.035, 0.055, 0.060, 0.86), Color(0.28, 0.36, 0.39, 0.52))
    phase_panel.name = "PhasePanel"
    var phase_content := Control.new()
    phase_panel.add_child(phase_content)
    phase_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    phase_label = _make_label(phase_content, "ДЕНЬ · 45", 8, VisualSystem.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
    phase_bar = ProgressBar.new()
    phase_content.add_child(phase_bar)
    phase_bar.show_percentage = false
    _style_progress(phase_bar, Color("1b272b"), VisualSystem.GOLD, 2)
    xp_bar = ProgressBar.new()
    phase_content.add_child(xp_bar)
    xp_bar.show_percentage = false
    _style_progress(xp_bar, Color("182126"), VisualSystem.BLUE, 1)
    level_label = Label.new()
    phase_content.add_child(level_label)
    level_label.add_theme_font_size_override("font_size", 6)
    level_label.add_theme_color_override("font_color", Color("aebacf"))
    wave_label = Label.new()
    phase_content.add_child(wave_label)
    wave_label.add_theme_font_size_override("font_size", 6)
    wave_label.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)
    wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    var base_panel := _panel(root, Color(0.035, 0.055, 0.060, 0.86), Color(0.49, 0.39, 0.22, 0.52))
    base_panel.name = "BasePanel"
    var base_content := Control.new()
    base_panel.add_child(base_content)
    base_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var hearth_icon := UiIcon.new()
    base_content.add_child(hearth_icon)
    hearth_icon.configure("hearth", VisualSystem.GOLD_BRIGHT, 0.62)
    hearth_icon.position = Vector2(6, 4)
    base_label = _make_label(base_content, "270", 9, VisualSystem.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
    base_bar = ProgressBar.new()
    base_content.add_child(base_bar)
    base_bar.show_percentage = false
    _style_progress(base_bar, Color("24221b"), VisualSystem.GOLD, 2)

    var pause := Button.new()
    root.add_child(pause)
    pause.name = "PauseButton"
    pause.text = ""
    pause.focus_mode = Control.FOCUS_NONE
    pause.add_theme_stylebox_override("normal", VisualSystem.panel(Color(0.035,0.055,0.060,0.86), Color(0.28,0.35,0.38,0.52), 5, 0, 1))
    pause.add_theme_stylebox_override("pressed", VisualSystem.panel(VisualSystem.SURFACE_3, VisualSystem.GOLD, 5, 0, 1))
    var pause_icon := UiIcon.new()
    pause.add_child(pause_icon)
    pause_icon.configure("pause", VisualSystem.TEXT_SOFT, 0.60)
    pause_icon.position = Vector2(7, 6)
    pause.pressed.connect(func() -> void: action_requested.emit("pause"))

    var storage_panel := _panel(root, Color(0.045, 0.055, 0.050, 0.76), Color(0.39, 0.34, 0.24, 0.38))
    storage_panel.name = "StoragePanel"
    var storage_row := HBoxContainer.new()
    storage_panel.add_child(storage_row)
    storage_row.alignment = BoxContainer.ALIGNMENT_CENTER
    storage_row.add_theme_constant_override("separation", 7)
    var storage_title := Label.new()
    storage_row.add_child(storage_title)
    storage_title.text = "СКЛАД"
    storage_title.add_theme_font_size_override("font_size", 6)
    storage_title.add_theme_color_override("font_color", Color("8e8a7d"))
    storage_wood_label = _resource_chip(storage_row, "wood", "0")
    storage_stone_label = _resource_chip(storage_row, "stone", "0")
    storage_ore_label = _resource_chip(storage_row, "ore", "0")
    storage_part_label = _resource_chip(storage_row, "part", "0")

    storage_label = Label.new()
    root.add_child(storage_label)
    storage_label.visible = false
    backpack_label = Label.new()
    root.add_child(backpack_label)
    backpack_label.visible = false

    objective_label = Label.new()
    root.add_child(objective_label)
    objective_label.visible = false
    objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    objective_label.add_theme_font_size_override("font_size", 7)
    objective_label.add_theme_color_override("font_color", Color("cdbb86"))
    objective_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.55))
    objective_label.add_theme_constant_override("shadow_offset_y", 1)
    objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    status_panel = _panel(root, Color(0.025,0.045,0.045,0.86), Color(0.34,0.45,0.42,0.42))
    status_panel.visible = false
    status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status_label = _make_label(status_panel, "", 8, Color("e3ebe7"), HORIZONTAL_ALIGNMENT_CENTER)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    build_panel = _panel(root, Color(0.03,0.048,0.048,0.92), Color(0.40,0.48,0.43,0.58))
    build_panel.visible = false
    build_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var build_content := Control.new()
    build_panel.add_child(build_content)
    build_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    build_title = _make_label(build_content, "", 9, VisualSystem.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT)
    build_effect = _make_label(build_content, "", 7, Color("cad5d0"), HORIZONTAL_ALIGNMENT_LEFT)
    build_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    build_cost = _make_label(build_content, "", 7, Color("df9f83"), HORIZONTAL_ALIGNMENT_LEFT)

    boss_panel = _panel(root, Color(0.075,0.025,0.032,0.90), Color(0.58,0.26,0.28,0.62))
    boss_panel.visible = false
    var boss_content := Control.new()
    boss_panel.add_child(boss_content)
    boss_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var skull := UiIcon.new()
    boss_content.add_child(skull)
    skull.configure("skull", Color("e0a188"), 0.62)
    skull.position = Vector2(8, 5)
    boss_label = _make_label(boss_content, "ХРАНИТЕЛЬ", 8, Color("f0d4c1"), HORIZONTAL_ALIGNMENT_CENTER)
    boss_bar = ProgressBar.new()
    boss_content.add_child(boss_bar)
    boss_bar.show_percentage = false
    _style_progress(boss_bar, Color("2c1418"), Color("c95c55"), 2)

    banner = Label.new()
    root.add_child(banner)
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_theme_font_size_override("font_size", 14)
    banner.add_theme_color_override("font_shadow_color", Color(0,0,0,0.66))
    banner.add_theme_constant_override("shadow_offset_x", 1)
    banner.add_theme_constant_override("shadow_offset_y", 2)
    banner.modulate.a = 0.0
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

    flash = ColorRect.new()
    root.add_child(flash)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(1,0,0,0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

    modal = ColorRect.new()
    root.add_child(modal)
    modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal.color = Color(0.008,0.016,0.018,0.80)
    modal.visible = false
    modal.mouse_filter = Control.MOUSE_FILTER_STOP

    var center := CenterContainer.new()
    modal.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal_panel = PanelContainer.new()
    center.add_child(modal_panel)
    modal_panel.custom_minimum_size = Vector2(330, 0)
    modal_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color("0f181c"), Color("526168"), 6, 16, 1))
    modal_box = VBoxContainer.new()
    modal_panel.add_child(modal_box)
    modal_box.add_theme_constant_override("separation", 9)

func _layout() -> void:
    if root == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var width: float = size.x
    var margin: float = 7.0
    var gap: float = 4.0
    var pause_w: float = 30.0
    var hp_w: float = 66.0
    var base_w: float = 72.0
    var top_y: float = 6.0
    if visual_gate_enabled:
        # A little more breathing room from the browser/device edge and a
        # slightly narrower information strip on phones.
        margin = 9.0
        gap = 3.0
        pause_w = 31.0
        hp_w = 64.0
        base_w = 68.0
        top_y = 9.0
    var phase_w: float = width - margin * 2.0 - gap * 3.0 - pause_w - hp_w - base_w
    if modal_panel != null:
        modal_panel.custom_minimum_size = Vector2(clampf(width - 30.0, 250.0, 330.0), 0.0)

    var hp_panel := root.get_node("HeroPanel") as PanelContainer
    var phase_panel := root.get_node("PhasePanel") as PanelContainer
    var base_panel := root.get_node("BasePanel") as PanelContainer
    var pause := root.get_node("PauseButton") as Button
    var storage_panel := root.get_node("StoragePanel") as PanelContainer

    hp_panel.position = Vector2(margin, top_y)
    hp_panel.size = Vector2(hp_w, 33)
    phase_panel.position = Vector2(margin + hp_w + gap, top_y)
    phase_panel.size = Vector2(phase_w, 33)
    base_panel.position = Vector2(margin + hp_w + gap + phase_w + gap, top_y)
    base_panel.size = Vector2(base_w, 33)
    pause.position = Vector2(width - margin - pause_w, top_y)
    pause.size = Vector2(pause_w, 33)

    hp_label.position = Vector2(27, 3)
    hp_label.size = Vector2(hp_w - 33, 14)
    hp_bar.position = Vector2(7, 23)
    hp_bar.size = Vector2(hp_w - 14, 4)

    phase_label.position = Vector2(4, 1)
    phase_label.size = Vector2(phase_w - 8, 13)
    phase_bar.position = Vector2(7, 17)
    phase_bar.size = Vector2(phase_w - 14, 4)
    xp_bar.position = Vector2(28, 26)
    xp_bar.size = Vector2(maxf(26.0, phase_w - 36), 2)
    level_label.position = Vector2(6, 22)
    level_label.size = Vector2(22, 8)
    wave_label.position = Vector2(phase_w - 35, 22)
    wave_label.size = Vector2(29, 8)

    base_label.position = Vector2(27, 3)
    base_label.size = Vector2(base_w - 33, 14)
    base_bar.position = Vector2(7, 23)
    base_bar.size = Vector2(base_w - 14, 4)

    if visual_gate_enabled:
        var storage_w: float = minf(246.0, width - margin * 2.0)
        storage_panel.position = Vector2((width - storage_w) * 0.5, top_y + 37.0)
        storage_panel.size = Vector2(storage_w, 22)
        objective_label.position = Vector2(margin + 14, top_y + 62.0)
        objective_label.size = Vector2(width - margin * 2.0 - 28, 12)
    else:
        storage_panel.position = Vector2(margin, 43)
        storage_panel.size = Vector2(width - margin * 2.0, 24)
        objective_label.position = Vector2(margin + 8, 70)
        objective_label.size = Vector2(width - margin * 2.0 - 16, 12)

    var context_y: float = 87.0 if not visual_gate_enabled else top_y + 78.0
    build_panel.position = Vector2((width - 204.0) * 0.5, context_y)
    build_panel.size = Vector2(204, 54)
    build_title.position = Vector2(9, 4)
    build_title.size = Vector2(186, 13)
    build_effect.position = Vector2(9, 19)
    build_effect.size = Vector2(186, 21)
    build_cost.position = Vector2(9, 40)
    build_cost.size = Vector2(186, 11)

    status_panel.position = Vector2((width - 236.0) * 0.5, context_y + 1.0)
    status_panel.size = Vector2(236, 26)
    status_label.position = Vector2(7, 2)
    status_label.size = Vector2(222, 22)

    var boss_y: float = 118.0 if not visual_gate_enabled else context_y + 31.0
    boss_panel.position = Vector2(38, boss_y)
    boss_panel.size = Vector2(width - 76, 38)
    boss_label.position = Vector2(32, 2)
    boss_label.size = Vector2(width - 140, 14)
    boss_bar.position = Vector2(11, 25)
    boss_bar.size = Vector2(width - 98, 5)

    var banner_y: float = 163.0 if not visual_gate_enabled else boss_y + 45.0
    banner.position = Vector2(18, banner_y)
    banner.size = Vector2(width - 36, 34)

func update_stats(hero_hp: float, base_hp: float, bag: int, capacity: int, wave: int, phase: String, phase_value: float, xp: int, next_xp: int, level: int, storage: Dictionary, enemies_left: int, inventory: Dictionary = {}) -> void:
    hp_label.text = str(int(ceil(hero_hp)))
    base_label.text = str(int(ceil(maxf(base_hp, 0.0))))
    hp_bar.value = clampf(hero_hp / maxf(1.0, 100.0 + float(GameState.data.get("upgrades", {}).get("hp", 0)) * 10.0) * 100.0, 0.0, 100.0)
    base_bar.value = clampf(base_hp / maxf(1.0, 270.0) * 100.0, 0.0, 100.0)
    wave_label.text = "%d/3" % wave

    if phase == "day":
        phase_label.text = "ДЕНЬ · %d С" % int(ceil(phase_value))
        phase_bar.value = clampf(phase_value / maxf(1.0, GameRules.day_duration(wave)) * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color("1b272b"), VisualSystem.GOLD, 2)
    else:
        phase_label.text = "НОЧЬ %d · %d" % [wave, enemies_left]
        phase_bar.value = clampf(float(enemies_left) / float(maxi(1, 8 + wave * 4)) * 100.0, 0.0, 100.0)
        _style_progress(phase_bar, Color("202532"), VisualSystem.VIOLET, 2)

    xp_bar.value = clampf(float(xp) / float(maxi(1, next_xp)) * 100.0, 0.0, 100.0)
    level_label.text = "L%d" % level
    backpack_label.text = "РЮКЗАК %d/%d  Д%d К%d Р%d" % [bag, capacity, int(inventory.get("wood", 0)), int(inventory.get("stone", 0)), int(inventory.get("ore", 0))]

    var wood_count: int = int(storage.get("wood", 0))
    var stone_count: int = int(storage.get("stone", 0))
    var ore_count: int = int(storage.get("ore", 0))
    storage_label.text = "СКЛАД Д%d К%d Р%d" % [wood_count, stone_count, ore_count]
    storage_wood_label.text = str(wood_count)
    storage_stone_label.text = str(stone_count)
    storage_ore_label.text = str(ore_count)
    if storage_part_label != null:
        storage_part_label.text = str(int(storage.get("parts", 0)))

func set_run_objective(text: String) -> void:
    if objective_label == null:
        return
    objective_label.text = _safe(text)
    objective_label.visible = not objective_label.text.strip_edges().is_empty()

func set_build_context(title: String, effect: String, cost: Dictionary, storage: Dictionary, ready: bool, progress: float = 0.0, parts_required: int = 0, parts_owned: int = 0) -> void:
    build_panel.visible = true
    status_panel.visible = false
    build_title.text = _safe(title)
    build_effect.text = _safe(effect)
    var wood_need: int = maxi(0, int(cost.get("wood", 0)) - int(storage.get("wood", 0)))
    var stone_need: int = maxi(0, int(cost.get("stone", 0)) - int(storage.get("stone", 0)))
    var ore_need: int = maxi(0, int(cost.get("ore", 0)) - int(storage.get("ore", 0)))
    if ready:
        build_cost.text = "СТРОИТСЯ %d%%" % int(clampf(progress,0.0,1.0)*100.0) if progress > 0.01 else ("ГОТОВО · ДЕТ %d/%d" % [parts_owned,parts_required] if parts_required > 0 else "МОЖНО СТРОИТЬ")
        build_cost.add_theme_color_override("font_color", Color("98cfa5"))
    else:
        var parts_need: int = maxi(0, parts_required - parts_owned)
        build_cost.text = "НУЖНО  Д%d  К%d  Р%d  ДЕТ%d" % [wood_need,stone_need,ore_need,parts_need]
        build_cost.add_theme_color_override("font_color", Color("df9f83"))

func set_built_context(title: String, effect: String) -> void:
    build_panel.visible = true
    status_panel.visible = false
    build_title.text = _safe(title + " · АКТИВНО")
    build_effect.text = _safe(effect)
    build_cost.text = "РАБОТАЕТ"
    build_cost.add_theme_color_override("font_color", Color("98cfa5"))

func hide_build_context() -> void:
    build_panel.visible = false

func set_status(text: String, priority: int = 0, duration: float = 2.2) -> void:
    if text.strip_edges().is_empty() or build_panel.visible:
        return
    var safe_text: String = _safe(text)
    if status_panel.visible and status_time > 0.25 and priority < status_priority:
        return
    if status_label.text == safe_text and status_panel.visible:
        status_time = maxf(status_time, duration)
        status_priority = maxi(status_priority, priority)
        return
    status_generation += 1
    status_priority = priority
    status_label.text = safe_text
    status_panel.visible = true
    status_panel.modulate.a = 1.0
    status_time = clampf(duration, 1.2, 3.0)

func show_banner(text: String, color: Color = VisualSystem.GOLD_BRIGHT, priority: int = 0) -> void:
    var safe_text: String = _safe(text)
    if safe_text.is_empty() or safe_text == banner_current_text:
        return
    for item: Dictionary in banner_queue:
        if str(item.get("text", "")) == safe_text:
            return
    if banner_queue.size() >= 3:
        var weakest_index: int = 0
        var weakest_priority: int = int(banner_queue[0].get("priority", 0))
        for i: int in range(1, banner_queue.size()):
            var queued_priority: int = int(banner_queue[i].get("priority", 0))
            if queued_priority < weakest_priority:
                weakest_priority = queued_priority
                weakest_index = i
        if priority < weakest_priority:
            return
        banner_queue.remove_at(weakest_index)
    var next_item: Dictionary = {"text":safe_text, "color":color, "priority":priority}
    var inserted: bool = false
    for i: int in range(banner_queue.size()):
        if priority > int(banner_queue[i].get("priority", 0)):
            banner_queue.insert(i, next_item)
            inserted = true
            break
    if not inserted:
        banner_queue.append(next_item)
    if not banner_running:
        _play_next_banner()

func _play_next_banner() -> void:
    if banner_queue.is_empty():
        banner_running = false
        banner_current_text = ""
        return
    banner_running = true
    var item: Dictionary = banner_queue.pop_front()
    banner_current_text = str(item.get("text", ""))
    banner.text = banner_current_text
    var item_color: Color = item.get("color", VisualSystem.GOLD_BRIGHT)
    banner.add_theme_color_override("font_color", item_color)
    banner.modulate.a = 0.0
    banner.scale = Vector2(0.94,0.94)
    banner.pivot_offset = banner.size * 0.5
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(banner, "modulate:a", 1.0, 0.11)
    tween.tween_property(banner, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(0.60)
    tween.chain().set_parallel(true)
    tween.tween_property(banner, "modulate:a", 0.0, 0.18)
    tween.tween_property(banner, "scale", Vector2(1.025,1.025), 0.18)
    tween.finished.connect(func() -> void:
        banner_running = false
        banner_current_text = ""
        _play_next_banner()
    )

func show_boss(name: String, hp: float, max_hp: float) -> void:
    boss_panel.visible = true
    boss_label.text = _safe(name.to_upper())
    boss_bar.value = clampf(hp / maxf(1.0,max_hp) * 100.0,0.0,100.0)

func hide_boss() -> void:
    boss_panel.visible = false

func damage_feedback(blocked: bool) -> void:
    flash.color = Color(0.35,0.75,1.0,0.10) if blocked else Color(0.95,0.16,0.16,0.13)
    var tween := create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.20)

func show_modal(icon: String, title: String, body_text: String, buttons: Array) -> void:
    build_panel.visible = false
    status_panel.visible = false
    modal.visible = true
    modal.modulate.a = 0.0
    for child: Node in modal_box.get_children():
        child.queue_free()

    if not icon.strip_edges().is_empty():
        var motif := UiIcon.new()
        modal_box.add_child(motif)
        motif.configure("star", VisualSystem.GOLD_BRIGHT, 1.05)
        motif.custom_minimum_size = Vector2(28,28)

    var title_label := Label.new()
    modal_box.add_child(title_label)
    title_label.text = _safe(title)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 17)
    title_label.add_theme_color_override("font_color", VisualSystem.TEXT)

    var body_label := Label.new()
    modal_box.add_child(body_label)
    body_label.text = _safe(body_text)
    body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 10)
    body_label.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)

    for spec_variant: Variant in buttons:
        var spec: Dictionary = spec_variant as Dictionary
        var button := Button.new()
        modal_box.add_child(button)
        button.text = _safe(str(spec.get("text","OK")))
        button.custom_minimum_size = Vector2(0,52)
        button.focus_mode = Control.FOCUS_NONE
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.add_theme_font_size_override("font_size", 10)
        if spec.has("rarity"):
            _style_buildcraft_choice(button, spec)
        else:
            button.add_theme_stylebox_override("normal", VisualSystem.button(modal_box.get_child_count() <= 3, false))
            button.add_theme_stylebox_override("pressed", VisualSystem.button(modal_box.get_child_count() <= 3, true))
            button.add_theme_color_override("font_color", VisualSystem.TEXT)
        var action: String = str(spec.get("action","close"))
        button.pressed.connect(func() -> void: action_requested.emit(action))

    var tween := create_tween()
    tween.tween_property(modal,"modulate:a",1.0,0.11)

func buildcraft_rarity_color(rarity: String) -> Color:
    match rarity:
        "rare":
            return Color("68b8d0")
        "epic":
            return Color("a978d1")
        "legendary":
            return Color("e4bd62")
        _:
            return Color("96a4a2")

func _style_buildcraft_choice(button: Button, spec: Dictionary) -> void:
    var rarity: String = str(spec.get("rarity","common"))
    var accent: Color = buildcraft_rarity_color(rarity)
    var evolution_ready: bool = bool(spec.get("evolution_ready",false))
    var evolution_active: bool = bool(spec.get("evolution_active",false))
    if evolution_ready or evolution_active:
        accent = Color("f1c96a")

    var fill_alpha: float = 0.105
    var border_alpha: float = 0.62
    var border_width: int = 1
    if rarity == "epic":
        fill_alpha = 0.13
        border_alpha = 0.72
    elif rarity == "legendary":
        fill_alpha = 0.16
        border_alpha = 0.90
        border_width = 2
    if evolution_ready:
        fill_alpha = 0.19
        border_alpha = 0.98
        border_width = 2

    button.custom_minimum_size = Vector2(0, 74 if evolution_ready else (68 if rarity == "legendary" else 64))
    button.add_theme_font_size_override("font_size", 10 if evolution_ready else 10)
    button.add_theme_stylebox_override(
        "normal",
        VisualSystem.panel(Color(accent, fill_alpha), Color(accent, border_alpha), 6, 9, border_width)
    )
    button.add_theme_stylebox_override(
        "pressed",
        VisualSystem.panel(Color(accent, minf(0.28, fill_alpha + 0.08)), Color(accent, 1.0), 6, 9, border_width)
    )
    button.add_theme_color_override("font_color", accent.lightened(0.18) if rarity != "common" or evolution_ready else VisualSystem.TEXT)
    button.add_theme_color_override("font_hover_color", accent.lightened(0.28))

    # MASTER P5: rarity must read before the player parses text. A persistent
    # top strip and an evolution-ready glow turn the old text button into a
    # proper mobile choice card without changing any perk mechanics.
    var rarity_strip := ColorRect.new()
    button.add_child(rarity_strip)
    rarity_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rarity_strip.color = Color(accent, 0.92 if rarity != "common" or evolution_ready else 0.58)
    rarity_strip.anchor_right = 1.0
    rarity_strip.offset_left = 5.0
    rarity_strip.offset_right = -5.0
    rarity_strip.offset_top = 4.0
    rarity_strip.offset_bottom = 7.0
    if evolution_ready:
        var evolution_glow := ColorRect.new()
        button.add_child(evolution_glow)
        evolution_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
        evolution_glow.color = Color(1.0,0.76,0.28,0.12)
        evolution_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        evolution_glow.show_behind_parent = true

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

func _resource_chip(parent: Control, kind: String, value: String) -> Label:
    var group := HBoxContainer.new()
    parent.add_child(group)
    group.add_theme_constant_override("separation", 2)
    var icon := ResourceIcon.new()
    group.add_child(icon)
    icon.configure(kind)
    var label := Label.new()
    group.add_child(label)
    label.text = value
    label.add_theme_font_size_override("font_size", 8)
    label.add_theme_color_override("font_color", VisualSystem.TEXT)
    return label

func _panel(parent: Control, color: Color, border_color: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.add_theme_stylebox_override("panel", VisualSystem.panel(color,border_color,5,0,1))
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
    bar.add_theme_stylebox_override("background",background)
    bar.add_theme_stylebox_override("fill",fill)
