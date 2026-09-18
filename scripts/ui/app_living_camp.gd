extends "res://scripts/ui/app.gd"

const CampViewScene: PackedScene = preload("res://scenes/camp_view.tscn")

func _show_home() -> void:
    _clear_body()

    var camp: CampView = CampViewScene.instantiate() as CampView
    body.add_child(camp)
    camp.custom_minimum_size = Vector2(0, 455)
    camp.action_requested.connect(_on_camp_action)

    selected_biome = clampi(selected_biome, 0, GameRules.BIOMES.size() - 1)
    var biome_data: Dictionary = GameRules.biome(selected_biome)
    var weapon_id: String = str(GameState.data.get("selected_weapon", "axes"))
    var weapon: Dictionary = WeaponRules.profile(weapon_id)
    var relic_count: int = _camp_relic_count()

    var story_panel := _panel(body)
    var story_box := VBoxContainer.new()
    story_panel.add_child(story_box)
    story_box.add_theme_constant_override("separation", 3)

    var chapter := Label.new()
    story_box.add_child(chapter)
    chapter.text = LoreRules.CHAPTER_TITLE
    chapter.add_theme_font_size_override("font_size", 9)
    chapter.add_theme_color_override("font_color", Color("d0ac68"))

    var whisper := Label.new()
    story_box.add_child(whisper)
    whisper.text = LoreRules.camp_whisper(relic_count)
    whisper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    whisper.add_theme_font_size_override("font_size", 10)
    whisper.add_theme_color_override("font_color", Color("c5cec9"))

    var departure := _panel(body)
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
        relic_count,
        int(GameState.data.get("wins", 0))
    ]
    progress.add_theme_font_size_override("font_size", 8)
    progress.add_theme_color_override("font_color", Color(0.63, 0.69, 0.70))

    var play := _button(departure_box, "В ЭКСПЕДИЦИЮ", true)
    play.custom_minimum_size = Vector2(0, 48)
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

func _show_arsenal() -> void:
    _clear_body()
    _section("Арсенал лагеря", "Оружие меняет не только цифры, но дистанцию, ритм и способ держать пространство.")

    var owned: Array = GameState.data.get("weapons_owned", ["axes"])
    var selected_id: String = str(GameState.data.get("selected_weapon", "axes"))
    var selected_profile: Dictionary = WeaponRules.profile(selected_id)

    var hero_panel := _panel(body)
    var hero_box := VBoxContainer.new()
    hero_panel.add_child(hero_box)
    hero_box.add_theme_constant_override("separation", 6)

    var preview := WeaponPreview.new()
    hero_box.add_child(preview)
    preview.configure(selected_id)

    var selected_title := Label.new()
    hero_box.add_child(selected_title)
    selected_title.text = str(selected_profile.get("name", "Оружие")).to_upper()
    selected_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    selected_title.add_theme_font_size_override("font_size", 18)
    selected_title.add_theme_color_override("font_color", Color("f0dfbd"))

    var selected_desc := Label.new()
    hero_box.add_child(selected_desc)
    selected_desc.text = str(selected_profile.get("desc", ""))
    selected_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    selected_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    selected_desc.add_theme_font_size_override("font_size", 10)
    selected_desc.add_theme_color_override("font_color", Color("aeb8b9"))

    _add_weapon_meters(hero_box, selected_profile)

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
        box.add_theme_constant_override("separation", 4)

        var top := HBoxContainer.new()
        box.add_child(top)

        var title := Label.new()
        top.add_child(title)
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title.text = str(profile.get("name", weapon_id))
        title.add_theme_font_size_override("font_size", 14)
        title.add_theme_color_override("font_color", Color("f0e8d8"))

        var state := Label.new()
        top.add_child(state)
        state.add_theme_font_size_override("font_size", 8)
        if selected:
            state.text = "ВЫБРАНО"
            state.add_theme_color_override("font_color", Color("8fd5b0"))
        elif is_owned:
            state.text = "ОТКРЫТО"
            state.add_theme_color_override("font_color", Color("d7c28e"))
        else:
            state.text = "ЗАКРЫТО"
            state.add_theme_color_override("font_color", Color("747d80"))

        var role := Label.new()
        box.add_child(role)
        role.text = str(profile.get("desc", ""))
        role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        role.add_theme_font_size_override("font_size", 9)
        role.add_theme_color_override("font_color", Color("aeb7b9"))

        var stats_text := Label.new()
        box.add_child(stats_text)
        stats_text.text = _weapon_stats_text(profile)
        stats_text.add_theme_font_size_override("font_size", 8)
        stats_text.add_theme_color_override("font_color", Color("c6ae7c"))

        if is_owned:
            var select := _button(box, "ВЫБРАНО" if selected else "ВЫБРАТЬ ДЛЯ ЭКСПЕДИЦИИ", selected)
            select.disabled = selected
            select.pressed.connect(_select_weapon_from_camp.bind(weapon_id))
        else:
            var locked := Label.new()
            box.add_child(locked)
            locked.text = str(unlock_hints.get(weapon_id, "Победи Хранителя"))
            locked.add_theme_font_size_override("font_size", 9)
            locked.add_theme_color_override("font_color", Color("777f81"))

