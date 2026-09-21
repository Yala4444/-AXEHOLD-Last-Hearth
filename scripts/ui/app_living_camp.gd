extends "res://scripts/ui/app.gd"

const CampViewScene: PackedScene = preload("res://scenes/camp_view.tscn")

func _show_home() -> void:
    _clear_body()

    var camp: CampView = CampViewScene.instantiate() as CampView
    body.add_child(camp)
    camp.custom_minimum_size = Vector2(0, 392)
    camp.action_requested.connect(_on_camp_action)

    selected_biome = clampi(selected_biome, 0, GameRules.BIOMES.size() - 1)
    var tutorial_pending: bool = GameState.tutorial_should_run()
    if tutorial_pending:
        selected_biome = 0
    var biome_data: Dictionary = GameRules.biome(selected_biome)
    var weapon_id: String = str(GameState.data.get("selected_weapon", "axes"))
    var weapon: Dictionary = WeaponRules.profile(weapon_id)
    var relic_count: int = _camp_relic_count()
    var chapter_one_complete: bool = GameState.chapter_one_complete()

    # Story is a ribbon, not another large dashboard card.
    var story := _panel(body)
    var story_row := HBoxContainer.new()
    story.add_child(story_row)
    story_row.add_theme_constant_override("separation", 8)

    var story_icon := UiIcon.new()
    story_row.add_child(story_icon)
    story_icon.configure("star", VisualSystem.GOLD_BRIGHT, 0.76)

    var story_copy := VBoxContainer.new()
    story_row.add_child(story_copy)
    story_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    story_copy.add_theme_constant_override("separation", 1)

    var chapter := Label.new()
    story_copy.add_child(chapter)
    chapter.text = LoreRules.chapter_title(chapter_one_complete)
    chapter.add_theme_font_size_override("font_size", 9)
    chapter.add_theme_color_override("font_color", VisualSystem.GOLD_BRIGHT)

    var whisper := Label.new()
    story_copy.add_child(whisper)
    whisper.text = LoreRules.chapter_promise(true) if chapter_one_complete else LoreRules.camp_whisper(relic_count)
    whisper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    whisper.add_theme_font_size_override("font_size", 8)
    whisper.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)

    var chronicle := Button.new()
    story_row.add_child(chronicle)
    chronicle.text = "ХРОНИКА"
    chronicle.custom_minimum_size = Vector2(72, 34)
    chronicle.focus_mode = Control.FOCUS_NONE
    chronicle.add_theme_font_size_override("font_size", 7)
    chronicle.add_theme_stylebox_override("normal", VisualSystem.panel(VisualSystem.SURFACE_2, VisualSystem.BORDER_SOFT, 5, 6, 1))
    chronicle.add_theme_stylebox_override("pressed", VisualSystem.panel(VisualSystem.SURFACE_3, VisualSystem.GOLD, 5, 6, 1))
    chronicle.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)
    chronicle.pressed.connect(_show_chronicle)

    if tutorial_pending:
        var tutorial_panel := _panel(body)
        tutorial_panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color("171d1a"), Color(VisualSystem.GOLD,0.48), 6, 10, 1))
        var tutorial_box := VBoxContainer.new()
        tutorial_panel.add_child(tutorial_box)
        tutorial_box.add_theme_constant_override("separation",4)

        var tutorial_title := Label.new()
        tutorial_box.add_child(tutorial_title)
        tutorial_title.text = "ПЕРВЫЙ ПУТЬ · ОБУЧЕНИЕ"
        tutorial_title.add_theme_font_size_override("font_size",11)
        tutorial_title.add_theme_color_override("font_color",VisualSystem.GOLD_BRIGHT)

        var tutorial_copy := Label.new()
        tutorial_box.add_child(tutorial_copy)
        tutorial_copy.text = "За один короткий маршрут игра покажет главное: движение → добыча → разгрузка → постройка → первая ночь. События и охоты пока отключены."
        tutorial_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        tutorial_copy.add_theme_font_size_override("font_size",8)
        tutorial_copy.add_theme_color_override("font_color",VisualSystem.TEXT_SOFT)

    # One departure surface contains the information needed to leave.
    var departure := _panel(body)
    var departure_box := VBoxContainer.new()
    departure.add_child(departure_box)
    departure_box.add_theme_constant_override("separation", 5)

    var departure_top := HBoxContainer.new()
    departure_box.add_child(departure_top)
    departure_top.add_theme_constant_override("separation", 7)

    var route_copy := VBoxContainer.new()
    departure_top.add_child(route_copy)
    route_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    route_copy.add_theme_constant_override("separation", 0)

    var eyebrow := Label.new()
    route_copy.add_child(eyebrow)
    eyebrow.text = "СЛЕДУЮЩИЙ ВЫХОД"
    eyebrow.add_theme_font_size_override("font_size", 7)
    eyebrow.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)

    var route := Label.new()
    route_copy.add_child(route)
    route.text = ("%s · УЧЕБНЫЙ МАРШРУТ\n%s" % [
        str(biome_data.get("name", "Забытый лес")),
        str(weapon.get("name", "Топоры Странника"))
    ]) if tutorial_pending else ("%s · Угроза %d\n%s" % [
        str(biome_data.get("name", "Забытый лес")),
        GameState.selected_threat(),
        str(weapon.get("name", "Топоры Странника"))
    ])
    route.add_theme_font_size_override("font_size", 12)
    route.add_theme_color_override("font_color", VisualSystem.TEXT)
    route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var progress := Label.new()
    departure_top.add_child(progress)
    progress.text = "СЛАВА\n%d%s" % [
        GameState.camp_renown(),
        "" if GameState.camp_level() >= 5 else "/%d" % GameState.camp_next_renown()
    ]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    progress.add_theme_font_size_override("font_size", 8)
    progress.add_theme_color_override("font_color", VisualSystem.GOLD)

    var contract_row := HBoxContainer.new()
    departure_box.add_child(contract_row)
    contract_row.add_theme_constant_override("separation", 6)

    var contract_icon := UiIcon.new()
    contract_row.add_child(contract_icon)
    contract_icon.configure("contract", VisualSystem.GOLD, 0.64)

    var active_contract: Dictionary = GameState.selected_contract()
    var contract_line := Label.new()
    contract_row.add_child(contract_line)
    contract_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if active_contract.is_empty():
        contract_line.text = "Контракт не выбран"
        contract_line.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)
    else:
        contract_line.text = "%s · %s · +%d славы" % [
            str(active_contract.get("name", "")),
            str(active_contract.get("risk", "СРЕДНИЙ")),
            int(active_contract.get("renown", 1))
        ]
        contract_line.add_theme_color_override("font_color", Color("d6bd83"))
    contract_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    contract_line.add_theme_font_size_override("font_size", 8)

    var contract_button := Button.new()
    contract_row.add_child(contract_button)
    contract_button.text = "ВЫБРАТЬ"
    contract_button.custom_minimum_size = Vector2(66, 32)
    contract_button.focus_mode = Control.FOCUS_NONE
    contract_button.add_theme_font_size_override("font_size", 7)
    contract_button.add_theme_stylebox_override("normal", VisualSystem.panel(VisualSystem.SURFACE_2, VisualSystem.BORDER_SOFT, 5, 5, 1))
    contract_button.add_theme_stylebox_override("pressed", VisualSystem.panel(VisualSystem.SURFACE_3, VisualSystem.GOLD, 5, 5, 1))
    contract_button.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)
    contract_button.pressed.connect(_show_contracts)

    var play := _button(
        departure_box,
        "НАЧАТЬ ОБУЧЕНИЕ" if tutorial_pending else "В ЭКСПЕДИЦИЮ · УГРОЗА %d" % GameState.selected_threat(),
        true
    )
    play.custom_minimum_size = Vector2(0, 48)
    play.pressed.connect(_start_expedition)

    var visual_slice := _button(departure_box, "ПОПРОБОВАТЬ НОВЫЙ ДИЗАЙН · ЖИВОЙ ГЕРОЙ", false)
    visual_slice.custom_minimum_size = Vector2(0, 40)
    visual_slice.tooltip_text = "Полная экспедиция с цельным героем в спокойной анимации и выбранным оружием"
    visual_slice.pressed.connect(_start_visual_slice)

    if GameState.endless_unlocked():
        var endless_stats: Dictionary = GameState.data.get("endless_stats", {})
        var endless_panel := _panel(body)
        var endless_box := VBoxContainer.new()
        endless_panel.add_child(endless_box)
        endless_box.add_theme_constant_override("separation",4)

        var endless_title := Label.new()
        endless_box.add_child(endless_title)
        endless_title.text = "ПОСЛЕДНИЙ РУБЕЖ"
        endless_title.add_theme_font_size_override("font_size",12)
        endless_title.add_theme_color_override("font_color",Color("e1bb76"))

        var endless_copy := Label.new()
        endless_box.add_child(endless_copy)
        endless_copy.text = "Бесконечная оборона · каждая 5-я ночь — Хранитель и реликтовый сундук.\nЛичный рекорд: ночь %d" % int(endless_stats.get("best_wave",0))
        endless_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        endless_copy.add_theme_font_size_override("font_size",8)
        endless_copy.add_theme_color_override("font_color",VisualSystem.TEXT_SOFT)

        var endless_button := _button(endless_box,"НАЧАТЬ ПОСЛЕДНИЙ РУБЕЖ",false)
        endless_button.pressed.connect(_start_endless)

    var notices: Array = GameState.data.get("meta_notices", [])
    if not notices.is_empty():
        var notice := Label.new()
        body.add_child(notice)
        notice.text = str(notices[0])
        notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        notice.add_theme_font_size_override("font_size", 8)
        notice.add_theme_color_override("font_color", Color("cdb475"))

