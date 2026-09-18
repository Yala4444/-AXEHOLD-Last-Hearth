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
    var chapter_one_complete: bool = GameState.chapter_one_complete()
    chapter.text = LoreRules.chapter_title(chapter_one_complete)
    chapter.add_theme_font_size_override("font_size", 9)
    chapter.add_theme_color_override("font_color", Color("d0ac68"))

    var whisper := Label.new()
    story_box.add_child(whisper)
    whisper.text = LoreRules.chapter_promise(true) if chapter_one_complete else LoreRules.camp_whisper(relic_count)
    whisper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    whisper.add_theme_font_size_override("font_size", 10)
    whisper.add_theme_color_override("font_color", Color("c5cec9"))

    var chronicle_text: String = "ХРОНИКА · ГЛАВА II" if chapter_one_complete else ("ХРОНИКА · ФИНАЛ ГЛАВЫ I" if GameState.chapter_one_ready() else "ОТКРЫТЬ ХРОНИКУ")
    var chronicle_button := _button(body, chronicle_text, false)
    chronicle_button.custom_minimum_size = Vector2(0, 38)
    chronicle_button.pressed.connect(_show_chronicle)

    var quest_button := _button(body, "ДОСКА ЗАДАНИЙ · %d АКТИВНЫХ" % QuestDirector.active_quests().size(), false)
    quest_button.custom_minimum_size = Vector2(0, 40)
    quest_button.pressed.connect(_show_quests)

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
    progress.text = "%s · Слава %d/%d   •   Реликвии %d/3" % [
        GameState.camp_level_name(),
        GameState.camp_renown(),
        GameState.camp_next_renown(),
        relic_count
    ]
    progress.add_theme_font_size_override("font_size", 8)
    progress.add_theme_color_override("font_color", Color(0.63, 0.69, 0.70))

    var active_contract: Dictionary = GameState.selected_contract()
    var contract_line := Label.new()
    departure_box.add_child(contract_line)
    if active_contract.is_empty():
        contract_line.text = "КОНТРАКТ НЕ ВЫБРАН · случайное полевое поручение не приносит славу лагерю"
        contract_line.add_theme_color_override("font_color", Color("8b9495"))
    else:
        contract_line.text = "КОНТРАКТ · %s · %s · +%d славы" % [
            str(active_contract.get("name", "")),
            str(active_contract.get("risk", "СРЕДНИЙ")),
            int(active_contract.get("renown", 1))
        ]
        contract_line.add_theme_color_override("font_color", Color("d7ba7b"))
    contract_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    contract_line.add_theme_font_size_override("font_size", 8)

    var contract_button := _button(departure_box, "ВЫБРАТЬ КОНТРАКТ", false)
    contract_button.custom_minimum_size = Vector2(0, 38)
    contract_button.pressed.connect(_show_contracts)

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

    var identity := Label.new()
    hero_box.add_child(identity)
    identity.text = str(selected_profile.get("identity", "")).to_upper()
    identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    identity.add_theme_font_size_override("font_size", 9)
    identity.add_theme_color_override("font_color", Color("d2af6c"))

    var signature := Label.new()
    hero_box.add_child(signature)
    signature.text = str(selected_profile.get("signature", ""))
    signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    signature.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    signature.add_theme_font_size_override("font_size", 9)
    signature.add_theme_color_override("font_color", Color("c7d0cc"))

    var selected_mastery_level: int = GameState.weapon_mastery_level(selected_id)
    var selected_mastery := Label.new()
    hero_box.add_child(selected_mastery)
    selected_mastery.text = "МАСТЕРСТВО %s" % GameState.weapon_mastery_stars(selected_id)
    selected_mastery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    selected_mastery.add_theme_font_size_override("font_size", 10)
    selected_mastery.add_theme_color_override("font_color", Color("d8bd7b"))

    var mastery_effect := Label.new()
    hero_box.add_child(mastery_effect)
    mastery_effect.text = "%s\nСледующее: %s" % [
        WeaponRules.weapon_mastery_bonus_text(selected_id, selected_mastery_level),
        WeaponRules.mastery_next_text(selected_id, selected_mastery_level)
    ]
    mastery_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mastery_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mastery_effect.add_theme_font_size_override("font_size", 8)
    mastery_effect.add_theme_color_override("font_color", Color("98a6a5"))

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
        role.text = "%s · %s" % [
            str(profile.get("identity", "")),
            str(profile.get("signature", ""))
        ]
        role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        role.add_theme_font_size_override("font_size", 9)
        role.add_theme_color_override("font_color", Color("aeb7b9"))

        var stats_text := Label.new()
        box.add_child(stats_text)
        stats_text.text = _weapon_stats_text(profile)
        stats_text.add_theme_font_size_override("font_size", 8)
        stats_text.add_theme_color_override("font_color", Color("c6ae7c"))

        if is_owned:
            var mastery_level: int = GameState.weapon_mastery_level(weapon_id)
            var mastery_line := Label.new()
            box.add_child(mastery_line)
            mastery_line.text = "МАСТЕРСТВО %s · %s" % [
                GameState.weapon_mastery_stars(weapon_id),
                WeaponRules.mastery_next_text(weapon_id, mastery_level)
            ]
            mastery_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            mastery_line.add_theme_font_size_override("font_size", 8)
            mastery_line.add_theme_color_override("font_color", Color("9b9480"))

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

    var play := _button(body, "В ЭКСПЕДИЦИЮ: " + str(biome_data.get("name", "Регион")).to_upper(), true)
    play.pressed.connect(_start_game)

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
    var resident_panel := _panel(body)
    var resident_box := VBoxContainer.new()
    resident_panel.add_child(resident_box)
    resident_box.add_theme_constant_override("separation", 5)

    var resident_title := Label.new()
    resident_box.add_child(resident_title)
    resident_title.text = "%s %s · ДОВЕРИЕ %d/%d" % [
        ResidentRules.role_for(resident_id),
        ResidentRules.name_for(resident_id).to_upper(),
        int(resident.get("trust", 0)),
        ResidentRules.max_trust(resident_id)
    ]
    resident_title.add_theme_font_size_override("font_size", 11)
    resident_title.add_theme_color_override("font_color", Color("e6c98c"))

    var role_desc := Label.new()
    resident_box.add_child(role_desc)
    role_desc.text = ResidentRules.description_for(resident_id)
    role_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    role_desc.add_theme_font_size_override("font_size", 8)
    role_desc.add_theme_color_override("font_color", Color("889597"))

    var resident_quest: Dictionary = QuestDirector.resident_quest_state(resident_id)
    if resident_quest.is_empty():
        return

    var resident_desc := Label.new()
    resident_box.add_child(resident_desc)
    resident_desc.text = str(resident_quest.get("desc", ""))
    resident_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    resident_desc.add_theme_font_size_override("font_size", 9)
    resident_desc.add_theme_color_override("font_color", Color("aeb8b9"))

    if not bool(resident_quest.get("complete", false)):
        var rq_goal: int = maxi(1, int(resident_quest.get("goal", 1)))
        var rq_progress: int = mini(rq_goal, int(resident_quest.get("progress", 0)))

        var row := HBoxContainer.new()
        resident_box.add_child(row)
        row.add_theme_constant_override("separation", 6)

        var resident_progress := Label.new()
        row.add_child(resident_progress)
        resident_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        resident_progress.text = "%s · %d/%d" % [str(resident_quest.get("title", "ПОРУЧЕНИЕ")), rq_progress, rq_goal]
        resident_progress.add_theme_font_size_override("font_size", 9)
        resident_progress.add_theme_color_override("font_color", Color("c9d2cf"))

        var reward_type: String = str(resident_quest.get("reward_type", "coins"))
        var reward_text: String = "%d ОСК." % int(resident_quest.get("reward", 0)) if reward_type == "shards" else "%d МОН." % int(resident_quest.get("reward", 0))
        var claim := _button(row, "ЗАБРАТЬ · " + reward_text if bool(resident_quest.get("ready", false)) else reward_text, false)
        claim.custom_minimum_size = Vector2(124, 40)
        claim.disabled = not bool(resident_quest.get("ready", false))
        claim.pressed.connect(_claim_resident_quest.bind(resident_id))
    else:
        var completed := Label.new()
        resident_box.add_child(completed)
        completed.text = "Цепочка завершена. %s остаётся постоянным жителем лагеря." % ResidentRules.name_for(resident_id)
        completed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        completed.add_theme_font_size_override("font_size", 9)
        completed.add_theme_color_override("font_color", Color("8fd5b0"))

