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

    var quest_button := _button(body, "ДОСКА ЗАДАНИЙ · %d АКТИВНЫХ" % QuestDirector.active_quests().size(), false)
    quest_button.custom_minimum_size = Vector2(0, 40)
    quest_button.pressed.connect(_show_quests)

    if GameState.chapter_one_complete():
        var frontier_button := _button(body, "СИГНАЛ ЗА ПЕПЛОМ · ДАЛЬНИЕ ВЫХОДЫ", true)
        frontier_button.custom_minimum_size = Vector2(0, 44)
        frontier_button.pressed.connect(_show_frontier)

    _add_resident_support_picker()

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

    var frontier_assignment: Dictionary = QuestDirector.frontier_assignment_state()
    if not frontier_assignment.is_empty():
        var assignment_line := Label.new()
        departure_box.add_child(assignment_line)
        assignment_line.text = "ДАЛЬНИЙ ВЫХОД · %s · до ночи %d" % [
            str(frontier_assignment.get("name", "")),
            int(frontier_assignment.get("deadline_wave", 1)) + 1
        ]
        assignment_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        assignment_line.add_theme_font_size_override("font_size", 8)
        assignment_line.add_theme_color_override("font_color", Color("d2b270"))

    var support_id: String = GameState.selected_run_support()
    if not support_id.is_empty():
        var support_line := Label.new()
        departure_box.add_child(support_line)
        support_line.text = "ПОДДЕРЖКА · " + str(FrontierRules.support(support_id).get("name", ""))
        support_line.add_theme_font_size_override("font_size", 8)
        support_line.add_theme_color_override("font_color", Color("9bc9b6"))

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
    _section("Карта Тьмы", "Чем дальше от Последнего Очагa, тем меньше мир похож на то, что было раньше.")

    var map_view := WorldMapView.new()
    body.add_child(map_view)
    map_view.configure(selected_biome)
    map_view.biome_selected.connect(_select_biome_from_map)
    map_view.frontier_requested.connect(_show_frontier)

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

    if GameState.chapter_one_complete():
        var finale_panel := _panel(body)
        var finale_box := VBoxContainer.new()
        finale_panel.add_child(finale_box)
        finale_box.add_theme_constant_override("separation", 4)

        var finale_title := Label.new()
        finale_box.add_child(finale_title)
        finale_title.text = "ГЛАВА I ЗАВЕРШЕНА · ПОГАСАНИЕ"
        finale_title.add_theme_font_size_override("font_size", 11)
        finale_title.add_theme_color_override("font_color", Color("dfc27e"))

        var finale_text := Label.new()
        finale_box.add_child(finale_text)
        finale_text.text = LoreRules.CHAPTER_ONE_FINALE + "\n\n" + LoreRules.FRONTIER_SIGNAL
        finale_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        finale_text.add_theme_font_size_override("font_size", 9)
        finale_text.add_theme_color_override("font_color", Color("bdc7c5"))

        var lore_count := Label.new()
        finale_box.add_child(lore_count)
        lore_count.text = "Фрагменты памяти: %d" % int(GameState.data.get("lore_fragments", 0))
        lore_count.add_theme_font_size_override("font_size", 8)
        lore_count.add_theme_color_override("font_color", Color("929fa0"))

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

    _section("Поручения жителей", "Спасённые жители дают последовательные цепочки, а доверие открывает поддержку перед экспедицией.")
    _resident_quest_card("mira", "РАЗВЕДЧИЦА МИРА")
    if GameState.chapter_one_complete():
        _resident_quest_card("thorn", "МЕХАНИК ТОРН")

    var trophies := _button(body, "К РЕЛИКВИЯМ И ДОСТИЖЕНИЯМ", false)
    trophies.pressed.connect(_show_goals)

func _resident_quest_card(resident_id: String, display_name: String) -> void:
    var residents: Dictionary = GameState.data.get("residents", {})
    var resident: Dictionary = residents.get(resident_id, {})
    if not bool(resident.get("unlocked", false)):
        var locked := Label.new()
        body.add_child(locked)
        locked.text = "%s · %s" % [
            display_name,
            "ищи разведчицу в дальних областях" if resident_id == "mira" else "после трёх реликвий найди механика за границей света"
        ]
        locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        locked.add_theme_font_size_override("font_size", 9)
        locked.add_theme_color_override("font_color", Color("777f81"))
        return

    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 5)

    var title := Label.new()
    box.add_child(title)
    title.text = "%s · ДОВЕРИЕ %d/3" % [display_name, int(resident.get("trust", 0))]
    title.add_theme_font_size_override("font_size", 11)
    title.add_theme_color_override("font_color", Color("e6c98c"))

    var quest: Dictionary = QuestDirector.resident_quest_state(resident_id)
    var desc := Label.new()
    box.add_child(desc)
    desc.text = str(quest.get("desc", "Поручений пока нет."))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 9)
    desc.add_theme_color_override("font_color", Color("aeb8b9"))

    if bool(quest.get("complete", false)):
        var done := Label.new()
        box.add_child(done)
        done.text = "Текущая цепочка завершена. Поддержка жителя остаётся доступной."
        done.add_theme_font_size_override("font_size", 9)
        done.add_theme_color_override("font_color", Color("8fd5b0"))
        return

    var goal: int = maxi(1, int(quest.get("goal", 1)))
    var progress: int = mini(goal, int(quest.get("progress", 0)))
    var progress_label := Label.new()
    box.add_child(progress_label)
    progress_label.text = "%s · %d/%d" % [str(quest.get("title", "ПОРУЧЕНИЕ")), progress, goal]
    progress_label.add_theme_font_size_override("font_size", 9)
    progress_label.add_theme_color_override("font_color", Color("c9d2cf"))

    if bool(quest.get("ready", false)):
        var claim := _button(box, "ЗАБРАТЬ НАГРАДУ", false)
        claim.pressed.connect(_claim_resident_quest.bind(resident_id))