func _show_arsenal() -> void:
    _clear_body()
    _section("Арсенал", "Выбирай стиль боя, а не просто большее число.")

    var owned: Array = GameState.data.get("weapons_owned", ["axes"])
    var selected_id: String = str(GameState.data.get("selected_weapon", "axes"))
    var selected_profile: Dictionary = WeaponRules.profile(selected_id)
    var mastery_level: int = GameState.weapon_mastery_level(selected_id)

    var hero_panel := _panel(body)
    var hero_box := VBoxContainer.new()
    hero_panel.add_child(hero_box)
    hero_box.add_theme_constant_override("separation", 4)

    var preview := WeaponPreview.new()
    hero_box.add_child(preview)
    preview.custom_minimum_size = Vector2(0, 138)
    preview.configure(selected_id)

    var title_row := HBoxContainer.new()
    hero_box.add_child(title_row)
    title_row.add_theme_constant_override("separation", 6)

    var selected_title := Label.new()
    title_row.add_child(selected_title)
    selected_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    selected_title.text = str(selected_profile.get("name", "Оружие")).to_upper()
    selected_title.add_theme_font_size_override("font_size", 15)
    selected_title.add_theme_color_override("font_color", VisualSystem.TEXT)

    var mastery := Label.new()
    title_row.add_child(mastery)
    mastery.text = GameState.weapon_mastery_stars(selected_id)
    mastery.add_theme_font_size_override("font_size", 9)
    mastery.add_theme_color_override("font_color", VisualSystem.GOLD_BRIGHT)

    var identity := Label.new()
    hero_box.add_child(identity)
    identity.text = "%s · %s" % [
        str(selected_profile.get("identity", "")),
        str(selected_profile.get("signature", ""))
    ]
    identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    identity.add_theme_font_size_override("font_size", 9)
    identity.add_theme_color_override("font_color", Color("d5bc83"))

    var selected_desc := Label.new()
    hero_box.add_child(selected_desc)
    selected_desc.text = str(selected_profile.get("desc", ""))
    selected_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    selected_desc.add_theme_font_size_override("font_size", 8)
    selected_desc.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)

    var stat_line := Label.new()
    hero_box.add_child(stat_line)
    stat_line.text = _weapon_stats_text(selected_profile)
    stat_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stat_line.add_theme_font_size_override("font_size", 8)
    stat_line.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)

    var mastery_effect := Label.new()
    hero_box.add_child(mastery_effect)
    mastery_effect.text = "%s · Далее: %s" % [
        WeaponRules.weapon_mastery_bonus_text(selected_id, mastery_level),
        WeaponRules.mastery_next_text(selected_id, mastery_level)
    ]
    mastery_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mastery_effect.add_theme_font_size_override("font_size", 7)
    mastery_effect.add_theme_color_override("font_color", Color("8f9b99"))

    var unlock_hints: Dictionary = {
        "axes":"Доступно с начала",
        "spear":"Победи Лесного Хранителя",
        "hammer":"Победи Ледяного Стража",
        "twin_blades":"Победи Пепельного Тирана"
    }

    for weapon_id: String in WeaponRules.ordered_ids():
        var profile: Dictionary = WeaponRules.profile(weapon_id)
        var is_owned: bool = owned.has(weapon_id)
        var selected: bool = weapon_id == selected_id

        var panel := _panel(body)
        if selected:
            panel.add_theme_stylebox_override("panel", VisualSystem.panel(Color("18231f"), Color(VisualSystem.GOLD,0.48), 5, 9, 1))
        var row := HBoxContainer.new()
        panel.add_child(row)
        row.add_theme_constant_override("separation", 8)

        var mini := WeaponPreview.new()
        row.add_child(mini)
        mini.custom_minimum_size = Vector2(74, 66)
        mini.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        mini.configure(weapon_id)

        var copy := VBoxContainer.new()
        row.add_child(copy)
        copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        copy.add_theme_constant_override("separation", 1)

        var name := Label.new()
        copy.add_child(name)
        name.text = str(profile.get("name", weapon_id)).to_upper()
        name.add_theme_font_size_override("font_size", 10)
        name.add_theme_color_override("font_color", VisualSystem.TEXT if is_owned else VisualSystem.TEXT_MUTED)

        var role := Label.new()
        copy.add_child(role)
        role.text = str(profile.get("identity", ""))
        role.add_theme_font_size_override("font_size", 8)
        role.add_theme_color_override("font_color", Color("c8ae77") if is_owned else Color("6f787a"))

        var stats := Label.new()
        copy.add_child(stats)
        stats.text = _weapon_stats_text(profile)
        stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        stats.add_theme_font_size_override("font_size", 7)
        stats.add_theme_color_override("font_color", Color("899597"))

        var action_box := VBoxContainer.new()
        row.add_child(action_box)
        action_box.custom_minimum_size = Vector2(72, 0)
        action_box.alignment = BoxContainer.ALIGNMENT_CENTER

        var state := Label.new()
        action_box.add_child(state)
        state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        state.add_theme_font_size_override("font_size", 7)
        if selected:
            state.text = "ВЫБРАНО"
            state.add_theme_color_override("font_color", VisualSystem.GREEN)
        elif is_owned:
            state.text = GameState.weapon_mastery_stars(weapon_id)
            state.add_theme_color_override("font_color", VisualSystem.GOLD)
        else:
            state.text = "ЗАКРЫТО"
            state.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)

        if is_owned and not selected:
            var select := Button.new()
            action_box.add_child(select)
            select.text = "ВЫБРАТЬ"
            select.custom_minimum_size = Vector2(70, 34)
            select.focus_mode = Control.FOCUS_NONE
            select.add_theme_font_size_override("font_size", 7)
            select.add_theme_stylebox_override("normal", VisualSystem.panel(VisualSystem.SURFACE_2, VisualSystem.BORDER, 5, 5, 1))
            select.add_theme_stylebox_override("pressed", VisualSystem.panel(VisualSystem.SURFACE_3, VisualSystem.GOLD, 5, 5, 1))
            select.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)
            select.pressed.connect(_select_weapon_from_camp.bind(weapon_id))
        elif not is_owned:
            var locked := Label.new()
            action_box.add_child(locked)
            locked.text = str(unlock_hints.get(weapon_id, "Победи Хранителя"))
            locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            locked.add_theme_font_size_override("font_size", 6)
            locked.add_theme_color_override("font_color", Color("687274"))