func _show_map() -> void:
    _clear_body()
    _section("Карта Тьмы", "Чем дальше от Последнего Очагa, тем меньше мир похож на то, что было раньше.")

    var map_view := WorldMapView.new()
    body.add_child(map_view)
    map_view.configure(selected_biome)
    map_view.biome_selected.connect(_select_biome_from_map)

    var biome_data: Dictionary = GameRules.biome(selected_biome)
    var lore_panel := _panel(body)
    var lore_box := VBoxContainer.new()
    lore_panel.add_child(lore_box)
    lore_box.add_theme_constant_override("separation", 4)

    var title := Label.new()
    lore_box.add_child(title)
    title.text = str(biome_data.get("name", "Регион")).to_upper()
    title.add_theme_font_size_override("font_size", 15)
    title.add_theme_color_override("font_color", Color("ead6aa"))

    var tagline := Label.new()
    lore_box.add_child(tagline)
    tagline.text = LoreRules.biome_tagline(selected_biome)
    tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tagline.add_theme_font_size_override("font_size", 10)
    tagline.add_theme_color_override("font_color", Color("c1cbca"))

    var rule := Label.new()
    lore_box.add_child(rule)
    rule.text = str(biome_data.get("rule", ""))
    rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rule.add_theme_font_size_override("font_size", 9)
    rule.add_theme_color_override("font_color", Color("9fa9aa"))

    var play := _button(body, "В ЭКСПЕДИЦИЮ: " + str(biome_data.get("name", "Регион")).to_upper(), true)
    play.pressed.connect(_start_game)

func _show_goals() -> void:
    GameState.ensure_daily_state()
    _clear_body()
    _section("Трофеи и следы", "Победы над Хранителями возвращают не только силу, но и фрагменты истории мира.")

    var hall := TrophyHallView.new()
    body.add_child(hall)

    var relics: Array = GameState.data.get("boss_relics", [false, false, false])
    for i: int in range(3):
        if i >= relics.size() or not bool(relics[i]):
            continue
        var clue_panel := _panel(body)
        var clue := Label.new()
        clue_panel.add_child(clue)
        clue.text = "%s
%s" % [WeaponRules.relic_name(i).to_upper(), LoreRules.relic_clue(i)]
        clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        clue.add_theme_font_size_override("font_size", 9)
        clue.add_theme_color_override("font_color", Color("c9c2ad"))

    _section("Доска задач", "Короткие цели дают дополнительное направление, но не заменяют экспедицию.")
    var mission_names: Dictionary = {"trees": "Лесоруб", "kills": "Защитник", "builds": "Строитель"}
    var missions: Dictionary = GameState.data["missions"]
    for kind: String in ["trees", "kills", "builds"]:
        var mission: Dictionary = missions[kind]
        var panel := _panel(body)
        var row := HBoxContainer.new()
        panel.add_child(row)

        var text := Label.new()
        row.add_child(text)
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.text = "%s
%d / %d" % [str(mission_names[kind]), int(mission["value"]), int(mission["goal"])]
        text.add_theme_font_size_override("font_size", 12)

        var claim_text: String = "ПОЛУЧЕНО" if bool(mission["claimed"]) else "+%d МОН." % int(mission["reward"])
        var claim := _button(row, claim_text, false)
        claim.custom_minimum_size = Vector2(118, 44)
        claim.disabled = bool(mission["claimed"]) or int(mission["value"]) < int(mission["goal"])
        claim.pressed.connect(_claim_mission.bind(kind))

    _section("Достижения", "Постоянные цели отмечают крупные вехи развития лагеря.")
    var biome_wins: Array = GameState.data["biome_wins"]
    var stats: Dictionary = GameState.data["stats"]
    _trophy("Первый Хранитель", "Победи босса Забытых лесов", int(biome_wins[0]) > 0, "boss", 1, true)
    _trophy("Архитектор", "Построй 8 сооружений суммарно", int(stats["builds"]) >= 8, "builder", 75, false)
    _trophy("Охотник", "Уничтожь 75 врагов", int(stats["kills"]) >= 75, "hunter", 90, false)