func _add_resident_support_picker() -> void:
    var available: Array[String] = []
    for support_id: String in FrontierRules.support_ids():
        if GameState.support_available(support_id):
            available.append(support_id)
    if available.is_empty():
        return

    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 4)

    var title := Label.new()
    box.add_child(title)
    title.text = "ПОДДЕРЖКА ЖИТЕЛЕЙ · ОДНА НА СЛЕДУЮЩИЙ ВЫХОД"
    title.add_theme_font_size_override("font_size", 8)
    title.add_theme_color_override("font_color", Color("bca36e"))

    var selected: String = GameState.selected_run_support()
    for support_id: String in available:
        var spec: Dictionary = FrontierRules.support(support_id)
        var button := _button(box, ("%s · %s" % [str(spec.get("name", "")), str(spec.get("desc", ""))]), selected == support_id)
        button.custom_minimum_size = Vector2(0, 46)
        button.disabled = selected == support_id
        button.pressed.connect(_select_run_support.bind(support_id))

func _select_run_support(support_id: String) -> void:
    if GameState.select_run_support(support_id):
        Feedback.play("level", 6)
    _show_home()

func _show_frontier() -> void:
    _clear_body()
    _section(LoreRules.FRONTIER_SIGNAL_TITLE, LoreRules.CHAPTER_TWO_TEASE)

    var story := _panel(body)
    var story_box := VBoxContainer.new()
    story.add_child(story_box)
    story_box.add_theme_constant_override("separation", 5)

    var finale := Label.new()
    story_box.add_child(finale)
    finale.text = LoreRules.CHAPTER_ONE_FINALE
    finale.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    finale.add_theme_font_size_override("font_size", 10)
    finale.add_theme_color_override("font_color", Color("e0d1b0"))

    var signal := Label.new()
    story_box.add_child(signal)
    signal.text = LoreRules.FRONTIER_SIGNAL
    signal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    signal.add_theme_font_size_override("font_size", 9)
    signal.add_theme_color_override("font_color", Color("aebabc"))

    var frontier_state: Dictionary = GameState.data.get("frontier_state", {})
    var completed: int = int(frontier_state.get("assignments_completed", 0))
    var progress := Label.new()
    story_box.add_child(progress)
    progress.text = "ДАЛЬНИЕ ВЫХОДЫ: %d · %s" % [completed, LoreRules.frontier_progress_text(completed)]
    progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    progress.add_theme_font_size_override("font_size", 9)
    progress.add_theme_color_override("font_color", Color("b9b7d8"))

    _section("Разведывательные задания", "Выбери одно. Цель нужно выполнить до второй ночи, а затем физически вернуться к Последнему Очагу.")

    var selected: String = GameState.frontier_assignment_id()
    for assignment_id: String in FrontierRules.assignment_ids():
        var spec: Dictionary = FrontierRules.assignment(assignment_id)
        var panel := _panel(body)
        var box := VBoxContainer.new()
        panel.add_child(box)
        box.add_theme_constant_override("separation", 4)

        var top := HBoxContainer.new()
        box.add_child(top)
        var assignment_title := Label.new()
        top.add_child(assignment_title)
        assignment_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        assignment_title.text = str(spec.get("name", "ЗАДАНИЕ"))
        assignment_title.add_theme_font_size_override("font_size", 12)
        assignment_title.add_theme_color_override("font_color", Color("e8dcc4"))

        var reward := Label.new()
        top.add_child(reward)
        reward.text = FrontierRules.reward_text(spec)
        reward.add_theme_font_size_override("font_size", 8)
        reward.add_theme_color_override("font_color", Color("d7b86e"))

        var desc := Label.new()
        box.add_child(desc)
        desc.text = str(spec.get("desc", ""))
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.add_theme_font_size_override("font_size", 9)
        desc.add_theme_color_override("font_color", Color("aeb8b9"))

        var pick := _button(box, "ВЫБРАНО" if selected == assignment_id else "ВЗЯТЬ ЗАДАНИЕ", selected == assignment_id)
        pick.disabled = selected == assignment_id
        pick.pressed.connect(_select_frontier_assignment.bind(assignment_id))

    if not selected.is_empty():
        var current: Dictionary = FrontierRules.assignment(selected)
        var current_note := Label.new()
        body.add_child(current_note)
        current_note.text = "Следующая экспедиция: %s. Регион можно выбрать на Карте." % str(current.get("name", "Дальний выход"))
        current_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        current_note.add_theme_font_size_override("font_size", 9)
        current_note.add_theme_color_override("font_color", Color("d7c58e"))

        var depart := _button(body, "В ЭКСПЕДИЦИЮ С ЗАДАНИЕМ", true)
        depart.pressed.connect(_start_game)

    var back := _button(body, "К КАРТЕ", false)
    back.pressed.connect(_show_map)

func _select_frontier_assignment(assignment_id: String) -> void:
    if GameState.select_frontier_assignment(assignment_id):
        Feedback.play("level", 8)
    _show_frontier()

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