func _show_map() -> void:
    _clear_body()
    _section("Карта Тьмы", "Чем дальше от Последнего Очага, тем меньше мир похож на то, что было раньше.")

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

    var threat_panel := _panel(body)
    var threat_box := VBoxContainer.new()
    threat_panel.add_child(threat_box)
    threat_box.add_theme_constant_override("separation",5)

    var threat_header := HBoxContainer.new()
    threat_box.add_child(threat_header)
    var threat_title := Label.new()
    threat_header.add_child(threat_title)
    threat_title.text = "УРОВЕНЬ УГРОЗЫ"
    threat_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    threat_title.add_theme_font_size_override("font_size",10)
    threat_title.add_theme_color_override("font_color",VisualSystem.GOLD_BRIGHT)

    var mastery := Label.new()
    threat_header.add_child(mastery)
    mastery.text = ThreatRules.stars(int((GameState.data.get("biome_mastery",[0,0,0]) as Array)[selected_biome]))
    mastery.add_theme_font_size_override("font_size",9)
    mastery.add_theme_color_override("font_color",VisualSystem.GOLD)

    var threat_row := HBoxContainer.new()
    threat_box.add_child(threat_row)
    threat_row.add_theme_constant_override("separation",4)
    var unlocked_threat: int = GameState.threat_unlocked_level(selected_biome)
    var selected_threat: int = GameState.selected_threat()
    for level_value: int in range(1,ThreatRules.MAX_LEVEL+1):
        var threat_button := _button(threat_row, ["I","II","III","IV","V"][level_value-1], level_value == selected_threat)
        threat_button.custom_minimum_size = Vector2(46,38)
        threat_button.disabled = level_value > unlocked_threat or level_value == selected_threat
        threat_button.pressed.connect(_select_threat_from_map.bind(level_value))

    var threat_spec: Dictionary = ThreatRules.spec(selected_threat)
    var threat_desc := Label.new()
    threat_box.add_child(threat_desc)
    threat_desc.text = "%s · награда ×%.2f\n%s\n%s" % [
        str(threat_spec.get("name","")),
        float(threat_spec.get("reward",1.0)),
        str(threat_spec.get("desc","")),
        ThreatRules.readiness_text(selected_threat)
    ]
    threat_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    threat_desc.add_theme_font_size_override("font_size",8)
    threat_desc.add_theme_color_override("font_color",VisualSystem.TEXT_SOFT)

    if not GameState.threat_clear_done(selected_biome, selected_threat):
        var first_reward: Dictionary = ThreatRules.first_clear_reward(selected_threat)
        var first_clear := Label.new()
        threat_box.add_child(first_clear)
        first_clear.text = "ПЕРВОЕ ПРОХОЖДЕНИЕ · +%d мон.%s" % [
            int(first_reward.get("coins",0)),
            " · +%d оск." % int(first_reward.get("shards",0)) if int(first_reward.get("shards",0)) > 0 else ""
        ]
        first_clear.add_theme_font_size_override("font_size",8)
        first_clear.add_theme_color_override("font_color",Color("d7bb7a"))

    var play := _button(body, "В ЭКСПЕДИЦИЮ · УГРОЗА %s" % ["I","II","III","IV","V"][selected_threat-1], true)
    play.pressed.connect(_start_expedition)

    if GameState.endless_unlocked():
        var endless := _button(body, "ПОСЛЕДНИЙ РУБЕЖ · БЕСКОНЕЧНЫЙ РЕЖИМ", false)
        endless.pressed.connect(_start_endless)

func _select_threat_from_map(level: int) -> void:
    if GameState.select_threat(level):
        Feedback.play("level",7)
    _show_map()

