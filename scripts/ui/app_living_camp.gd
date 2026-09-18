extends "res://scripts/ui/app.gd"

const CampViewScene: PackedScene = preload("res://scenes/camp_view.tscn")

func _show_home() -> void:
    _clear_body()

    var camp: CampView = CampViewScene.instantiate() as CampView
    body.add_child(camp)
    camp.action_requested.connect(_on_camp_action)

    selected_biome = clampi(selected_biome, 0, GameRules.BIOMES.size() - 1)
    var biome_data: Dictionary = GameRules.biome(selected_biome)
    var weapon_id: String = str(GameState.data.get("selected_weapon", "axes"))
    var weapon: Dictionary = WeaponRules.profile(weapon_id)

    var departure := _panel(body)
    departure.custom_minimum_size = Vector2(0, 126)
    var departure_box := VBoxContainer.new()
    departure.add_child(departure_box)
    departure_box.add_theme_constant_override("separation", 5)

    var eyebrow := Label.new()
    departure_box.add_child(eyebrow)
    eyebrow.text = "СЛЕДУЮЩИЙ ВЫХОД"
    eyebrow.add_theme_font_size_override("font_size", 8)
    eyebrow.add_theme_color_override("font_color", Color("c6a566"))

    var route := Label.new()
    departure_box.add_child(route)
    route.text = "%s   •   %s" % [
        str(biome_data.get("name", "Забытый лес")),
        str(weapon.get("name", "Топоры Странника"))
    ]
    route.add_theme_font_size_override("font_size", 14)
    route.add_theme_color_override("font_color", Color("f0e7d2"))
    route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var progress := Label.new()
    departure_box.add_child(progress)
    progress.text = "Мастерство %d   •   Реликвии %d/3   •   Победы %d" % [
        GameState.total_mastery(),
        _camp_relic_count(),
        int(GameState.data.get("wins", 0))
    ]
    progress.add_theme_font_size_override("font_size", 8)
    progress.add_theme_color_override("font_color", Color(0.63, 0.69, 0.70))

    var play := _button(departure_box, "В ЭКСПЕДИЦИЮ", true)
    play.custom_minimum_size = Vector2(0, 45)
    play.pressed.connect(_start_game)

    var notices: Array = GameState.data.get("meta_notices", [])
    if not notices.is_empty():
        var notice := Label.new()
        body.add_child(notice)
        notice.text = "НОВОЕ В ЛАГЕРЕ: " + str(notices[0])
        notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        notice.add_theme_font_size_override("font_size", 8)
        notice.add_theme_color_override("font_color", Color("e1bf76"))

func _camp_relic_count() -> int:
    var count: int = 0
    var relics: Array = GameState.data.get("boss_relics", [false, false, false])
    for value: Variant in relics:
        if bool(value):
            count += 1
    return count

func _add_meta_notice_panel() -> void:
    var notices: Array = GameState.data.get("meta_notices", [])
    if notices.is_empty():
        return

    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 7)

    var title := Label.new()
    box.add_child(title)
    title.text = "🏆 НОВОЕ В ЛАГЕРЕ"
    title.add_theme_font_size_override("font_size", 12)
    title.add_theme_color_override("font_color", Color("f0c778"))

    var lines: Array[String] = []
    for notice: Variant in notices:
        lines.append(str(notice))
    var message := Label.new()
    box.add_child(message)
    message.text = "\n".join(lines)
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_color_override("font_color", Color(0.88, 0.88, 0.84))

    var acknowledge := _button(box, "Осмотреть трофеи", false)
    acknowledge.pressed.connect(_acknowledge_meta_notices)

func _acknowledge_meta_notices() -> void:
    GameState.consume_meta_notices()
    Feedback.play("level", 10)
    _show_home()

func _on_camp_action(action: String) -> void:
    match action:
        "forge":
            _show_forge()
        "arsenal":
            _show_arsenal()
        "goals":
            _show_goals()
        "map":
            _show_map()

func _show_arsenal() -> void:
    _clear_body()
    _section("Арсенал лагеря", "Оружие открывается победами над Хранителями и меняет стиль каждого забега.")

    var owned: Array = GameState.data.get("weapons_owned", ["axes"])
    var selected_id: String = str(GameState.data.get("selected_weapon", "axes"))
    var unlock_hints: Dictionary = {
        "axes": "Доступно с начала",
        "spear": "Победи Лесного Хранителя",
        "hammer": "Победи Ледяного Стража",
        "twin_blades": "Победи Пепельного Тирана"
    }

    for weapon_id: String in WeaponRules.ordered_ids():
        var profile: Dictionary = WeaponRules.profile(weapon_id)
        var is_owned: bool = owned.has(weapon_id)
        var selected: bool = weapon_id == selected_id

        var panel := _panel(body)
        var box := VBoxContainer.new()
        panel.add_child(box)
        box.add_theme_constant_override("separation", 6)

        var top := HBoxContainer.new()
        box.add_child(top)
        top.add_theme_constant_override("separation", 8)

        var title := Label.new()
        top.add_child(title)
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title.text = "%s  %s" % [str(profile.get("icon", "⚔️")), str(profile.get("name", weapon_id))]
        title.add_theme_font_size_override("font_size", 16)

        var state := Label.new()
        top.add_child(state)
        if selected:
            state.text = "ВЫБРАНО"
            state.add_theme_color_override("font_color", Color("8fd5b0"))
        elif is_owned:
            state.text = "ОТКРЫТО"
            state.add_theme_color_override("font_color", Color("d7c28e"))
        else:
            state.text = "ЗАКРЫТО"
            state.add_theme_color_override("font_color", Color(0.52, 0.55, 0.58))
        state.add_theme_font_size_override("font_size", 10)

        var description := Label.new()
        box.add_child(description)
        description.text = str(profile.get("desc", ""))
        description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        description.add_theme_color_override("font_color", Color(0.76, 0.79, 0.81))

        var stats_text := Label.new()
        box.add_child(stats_text)
        stats_text.text = _weapon_stats_text(profile)
        stats_text.add_theme_font_size_override("font_size", 10)
        stats_text.add_theme_color_override("font_color", Color("cab48a"))

        if is_owned:
            var select := _button(box, "✓ Выбрано" if selected else "Выбрать для экспедиции", selected)
            select.disabled = selected
            select.pressed.connect(_select_weapon_from_camp.bind(weapon_id))
        else:
            var locked := Label.new()
            box.add_child(locked)
            locked.text = "🔒 " + str(unlock_hints.get(weapon_id, "Победи Хранителя"))
            locked.add_theme_font_size_override("font_size", 11)
            locked.add_theme_color_override("font_color", Color(0.60, 0.62, 0.64))

    var back := _button(body, "← Вернуться в лагерь", false)
    back.pressed.connect(_show_home)

func _weapon_stats_text(profile: Dictionary) -> String:
    var damage_percent: int = int(round(float(profile.get("damage_mult", 1.0)) * 100.0))
    var speed_percent: int = int(round(float(profile.get("speed_mult", 1.0)) * 100.0))
    var reach: int = int(round(float(profile.get("orbit_radius", 44.0))))
    var crit: int = int(round(float(profile.get("crit_bonus", 0.0)) * 100.0))
    return "Урон %d%% · Скорость %d%% · Радиус %d · Крит +%d%%" % [damage_percent, speed_percent, reach, crit]

func _select_weapon_from_camp(weapon_id: String) -> void:
    if not GameState.select_weapon(weapon_id):
        return
    Feedback.play("level", 10)
    Analytics.event("camp_weapon_selected", {"weapon": weapon_id})
    _show_arsenal()