func _daily_quest_card(quest: Dictionary) -> void:
    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 5)

    var top := HBoxContainer.new()
    box.add_child(top)

    var title := Label.new()
    top.add_child(title)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.text = str(quest.get("title", "ЗАДАНИЕ"))
    title.add_theme_font_size_override("font_size", 12)
    title.add_theme_color_override("font_color", Color("efe5d0"))

    var category := Label.new()
    top.add_child(category)
    category.text = str(quest.get("category", "")).to_upper()
    category.add_theme_font_size_override("font_size", 7)
    category.add_theme_color_override("font_color", Color("9a8761"))

    var desc := Label.new()
    box.add_child(desc)
    desc.text = str(quest.get("desc", ""))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 9)
    desc.add_theme_color_override("font_color", Color("aeb7b9"))

    var goal: int = maxi(1, int(quest.get("goal", 1)))
    var progress: int = mini(goal, int(quest.get("progress", 0)))

    var progress_row := HBoxContainer.new()
    box.add_child(progress_row)

    var progress_text := Label.new()
    progress_row.add_child(progress_text)
    progress_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    progress_text.text = "%d / %d" % [progress, goal]
    progress_text.add_theme_font_size_override("font_size", 10)
    progress_text.add_theme_color_override("font_color", Color("c9d2cf"))

    var reward_type: String = str(quest.get("reward_type", "coins"))
    var reward_text: String = "%d ОСК." % int(quest.get("reward", 0)) if reward_type == "shards" else "%d МОН." % int(quest.get("reward", 0))
    var claim := _button(progress_row, "ЗАБРАТЬ · " + reward_text if bool(quest.get("ready", false)) else reward_text, false)
    claim.custom_minimum_size = Vector2(126, 40)
    claim.disabled = not bool(quest.get("ready", false))
    claim.pressed.connect(_claim_daily_quest.bind(str(quest.get("id", ""))))

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