func _start_expedition() -> void:
    GameState.visual_preview_v2 = false
    GameState.data["run_mode"] = "expedition"
    if GameState.tutorial_should_run():
        selected_biome = 0
        GameState.data["selected_biome"] = 0
        GameState.data["selected_threat"] = 1
    GameState.save()
    _start_game()

func _start_visual_slice() -> void:
    GameState.visual_preview_v2 = true
    GameState.data["run_mode"] = "expedition"
    GameState.save()
    _start_game()

func _start_endless() -> void:
    if not GameState.endless_unlocked():
        return
    GameState.visual_preview_v2 = false
    GameState.data["run_mode"] = "endless"
    GameState.save()
    _start_game()

func _show_contracts() -> void:
    _clear_body()
    GameState.ensure_contract_board()

    _section(
        "Контракты Последнего Очагa",
        "На день доступны три поручения. Выполни выбранный контракт в экспедиции, чтобы получить монеты и Славу — она физически развивает лагерь."
    )

    var progress_panel := _panel(body)
    var progress_box := VBoxContainer.new()
    progress_panel.add_child(progress_box)
    progress_box.add_theme_constant_override("separation", 4)

    var level := Label.new()
    progress_box.add_child(level)
    level.text = "%s · УРОВЕНЬ ЛАГЕРЯ %d" % [GameState.camp_level_name(), GameState.camp_level()]
    level.add_theme_font_size_override("font_size", 14)
    level.add_theme_color_override("font_color", Color("e4c27d"))

    var next := Label.new()
    progress_box.add_child(next)
    if GameState.camp_level() >= 5:
        next.text = "Слава %d · лагерь достиг текущего максимума развития." % GameState.camp_renown()
    else:
        next.text = "Слава %d/%d · следующий рост изменит Последний Очаг визуально." % [
            GameState.camp_renown(),
            GameState.camp_next_renown()
        ]
    next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    next.add_theme_font_size_override("font_size", 9)
    next.add_theme_color_override("font_color", Color("9faeac"))

    var state: Dictionary = GameState.data.get("contract_state", {})
    var completed_today: Array = state.get("completed_today", [])
    var selected_id: String = GameState.selected_contract_id()

    for contract_id: String in GameState.contract_offers():
        var spec: Dictionary = GameRules.contract_by_id(contract_id)
        var completed: bool = completed_today.has(contract_id)
        var selected: bool = selected_id == contract_id

        var panel := _panel(body)
        var box := VBoxContainer.new()
        panel.add_child(box)
        box.add_theme_constant_override("separation", 5)

        var top := HBoxContainer.new()
        box.add_child(top)
        var title := Label.new()
        top.add_child(title)
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title.text = str(spec.get("name", "КОНТРАКТ"))
        title.add_theme_font_size_override("font_size", 13)
        title.add_theme_color_override("font_color", Color("f0dfbd"))

        var badge := Label.new()
        top.add_child(badge)
        badge.add_theme_font_size_override("font_size", 8)
        if completed:
            badge.text = "ВЫПОЛНЕНО"
            badge.add_theme_color_override("font_color", Color("8fd5b0"))
        elif selected:
            badge.text = "ВЫБРАН"
            badge.add_theme_color_override("font_color", Color("d8bd7b"))
        else:
            badge.text = str(spec.get("risk", "СРЕДНИЙ"))
            badge.add_theme_color_override("font_color", Color("a9b3b4"))

        var desc := Label.new()
        box.add_child(desc)
        desc.text = str(spec.get("desc", ""))
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.add_theme_font_size_override("font_size", 9)
        desc.add_theme_color_override("font_color", Color("aeb8b9"))

        var reward := Label.new()
        box.add_child(reward)
        reward.text = "НАГРАДА · %d мон. · +%d славы · риск %s" % [
            int(spec.get("reward", 0)),
            int(spec.get("renown", 1)),
            str(spec.get("risk", "СРЕДНИЙ"))
        ]
        reward.add_theme_font_size_override("font_size", 8)
        reward.add_theme_color_override("font_color", Color("c9ad72"))

        if not completed:
            var choose := _button(box, "ВЫБРАН" if selected else "ВЗЯТЬ КОНТРАКТ", selected)
            choose.disabled = selected
            choose.custom_minimum_size = Vector2(0, 40)
            choose.pressed.connect(_select_contract_from_camp.bind(contract_id))

    _section("Люди меняют экспедицию", "Доверие жителей теперь даёт небольшие практические преимущества, а не только текст в лагере.")

    var bonuses: Dictionary = GameState.expedition_resident_bonuses()
    var resident_panel := _panel(body)
    var resident_box := VBoxContainer.new()
    resident_panel.add_child(resident_box)
    resident_box.add_theme_constant_override("separation", 4)

    var mira := Label.new()
    resident_box.add_child(mira)
    mira.text = "МИРА · доверие %d/%d · скорость +%d%% · предвестие ночи раньше на %.1f сек." % [
        GameState.resident_trust("mira"),
        ResidentRules.max_trust("mira"),
        int(round((float(bonuses.get("move_mult", 1.0)) - 1.0) * 100.0)),
        float(bonuses.get("preview_bonus", 0.0))
    ]
    mira.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mira.add_theme_font_size_override("font_size", 9)
    mira.add_theme_color_override("font_color", Color("9fc3a5"))

    var thorn := Label.new()
    resident_box.add_child(thorn)
    thorn.text = "ТОРН · доверие %d/%d · стартовые детали %d · усиление Башни %s" % [
        GameState.resident_trust("thorn"),
        ResidentRules.max_trust("thorn"),
        int(bonuses.get("starting_parts", 0)),
        "+5%" if float(bonuses.get("tower_damage_mult", 1.0)) > 1.0 else "нет"
    ]
    thorn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    thorn.add_theme_font_size_override("font_size", 9)
    thorn.add_theme_color_override("font_color", Color("c1aa91"))

    var back := _button(body, "К ЛАГЕРЮ", false)
    back.pressed.connect(_show_home)

func _select_contract_from_camp(contract_id: String) -> void:
    if GameState.select_contract(contract_id):
        Feedback.play("level", 8)
        Analytics.event("camp_contract_selected", {"id":contract_id})
    _show_contracts()

