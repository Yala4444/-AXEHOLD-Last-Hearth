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
    var departure_box := VBoxContainer.new()
    departure.add_child(departure_box)
    departure_box.add_theme_constant_override("separation", 7)

    var caption := Label.new()
    departure_box.add_child(caption)
    caption.text = "СЛЕДУЮЩАЯ ЭКСПЕДИЦИЯ"
    caption.add_theme_font_size_override("font_size", 10)
    caption.add_theme_color_override("font_color", Color("d4b77c"))

    var route := Label.new()
    departure_box.add_child(route)
    route.text = "%s  ·  %s %s" % [
        str(biome_data.get("name", "Забытый лес")),
        str(weapon.get("icon", "⚔️")),
        str(weapon.get("name", "Топоры Странника"))
    ]
    route.add_theme_font_size_override("font_size", 15)
    route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var route_hint := Label.new()
    departure_box.add_child(route_hint)
    route_hint.text = "Коснись объектов лагеря, чтобы подготовиться, или отправляйся сразу."
    route_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    route_hint.add_theme_font_size_override("font_size", 10)
    route_hint.add_theme_color_override("font_color", Color(0.68, 0.72, 0.75))

    var play := _button(departure_box, "▶  В ЭКСПЕДИЦИЮ", true)
    play.pressed.connect(_start_game)

    var stats := GridContainer.new()
    body.add_child(stats)
    stats.columns = 2
    stats.add_theme_constant_override("h_separation", 8)
    stats.add_theme_constant_override("v_separation", 8)
    _stat(stats, "Лучший забег", "%d ночей" % int(GameState.data.get("best_wave", 0)))
    _stat(stats, "Сила героя", str(_hero_power()))

    var supply := _panel(body)
    var supply_box := VBoxContainer.new()
    supply.add_child(supply_box)
    supply_box.add_theme_constant_override("separation", 6)

    var supply_text := Label.new()
    supply_box.add_child(supply_text)
    supply_text.text = "📦 Караван припасов\nОдин бонус на текущий день"

    var supply_row := HBoxContainer.new()
    supply_box.add_child(supply_row)
    supply_row.add_theme_constant_override("separation", 6)

    var free := _button(supply_row, "+25 🪙", false)
    free.disabled = bool(GameState.data.get("supply_claimed", false))
    free.pressed.connect(_claim_supply.bind(false))

    var ad := _button(supply_row, "▶ +60 🪙", false)
    ad.disabled = bool(GameState.data.get("supply_claimed", false))
    ad.pressed.connect(_claim_supply.bind(true))

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