func _show_forge() -> void:
    _clear_body()
    _section("Кузница лагеря", "Постоянные улучшения помогают Страннику, но не заменяют решения внутри забега.")

    var intro := _panel(body)
    var intro_label := Label.new()
    intro.add_child(intro_label)
    intro_label.text = "Огонь кузницы питается от Последнего Очагa. Чем сильнее лагерь, тем дальше Странник может уйти во Тьму."
    intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro_label.add_theme_font_size_override("font_size", 9)
    intro_label.add_theme_color_override("font_color", Color("bbb8aa"))

    var specs: Array[Dictionary] = [
        {"id": "damage", "title": "Закалённые лезвия", "desc": "+10% базового урона"},
        {"id": "hp", "title": "Крепкое сердце", "desc": "+10 максимального HP"},
        {"id": "bag", "title": "Походный ранец", "desc": "+5 вместимости"},
        {"id": "speed", "title": "Следопыт", "desc": "+4% скорости"}
    ]
    var upgrades: Dictionary = GameState.data["upgrades"]
    for spec: Dictionary in specs:
        var kind: String = str(spec["id"])
        var panel := _panel(body)
        var row := HBoxContainer.new()
        panel.add_child(row)
        row.add_theme_constant_override("separation", 8)

        var text := Label.new()
        row.add_child(text)
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.text = "%s
%s · Ур. %d" % [spec["title"], spec["desc"], int(upgrades.get(kind, 0))]
        text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        text.add_theme_font_size_override("font_size", 10)
        text.add_theme_color_override("font_color", Color("e7e1d5"))

        var buy := _button(row, "%d МОН." % GameState.upgrade_cost(kind), false)
        buy.custom_minimum_size = Vector2(112, 48)
        buy.pressed.connect(_buy_upgrade.bind(kind))

func _camp_relic_count() -> int:
    var count: int = 0
    var relics: Array = GameState.data.get("boss_relics", [false, false, false])
    for value: Variant in relics:
        if bool(value):
            count += 1
    return count

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

func _select_biome_from_map(index: int) -> void:
    selected_biome = index
    GameState.data["selected_biome"] = index
    GameState.save()
    Feedback.play("level", 8)
    Analytics.event("camp_biome_selected", {"biome": index})
    _show_map()

func _add_weapon_meters(parent: Control, profile: Dictionary) -> void:
    var damage_value: float = clampf(float(profile.get("damage_mult", 1.0)) / 1.6, 0.0, 1.0)
    var speed_value: float = clampf(float(profile.get("speed_mult", 1.0)) / 1.2, 0.0, 1.0)
    var reach_value: float = clampf(float(profile.get("orbit_radius", 44.0)) / 72.0, 0.0, 1.0)
    var crit_value: float = clampf((0.05 + float(profile.get("crit_bonus", 0.0))) / 0.18, 0.0, 1.0)
    _weapon_meter(parent, "УРОН", damage_value)
    _weapon_meter(parent, "СКОРОСТЬ", speed_value)
    _weapon_meter(parent, "ДИСТАНЦИЯ", reach_value)
    _weapon_meter(parent, "КРИТ", crit_value)

func _weapon_meter(parent: Control, title_text: String, value: float) -> void:
    var row := HBoxContainer.new()
    parent.add_child(row)
    row.add_theme_constant_override("separation", 7)

    var title := Label.new()
    row.add_child(title)
    title.text = title_text
    title.custom_minimum_size = Vector2(72, 14)
    title.add_theme_font_size_override("font_size", 7)
    title.add_theme_color_override("font_color", Color("8f9b9d"))

    var bar := ProgressBar.new()
    row.add_child(bar)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.custom_minimum_size = Vector2(0, 7)
    bar.show_percentage = false
    bar.min_value = 0
    bar.max_value = 100
    bar.value = value * 100.0
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color("0d1417")
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color("b79454")
    bar.add_theme_stylebox_override("background", bg)
    bar.add_theme_stylebox_override("fill", fill)

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