func _show_chronicle() -> void:
    GameState.mark_chronicle_seen()
    _clear_body()

    var chapter_complete: bool = GameState.chapter_one_complete()
    _section(
        "Хроника Последнего Очага",
        "История открывается не диалоговыми окнами, а тем, что Странник действительно принёс домой."
    )

    var overview := _panel(body)
    var overview_box := VBoxContainer.new()
    overview.add_child(overview_box)
    overview_box.add_theme_constant_override("separation", 4)

    var chapter_label := Label.new()
    overview_box.add_child(chapter_label)
    chapter_label.text = LoreRules.chapter_title(chapter_complete)
    chapter_label.add_theme_font_size_override("font_size", 14)
    chapter_label.add_theme_color_override("font_color", Color("e5c17c"))

    var promise := Label.new()
    overview_box.add_child(promise)
    promise.text = LoreRules.chapter_promise(chapter_complete)
    promise.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    promise.add_theme_font_size_override("font_size", 10)
    promise.add_theme_color_override("font_color", Color("c3cecb"))

    var meta := Label.new()
    overview_box.add_child(meta)
    meta.text = "Реликвии %d/3 · Фрагменты памяти %d · Жители %d/%d" % [
        GameState.relic_count(),
        int(GameState.data.get("lore_fragments", 0)),
        GameState.unlocked_resident_count(),
        ResidentRules.ids().size()
    ]
    meta.add_theme_font_size_override("font_size", 8)
    meta.add_theme_color_override("font_color", Color("8f9a9c"))

    _section("Следы Хранителей", "Каждая реликвия — не трофей, а часть карты старой сети.")

    var relics: Array = GameState.data.get("boss_relics", [false, false, false])
    for item: Dictionary in LoreRules.chronicle_relic_progress(relics):
        var card := _panel(body)
        var box := VBoxContainer.new()
        card.add_child(box)
        box.add_theme_constant_override("separation", 3)

        var found: bool = bool(item.get("found", false))
        var title := Label.new()
        box.add_child(title)
        title.text = ("%s · НАЙДЕНА" if found else "НЕИЗВЕСТНАЯ РЕЛИКВИЯ") % str(item.get("name", "Реликвия"))
        title.add_theme_font_size_override("font_size", 10)
        title.add_theme_color_override("font_color", Color("e0c27f") if found else Color("6f797b"))

        var clue := Label.new()
        box.add_child(clue)
        clue.text = str(item.get("clue", ""))
        clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        clue.add_theme_font_size_override("font_size", 9)
        clue.add_theme_color_override("font_color", Color("b8c1bf") if found else Color("697274"))

    if GameState.chapter_one_ready() and not chapter_complete:
        _section("Три части одного знака", "Теперь реликвии можно соединить на столе Хроники.")

        var finale := _panel(body)
        var finale_box := VBoxContainer.new()
        finale.add_child(finale_box)
        finale_box.add_theme_constant_override("separation", 7)

        var finale_text := Label.new()
        finale_box.add_child(finale_text)
        finale_text.text = LoreRules.CHAPTER_ONE_FINALE
        finale_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        finale_text.add_theme_font_size_override("font_size", 10)
        finale_text.add_theme_color_override("font_color", Color("d7d1c2"))

        var finish_chapter := _button(finale_box, "ЗАВЕРШИТЬ ГЛАВУ I · +2 ОСК.", true)
        finish_chapter.custom_minimum_size = Vector2(0, 48)
        finish_chapter.pressed.connect(_claim_chapter_one)
    elif chapter_complete:
        _section(LoreRules.CHAPTER_TWO_TITLE, "Глава открыта как направление развития, а не как обещание уже готового региона.")

        var next_panel := _panel(body)
        var next_box := VBoxContainer.new()
        next_panel.add_child(next_box)
        next_box.add_theme_constant_override("separation", 5)

        var next_story := Label.new()
        next_box.add_child(next_story)
        next_story.text = LoreRules.CHAPTER_TWO_PROMISE
        next_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        next_story.add_theme_font_size_override("font_size", 10)
        next_story.add_theme_color_override("font_color", Color("cad6d2"))

        var next_objective := Label.new()
        next_box.add_child(next_objective)
        next_objective.text = "СЛЕДУЮЩАЯ ЦЕЛЬ
" + LoreRules.CHAPTER_TWO_OBJECTIVE
        next_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        next_objective.add_theme_font_size_override("font_size", 9)
        next_objective.add_theme_color_override("font_color", Color("d9b66d"))

    _section("Люди у Огня", "Спасённые жители превращают лагерь из меню между забегами в место, которое помнит твои решения.")

    var residents: Dictionary = GameState.data.get("residents", {})
    for resident_id: String in ResidentRules.ids():
        var resident: Dictionary = residents.get(resident_id, {})
        var unlocked: bool = bool(resident.get("unlocked", false))
        var resident_panel := _panel(body)
        var resident_box := VBoxContainer.new()
        resident_panel.add_child(resident_box)
        resident_box.add_theme_constant_override("separation", 3)

        var resident_title := Label.new()
        resident_box.add_child(resident_title)
        resident_title.text = "%s · %s" % [ResidentRules.role_for(resident_id), ResidentRules.name_for(resident_id).to_upper()] if unlocked else "НЕИЗВЕСТНЫЙ ВЫЖИВШИЙ"
        resident_title.add_theme_font_size_override("font_size", 10)
        resident_title.add_theme_color_override("font_color", Color("d9bf84") if unlocked else Color("6e7778"))

        var resident_desc := Label.new()
        resident_box.add_child(resident_desc)
        resident_desc.text = ResidentRules.description_for(resident_id) if unlocked else ("Помоги раненой разведчице в мире." if resident_id == "mira" else "Восстанови старую сломанную башню и дождись ответа на сигнал.")
        resident_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        resident_desc.add_theme_font_size_override("font_size", 9)
        resident_desc.add_theme_color_override("font_color", Color("aab5b3") if unlocked else Color("687173"))

        if unlocked:
            var trust := Label.new()
            resident_box.add_child(trust)
            trust.text = "Доверие %d/%d · поручение %d/%d" % [
                int(resident.get("trust", 0)),
                ResidentRules.max_trust(resident_id),
                mini(ResidentRules.chain_size(resident_id), int(resident.get("quest_step", 0)) + 1),
                ResidentRules.chain_size(resident_id)
            ]
            trust.add_theme_font_size_override("font_size", 8)
            trust.add_theme_color_override("font_color", Color("899796"))

    var quest_button := _button(body, "К ПОРУЧЕНИЯМ ЖИТЕЛЕЙ", false)
    quest_button.pressed.connect(_show_quests)
    var map_button := _button(body, "К КАРТЕ", false)
    map_button.pressed.connect(_show_map)

func _show_goals() -> void:
    _clear_body()
    _section("Трофеи и следы", "Реликвии хранят историю Хранителей. Достижения отмечают постоянные вехи лагеря.")

    var hall := TrophyHallView.new()
    body.add_child(hall)

    var world_stats: Dictionary = GameState.dynamic_world_stats()
    var field_panel := _panel(body)
    var field_box := VBoxContainer.new()
    field_panel.add_child(field_box)
    field_box.add_theme_constant_override("separation", 3)

    var field_title := Label.new()
    field_box.add_child(field_title)
    field_title.text = "ПОЛЕВОЙ ЖУРНАЛ"
    field_title.add_theme_font_size_override("font_size", 10)
    field_title.add_theme_color_override("font_color", Color("d7bb7a"))

    var field_text := Label.new()
    field_box.add_child(field_text)
    field_text.text = "События %d · Элиты %d · Спасения %d · Цепочки %d" % [
        int(world_stats.get("events", 0)),
        int(world_stats.get("elites", 0)),
        int(world_stats.get("rescues", 0)),
        int(world_stats.get("chains", 0))
    ]
    field_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    field_text.add_theme_font_size_override("font_size", 9)
    field_text.add_theme_color_override("font_color", Color("a9b6b2"))

    var field_objective_stats: Dictionary = GameState.field_objective_stats()
    var objective_text := Label.new()
    field_box.add_child(objective_text)
    objective_text.text = "Полевые цели %d · идеально %d · упущено %d" % [
        int(field_objective_stats.get("completed", 0)),
        int(field_objective_stats.get("perfect", 0)),
        int(field_objective_stats.get("failed", 0))
    ]
    objective_text.add_theme_font_size_override("font_size", 8)
    objective_text.add_theme_color_override("font_color", Color("8ea39a"))

    var region_stats: Dictionary = GameState.biome_event_stats()
    var region_lines: Array[String] = []
    for i: int in range(3):
        var biome_data: Dictionary = GameRules.biome(i)
        var biome_id: String = str(biome_data.get("id", "forest"))
        var stats_for_region: Dictionary = region_stats.get(biome_id, {})
        region_lines.append("%s · события %d · охоты %d · чисто %d" % [
            str(biome_data.get("name", "Регион")),
            int(stats_for_region.get("events", 0)),
            int(stats_for_region.get("hunts", 0)),
            int(stats_for_region.get("perfect", 0))
        ])

    var region_text := Label.new()
    field_box.add_child(region_text)
    region_text.text = "\n".join(PackedStringArray(region_lines))
    region_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    region_text.add_theme_font_size_override("font_size", 8)
    region_text.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)

    var relics: Array = GameState.data.get("boss_relics", [false, false, false])
    for i: int in range(3):
        if i >= relics.size() or not bool(relics[i]):
            continue
        var clue_panel := _panel(body)
        var clue := Label.new()
        clue_panel.add_child(clue)
        clue.text = "%s\n%s" % [WeaponRules.relic_name(i).to_upper(), LoreRules.relic_clue(i)]
        clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        clue.add_theme_font_size_override("font_size", 9)
        clue.add_theme_color_override("font_color", Color("c9c2ad"))

    var quests := _button(body, "ОТКРЫТЬ ДОСКУ ЗАДАНИЙ", false)
    quests.pressed.connect(_show_quests)

    _section("Достижения", "Постоянные цели не исчезают при ежедневном обновлении.")
    var biome_wins: Array = GameState.data["biome_wins"]
    var stats: Dictionary = GameState.data["stats"]
    _trophy("Первый Хранитель", "Победи босса Забытого леса", int(biome_wins[0]) > 0, "boss", 1, true)
    _trophy("Архитектор", "Построй 8 сооружений суммарно", int(stats["builds"]) >= 8, "builder", 75, false)
    _trophy("Охотник", "Уничтожь 75 врагов", int(stats["kills"]) >= 75, "hunter", 90, false)

func _show_quests() -> void:
    QuestDirector.ensure_daily_quests()
    _clear_body()
    _section("Доска заданий", "Три активных поручения меняются. После получения награды доска подбирает следующую цель.")

    var summary := _panel(body)
    var summary_box := VBoxContainer.new()
    summary.add_child(summary_box)
    summary_box.add_theme_constant_override("separation", 3)

    var day_label := Label.new()
    summary_box.add_child(day_label)
    day_label.text = "СЕГОДНЯ · МОЖНО ПОЛУЧИТЬ ЕЩЁ %d НАГР." % QuestDirector.claims_left_today()
    day_label.add_theme_font_size_override("font_size", 9)
    day_label.add_theme_color_override("font_color", Color("d0ac68"))

    var archive := Label.new()
    summary_box.add_child(archive)
    archive.text = "Выполнено поручений за всё время: %d" % QuestDirector.archive_count()
    archive.add_theme_font_size_override("font_size", 8)
    archive.add_theme_color_override("font_color", Color("9fa9aa"))

    var quests: Array[Dictionary] = QuestDirector.active_quests()
    if quests.is_empty():
        var empty := Label.new()
        body.add_child(empty)
        empty.text = "Все награды на сегодня получены. Новые поручения появятся завтра."
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.add_theme_color_override("font_color", Color("aeb8b9"))
    else:
        for quest: Dictionary in quests:
            _daily_quest_card(quest)

    _section("Поручения жителей", "У каждого спасённого жителя своя цепочка. Доверие растёт только за реальные действия в экспедициях.")
    var residents: Dictionary = GameState.data.get("residents", {})
    var unlocked_residents: int = 0
    for resident_id: String in ResidentRules.ids():
        var resident: Dictionary = residents.get(resident_id, {})
        if bool(resident.get("unlocked", false)):
            unlocked_residents += 1
            _resident_quest_card(resident_id, resident)

    if unlocked_residents < ResidentRules.ids().size():
        var locked := Label.new()
        body.add_child(locked)
        locked.text = "Ещё не все места у Огня заняты. Мира находится через спасение разведчицы, Торн — через восстановление старой башни."
        locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        locked.add_theme_font_size_override("font_size", 9)
        locked.add_theme_color_override("font_color", Color("7f898a"))

    var trophies := _button(body, "К РЕЛИКВИЯМ И ДОСТИЖЕНИЯМ", false)
    trophies.pressed.connect(_show_goals)

func _resident_quest_card(resident_id: String, resident: Dictionary) -> void:
    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 4)

    var top := HBoxContainer.new()
    box.add_child(top)
    top.add_theme_constant_override("separation", 6)

    var resident_icon := UiIcon.new()
    top.add_child(resident_icon)
    resident_icon.configure("camp", VisualSystem.GREEN if resident_id == "mira" else VisualSystem.GOLD, 0.66)

    var resident_title := Label.new()
    top.add_child(resident_title)
    resident_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    resident_title.text = "%s · %s" % [ResidentRules.name_for(resident_id).to_upper(), ResidentRules.role_for(resident_id)]
    resident_title.add_theme_font_size_override("font_size", 10)
    resident_title.add_theme_color_override("font_color", VisualSystem.TEXT)

    var trust := Label.new()
    top.add_child(trust)
    trust.text = "%d/%d" % [int(resident.get("trust",0)), ResidentRules.max_trust(resident_id)]
    trust.add_theme_font_size_override("font_size", 8)
    trust.add_theme_color_override("font_color", VisualSystem.GOLD_BRIGHT)

    var resident_quest: Dictionary = QuestDirector.resident_quest_state(resident_id)
    if resident_quest.is_empty():
        return

    if bool(resident_quest.get("complete", false)):
        var completed := Label.new()
        box.add_child(completed)
        completed.text = "Цепочка завершена · постоянный житель Последнего Очага"
        completed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        completed.add_theme_font_size_override("font_size", 8)
        completed.add_theme_color_override("font_color", VisualSystem.GREEN)
        return

    var title := Label.new()
    box.add_child(title)
    title.text = str(resident_quest.get("title","ПОРУЧЕНИЕ"))
    title.add_theme_font_size_override("font_size", 9)
    title.add_theme_color_override("font_color", Color("d4bc86"))

    var desc := Label.new()
    box.add_child(desc)
    desc.text = str(resident_quest.get("desc",""))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 8)
    desc.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)

    var goal: int = maxi(1,int(resident_quest.get("goal",1)))
    var progress: int = mini(goal,int(resident_quest.get("progress",0)))
    var bar := ProgressBar.new()
    box.add_child(bar)
    bar.custom_minimum_size = Vector2(0,5)
    bar.show_percentage = false
    bar.max_value = goal
    bar.value = progress
    _style_compact_progress(bar, VisualSystem.GREEN if resident_id == "mira" else VisualSystem.GOLD)

    var bottom := HBoxContainer.new()
    box.add_child(bottom)
    var progress_text := Label.new()
    bottom.add_child(progress_text)
    progress_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_text.text = "%d / %d" % [progress,goal]
    progress_text.add_theme_font_size_override("font_size", 8)
    progress_text.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)

    var reward_type: String = str(resident_quest.get("reward_type","coins"))
    var reward_text: String = "%d ОСК." % int(resident_quest.get("reward",0)) if reward_type=="shards" else "%d МОН." % int(resident_quest.get("reward",0))
    var claim := _button(bottom, "ЗАБРАТЬ · "+reward_text if bool(resident_quest.get("ready",false)) else reward_text, false)
    claim.custom_minimum_size = Vector2(108,34)
    claim.disabled = not bool(resident_quest.get("ready",false))
    claim.pressed.connect(_claim_resident_quest.bind(resident_id))

func _daily_quest_card(quest: Dictionary) -> void:
    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 4)

    var top := HBoxContainer.new()
    box.add_child(top)
    top.add_theme_constant_override("separation", 6)

    var icon := UiIcon.new()
    top.add_child(icon)
    icon.configure("quest", VisualSystem.GOLD, 0.66)

    var title := Label.new()
    top.add_child(title)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.text = str(quest.get("title","ЗАДАНИЕ"))
    title.add_theme_font_size_override("font_size", 10)
    title.add_theme_color_override("font_color", VisualSystem.TEXT)

    var category := Label.new()
    top.add_child(category)
    category.text = str(quest.get("category","")).to_upper()
    category.add_theme_font_size_override("font_size", 7)
    category.add_theme_color_override("font_color", Color("9f8b63"))

    var desc := Label.new()
    box.add_child(desc)
    desc.text = str(quest.get("desc",""))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 8)
    desc.add_theme_color_override("font_color", VisualSystem.TEXT_SOFT)

    var goal: int = maxi(1,int(quest.get("goal",1)))
    var progress: int = mini(goal,int(quest.get("progress",0)))

    var bar := ProgressBar.new()
    box.add_child(bar)
    bar.custom_minimum_size = Vector2(0,5)
    bar.show_percentage = false
    bar.max_value = goal
    bar.value = progress
    _style_compact_progress(bar, VisualSystem.GOLD)

    var bottom := HBoxContainer.new()
    box.add_child(bottom)

    var progress_text := Label.new()
    bottom.add_child(progress_text)
    progress_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_text.text = "%d / %d" % [progress,goal]
    progress_text.add_theme_font_size_override("font_size", 8)
    progress_text.add_theme_color_override("font_color", VisualSystem.TEXT_MUTED)

    var reward_type: String = str(quest.get("reward_type","coins"))
    var reward_text: String = "%d ОСК." % int(quest.get("reward",0)) if reward_type=="shards" else "%d МОН." % int(quest.get("reward",0))
    var claim := _button(bottom, "ЗАБРАТЬ · "+reward_text if bool(quest.get("ready",false)) else reward_text, false)
    claim.custom_minimum_size = Vector2(108,34)
    claim.disabled = not bool(quest.get("ready",false))
    claim.pressed.connect(_claim_daily_quest.bind(str(quest.get("id",""))))

func _style_compact_progress(bar: ProgressBar, accent: Color) -> void:
    var track := StyleBoxFlat.new()
    track.bg_color = Color("20292c")
    track.corner_radius_top_left = 2
    track.corner_radius_top_right = 2
    track.corner_radius_bottom_left = 2
    track.corner_radius_bottom_right = 2
    var fill := StyleBoxFlat.new()
    fill.bg_color = accent
    fill.corner_radius_top_left = 2
    fill.corner_radius_top_right = 2
    fill.corner_radius_bottom_left = 2
    fill.corner_radius_bottom_right = 2
    bar.add_theme_stylebox_override("background", track)
    bar.add_theme_stylebox_override("fill", fill)

func _claim_resident_quest(resident_id: String) -> void:
    var result: Dictionary = QuestDirector.claim_resident(resident_id)
    if bool(result.get("ok", false)):
        _refresh_currency()
    _show_quests()

func _claim_daily_quest(quest_id: String) -> void:
    var result: Dictionary = QuestDirector.claim(quest_id)
    if bool(result.get("ok", false)):
        _refresh_currency()
        Feedback.play("victory", 8)
    _show_quests()

func _claim_chapter_one() -> void:
    var result: Dictionary = GameState.claim_chapter_one()
    if bool(result.get("ok", false)):
        _refresh_currency()
        Feedback.play("victory", 18)
    _show_chronicle()

func _show_forge() -> void:
    _clear_body()
    _section("Кузница лагеря", "Постоянные улучшения помогают Страннику, но не заменяют решения внутри забега.")

    var intro := _panel(body)
    var intro_label := Label.new()
    intro.add_child(intro_label)
    intro_label.text = "Огонь кузницы питается от Последнего Очага. Чем сильнее лагерь, тем дальше Странник может уйти во Тьму."
    intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro_label.add_theme_font_size_override("font_size", 9)
    intro_label.add_theme_color_override("font_color", Color("bbb8aa"))

    _section("Чертежи укреплений", "Монеты развивают лагерь, а осколки Хранителей открывают качественно новые возможности внутри экспедиции.")

    for build_type: String in ["wall", "forge", "turret", "shrine"]:
        var project: Dictionary = BuildingRules.project_spec(build_type)
        var owned: bool = GameState.has_building_project(build_type)
        var mastery_need: int = int(project.get("min_mastery", 0))
        var available: bool = GameState.total_mastery() >= mastery_need

        var project_panel := _panel(body)
        var project_box := VBoxContainer.new()
        project_panel.add_child(project_box)
        project_box.add_theme_constant_override("separation", 5)

        var project_top := HBoxContainer.new()
        project_box.add_child(project_top)

        var project_title := Label.new()
        project_top.add_child(project_title)
        project_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        project_title.text = str(project.get("name", "ЧЕРТЁЖ"))
        project_title.add_theme_font_size_override("font_size", 12)
        project_title.add_theme_color_override("font_color", Color("efe0c1"))

        var project_state := Label.new()
        project_top.add_child(project_state)
        project_state.add_theme_font_size_override("font_size", 8)
        if owned:
            project_state.text = "ИЗУЧЕНО"
            project_state.add_theme_color_override("font_color", Color("8fd5b0"))
        elif available:
            project_state.text = "ДОСТУПНО"
            project_state.add_theme_color_override("font_color", Color("d6bd83"))
        else:
            project_state.text = "МАСТ. %d" % mastery_need
            project_state.add_theme_color_override("font_color", Color("777f81"))

        var project_desc := Label.new()
        project_box.add_child(project_desc)
        project_desc.text = str(project.get("desc", ""))
        project_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        project_desc.add_theme_font_size_override("font_size", 9)
        project_desc.add_theme_color_override("font_color", Color("aeb7b9"))

        var branches: Array[Dictionary] = BuildingRules.branches(build_type)
        var branch_names := PackedStringArray()
        for branch_spec: Dictionary in branches:
            branch_names.append(str(branch_spec.get("name", "ВЕТКА")))
        var branch_label := Label.new()
        project_box.add_child(branch_label)
        branch_label.text = "В экспедиции: " + " / ".join(branch_names)
        branch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        branch_label.add_theme_font_size_override("font_size", 8)
        branch_label.add_theme_color_override("font_color", Color("8fa0a2"))

        if not owned:
            var coin_cost: int = int(project.get("coins", 0))
            var shard_cost: int = int(project.get("shards", 0))
            var can_pay: bool = int(GameState.data.get("coins", 0)) >= coin_cost and int(GameState.data.get("shards", 0)) >= shard_cost and available
            var buy_project := _button(project_box, "%d МОН. · %d ОСК." % [coin_cost, shard_cost], false)
            buy_project.disabled = not can_pay
            buy_project.pressed.connect(_buy_building_project.bind(build_type))

    _section("Реликтовая кузня", "Осколки теперь дают постоянный выбор между силой, выживанием и экономикой.")

    var forge_specs: Array[Dictionary] = [
        {"id":"power","name":"ЖАР ОРУЖИЯ","desc":"+5% урона во всех режимах за уровень"},
        {"id":"ward","name":"КЛЯТВА ОЧАГА","desc":"+12 максимального HP за уровень"},
        {"id":"fortune","name":"ЗНАК ДОБЫТЧИКА","desc":"+10% монет за экспедицию за уровень"}
    ]
    for forge_spec: Dictionary in forge_specs:
        var forge_id: String = str(forge_spec.get("id",""))
        var level_value: int = GameState.relic_forge_level(forge_id)
        var forge_panel := _panel(body)
        var forge_row := HBoxContainer.new()
        forge_panel.add_child(forge_row)
        forge_row.add_theme_constant_override("separation",8)

        var forge_copy := Label.new()
        forge_row.add_child(forge_copy)
        forge_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        forge_copy.text = "%s · %s\n%s" % [
            str(forge_spec.get("name","")),
            ThreatRules.stars(level_value).substr(0,3),
            str(forge_spec.get("desc",""))
        ]
        forge_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        forge_copy.add_theme_font_size_override("font_size",9)
        forge_copy.add_theme_color_override("font_color",VisualSystem.TEXT_SOFT)

        var forge_buy := _button(forge_row,"МАКС." if level_value >= 3 else "%d ОСК." % GameState.relic_forge_cost(forge_id),false)
        forge_buy.custom_minimum_size = Vector2(92,44)
        forge_buy.disabled = level_value >= 3 or int(GameState.data.get("shards",0)) < GameState.relic_forge_cost(forge_id)
        forge_buy.pressed.connect(_buy_relic_forge.bind(forge_id))

    _section("Подготовка Странника", "Обычные улучшения остаются полезными, но теперь конкурируют с чертежами за монеты.")

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

func _buy_relic_forge(kind: String) -> void:
    if GameState.buy_relic_forge(kind):
        Feedback.play("level",12)
    _show_forge()

func _buy_building_project(build_type: String) -> void:
    if GameState.buy_building_project(build_type):
        Feedback.play("level", 12)
        _refresh_currency()
    _show_forge()

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
        "quests":
            _show_quests()
        "contracts":
            _show_contracts()
        "chronicle":
            _show_chronicle()
        "map":
            _show_map()

func _select_biome_from_map(index: int) -> void:
    selected_biome = index
    GameState.data["selected_biome"] = index
    var max_threat: int = GameState.threat_unlocked_level(index)
    GameState.data["selected_threat"] = mini(int(GameState.data.get("selected_threat",1)), max_threat)
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
    var reach: int = int(round(float(profile.get("attack_range", profile.get("orbit_radius", 44.0)))))
    var crit: int = int(round(float(profile.get("crit_bonus", 0.0)) * 100.0))
    var cooldown: float = float(profile.get("attack_cooldown", 0.0))
    var rhythm: String = "ПОСТОЯННО" if cooldown <= 0.01 else "%.2f С" % cooldown
    return "Урон %d%% · Скорость %d%% · Дистанция %d · Крит +%d%% · Ритм %s" % [damage_percent, speed_percent, reach, crit, rhythm]

func _select_weapon_from_camp(weapon_id: String) -> void:
    if not GameState.select_weapon(weapon_id):
        return
    Feedback.play("level", 10)
    Analytics.event("camp_weapon_selected", {"weapon": weapon_id})
    _show_arsenal()
